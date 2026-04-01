import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../data/database_helper.dart';
import '../screens/add_livreur_screen.dart';

class AdminScreen extends StatefulWidget {
  final User user;

  const AdminScreen({required this.user, Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final db = DatabaseHelper();

  // 🔐 Popup changement mot de passe
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Changer mot de passe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Ancien mot de passe"),
            ),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Nouveau mot de passe"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final oldPass = oldPassController.text.trim();
              final newPass = newPassController.text.trim();

              if (oldPass != widget.user.password) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Ancien mot de passe incorrect")),
                );
                return;
              }

              if (newPass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Nouveau mot de passe invalide")),
                );
                return;
              }

              final updatedUser = User(
                id: widget.user.id,
                username: widget.user.username,
                password: newPass,
                isAdmin: widget.user.isAdmin,
              );

              await db.updateUser(updatedUser);

              Navigator.pop(context);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Mot de passe modifié")));
            },
            child: Text("Valider"),
          ),
        ],
      ),
    );
  }

  // 🎯 Gestion menu settings
  void _handleMenuSelection(String value) {
    if (value == "password") {
      _showChangePasswordDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel"),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "password",
                child: Text("Changer mot de passe"),
              ),
            ],
            icon: Icon(Icons.settings), // ⚙️ en haut à droite
          ),
        ],
      ),

      // 🔥 CONTENU PRINCIPAL
      body: Center(
        child: Text(
          "Bienvenue Admin ${widget.user.username}",
          style: TextStyle(fontSize: 18),
        ),
      ),

      // 🚀 bouton principal futur (ajouter livreur)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddLivreurScreen()),
          );
        },
        child: Icon(Icons.person_add),
      ),
    );
  }
}
