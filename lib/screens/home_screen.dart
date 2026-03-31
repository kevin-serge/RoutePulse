import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/delivery_provider.dart';
import '../models/delivery_model.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(deliveryProvider);

    return Scaffold(
      appBar: AppBar(title: Text("RoutePulse")),

      body: ListView.builder(
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];

          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(delivery.client),
              subtitle: Text("${delivery.address} • ${delivery.status}"),

              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "LIVREE") {
                    ref
                        .read(deliveryProvider.notifier)
                        .updateStatus(index, "LIVREE");
                  } else if (value == "ANNULLEE") {
                    ref
                        .read(deliveryProvider.notifier)
                        .updateStatus(index, "ANNULLEE");
                  } else if (value == "SUPPRIMER") {
                    ref.read(deliveryProvider.notifier).deleteDelivery(index);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: "LIVREE", child: Text("Livrée")),
                  PopupMenuItem(value: "ANNULLEE", child: Text("Annulée")),
                  PopupMenuItem(value: "SUPPRIMER", child: Text("Supprimer")),
                ],
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(context, ref);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final clientController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Nouvelle livraison"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: clientController,
              decoration: InputDecoration(labelText: "Client"),
            ),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: "Adresse"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              final newDelivery = Delivery(
                client: clientController.text,
                address: addressController.text,
                status: "EN_ATTENTE",
              );

              ref.read(deliveryProvider.notifier).addDelivery(newDelivery);

              Navigator.pop(context);
            },
            child: Text("Ajouter"),
          ),
        ],
      ),
    );
  }
}
