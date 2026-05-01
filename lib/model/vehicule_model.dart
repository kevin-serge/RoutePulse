import 'package:flutter/material.dart';

class Vehicule {
  int? id;
  String nom;
  String? immatriculation;
  String? type; // voiture | moto | velo | camionnette
  String? notes;
  bool actif;
  String? created_at;

  Vehicule({
    this.id,
    required this.nom,
    this.immatriculation,
    this.type,
    this.notes,
    this.actif = true,
    this.created_at,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'immatriculation': immatriculation,
        'type': type,
        'notes': notes,
        'actif': actif ? 1 : 0,
        'created_at': created_at ?? DateTime.now().toIso8601String(),
      };

  factory Vehicule.fromMap(Map<String, dynamic> map) => Vehicule(
        id: map['id'] as int?,
        nom: map['nom'] ?? '',
        immatriculation: map['immatriculation'],
        type: map['type'],
        notes: map['notes'],
        actif: (map['actif'] as int? ?? 1) == 1,
        created_at: map['created_at'],
      );

  IconData get icon {
    switch (type) {
      case 'moto':
        return Icons.two_wheeler;
      case 'velo':
        return Icons.pedal_bike;
      case 'camionnette':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }
}
