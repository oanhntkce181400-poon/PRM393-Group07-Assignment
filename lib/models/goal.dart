class Goal {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String startDate;
  final String endDate;

  Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'startDate': startDate,
    'endDate': endDate,
  };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
    id: map['id'],
    name: map['name'],
    targetAmount: map['targetAmount'],
    currentAmount: map['currentAmount'],
    startDate: map['startDate'],
    endDate: map['endDate'],
  );
}
