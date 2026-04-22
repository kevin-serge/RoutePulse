import '../data/database_helper.dart';
import '../model/user_model.dart';

class UserController {
  final db = DatabaseHelper();

  Future<User?> login(String email, String password) async {
    return await db.getUserByEmailAndPassword(email, password);
  }
}
