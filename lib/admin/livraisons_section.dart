import 'package:flutter/material.dart';
import '../repository/livraison_repository.dart';
import '../model/livraison_model.dart';
import '../model/user_model.dart';
import '../widget/rp_widgets.dart';

class LivraisonsSection extends StatefulWidget {
  const LivraisonsSection({Key? key}) : super(key: key);

  @override
  State<LivraisonsSection> createState() => _LivraisonsSectionState();
}

class _LivraisonsSectionState extends State<LivraisonsSection> {
  final repo = LivraisonRepository();

  List<Livraison> livraisons = [];
  List<User> livreursDispo = [];
  bool _loading = true;
  String? _filterStatut;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    livraisons = await repo.getAllLivraisons();
    livreursDispo = await repo.getLivreursDisponibles();
    setState(() => _loading = false);
  }

  List<Livraison> get _filtered {
    if (_filterStatut == null) return livraisons;
    return livraisons.where((l) => l.statut == _filterStatut).toList();
  }

  // ── DIALOG AJOUT / EDIT
  void _showFormDialog({Livraison? existing}) {
    final clientCtrl =
        TextEditingController(text: existing?.client ?? '');
    final adresseCtrl =
        TextEditingController(text: existing?.adresse ?? '');
    final notesCtrl =
        TextEditingController(text: existing?.notes ?? '');
    final creneauCtrl =
        TextEditingController(text: existing?.creneau ?? '');
    final articlesCtrl =
        TextEditingController(text: existing?.articles ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Nouvelle livraison' : 'Modifier livraison'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(clientCtrl, 'Client *', Icons.person_outline),
              const SizedBox(height: 10),
              _field(adresseCtrl, 'Adresse *', Icons.location_on_outlined),
              const SizedBox(height: 10),
              _field(creneauCtrl, 'Créneau (ex: 09:00-11:00)',
                  Icons.schedule),
              const SizedBox(height: 10),
              _field(articlesCtrl, 'Articles', Icons.inventory_2_outlined),
              const SizedBox(height: 10),
              _field(notesCtrl, 'Notes', Icons.notes, maxLines: 2),
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
              final client = clientCtrl.text.trim();
              final adresse = adresseCtrl.text.trim();
              if (client.isEmpty || adresse.isEmpty) return;

              if (existing == null) {
                await repo.addLivraison(Livraison(
                  client: client,
                  adresse: adresse,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                  creneau: creneauCtrl.text.trim().isEmpty
                      ? null
                      : creneauCtrl.text.trim(),
                  articles: articlesCtrl.text.trim().isEmpty
                      ? null
                      : articlesCtrl.text.trim(),
                ));
              } else {
                existing.client = client;
                existing.adresse = adresse;
                existing.notes = notesCtrl.text.trim().isEmpty
                    ? null
                    : notesCtrl.text.trim();
                existing.creneau = creneauCtrl.text.trim().isEmpty
                    ? null
                    : creneauCtrl.text.trim();
                existing.articles = articlesCtrl.text.trim().isEmpty
                    ? null
                    : articlesCtrl.text.trim();
                await repo.updateLivraison(existing);
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

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  // ── DIALOG ASSIGNER
  void _showAssignDialog(Livraison l) {
    int? selectedLivreurId = l.livreurId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Attribuer un livreur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.client,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: selectedLivreurId,
                hint: const Text('Sélectionner un livreur'),
                decoration: const InputDecoration(
                  labelText: 'Livreur disponible',
                  prefixIcon: Icon(Icons.person, size: 18),
                ),
                items: livreursDispo.map((livreur) {
                  return DropdownMenuItem(
                    value: livreur.id,
                    child: Text(livreur.email),
                  );
                }).toList(),
                onChanged: (val) =>
                    setInner(() => selectedLivreurId = val),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: selectedLivreurId == null
                  ? null
                  : () async {
                      await repo.assignerLivraison(
                          l.id!, selectedLivreurId!);
                      if (mounted) Navigator.pop(ctx);
                      _loadData();
                      if (mounted) showSuccess(context, 'Livreur assigné');
                    },
              child: const Text('Attribuer'),
            ),
          ],
        ),
      ),
    );
  }

  // ── DIALOG ANNULATION
  void _showAnnulerDialog(Livraison l) {
    final motifCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler la livraison'),
        content: TextField(
          controller: motifCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motif d\'annulation *',
            hintText: 'Expliquez la raison...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RPColors.annulee),
            onPressed: () async {
              if (motifCtrl.text.trim().isEmpty) return;
              await repo.updateStatut(
                l.id!,
                'annulee',
                motif: motifCtrl.text.trim(),
              );
              if (mounted) Navigator.pop(context);
              _loadData();
              if (mounted) showError(context, 'Livraison annulée');
            },
            child: const Text('Confirmer annulation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── HEADER
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${livraisons.length} livraison${livraisons.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: RPColors.textPrimary),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showFormDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Filtres statuts
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip(null, 'Tous'),
                    _filterChip('en_attente', 'En attente'),
                    _filterChip('en_cours', 'En cours'),
                    _filterChip('a_reporter', 'À reporter'),
                    _filterChip('livree', 'Livrées'),
                    _filterChip('annulee', 'Annulées'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── LISTE
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 60, color: RPColors.textSecondary),
                          SizedBox(height: 12),
                          Text('Aucune livraison',
                              style: TextStyle(
                                  color: RPColors.textSecondary, fontSize: 15)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final l = _filtered[index];
                          return LivraisonCard(
                            livraison: l,
                            onTap: () => _showFormDialog(existing: l),
                            trailing: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (l.statut == 'en_attente')
                                  _actionBtn(
                                    Icons.person_add_outlined,
                                    'Assigner',
                                    RPColors.enCours,
                                    () => _showAssignDialog(l),
                                  ),
                                if (l.statut != 'annulee' &&
                                    l.statut != 'livree')
                                  _actionBtn(
                                    Icons.cancel_outlined,
                                    'Annuler',
                                    RPColors.annulee,
                                    () => _showAnnulerDialog(l),
                                  ),
                                _actionBtn(
                                  Icons.delete_outline,
                                  'Supprimer',
                                  RPColors.annulee,
                                  () async {
                                    final ok = await _confirmDelete(l.client);
                                    if (ok) {
                                      await repo.deleteLivraison(l.id!);
                                      _loadData();
                                    }
                                  },
                                ),
                              ],
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
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => setState(() => _filterStatut = statut),
        selectedColor: RPColors.primary.withValues(alpha: 0.15),
        checkmarkColor: RPColors.primary,
        labelStyle: TextStyle(
            color: selected ? RPColors.primary : RPColors.textSecondary),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback fn) {
    return TextButton.icon(
      onPressed: fn,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text('Supprimer la livraison de "$name" ?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler')),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: RPColors.annulee),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
