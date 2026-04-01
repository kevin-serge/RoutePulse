import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/database_helper.dart';
import 'screens/login_screen.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser la base SQLite
  final db = DatabaseHelper();
  await db.database; // crée la DB si elle n'existe pas

  // Créer un compte admin par défaut si aucun utilisateur
  final users = await db.getUser("admin", "admin123");
  if (users == null) {
    await db.insertUser(
      User(username: "admin", password: "admin123", isAdmin: true),
    );
  }

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoutePulse',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}
