import 'package:hive/hive.dart';

part 'delivery_model.g.dart';

@HiveType(typeId: 0)
class Delivery extends HiveObject {
  @HiveField(0)
  String client;

  @HiveField(1)
  String address;

  @HiveField(2)
  String status;

  Delivery({required this.client, required this.address, required this.status});

  Delivery copyWith({String? client, String? address, String? status}) {
    return Delivery(
      client: client ?? this.client,
      address: address ?? this.address,
      status: status ?? this.status,
    );
  }
}
