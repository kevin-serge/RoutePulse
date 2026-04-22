import 'package:flutter/material.dart';
import '../model/user_model.dart';
import '../model/livraison_model.dart';
import '../repository/livraison_repository.dart';
import '../widget/rp_widgets.dart';

class LivreurScreen extends StatefulWidget {
  final User user;
  const LivreurScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<LivreurScreen> createState() => _LivreurScreenState();
}

class _LivreurScreenState extends State<LivreurScreen> {
  final repo = LivraisonRepository();

  List<Livraison> _livraisons = [];
  bool _loading = true;
  int _tabIndex = 0; // 0 = Aujourd'hui, 1 = Toutes

  @override
  void initState() {
    super.initState();
    _loadLivraisons();
  }

  Future<void> _loadLivraisons() async {
    setState(() => _loading = true);
    if (_tabIndex == 0) {
      _livraisons = await repo.getLivraisonsDuJour(
          livreurId: widget.user.id);
    } else {
      _livraisons =
          await repo.getLivraisonsByLivreur(widget.user.id!);
    }
    setState(() => _loading = false);
  }

  // ── VALIDER LIVRAISON
  void _showValiderDialog(Livraison l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Valider la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.client,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(l.adresse,
                style:
                    const TextStyle(color: RPColors.textSecondary)),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: RPColors.textSecondary),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Confirmez que la livraison a bien été effectuée.',
                    style: TextStyle(
                        fontSize: 13,
                        color: RPColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: RPColors.livree),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Confirmer livraison'),
            onPressed: () async {
              await repo.updateStatut(l.id!, 'livree');
              if (mounted) Navigator.pop(context);
              _loadLivraisons();
              if (mounted)
                showSuccess(context, 'Livraison validée !');
            },
          ),
        ],
      ),
    );
  }

  // ── REPORTER LIVRAISON
  void _showReporterDialog(Livraison l) {
    final motifCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reporter la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.client,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: motifCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motif du report *',
                hintText: 'Absent, adresse incorrecte...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: RPColors.aReporter),
            onPressed: () async {
              if (motifCtrl.text.trim().isEmpty) return;
              await repo.updateStatut(
                l.id!,
                'a_reporter',
                motif: motifCtrl.text.trim(),
              );
              if (mounted) Navigator.pop(context);
              _loadLivraisons();
            },
          child: const Text('Confirmer le report'),
          ),
        ],
      ),
    );
  }

  // ── DETAIL LIVRAISON
  void _showDetail(Livraison l) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(livraison: l),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enAttenteCount = _livraisons
        .where((l) =>
            l.statut == 'en_attente' || l.statut == 'en_cours')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_shipping, size: 20),
            SizedBox(width: 8),
            Text('RoutePulse'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── PROFIL HEADER
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: RPColors.primary.withValues(alpha: 0.12),
                  radius: 22,
                  child: Text(
                    widget.user.email[0].toUpperCase(),
                    style: const TextStyle(
                        color: RPColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.email,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: RPColors.livree,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('Disponible',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: RPColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (enAttenteCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: RPColors.enAttente.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$enAttenteCount à faire',
                      style: const TextStyle(
                          color: RPColors.enAttente,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),

          // ── TABS
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _tab('Aujourd\'hui', 0),
                _tab('Toutes', 1),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── LISTE
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _livraisons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _tabIndex == 0
                                  ? Icons.check_circle_outline
                                  : Icons.local_shipping_outlined,
                              size: 60,
                              color: RPColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _tabIndex == 0
                                  ? 'Aucune livraison pour aujourd\'hui'
                                  : 'Aucune livraison assignée',
                              style: const TextStyle(
                                  color: RPColors.textSecondary,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLivraisons,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _livraisons.length,
                          itemBuilder: (ctx, i) {
                            final l = _livraisons[i];
                            return LivraisonCard(
                              livraison: l,
                              onTap: () => _showDetail(l),
                              trailing: _actionsRow(l),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tabIndex = index);
          _loadLivraisons();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? RPColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.normal,
              color:
                  selected ? RPColors.primary : RPColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionsRow(Livraison l) {
    if (l.statut == 'livree' || l.statut == 'annulee') {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (l.statut == 'en_cours' || l.statut == 'en_attente') ...[
          TextButton.icon(
            onPressed: () => _showValiderDialog(l),
            icon: const Icon(Icons.check_circle_outline,
                size: 15, color: RPColors.livree),
            label: const Text('Valider',
                style:
                    TextStyle(color: RPColors.livree, fontSize: 12)),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4)),
          ),
          TextButton.icon(
            onPressed: () => _showReporterDialog(l),
            icon: const Icon(Icons.schedule,
                size: 15, color: RPColors.aReporter),
            label: const Text('Reporter',
                style: TextStyle(
                    color: RPColors.aReporter, fontSize: 12)),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4)),
          ),
        ],
      ],
    );
  }
}

// ── BOTTOM SHEET DETAIL
class _DetailSheet extends StatelessWidget {
  final Livraison livraison;
  const _DetailSheet({required this.livraison});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RPColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: RPColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Text(
                  livraison.client,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: RPColors.textPrimary,
                  ),
                ),
              ),
              StatutBadge(livraison.statut),
            ],
          ),
          const SizedBox(height: 14),

          _detailRow(Icons.location_on_outlined, livraison.adresse),
          if (livraison.creneau != null && livraison.creneau!.isNotEmpty)
            _detailRow(Icons.schedule, livraison.creneau!),
          if (livraison.articles != null && livraison.articles!.isNotEmpty)
            _detailRow(Icons.inventory_2_outlined, livraison.articles!),
          if (livraison.notes != null && livraison.notes!.isNotEmpty)
            _detailRow(Icons.notes, livraison.notes!),
          if (livraison.motifAnnulation != null &&
              livraison.motifAnnulation!.isNotEmpty)
            _detailRow(Icons.info_outline, livraison.motifAnnulation!,
                color: RPColors.annulee),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16,
              color: color ?? RPColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 14,
                  color: color ?? RPColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
