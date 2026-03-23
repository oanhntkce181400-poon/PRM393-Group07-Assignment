class Debt {
  final int? id;
  final String partnerName;
  final String debtType; // 'LEND' or 'BORROW'
  final double amount;
  final String dueDate;
  final int status; // 0: Unpaid, 1: Paid

  Debt({
    this.id,
    required this.partnerName,
    required this.debtType,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'partnerName': partnerName,
    'debtType': debtType,
    'amount': amount,
    'dueDate': dueDate,
    'status': status,
  };

  factory Debt.fromMap(Map<String, dynamic> map) => Debt(
    id: map['id'],
    partnerName: map['partnerName'],
    debtType: map['debtType'],
    amount: map['amount'],
    dueDate: map['dueDate'],
    status: map['status'],
  );
}
