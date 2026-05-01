import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/livraison_model.dart';
import '../../widget/rp_widgets.dart';

/// Vue carte : affiche les livraisons du jour et permet d'ouvrir
/// l'itinéraire dans Google Maps / Maps natif
class CarteParcoursPage extends StatelessWidget {
  final List<Livraison> livraisons;

  const CarteParcoursPage({super.key, required this.livraisons});

  // Filtre uniquement les livraisons non terminées
  List<Livraison> get _actives => livraisons
      .where((l) => l.statut != 'livree' && l.statut != 'annulee')
      .toList();

  Future<void> _ouvrirItineraire(Livraison l) async {
    final adresse = Uri.encodeComponent(l.adresse);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$adresse',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _ouvrirToutItineraire(BuildContext context) async {
    final actives = _actives;
    if (actives.isEmpty) {
      showError(context, 'Aucune livraison active à afficher');
      return;
    }

    // Construire waypoints Google Maps
    // Format: origin=A&waypoints=B|C&destination=D
    final adresses = actives
        .map((l) => Uri.encodeComponent(l.adresse))
        .toList();

    String url;
    if (adresses.length == 1) {
      url =
          'https://www.google.com/maps/dir/?api=1&destination=${adresses.first}';
    } else {
      final origin = adresses.first;
      final destination = adresses.last;
      final waypoints = adresses.sublist(1, adresses.length - 1).join('|');
      url =
          'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination'
          '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actives = _actives;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcours du jour'),
        actions: [
          if (actives.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: 'Ouvrir tout l\'itinéraire',
              onPressed: () => _ouvrirToutItineraire(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── BANNER info
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RPColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.route,
                    color: RPColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${actives.length} arrêt${actives.length > 1 ? 's' : ''} restant${actives.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: RPColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Appuyez sur un arrêt pour naviguer',
                        style: TextStyle(
                          fontSize: 12,
                          color: RPColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (actives.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _ouvrirToutItineraire(context),
                    icon: const Icon(Icons.navigation, size: 16),
                    label: const Text('Tout ouvrir'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── LISTE ARRÊTS
          Expanded(
            child: actives.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 60,
                          color: RPColors.livree,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Toutes les livraisons sont terminées !',
                          style: TextStyle(
                            color: RPColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: actives.length,
                    itemBuilder: (ctx, i) {
                      final l = actives[i];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: RPColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            l.client,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.adresse,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (l.creneau != null && l.creneau!.isNotEmpty)
                                Text(
                                  '⏱ ${l.creneau}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: RPColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatutBadge(l.statut),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.navigation_outlined,
                                  color: RPColors.primary,
                                  size: 22,
                                ),
                                onPressed: () => _ouvrirItineraire(l),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
