class Livraison {
  int? id;
  String client;
  String adresse;
  String statut; // en_attente | en_cours | a_reporter | annulee | livree
  int? livreurId;
  List<String> photos;
  String? notes;
  String? motifAnnulation;
  String? creneau; // ex: "09:00-11:00"
  String? articles; // liste articles en texte
  int isSynced;
  String? remoteId;
  String? updatedAt;
  String? createdAt;

  Livraison({
    this.id,
    required this.client,
    required this.adresse,
    this.statut = 'en_attente',
    this.livreurId,
    this.photos = const [],
    this.notes,
    this.motifAnnulation,
    this.creneau,
    this.articles,
    this.isSynced = 0,
    this.remoteId,
    this.updatedAt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'client': client,
        'adresse': adresse,
        'statut': statut,
        'livreurId': livreurId,
        'photos': photos.join(','),
        'notes': notes,
        'motifAnnulation': motifAnnulation,
        'creneau': creneau,
        'articles': articles,
        'isSynced': isSynced,
        'remoteId': remoteId,
        'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
        'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      };

  factory Livraison.fromMap(Map<String, dynamic> map) => Livraison(
        id: map['id'],
        client: map['client'] ?? '',
        adresse: map['adresse'] ?? '',
        statut: map['statut'] ?? 'en_attente',
        livreurId: map['livreurId'],
        photos: (map['photos'] != null && map['photos'].toString().isNotEmpty)
            ? map['photos'].toString().split(',').where((s) => s.isNotEmpty).toList()
            : [],
        notes: map['notes'],
        motifAnnulation: map['motifAnnulation'],
        creneau: map['creneau'],
        articles: map['articles'],
        isSynced: map['isSynced'] ?? 0,
        remoteId: map['remoteId'],
        updatedAt: map['updatedAt'],
        createdAt: map['createdAt'],
      );

  /// Retourne la couleur selon le statut (hex string pour référence)
  static Map<String, String> statutColors = {
    'en_attente': '#FFA726',
    'en_cours': '#42A5F5',
    'a_reporter': '#AB47BC',
    'annulee': '#EF5350',
    'livree': '#66BB6A',
  };

  static String statutLabel(String statut) {
    const labels = {
      'en_attente': 'En attente',
      'en_cours': 'En cours',
      'a_reporter': 'À reporter',
      'annulee': 'Annulée',
      'livree': 'Livrée',
    };
    return labels[statut] ?? statut;
  }
}
