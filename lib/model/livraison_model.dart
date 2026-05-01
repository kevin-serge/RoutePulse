import 'dart:convert';

class Livraison {
  int? id;
  String client;
  String adresse;
  String statut; // en_attente | en_cours | a_reporter | annulee | livree
  int? livreurId;
  List<String> photos;
  String? notes;
  String? motifAnnulation;
  String? creneau;
  String? articles;
  int isSynced;
  String? remoteId;
  bool isDeleted;
  String? updated_at;
  String? created_at;

  Livraison({
    this.id,
    required this.client,
    required this.adresse,
    this.statut = 'en_attente',
    this.livreurId,
    List<String>? photos,
    this.notes,
    this.motifAnnulation,
    this.creneau,
    this.articles,
    this.isSynced = 0,
    this.remoteId,
    this.isDeleted = false,
    this.updated_at,
    this.created_at,
  }) : photos = photos ?? [];

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'client': client,
        'adresse': adresse,
        'statut': statut,
        'livreurId': livreurId,
        'photos': jsonEncode(photos),
        'notes': notes,
        'motifAnnulation': motifAnnulation,
        'creneau': creneau,
        'articles': articles,
        'isSynced': isSynced,
        'remoteId': remoteId,
        'isDeleted': isDeleted ? 1 : 0,
        'updated_at': updated_at ?? DateTime.now().toIso8601String(),
        'created_at': created_at ?? DateTime.now().toIso8601String(),
      };

  factory Livraison.fromMap(Map<String, dynamic> map) => Livraison(
        id: map['id'] as int?,
        client: map['client'] ?? '',
        adresse: map['adresse'] ?? '',
        statut: map['statut'] ?? 'en_attente',
        livreurId: map['livreurId'] as int?,
        photos: _parsePhotos(map['photos']),
        notes: map['notes'],
        motifAnnulation: map['motifAnnulation'],
        creneau: map['creneau'],
        articles: map['articles'],
        isSynced: map['isSynced'] as int? ?? 0,
        remoteId: map['remoteId'],
        isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
        updated_at: map['updated_at'],
        created_at: map['created_at'],
      );

  static List<String> _parsePhotos(dynamic raw) {
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }

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

  Livraison copyWith({
    int? id,
    String? client,
    String? adresse,
    String? statut,
    int? livreurId,
    List<String>? photos,
    String? notes,
    String? motifAnnulation,
    String? creneau,
    String? articles,
    int? isSynced,
    String? remoteId,
    bool? isDeleted,
    String? updated_at,
    String? created_at,
  }) =>
      Livraison(
        id: id ?? this.id,
        client: client ?? this.client,
        adresse: adresse ?? this.adresse,
        statut: statut ?? this.statut,
        livreurId: livreurId ?? this.livreurId,
        photos: photos ?? this.photos,
        notes: notes ?? this.notes,
        motifAnnulation: motifAnnulation ?? this.motifAnnulation,
        creneau: creneau ?? this.creneau,
        articles: articles ?? this.articles,
        isSynced: isSynced ?? this.isSynced,
        remoteId: remoteId ?? this.remoteId,
        isDeleted: isDeleted ?? this.isDeleted,
        updated_at: updated_at ?? this.updated_at,
        created_at: created_at ?? this.created_at,
      );
}
