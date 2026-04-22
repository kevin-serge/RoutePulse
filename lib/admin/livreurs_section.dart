import 'package:flutter/material.dart';
import '../model/user_model.dart';
import '../data/database_helper.dart';

class LivreursSection extends StatefulWidget {
  const LivreursSection({Key? key}) : super(key: key);

  @override
  State<LivreursSection> createState() => _LivreursSectionState();
}

class _LivreursSectionState extends State<LivreursSection> {
  final db = DatabaseHelper();
  List<User> livreurs = [];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLivreurs();
  }

  Future<void> _loadLivreurs() async {
    final list = await db.getAllLivreurs();
    setState(() => livreurs = list);
  }

  Future<void> _addLivreur() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    final user = User(
      email: email,
      passwordHash: User.hashPassword(password),
      role: 'livreur',
      status: 'disponible',
    );

    await db.addLivreur(user);

    _emailController.clear();
    _passwordController.clear();
    _loadLivreurs();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ➕ Ajout livreur
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addLivreur,
                child: const Text("Ajouter"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 📋 liste livreurs
          Expanded(
            child: ListView.builder(
              itemCount: livreurs.length,
              itemBuilder: (context, index) {
                final l = livreurs[index];

                return Card(
                  child: ListTile(
                    title: Text(l.email),
                    subtitle: Text(l.status),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}