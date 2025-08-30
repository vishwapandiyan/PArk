class Wallet {
  final String id;
  final String userId;
  final int balance; // in fake currency units
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: json['balance'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedBalance => '₹$balance';

  Wallet copyWith({
    String? id,
    String? userId,
    int? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Transaction {
  final String id;
  final String userId;
  final String transactionType; // credit, debit
  final int amount;
  final String description;
  final String? referenceId;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.transactionType,
    required this.amount,
    required this.description,
    this.referenceId,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      transactionType: json['transaction_type'] as String,
      amount: json['amount'] as int,
      description: json['description'] as String,
      referenceId: json['reference_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'transaction_type': transactionType,
      'amount': amount,
      'description': description,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCredit => transactionType == 'credit';
  bool get isDebit => transactionType == 'debit';

  String get formattedAmount {
    final prefix = isCredit ? '+' : '-';
    return '$prefix₹$amount';
  }

  String get typeDisplay => isCredit ? 'Credit' : 'Debit';

  Transaction copyWith({
    String? id,
    String? userId,
    String? transactionType,
    int? amount,
    String? description,
    String? referenceId,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
