import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/delivery_model.dart';

final deliveryProvider =
    StateNotifierProvider<DeliveryNotifier, List<Delivery>>((ref) {
      return DeliveryNotifier();
    });

class DeliveryNotifier extends StateNotifier<List<Delivery>> {
  late Box<Delivery> _box;

  DeliveryNotifier() : super([]) {
    _box = Hive.box<Delivery>('deliveries');
    state = _box.values.toList(); // charge les livraisons depuis Hive
  }

  void addDelivery(Delivery delivery) {
    _box.add(delivery);
    state = _box.values.toList();
  }

  void updateStatus(int index, String status) {
    final delivery = _box.getAt(index);
    if (delivery != null) {
      delivery.status = status;
      delivery.save();
      state = _box.values.toList();
    }
  }

  void deleteDelivery(int index) {
    _box.deleteAt(index);
    state = _box.values.toList();
  }
}
