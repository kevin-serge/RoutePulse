import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class User {
  int? id;
  String email;
  String passwordHash;
  String role; // 'admin' | 'livreur'
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
        id: map['id'] as int?,
        email: map['email'] ?? '',
        passwordHash: map['password'] ?? '',
        role: map['role'] ?? 'livreur',
        status: map['status'] ?? 'disponible',
        distanceParcourue:
            (map['distanceParcourue'] as num?)?.toDouble() ?? 0.0,
      );

  // ──────────────────────────────────────
  // SÉCURITÉ : SHA-256 avec sel (10 000 itérations)
  // Format stocké : "sel:hash"
  // ──────────────────────────────────────
  static String hashPassword(String password, {String? salt}) {
    final actualSalt = salt ?? _generateSalt();
    List<int> hash = utf8.encode(actualSalt + password);
    for (int i = 0; i < 10000; i++) {
      hash = sha256.convert(hash).bytes;
    }
    final hex = hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '$actualSalt:$hex';
  }

  static bool verifyPassword(String password, String storedHash) {
    // Rétrocompatibilité : ancien hash sans sel
    if (!storedHash.contains(':')) {
      return sha256.convert(utf8.encode(password)).toString() == storedHash;
    }
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    return hashPassword(password, salt: parts[0]) == storedHash;
  }

  static String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }
}
