import 'package:flutter/material.dart';
import '../models/user_model.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("RoutePulse - ${user.email}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: paramètres
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔥 Bandeau statut rapide
          _buildStatusBanner(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildCard(context, Icons.list, "Livraisons du jour"),
                  _buildCard(context, Icons.map, "Carte & itinéraire"),
                  _buildCard(context, Icons.check_circle, "Valider livraison"),
                  _buildCard(context, Icons.warning, "Reporter / Annuler"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Carte UI
  Widget _buildCard(BuildContext context, IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$title cliqué")));
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Bandeau statut dynamique
  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Statut : En attente",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Icon(Icons.timelapse),
        ],
      ),
    );
  }
}
