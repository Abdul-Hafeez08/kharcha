enum TransactionType { expense, cash }

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final List<String> involvedUserIds; // List of 6-digit IDs
  final String adminEmail;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.involvedUserIds,
    required this.adminEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'involvedUserIds': involvedUserIds,
      'adminEmail': adminEmail,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => TransactionType.expense,
      ),
      date: DateTime.parse(map['date']),
      involvedUserIds: List<String>.from(map['involvedUserIds'] ?? []),
      adminEmail: map['adminEmail'] ?? '',
    );
  }
}
