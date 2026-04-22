import 'dart:convert';
import 'package:crypto/crypto.dart';

class User {
  int? id;
  String email;
  String passwordHash;
  String role; // 'admin' ou 'livreur'
  String status; // 'disponible' | 'en_livraison'
  double distanceParcourue;

  User({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.status = 'disponible',
    this.distanceParcourue = 0.0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'password': passwordHash,
        'role': role,
        'status': status,
        'distanceParcourue': distanceParcourue,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        email: map['email'] ?? '',
        passwordHash: map['password'] ?? '',
        role: map['role'] ?? 'livreur',
        status: map['status'] ?? 'disponible',
        distanceParcourue: (map['distanceParcourue'] as num?)?.toDouble() ?? 0.0,
      );

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
