class Transaction {
  final int? id;
  final int walletId;
  final double amount;
  final String transactionType; // 'INCOME' or 'EXPENSE'
  final String date;
  final String note;

  Transaction({
    this.id,
    required this.walletId,
    required this.amount,
    required this.transactionType,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'walletId': walletId,
    'amount': amount,
    'transactionType': transactionType,
    'date': date,
    'note': note,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'],
    walletId: map['walletId'],
    amount: (map['amount'] as num).toDouble(),
    transactionType: map['transactionType'],
    date: map['date'],
    note: map['note'],
  );
}
