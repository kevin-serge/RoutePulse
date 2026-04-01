import 'package:flutter/material.dart';
import '../models/user_model.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("RoutePulse - ${user.username}"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // futur : paramètres / changer mot de passe
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildCard(context, Icons.add_box, "Créer une livraison"),
            _buildCard(context, Icons.list, "Livraisons du jour"),
            _buildCard(context, Icons.map, "Voir la carte"),
            _buildCard(context, Icons.check_circle, "Valider / Reporter"),
            _buildCard(context, Icons.bar_chart, "Statistiques"),
            _buildCard(context, Icons.local_shipping, "Véhicules"),
            _buildCard(context, Icons.people, "Clients"),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        // navigation future
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$title cliqué")));
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
