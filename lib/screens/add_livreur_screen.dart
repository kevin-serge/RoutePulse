import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/user_model.dart';

class AddLivreurScreen extends StatefulWidget {
  @override
  _AddLivreurScreenState createState() => _AddLivreurScreenState();
}

class _AddLivreurScreenState extends State<AddLivreurScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final db = DatabaseHelper();

  bool _isLoading = false;

  void _createLivreur() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Remplis tous les champs");
      return;
    }

    // Validation email
    if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(email)) {
      _showMessage("Email invalide");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Vérifie si l'utilisateur existe déjà
      final exists = await db.userExists(email);
      if (exists) {
        _showMessage("Email déjà utilisé");
      } else {
        await db.insertUser(
          User(
            email: email,
            password:
                password, // sera hashé automatiquement dans DatabaseHelper
            isAdmin: false, // 🚚 livreur
          ),
        );

        _showMessage("Livreur créé avec succès");

        Navigator.pop(
          context,
          true,
        ); // signale que le livreur a été ajouté// retour à l'écran admin
      }
    } catch (e) {
      _showMessage("Erreur : ${e.toString()}");
    }

    setState(() => _isLoading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter Livreur")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔥 Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 15),

              // 🔥 Mot de passe
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 🔥 Bouton créer
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createLivreur,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text("Créer"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
