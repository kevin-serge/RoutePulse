import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/user_model.dart';

class AddLivreurScreen extends StatefulWidget {
  @override
  _AddLivreurScreenState createState() => _AddLivreurScreenState();
}

class _AddLivreurScreenState extends State<AddLivreurScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final db = DatabaseHelper();

  bool _isLoading = false;

  void _createLivreur() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Remplis tous les champs")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await db.insertUser(
        User(
          username: username,
          password: password,
          isAdmin: false, // 🚚 livreur
        ),
      );

      Navigator.pop(context); // retour admin

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Livreur créé avec succès")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Username déjà utilisé")));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter Livreur")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Mot de passe"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createLivreur,
                    child: Text("Créer"),
                  ),
          ],
        ),
      ),
    );
  }
}
