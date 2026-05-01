import 'package:flutter/material.dart';
import 'package:routepulse/repository/app_repo.dart';
import 'package:routepulse/model/vehicule_model.dart';
import 'package:routepulse/widget/rp_widgets.dart';

class VehiculesSection extends StatefulWidget {
  const VehiculesSection({super.key});

  @override
  State<VehiculesSection> createState() => _VehiculesSectionState();
}

class _VehiculesSectionState extends State<VehiculesSection> {
  final repo = AppRepo().repo;
  List<Vehicule> vehicules = [];
  bool _loading = true;

  final _types = ['voiture', 'camionnette', 'moto', 'velo'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    vehicules = await repo.getAllVehicules();
    setState(() => _loading = false);
  }

  void _showForm({Vehicule? existing}) {
    final nomCtrl = TextEditingController(text: existing?.nom ?? '');
    final immaCtrl = TextEditingController(
      text: existing?.immatriculation ?? '',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String? selectedType = existing?.type ?? 'voiture';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(
            existing == null ? 'Nouveau véhicule' : 'Modifier véhicule',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    prefixIcon: Icon(Icons.local_shipping, size: 18),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: immaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Immatriculation',
                    prefixIcon: Icon(
                      Icons.confirmation_number_outlined,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de véhicule',
                    prefixIcon: Icon(Icons.category_outlined, size: 18),
                  ),
                  items: _types.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t[0].toUpperCase() + t.substring(1)),
                    );
                  }).toList(),
                  onChanged: (v) => setInner(() => selectedType = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes, size: 18),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomCtrl.text.trim().isEmpty) return;
                final v = Vehicule(
                  id: existing?.id,
                  nom: nomCtrl.text.trim(),
                  immatriculation: immaCtrl.text.trim().isEmpty
                      ? null
                      : immaCtrl.text.trim(),
                  type: selectedType,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                );
                if (existing == null) {
                  await repo.addVehicule(v);
                } else {
                  await repo.updateVehicule(v);
                }
                if (mounted) Navigator.pop(ctx);
                _load();
              },
              child: Text(existing == null ? 'Créer' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${vehicules.length} véhicule${vehicules.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: RPColors.textPrimary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : vehicules.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 60,
                        color: RPColors.textSecondary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aucun véhicule enregistré',
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
                    itemCount: vehicules.length,
                    itemBuilder: (ctx, i) {
                      final v = vehicules[i];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: RPColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              v.icon,
                              color: RPColors.primary,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            v.nom,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (v.immatriculation != null)
                                Text(
                                  v.immatriculation!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (v.type != null)
                                Text(
                                  v.type![0].toUpperCase() +
                                      v.type!.substring(1),
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
                              Switch(
                                value: v.actif,
                                activeColor: RPColors.livree,
                                onChanged: (val) async {
                                  v.actif = val;
                                  await repo.updateVehicule(v);
                                  _load();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: RPColors.primary,
                                ),
                                onPressed: () => _showForm(existing: v),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: RPColors.annulee,
                                ),
                                onPressed: () async {
                                  await repo.deleteVehicule(v.id!);
                                  _load();
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
}
