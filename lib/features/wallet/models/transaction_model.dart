enum TransactionType { saved, redeemed, bonus }

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.amount,
    required this.type,
    required this.description,
  });

  final String id;
  final String userId;
  final DateTime date;
  final double amount;
  final TransactionType type;
  final String description;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (t) => t.name == (json['type'] as String),
        orElse: () => TransactionType.saved,
      ),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date.toIso8601String(),
        'amount': amount,
        'type': type.name,
        'description': description,
      };
}
