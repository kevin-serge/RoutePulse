import 'package:flutter/material.dart';
import '../model/user_model.dart';
import 'livreurs_section.dart';
import 'livraisons_section.dart';
import 'stats_section.dart';

class AccueilAdmin extends StatefulWidget {
  final User admin;

  const AccueilAdmin({required this.admin, Key? key}) : super(key: key);

  @override
  State<AccueilAdmin> createState() => _AccueilAdminState();
}

class _AccueilAdminState extends State<AccueilAdmin> {
  int selectedIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      LivreursSection(), // 👤 ton code déplacé ici
      LivraisonsSection(), // 📦 nouveau module
      StatsSection(), // 📈 statistiques
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Control Center")),

      body: Row(
        children: [
          // 📌 MENU LATÉRAL
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() => selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text("Livreurs"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_shipping),
                label: Text("Livraisons"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.show_chart),
                label: Text("Statistiques"),
              ),
            ],
          ),

          const VerticalDivider(width: 1),

          // 📌 CONTENU
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }
}
