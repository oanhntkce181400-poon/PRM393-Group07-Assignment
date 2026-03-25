import '../models/user.dart';
import 'database_helper.dart';

class AuthService {
  static Future<String?> register(User user) async {
    final db = await DatabaseHelper.database;

    final exist = await db.query(
      'users',
      where: 'email=?',
      whereArgs: [user.email],
    );

    if (exist.isNotEmpty) {
      return "Email đã tồn tại";
    }

    await db.insert('users', user.toMap());

    /// DEFAULT WALLET
    await db.insert('wallets', {
      'name': 'Túi tiền mặt',
      'balance': 0,
      'userEmail': user.email,
    });

    return null;
  }

  static Future<User?> login(String email, String password) async {
    final db = await DatabaseHelper.database;

    final result = await db.query(
      'users',
      where: 'email=? AND password=?',
      whereArgs: [email, password],
    );

    if (result.isEmpty) return null;

    return User.fromMap(result.first);
  }
}
