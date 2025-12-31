import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Admin: Create/Update Admin Profile
  Future<void> saveAdminProfile(AdminModel admin) async {
    await _db.collection('admins').doc(admin.email).set(admin.toMap());
  }

  // Admin: Get Admin Profile
  Stream<AdminModel?> getAdminProfile(String email) {
    return _db.collection('admins').doc(email).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return AdminModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // Admin: Add Person (User)
  // Persons are stored in a top-level collection 'persons' but linked by adminEmail
  // or subcollection of admins?
  // "collectin kharcha -> admin data with his email collection"
  // "admin all persons with unique id of 6 digits with generated random"
  // Let's use a subcollection 'persons' under the admin document to keep it organized and efficient for querying by admin.
  // Actually, for "User Login" which needs to find the person by "Admin Email" + "6 digit ID",
  // structure: admins/{adminEmail}/persons/{personId} works well.

  // Global: Find Person by ID (using Lookup Collection)
  // Bypasses the need for Collection Group Index
  Future<PersonModel?> findPersonById(String personId) async {
    try {
      // 1. Check Lookup Table
      final lookupDoc = await _db
          .collection('person_lookups')
          .doc(personId)
          .get();

      if (lookupDoc.exists && lookupDoc.data() != null) {
        final adminEmail = lookupDoc.data()!['adminEmail'] as String;

        // 2. Fetch Actual Person Data
        final personDoc = await _db
            .collection('admins')
            .doc(adminEmail)
            .collection('persons')
            .doc(personId)
            .get();

        if (personDoc.exists) {
          return PersonModel.fromMap(personDoc.data()!);
        }
      }
      return null;
    } catch (e) {
      print('Error finding person: $e');
      rethrow;
    }
  }

  // Check if Person ID exists (Global Uniqueness via Lookup)
  Future<bool> checkPersonIdExists(String adminEmail, String personId) async {
    final doc = await _db.collection('person_lookups').doc(personId).get();
    return doc.exists;
  }

  // Data Stream: All Persons for an Admin
  Stream<List<PersonModel>> getPersons(String adminEmail) {
    return _db
        .collection('admins')
        .doc(adminEmail)
        .collection('persons')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PersonModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Single Person Stream
  Stream<PersonModel?> getPerson(String adminEmail, String personId) {
    return _db
        .collection('admins')
        .doc(adminEmail)
        .collection('persons')
        .doc(personId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return PersonModel.fromMap(snapshot.data()!);
          }
          return null;
        });
  }

  // Add Transaction (Expense or Cash)
  Future<void> addTransaction(TransactionModel transaction) async {
    final batch = _db.batch();

    // 1. Save Transaction to a global 'transactions' collection or subcollection
    DocumentReference txRef = _db
        .collection('admins')
        .doc(transaction.adminEmail)
        .collection('transactions')
        .doc(transaction.id);
    batch.set(txRef, transaction.toMap());

    // 2. Update each involved person's stats
    for (String personId in transaction.involvedUserIds) {
      DocumentReference personRef = _db
          .collection('admins')
          .doc(transaction.adminEmail)
          .collection('persons')
          .doc(personId);

      if (transaction.type == TransactionType.expense) {
        batch.update(personRef, {
          'totalExpense': FieldValue.increment(transaction.amount),
        });
      } else {
        batch.update(personRef, {
          'totalCash': FieldValue.increment(transaction.amount), // Cash added
        });
      }
    }

    await batch.commit();
  }

  Future<void> addPerson(String adminEmail, PersonModel person) async {
    final batch = _db.batch();

    // 1. Add to Admin's Person List
    final personRef = _db
        .collection('admins')
        .doc(adminEmail)
        .collection('persons')
        .doc(person.id);
    batch.set(personRef, person.toMap());

    // 2. Add to Global Lookup Table
    final lookupRef = _db.collection('person_lookups').doc(person.id);
    batch.set(lookupRef, {
      'adminEmail': adminEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Admin: Delete Person
  Future<void> deletePerson(String adminEmail, String personId) async {
    final batch = _db.batch();

    // 1. Delete from Admin's List
    final personRef = _db
        .collection('admins')
        .doc(adminEmail)
        .collection('persons')
        .doc(personId);
    batch.delete(personRef);

    // 2. Delete from Global Lookup
    final lookupRef = _db.collection('person_lookups').doc(personId);
    batch.delete(lookupRef);

    // Note: Transactions remain for history integrity
    await batch.commit();
  }

  // Get Transactions for a specific person
  Stream<List<TransactionModel>> getPersonTransactions(
    String adminEmail,
    String personId,
  ) {
    return _db
        .collection('admins')
        .doc(adminEmail)
        .collection('transactions')
        .where('involvedUserIds', arrayContains: personId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data()))
              .toList();
          // Sort client-side
          docs.sort((a, b) => b.date.compareTo(a.date));
          return docs;
        });
  }

  // Admin: Get all transactions
  Stream<List<TransactionModel>> getAllTransactions(String adminEmail) {
    return _db
        .collection('admins')
        .doc(adminEmail)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Reset Person Data (Clear History & Stats)
  Future<void> resetPersonData(String adminEmail, String personId) async {
    WriteBatch batch = _db.batch();

    // 1. Reset Stats
    DocumentReference personRef = _db
        .collection('admins')
        .doc(adminEmail)
        .collection('persons')
        .doc(personId);

    batch.update(personRef, {'totalCash': 0.0, 'totalExpense': 0.0});

    // 2. Handle Transactions
    // Get all transactions involving this user
    QuerySnapshot txSnapshot = await _db
        .collection('admins')
        .doc(adminEmail)
        .collection('transactions')
        .where('involvedUserIds', arrayContains: personId)
        .get();

    for (var doc in txSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final involved = List<String>.from(data['involvedUserIds'] ?? []);

      if (involved.length == 1) {
        // Only this user -> Delete
        batch.delete(doc.reference);
      } else {
        // Shared -> Remove user from list
        batch.update(doc.reference, {
          'involvedUserIds': FieldValue.arrayRemove([personId]),
        });
      }
    }

    await batch.commit();
  }

  // Delete Transaction (Reverse Stats & Delete Doc)
  Future<void> deleteTransaction(TransactionModel tx) async {
    WriteBatch batch = _db.batch();

    // 1. Delete Transaction Doc
    DocumentReference txRef = _db
        .collection('admins')
        .doc(tx.adminEmail)
        .collection('transactions')
        .doc(tx.id);
    batch.delete(txRef);

    // 2. Reverse Stats
    for (String personId in tx.involvedUserIds) {
      DocumentReference personRef = _db
          .collection('admins')
          .doc(tx.adminEmail)
          .collection('persons')
          .doc(personId);

      if (tx.type == TransactionType.expense) {
        // Was expense (added to totalExpense), so subtract it
        batch.update(personRef, {
          'totalExpense': FieldValue.increment(-tx.amount),
        });
      } else {
        // Was cash (added to totalCash), so subtract it
        batch.update(personRef, {
          'totalCash': FieldValue.increment(-tx.amount),
        });
      }
    }
    await batch.commit();
  }

  // Update Transaction
  Future<void> updateTransaction(
    TransactionModel oldTx,
    TransactionModel newTx,
  ) async {
    WriteBatch batch = _db.batch();

    // 1. Update Transaction Doc
    DocumentReference txRef = _db
        .collection('admins')
        .doc(newTx.adminEmail)
        .collection('transactions')
        .doc(newTx.id);
    batch.update(txRef, newTx.toMap());

    // 2. Adjust Stats (Only if amount or type changed)
    // Simplest way: Reverse Old, Apply New.
    // Optimized way: Calculate diff. Let's do Reverse+Apply for safety/clarity.

    // Reverse Old
    for (String personId in oldTx.involvedUserIds) {
      DocumentReference personRef = _db
          .collection('admins')
          .doc(oldTx.adminEmail)
          .collection('persons')
          .doc(personId);
      if (oldTx.type == TransactionType.expense) {
        batch.update(personRef, {
          'totalExpense': FieldValue.increment(-oldTx.amount),
        });
      } else {
        batch.update(personRef, {
          'totalCash': FieldValue.increment(-oldTx.amount),
        });
      }
    }

    // Apply New
    for (String personId in newTx.involvedUserIds) {
      DocumentReference personRef = _db
          .collection('admins')
          .doc(newTx.adminEmail)
          .collection('persons')
          .doc(personId);
      if (newTx.type == TransactionType.expense) {
        batch.update(personRef, {
          'totalExpense': FieldValue.increment(newTx.amount),
        });
      } else {
        batch.update(personRef, {
          'totalCash': FieldValue.increment(newTx.amount),
        });
      }
    }

    await batch.commit();
  }
}
