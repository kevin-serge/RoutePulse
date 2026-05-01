import 'package:flutter/material.dart';
import 'package:routepulse/repository/app_repo.dart';
import 'package:routepulse/model/client_model.dart';
import 'package:routepulse/widget/rp_widgets.dart';
//import '../model/client_model.dart';
//import '../widget/rp_widgets.dart';

class ClientsSection extends StatefulWidget {
  const ClientsSection({super.key});

  @override
  State<ClientsSection> createState() => _ClientsSectionState();
}

class _ClientsSectionState extends State<ClientsSection> {
  final repo = AppRepo().repo;
  List<Client> clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final data = await repo.getAllClients();

    if (!mounted) return;

    setState(() {
      clients = data;
      _loading = false;
    });
  }

  void _showForm({Client? existing}) {
    final nomCtrl = TextEditingController(text: existing?.nom ?? '');
    final telCtrl = TextEditingController(text: existing?.telephone ?? '');
    final adresseCtrl = TextEditingController(
      text: existing?.adresseHabituelle ?? '',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Nouveau client' : 'Modifier client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nomCtrl, 'Nom *', Icons.person_outline),
              const SizedBox(height: 10),
              _field(
                telCtrl,
                'Téléphone',
                Icons.phone_outlined,
                type: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              _field(
                adresseCtrl,
                'Adresse habituelle',
                Icons.location_on_outlined,
              ),
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
              if (nomCtrl.text.trim().isEmpty) return;
              final c = Client(
                id: existing?.id,
                nom: nomCtrl.text.trim(),
                telephone: telCtrl.text.trim().isEmpty
                    ? null
                    : telCtrl.text.trim(),
                adresseHabituelle: adresseCtrl.text.trim().isEmpty
                    ? null
                    : adresseCtrl.text.trim(),
                notes: notesCtrl.text.trim().isEmpty
                    ? null
                    : notesCtrl.text.trim(),
              );
              if (existing == null) {
                await repo.addClient(c);
              } else {
                await repo.updateClient(c);
              }
              if (mounted) Navigator.pop(context);
              _load();
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
    TextInputType? type,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${clients.length} client${clients.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: RPColors.textPrimary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
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
              : clients.isEmpty
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
                        'Aucun client enregistré',
                        style: TextStyle(
                          color: RPColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: clients.length,
                    itemBuilder: (ctx, i) {
                      final c = clients[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: RPColors.accent.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              c.nom[0].toUpperCase(),
                              style: const TextStyle(
                                color: RPColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            c.nom,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (c.telephone != null)
                                Text(
                                  c.telephone!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (c.adresseHabituelle != null)
                                Text(
                                  c.adresseHabituelle!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: RPColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: RPColors.primary,
                                ),
                                onPressed: () => _showForm(existing: c),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: RPColors.annulee,
                                ),
                                onPressed: () async {
                                  final ok = await _confirmDelete(c.nom);
                                  if (ok) {
                                    await repo.deleteClient(c.id!);
                                    _load();
                                  }
                                },
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

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer le client'),
            content: Text('Supprimer "$name" ?'),
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
  }
}
