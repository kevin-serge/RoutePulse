import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../data/database_helper.dart';

class AdminScreen extends StatefulWidget {
  final User user;

  AdminScreen({required this.user});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final db = DatabaseHelper();

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

              // mise à jour
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Panel")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bienvenue Admin ${widget.user.username}"),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _showChangePasswordDialog,
              child: Text("Changer mot de passe"),
            ),
          ],
        ),
      ),
    );
  }
}
