import 'dart:async';
import 'package:flutter/material.dart';
import 'package:routepulse/repository/app_repo.dart';
import 'package:routepulse/model/livraison_model.dart';
import 'package:routepulse/model/user_model.dart';
import 'package:routepulse/widget/rp_widgets.dart';

class LivraisonsSection extends StatefulWidget {
  const LivraisonsSection({super.key});

  @override
  State<LivraisonsSection> createState() => _LivraisonsSectionState();
}

class _LivraisonsSectionState extends State<LivraisonsSection> {
  final repo = AppRepo().repo;

  StreamSubscription? _syncSub;
  Timer? _debounce;

  List<Livraison> livraisons = [];
  List<User> livreursDispo = [];

  bool _loading = true;
  String? _filterStatut;

  final _clientCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _creneauCtrl = TextEditingController();
  final _articlesCtrl = TextEditingController();

  int? _selectedLivreurId;

  @override
  void initState() {
    super.initState();
    _loadData();

    _syncSub = repo.onRefresh.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _loadData);
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _debounce?.cancel();

    _clientCtrl.dispose();
    _adresseCtrl.dispose();
    _notesCtrl.dispose();
    _creneauCtrl.dispose();
    _articlesCtrl.dispose();

    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        repo.getLivraisons(),
        repo.getLivreursDisponibles(),
      ]);

      if (!mounted) return;

      setState(() {
        livraisons = results[0] as List<Livraison>;
        livreursDispo = results[1] as List<User>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Livraison> get _filtered {
    if (_filterStatut == null) return livraisons;
    return livraisons.where((l) => (l.statut ?? '') == _filterStatut).toList();
  }

  void _resetForm() {
    _clientCtrl.clear();
    _adresseCtrl.clear();
    _notesCtrl.clear();
    _creneauCtrl.clear();
    _articlesCtrl.clear();
    _selectedLivreurId = null;
  }

  void _showFormDialog({Livraison? existing}) {
    _resetForm();

    if (existing != null) {
      _clientCtrl.text = existing.client;
      _adresseCtrl.text = existing.adresse;
      _notesCtrl.text = existing.notes ?? '';
      _creneauCtrl.text = existing.creneau ?? '';
      _articlesCtrl.text = existing.articles ?? '';
      _selectedLivreurId = existing.livreurId;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          existing == null ? 'Nouvelle livraison' : 'Modifier livraison',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_clientCtrl, 'Client *', Icons.person),
              const SizedBox(height: 10),
              _field(_adresseCtrl, 'Adresse *', Icons.location_on),
              const SizedBox(height: 10),

              DropdownButtonFormField<int>(
                value: _selectedLivreurId,
                hint: const Text("Assigner un livreur"),
                items: livreursDispo.map((l) {
                  return DropdownMenuItem(value: l.id, child: Text(l.email));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedLivreurId = val);
                },
              ),

              const SizedBox(height: 10),
              _field(_creneauCtrl, 'Créneau', Icons.schedule),
              const SizedBox(height: 10),
              _field(_articlesCtrl, 'Articles', Icons.inventory),
              const SizedBox(height: 10),
              _field(_notesCtrl, 'Notes', Icons.notes, maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final client = _clientCtrl.text.trim();
              final adresse = _adresseCtrl.text.trim();

              if (client.isEmpty || adresse.isEmpty) return;

              final livraison = Livraison(
                id: existing?.id,
                client: client,
                adresse: adresse,
                notes: _notesCtrl.text.trim().isEmpty
                    ? null
                    : _notesCtrl.text.trim(),
                creneau: _creneauCtrl.text.trim().isEmpty
                    ? null
                    : _creneauCtrl.text.trim(),
                articles: _articlesCtrl.text.trim().isEmpty
                    ? null
                    : _articlesCtrl.text.trim(),
                statut: existing?.statut ?? 'en_attente',
                livreurId: _selectedLivreurId,
              );

              if (existing == null) {
                await repo.addLivraison(livraison);

                await _loadData();

                if (_selectedLivreurId != null && livraisons.isNotEmpty) {
                  final last = livraisons.first;
                  if (last.id != null) {
                    await repo.assignerLivraison(last.id!, _selectedLivreurId!);
                  }
                }
              } else {
                await repo.updateLivraison(livraison);

                if (_selectedLivreurId != null && livraison.id != null) {
                  await repo.assignerLivraison(
                    livraison.id!,
                    _selectedLivreurId!,
                  );
                }
              }

              if (mounted) Navigator.pop(context);
              _loadData();
            },
            child: Text(existing == null ? 'Créer' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _softDeleteLivraison(Livraison l) async {
    final backup = List<Livraison>.from(livraisons);

    setState(() {
      livraisons.removeWhere((e) => e.id == l.id);
    });

    try {
      if (l.id == null) return;
      await repo.deleteLivraison(l.id!);
    } catch (_) {
      setState(() => livraisons = backup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${livraisons.length} livraison(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showFormDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip(null, 'Tous'),
                    _filterChip('en_attente', 'En attente'),
                    _filterChip('en_cours', 'En cours'),
                    _filterChip('livree', 'Livrées'),
                    _filterChip('annulee', 'Annulées'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? const Center(child: Text('Aucune livraison'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final l = _filtered[index];

                      return LivraisonCard(
                        livraison: l,
                        onTap: () => _showFormDialog(existing: l),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _softDeleteLivraison(l),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String? statut, String label) {
    final selected = _filterStatut == statut;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filterStatut = statut),
      ),
    );
  }
}
