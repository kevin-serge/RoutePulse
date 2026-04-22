import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../model/livraison_model.dart';
import '../model/user_model.dart';

class LivraisonsSection extends StatefulWidget {
  const LivraisonsSection({Key? key}) : super(key: key);

  @override
  State<LivraisonsSection> createState() => _LivraisonsSectionState();
}

class _LivraisonsSectionState extends State<LivraisonsSection> {
  final db = DatabaseHelper();

  List<Livraison> livraisons = [];
  List<User> livreursDispo = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    livraisons = await db.getAllLivraisons();
    livreursDispo = await db.getLivreursDisponibles();
    setState(() {});
  }

  Future<void> _assignerLivraison(int livraisonId, int livreurId) async {
    await db.assignerLivraison(livraisonId, livreurId);
    _loadData();
  }

  Future<void> _deleteLivraison(int id) async {
    await db.deleteLivraison(id);
    _loadData();
  }

  void _showAddLivraisonDialog() {
    final clientCtrl = TextEditingController();
    final adresseCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nouvelle livraison"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: clientCtrl,
              decoration: const InputDecoration(labelText: "Client"),
            ),
            TextField(
              controller: adresseCtrl,
              decoration: const InputDecoration(labelText: "Adresse"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              await db.addLivraison(
                clientCtrl.text,
                adresseCtrl.text,
              );
              Navigator.pop(context);
              _loadData();
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // 🔘 HEADER ACTIONS
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showAddLivraisonDialog,
                icon: const Icon(Icons.add),
                label: const Text("Ajouter livraison"),
              ),
            ],
          ),
        ),

        // 📋 LISTE LIVRAISONS
        Expanded(
          child: ListView.builder(
            itemCount: livraisons.length,
            itemBuilder: (context, index) {
              final l = livraisons[index];

              return Card(
                child: ExpansionTile(
                  title: Text(l.client),
                  subtitle: Text("${l.adresse} • ${l.statut}"),

                  children: [

                    // 👤 ASSIGNATION LIVREUR
                    DropdownButton<int>(
                      hint: const Text("Attribuer un livreur"),
                      value: l.livreurId,
                      items: livreursDispo.map((livreur) {
                        return DropdownMenuItem(
                          value: livreur.id,
                          child: Text(livreur.email),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _assignerLivraison(l.id!, val);
                        }
                      },
                    ),

                    // 📷 PHOTOS
                    Wrap(
                      children: l.photos.map((p) {
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.network(
                            p,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        );
                      }).toList(),
                    ),

                    // 🗑 DELETE
                    TextButton.icon(
                      onPressed: () => _deleteLivraison(l.id!),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Supprimer"),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}