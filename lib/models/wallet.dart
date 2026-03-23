class Wallet {
  final int? id;
  final String name;
  final int iconCode;
  final double budget;
  final double balance;

  Wallet({
    this.id,
    required this.name,
    required this.iconCode,
    required this.budget,
    required this.balance,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'iconCode': iconCode,
    'budget': budget,
    'balance': balance,
  };

  factory Wallet.fromMap(Map<String, dynamic> map) => Wallet(
    id: map['id'],
    name: map['name'],
    iconCode: map['iconCode'],
    budget: (map['budget'] as num).toDouble(),
    balance: (map['balance'] as num).toDouble(),
  );
}
