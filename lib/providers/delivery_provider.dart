import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_model.dart';
import '../data/database_helper.dart';

final deliveryProvider =
    StateNotifierProvider<DeliveryNotifier, List<Delivery>>((ref) {
      return DeliveryNotifier();
    });

class DeliveryNotifier extends StateNotifier<List<Delivery>> {
  final db = DatabaseHelper();

  DeliveryNotifier() : super([]) {
    loadDeliveries();
  }

  Future<void> loadDeliveries() async {
    state = await db.getDeliveries();
  }

  Future<void> addDelivery(Delivery d) async {
    await db.insertDelivery(d);
    await loadDeliveries();
  }

  Future<void> updateStatus(Delivery d, String status) async {
    await db.updateDelivery(d.copyWith(status: status));
    await loadDeliveries();
  }

  Future<void> deleteDelivery(int id) async {
    await db.deleteDelivery(id);
    await loadDeliveries();
  }
}
