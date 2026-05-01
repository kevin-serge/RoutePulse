class Client {
  int? id;
  String nom;
  String? telephone;
  String? adresseHabituelle;
  String? notes;
  String? created_at;

  Client({
    this.id,
    required this.nom,
    this.telephone,
    this.adresseHabituelle,
    this.notes,
    this.created_at,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'telephone': telephone,
        'adresseHabituelle': adresseHabituelle,
        'notes': notes,
        'created_at': created_at ?? DateTime.now().toIso8601String(),
      };

  factory Client.fromMap(Map<String, dynamic> map) => Client(
        id: map['id'] as int?,
        nom: map['nom'] ?? '',
        telephone: map['telephone'],
        adresseHabituelle: map['adresseHabituelle'],
        notes: map['notes'],
        created_at: map['created_at'],
      );
}
