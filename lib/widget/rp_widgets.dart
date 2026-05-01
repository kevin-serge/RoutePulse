import 'package:flutter/material.dart';
import '../model/livraison_model.dart';

// =========================
// DESIGN SYSTEM ROUTEPULSE
// =========================

class RPColors {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const primaryDark = Color(0xFF0D47A1);
  static const accent = Color(0xFFFF6F00);

  static const enAttente = Color(0xFFFFA726);
  static const enCours = Color(0xFF42A5F5);
  static const aReporter = Color(0xFFAB47BC);
  static const annulee = Color(0xFFEF5350);
  static const livree = Color(0xFF66BB6A);

  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1A2332);
  static const textSecondary = Color(0xFF6B7A8D);
  static const divider = Color(0xFFE8ECF0);
}

/// Extension pour remplacer withOpacity (déprécié Flutter 3.27+)
extension ColorAlpha on Color {
  Color op(double opacity) => withValues(alpha: opacity);
}

class RPTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: RPColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: RPColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: RPColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: RPColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: RPColors.divider, width: 1),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: RPColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: RPColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: RPColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: RPColors.primary, width: 2),
          ),
          labelStyle: const TextStyle(color: RPColors.textSecondary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: RPColors.primary,
          unselectedItemColor: RPColors.textSecondary,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
      );
}

// =========================
// BADGE STATUT
// =========================
class StatutBadge extends StatelessWidget {
  final String statut;
  const StatutBadge(this.statut, {super.key});

  Color get _color {
    switch (statut) {
      case 'en_attente': return RPColors.enAttente;
      case 'en_cours':   return RPColors.enCours;
      case 'a_reporter': return RPColors.aReporter;
      case 'annulee':    return RPColors.annulee;
      case 'livree':     return RPColors.livree;
      default:           return RPColors.textSecondary;
    }
  }

  String get _label {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'en_cours':   return 'En cours';
      case 'a_reporter': return 'À reporter';
      case 'annulee':    return 'Annulée';
      case 'livree':     return 'Livrée';
      default:           return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.op(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.op(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// =========================
// CARTE LIVRAISON (typée)
// =========================
class LivraisonCard extends StatelessWidget {
  final Livraison livraison;
  final VoidCallback? onTap;
  final Widget? trailing;

  const LivraisonCard({
    super.key,
    required this.livraison,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: RPColors.primaryLight.op(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: RPColors.primaryLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          livraison.client,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: RPColors.textPrimary,
                          ),
                        ),
                        Text(
                          livraison.adresse,
                          style: const TextStyle(
                            color: RPColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  StatutBadge(livraison.statut),
                ],
              ),
              if (livraison.creneau != null && livraison.creneau!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 13, color: RPColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        livraison.creneau!,
                        style: const TextStyle(fontSize: 12, color: RPColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              if (trailing != null) ...[
                const Divider(height: 16),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// SNACKBAR HELPERS
// =========================
void showSuccess(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle, color: Colors.white, size: 16),
      const SizedBox(width: 8),
      Flexible(child: Text(msg)),
    ]),
    backgroundColor: RPColors.livree,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ));
}

void showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.error_outline, color: Colors.white, size: 16),
      const SizedBox(width: 8),
      Flexible(child: Text(msg)),
    ]),
    backgroundColor: RPColors.annulee,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ));
}
