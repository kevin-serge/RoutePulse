import '../repository/livraison_repository.dart';
import '../model/user_model.dart';

class UserController {
  final LivraisonRepository _repo = LivraisonRepository();

  Future<User?> login(String email, String password) async {
    return _repo.getUserByEmailAndPassword(email, password);
  }
}
