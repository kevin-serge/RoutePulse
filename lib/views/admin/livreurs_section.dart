import 'package:flutter/material.dart';
import 'package:routepulse/repository/app_repo.dart';
import 'package:routepulse/model/user_model.dart';
import 'package:routepulse/widget/rp_widgets.dart';
import 'dart:async';

class LivreursSection extends StatefulWidget {
  const LivreursSection({super.key});

  @override
  State<LivreursSection> createState() => _LivreursSectionState();
}

class _LivreursSectionState extends State<LivreursSection> {
  final repo = AppRepo().repo;
  StreamSubscription? _syncSub;
  List<User> livreurs = [];
  bool _loading = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadLivreurs();
    _syncSub = repo.onRefresh.listen((_) => _loadLivreurs());
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLivreurs() async {
    setState(() => _loading = true);
    livreurs = await repo.getAllLivreurs();
    setState(() => _loading = false);
  }

  void _showAddDialog() {
    _emailCtrl.clear();
    _passwordCtrl.clear();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Nouveau livreur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mot de passe *',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () => setInner(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = _emailCtrl.text.trim();
                final pwd = _passwordCtrl.text;
                if (email.isEmpty || pwd.isEmpty) return;

                await repo.addLivreur(
                  User(
                    email: email,
                    passwordHash: User.hashPassword(pwd),
                    role: 'livreur',
                    status: 'disponible',
                  ),
                );

                if (mounted) Navigator.pop(ctx);
                _loadLivreurs();
                if (mounted) showSuccess(context, 'Livreur ajouté');
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteLivreur(User l) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer le livreur'),
            content: Text('Supprimer "${l.email}" ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RPColors.annulee,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (ok) {
      await repo.deleteLivreur(l.id!);
      _loadLivreurs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── HEADER
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${livreurs.length} livreur${livreurs.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: RPColors.textPrimary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : livreurs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 60,
                        color: RPColors.textSecondary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aucun livreur enregistré',
                        style: TextStyle(
                          color: RPColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLivreurs,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: livreurs.length,
                    itemBuilder: (context, index) {
                      final l = livreurs[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: RPColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              l.email[0].toUpperCase(),
                              style: const TextStyle(
                                color: RPColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            l.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: l.status == 'disponible'
                                      ? RPColors.livree
                                      : RPColors.enCours,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l.status == 'disponible'
                                    ? 'Disponible'
                                    : 'En livraison',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (l.distanceParcourue > 0)
                                Text(
                                  '${l.distanceParcourue.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: RPColors.textSecondary,
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: RPColors.annulee,
                                  size: 20,
                                ),
                                onPressed: () => _deleteLivreur(l),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
