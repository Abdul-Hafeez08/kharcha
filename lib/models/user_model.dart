class AdminModel {
  final String uid;
  final String email;
  final String name;
  final String khataName;
  final String phoneNumber;

  AdminModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.khataName,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'khataName': khataName,
      'phoneNumber': phoneNumber,
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      khataName: map['khataName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}

class PersonModel {
  final String id; // 6-digit unique ID
  final String name;
  // final String phone;

  final double totalCash;
  final double totalExpense;
  final DateTime createdAt;
  final String adminEmail; // Reference to admin

  PersonModel({
    required this.id,
    required this.name,
    // required this.phone,
    required this.totalCash,
    required this.totalExpense,
    required this.createdAt,
    required this.adminEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      // 'phone': phone,
      'totalCash': totalCash,
      'totalExpense': totalExpense,
      'createdAt': createdAt.toIso8601String(),
      'adminEmail': adminEmail,
    };
  }

  factory PersonModel.fromMap(Map<String, dynamic> map) {
    return PersonModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      //  phone: map['phone'] ?? '',
      totalCash: (map['totalCash'] ?? 0).toDouble(),
      totalExpense: (map['totalExpense'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      adminEmail: map['adminEmail'] ?? '',
    );
  }
}
