class Delivery {
  int? id;
  String client;
  String address;
  String status;
  String assignedTo;

  Delivery({
    this.id,
    required this.client,
    required this.address,
    required this.status,
    this.assignedTo = "",
  });

  // ✅ Inclure assignedTo pour que la DB le stocke
  Map<String, dynamic> toMap() => {
    'id': id,
    'client': client,
    'address': address,
    'status': status,
    'assignedTo': assignedTo, // <- ajouté
  };

  factory Delivery.fromMap(Map<String, dynamic> map) => Delivery(
    id: map['id'],
    client: map['client'],
    address: map['address'],
    status: map['status'],
    assignedTo: map['assignedTo'] ?? "",
  );

  Delivery copyWith({String? status, String? assignedTo}) {
    return Delivery(
      id: id,
      client: client,
      address: address,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}
