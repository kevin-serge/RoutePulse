import '../repository/livraison_repository.dart';
import '../model/user_model.dart';

class UserController {
  final LivraisonRepository repo = LivraisonRepository();

  Future<User?> login(String email, String password) async {
    return await repo.getUserByEmailAndPassword(email, password);
  }
}
