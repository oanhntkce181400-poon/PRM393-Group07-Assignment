class User {
  final int? id;
  final String fullName;
  final String email;
  final String password;

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'password': password,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    fullName: map['fullName'],
    email: map['email'],
    password: map['password'],
  );
}
