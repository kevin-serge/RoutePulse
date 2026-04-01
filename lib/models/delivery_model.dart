class Delivery {
  int? id;
  String client;
  String address;
  String status;

  Delivery({
    this.id,
    required this.client,
    required this.address,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'client': client,
    'address': address,
    'status': status,
  };

  factory Delivery.fromMap(Map<String, dynamic> map) => Delivery(
    id: map['id'],
    client: map['client'],
    address: map['address'],
    status: map['status'],
  );

  Delivery copyWith({String? status}) {
    return Delivery(
      id: id,
      client: client,
      address: address,
      status: status ?? this.status,
    );
  }
}
