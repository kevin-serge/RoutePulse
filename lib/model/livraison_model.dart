class Livraison {
  int? id;
  String client;
  String adresse;
  String statut;
  int? livreurId;
  List<String> photos;

  Livraison({
    this.id,
    required this.client,
    required this.adresse,
    this.statut = "en_attente",
    this.livreurId,
    this.photos = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client': client,
      'adresse': adresse,
      'statut': statut,
      'livreurId': livreurId,
      'photos': photos.join(','),
    };
  }

  factory Livraison.fromMap(Map<String, dynamic> map) {
    return Livraison(
      id: map['id'],
      client: map['client'],
      adresse: map['adresse'],
      statut: map['statut'],
      livreurId: map['livreurId'],
      photos: map['photos'] != null ? map['photos'].split(',') : [],
    );
  }
}
