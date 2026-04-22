import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class StatsSection extends StatefulWidget {
  const StatsSection({Key? key}) : super(key: key);

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  final db = DatabaseHelper();

  int totalLivraisons = 0;
  int livrees = 0;
  int enAttente = 0;
  int enCours = 0;
  int echec = 0;

  int totalLivreurs = 0;
  int dispo = 0;
  int enService = 0;

  double tauxReussite = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final livraisons = await db.getAllLivraisons();
    final livreurs = await db.getAllLivreurs();

    setState(() {
      totalLivraisons = livraisons.length;

      livrees = livraisons.where((l) => l.statut == "livree").length;
      enAttente = livraisons.where((l) => l.statut == "en_attente").length;
      enCours = livraisons.where((l) => l.statut == "en_cours").length;
      echec = livraisons.where((l) => l.statut == "echec").length;

      totalLivreurs = livreurs.length;
      dispo = livreurs.where((l) => l.status == "disponible").length;
      enService = livreurs.where((l) => l.status == "en livraison").length;

      tauxReussite = totalLivraisons == 0
          ? 0
          : (livrees / totalLivraisons) * 100;
    });
  }

  Widget _buildCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          const Text(
            "📊 Dashboard Statistiques",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // 📦 LIVRAISONS
          _buildCard("Total livraisons", "$totalLivraisons", Icons.local_shipping),
          _buildCard("Livrées", "$livrees", Icons.check_circle),
          _buildCard("En attente", "$enAttente", Icons.hourglass_empty),
          _buildCard("En cours", "$enCours", Icons.directions_run),
          _buildCard("Échecs", "$echec", Icons.error),

          const SizedBox(height: 20),

          // 👤 LIVREURS
          _buildCard("Total livreurs", "$totalLivreurs", Icons.people),
          _buildCard("Disponibles", "$dispo", Icons.person),
          _buildCard("En service", "$enService", Icons.delivery_dining),

          const SizedBox(height: 20),

          // 📈 KPI
          Card(
            color: Colors.blue.shade50,
            child: ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text("Taux de réussite"),
              trailing: Text(
                "${tauxReussite.toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}