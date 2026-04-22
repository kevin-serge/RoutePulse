import 'dart:convert';
import 'package:crypto/crypto.dart';

class User {
  int? id;
  String email;
  String passwordHash;
  String role; // 'admin' ou 'livreur'
  String status; // 'disponible' ou 'en livraison'
  double distanceParcourue; // en km

  User({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.status = 'disponible',
    this.distanceParcourue = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': passwordHash,
      'role': role,
      'status': status,
      'distanceParcourue': distanceParcourue,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      passwordHash: map['password'],
      role: map['role'],
      status: map['status'] ?? 'disponible',
      distanceParcourue: map['distanceParcourue'] != null
          ? map['distanceParcourue'] as double
          : 0.0,
    );
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
