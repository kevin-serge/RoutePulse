import 'package:flutter/material.dart';
import '../model/user_model.dart';
import '../widget/rp_widgets.dart';
import 'livraisons_section.dart';
import 'livreurs_section.dart';
import 'stats_section.dart';

class AccueilAdmin extends StatefulWidget {
  final User admin;
  const AccueilAdmin({required this.admin, Key? key}) : super(key: key);

  @override
  State<AccueilAdmin> createState() => _AccueilAdminState();
}

class _AccueilAdminState extends State<AccueilAdmin> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const LivraisonsSection(),
      const LivreursSection(),
      const StatsSection(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_shipping, size: 20),
            const SizedBox(width: 8),
            const Text('RoutePulse'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.admin.email,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Livraisons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Livreurs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
        ],
      ),
    );
  }
}
