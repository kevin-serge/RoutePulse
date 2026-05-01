import 'livraison_repository.dart';

/// Singleton partagé dans toute l'app
class AppRepo {
  static final AppRepo _instance = AppRepo._internal();
  factory AppRepo() => _instance;
  AppRepo._internal();

  final LivraisonRepository repo = LivraisonRepository();
}
