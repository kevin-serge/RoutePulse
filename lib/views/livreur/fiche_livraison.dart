import 'package:flutter/material.dart';
import '../../model/livraison_model.dart';
import '../../widget/rp_widgets.dart';
import 'dart:io'; // ✅ nécessaire pour Image.file

class FicheLivraisonPage extends StatelessWidget {
  final Livraison livraison;
  final String? nomLivreur;

  const FicheLivraisonPage({
    super.key,
    required this.livraison,
    this.nomLivreur,
  });

  @override
  Widget build(BuildContext context) {
    final photos = livraison.photos ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche livraison'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatutBadge(livraison.statut),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── CLIENT
          _section('Client', [
            _row(Icons.person_outline, livraison.client),
            _row(Icons.location_on_outlined, livraison.adresse),
            if (livraison.creneau?.isNotEmpty == true)
              _row(Icons.schedule, 'Créneau : ${livraison.creneau}'),
            if (livraison.articles?.isNotEmpty == true)
              _row(Icons.inventory_2_outlined, livraison.articles!),
            if (livraison.notes?.isNotEmpty == true)
              _row(Icons.notes, livraison.notes!),
          ]),

          const SizedBox(height: 16),

          // ── ASSIGNATION
          _section('Assignation', [
            _row(
              Icons.person_pin_outlined,
              nomLivreur != null ? 'Livreur : $nomLivreur' : 'Non assigné',
            ),
            if (livraison.created_at != null)
              _row(
                Icons.calendar_today_outlined,
                'Créé le : ${_formatDate(livraison.created_at!)}',
              ),
            if (livraison.updated_at != null)
              _row(
                Icons.update,
                'Mis à jour : ${_formatDate(livraison.updated_at!)}',
              ),
          ]),

          const SizedBox(height: 16),

          // ── HISTORIQUE
          _section('Historique', [_timeline(livraison.statut)]),

          // ── PHOTOS (SAFE)
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section('Preuves de livraison', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: photos.map((p) {
                  final isNetwork = p.startsWith('http');

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isNetwork
                        ? Image.network(
                            p,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _errorImg(),
                          )
                        : Image.file(
                            File(p),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _errorImg(),
                          ),
                  );
                }).toList(),
              ),
            ]),
          ],

          // ── MOTIF
          if (livraison.motifAnnulation?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RPColors.annulee.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: RPColors.annulee.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: RPColors.annulee,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(livraison.motifAnnulation!)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorImg() {
    return Container(
      width: 90,
      height: 90,
      color: RPColors.divider,
      child: const Icon(Icons.broken_image_outlined),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RPColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: RPColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: RPColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _timeline(String statut) {
    final steps = [
      ('en_attente', 'En attente'),
      ('en_cours', 'En cours'),
      ('livree', 'Livrée'),
    ];

    return Column(
      children: steps.map((s) {
        final done = _statutOrder(statut) >= _statutOrder(s.$1);
        return Row(
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: done ? RPColors.primary : RPColors.divider,
            ),
            const SizedBox(width: 8),
            Text(s.$2),
          ],
        );
      }).toList(),
    );
  }

  int _statutOrder(String s) {
    const order = {'en_attente': 0, 'en_cours': 1, 'livree': 2};
    return order[s] ?? -1;
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute}';
  }
}
