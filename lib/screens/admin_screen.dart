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
  List<User> _livreurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLivreurs();
  }

  Future<void> _loadLivreurs() async {
    setState(() => _isLoading = true);
    final allUsers = await db.getAllUsers();
    // 🔹 seuls les livreurs (isAdmin == false)
    _livreurs = allUsers.where((u) => !u.isAdmin).toList();
    setState(() => _isLoading = false);
  }

  // 🔐 Popup changement mot de passe
  void _showChangePasswordDialog(User user) {
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Changer mot de passe"),
        content: TextField(
          controller: newPassController,
          obscureText: true,
          decoration: InputDecoration(labelText: "Nouveau mot de passe"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = newPassController.text.trim();
              if (newPass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Mot de passe invalide")),
                );
                return;
              }

              final updatedUser = User(
                id: user.id,
                email: user.email,
                password: newPass,
                isAdmin: user.isAdmin,
              );

              await db.updateUser(updatedUser);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Mot de passe modifié")));
              _loadLivreurs();
            },
            child: Text("Valider"),
          ),
        ],
      ),
    );
  }

  // 🔥 Supprimer livreur
  void _deleteLivreur(User user) async {
    if (user.id != null) {
      await db.deleteUser(user.id!);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Livreur supprimé")));
      _loadLivreurs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Panel")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _livreurs.isEmpty
          ? Center(child: Text("Aucun livreur trouvé"))
          : ListView.builder(
              itemCount: _livreurs.length,
              itemBuilder: (context, index) {
                final livreur = _livreurs[index];
                return ListTile(
                  leading: Icon(Icons.person),
                  title: Text(livreur.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showChangePasswordDialog(livreur),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteLivreur(livreur),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddLivreurScreen()),
          );

          if (result == true) {
            // Un nouveau livreur a été ajouté
            _loadLivreurs(); // Recharge la liste
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Livreur créé avec succès")));
          }
        },
        child: Icon(Icons.person_add),
        tooltip: "Ajouter Livreur",
      ),
    );
  }
}
