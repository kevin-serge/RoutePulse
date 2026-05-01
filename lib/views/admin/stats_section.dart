import 'package:flutter/material.dart';
import 'dart:async';
import 'package:routepulse/model/livraison_model.dart';
import 'package:routepulse/repository/app_repo.dart';
import 'package:routepulse/model/user_model.dart';
import 'package:routepulse/widget/rp_widgets.dart';

class StatsSection extends StatefulWidget {
  const StatsSection({super.key});

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  final repo = AppRepo().repo;
  StreamSubscription? _syncSub;

  bool _loading = true;
  Map<String, int> _statsStatuts = {};
  int _totalLivraisons = 0;
  int _totalLivreurs = 0;
  List<Livraison> _livraisons = [];
  List<User> _livreurs = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _syncSub = repo.onRefresh.listen((_) => _loadStats());
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);

    _statsStatuts = await repo.getStatsStatuts();
    _livraisons = await repo.getLivraisons();
    _livreurs = await repo.getAllLivreurs();
    _totalLivraisons = _livraisons.length;
    _totalLivreurs = _livreurs.length;

    setState(() => _loading = false);
  }

  double get _tauxReussite {
    if (_totalLivraisons == 0) return 0;
    final livrees = _statsStatuts['livree'] ?? 0;
    return livrees / _totalLivraisons * 100;
  }

  double get _tauxRetard {
    if (_totalLivraisons == 0) return 0;
    final reporters = _statsStatuts['a_reporter'] ?? 0;
    return reporters / _totalLivraisons * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── KPI CARDS
          const Text(
            'Vue d\'ensemble',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: RPColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Total livraisons',
                  '$_totalLivraisons',
                  Icons.local_shipping,
                  RPColors.enCours,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  'Livreurs actifs',
                  '$_totalLivreurs',
                  Icons.people,
                  RPColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Taux de réussite',
                  '${_tauxReussite.toStringAsFixed(0)}%',
                  Icons.check_circle_outline,
                  RPColors.livree,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  'Taux de report',
                  '${_tauxRetard.toStringAsFixed(0)}%',
                  Icons.schedule,
                  RPColors.aReporter,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── RÉPARTITION PAR STATUT
          const Text(
            'Répartition par statut',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: RPColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ..._statsStatuts.entries
              .where((e) => e.value > 0)
              .map((e) => _statutBar(e.key, e.value))
              .toList(),

          const SizedBox(height: 24),

          // ── LIVREURS PERFORMANCE
          const Text(
            'Performance par livreur',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: RPColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ..._livreurs.map((livreur) {
            final ses = _livraisons
                .where((l) => l.livreurId == livreur.id)
                .toList();
            final livrees = ses.where((l) => l.statut == 'livree').length;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: RPColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        livreur.email[0].toUpperCase(),
                        style: const TextStyle(
                          color: RPColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            livreur.email,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${ses.length} livraisons • $livrees livrées',
                            style: const TextStyle(
                              fontSize: 12,
                              color: RPColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (livreur.distanceParcourue > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${livreur.distanceParcourue.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: RPColors.primary,
                            ),
                          ),
                          const Text(
                            'km',
                            style: TextStyle(
                              fontSize: 11,
                              color: RPColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }).toList(),

          if (_livreurs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Aucun livreur enregistré',
                  style: TextStyle(color: RPColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
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
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: RPColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statutBar(String statut, int count) {
    final total = _totalLivraisons == 0 ? 1 : _totalLivraisons;
    final pct = count / total;
    final label = Livraison.statutLabel(statut);

    Color color;
    switch (statut) {
      case 'en_attente':
        color = RPColors.enAttente;
        break;
      case 'en_cours':
        color = RPColors.enCours;
        break;
      case 'a_reporter':
        color = RPColors.aReporter;
        break;
      case 'annulee':
        color = RPColors.annulee;
        break;
      case 'livree':
        color = RPColors.livree;
        break;
      default:
        color = RPColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatutBadge(statut),
              const Spacer(),
              Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: RPColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${(pct * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(
                  fontSize: 12,
                  color: RPColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
