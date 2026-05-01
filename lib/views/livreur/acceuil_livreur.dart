import 'package:flutter/material.dart';
import '../../model/user_model.dart';
import '../../model/livraison_model.dart';
import '../../repository/app_repo.dart';
import 'dart:async';
import '../../widget/rp_widgets.dart';
import 'package:image_picker/image_picker.dart';

// IMPORTS
import 'fiche_livraison.dart';
import 'carte_parcourt.dart';

class LivreurScreen extends StatefulWidget {
  final User user;
  const LivreurScreen({required this.user, super.key});

  @override
  State<LivreurScreen> createState() => _LivreurScreenState();
}

class _LivreurScreenState extends State<LivreurScreen> {
  final repo = AppRepo().repo;
  final ImagePicker _picker = ImagePicker();

  StreamSubscription? _syncSub;

  List<Livraison> _livraisons = [];
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLivraisons();

    // refresh event (fallback simple)
    _syncSub = repo.onRefresh.listen((_) => _loadLivraisons());
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  // ─────────────────────────────
  // 🔄 LOAD + SYNC (CLEAN ARCHI)
  // ─────────────────────────────
  Future<void> _loadLivraisons() async {
    setState(() => _loading = true);

    final id = widget.user.id;
    if (id == null) return;

    // 1. SYNC CLOUD → SQLITE
    await repo.getLivraisonsByLivreur(id);

    // 2. UI FROM SQLITE ONLY
    if (_tabIndex == 0) {
      _livraisons = await repo.getLivraisons();
    } else {
      _livraisons = await repo.getLivraisonsByLivreur(id);
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ─────────────────────────────
  // 📸 PHOTO
  // ─────────────────────────────
  Future<String?> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    return photo?.path;
  }

  // ─────────────────────────────
  // ✅ VALIDATION
  // ─────────────────────────────
  void _showValiderDialog(Livraison l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Valider la livraison'),
        content: Text(l.client),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final photo = await _takePhoto();
              if (photo == null) return;

              await repo.updateStatut(l.id!, 'livree', photos: [photo]);

              if (!mounted) return;

              Navigator.pop(context);
              await _loadLivraisons();
              showSuccess(context, 'Livraison validée avec preuve');
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // ⏳ REPORT
  // ─────────────────────────────
  void _showReporterDialog(Livraison l) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reporter'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;

              await repo.updateStatut(l.id!, 'a_reporter', motif: ctrl.text);

              if (!mounted) return;

              Navigator.pop(context);
              _loadLivraisons();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // UI
  // ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    final id = widget.user.id;

    final count = _livraisons
        .where((l) => l.statut == 'en_attente' || l.statut == 'en_cours')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RoutePulse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CarteParcoursPage(livraisons: _livraisons),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      body: Column(
        children: [
          ListTile(
            title: Text(widget.user.email),
            subtitle: Text('$count livraisons'),
          ),

          Row(children: [_tab('Aujourd’hui', 0), _tab('Toutes', 1)]),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _livraisons.length,
                    itemBuilder: (ctx, i) {
                      final l = _livraisons[i];

                      return LivraisonCard(
                        livraison: l,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FicheLivraisonPage(livraison: l),
                          ),
                        ),
                        trailing: _actions(l),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // TAB
  // ─────────────────────────────
  Widget _tab(String label, int index) {
    final selected = _tabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tabIndex = index);
          _loadLivraisons();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────
  // ACTIONS
  // ─────────────────────────────
  Widget _actions(Livraison l) {
    if (l.statut == 'livree') return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _showValiderDialog(l),
          child: const Text('Valider'),
        ),
        TextButton(
          onPressed: () => _showReporterDialog(l),
          child: const Text('Reporter'),
        ),
      ],
    );
  }
}
