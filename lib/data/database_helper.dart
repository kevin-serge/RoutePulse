import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/user_model.dart';
import '../model/livraison_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  // =========================
  // INIT DATABASE
  // =========================
  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'users.db');

    return await openDatabase(
      path,
      version: 3, // 🔥 version mise à jour
      onCreate: (db, version) async {
        // =========================
        // TABLE USERS (EXISTANTE)
        // =========================
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            status TEXT DEFAULT 'disponible',
            distanceParcourue REAL DEFAULT 0
          )
        ''');

        // =========================
        // TABLE LIVRAISON (NOUVELLE)
        // =========================
        await db.execute('''
          CREATE TABLE livraison(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client TEXT NOT NULL,
            adresse TEXT NOT NULL,
            statut TEXT DEFAULT 'en_attente',
            livreurId INTEGER,
            photos TEXT
          )
        ''');

        // =========================
        // USERS PAR DÉFAUT
        // =========================
        await db.insert(
          'users',
          User(
            email: 'admin@example.com',
            passwordHash: User.hashPassword('admin123'),
            role: 'admin',
          ).toMap(),
        );

        await db.insert(
          'users',
          User(
            email: 'livreur@example.com',
            passwordHash: User.hashPassword('livreur123'),
            role: 'livreur',
          ).toMap(),
        );
      },

      // =========================
      // MIGRATION SAFE
      // =========================
      onUpgrade: (db, oldVersion, newVersion) async {
        // USERS upgrades
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN status TEXT DEFAULT "disponible"',
          );
          await db.execute(
            'ALTER TABLE users ADD COLUMN distanceParcourue REAL DEFAULT 0',
          );
        }

        // LIVRAISON TABLE
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS livraison(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              client TEXT NOT NULL,
              adresse TEXT NOT NULL,
              statut TEXT DEFAULT 'en_attente',
              livreurId INTEGER,
              photos TEXT
            )
          ''');
        }
      },
    );
  }

  // =========================
  // AUTH
  // =========================
  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    final db = await database;
    final hash = User.hashPassword(password);

    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hash],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // =========================
  // LIVREURS
  // =========================
  Future<int> addLivreur(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateLivreurStatus(
    int userId,
    String status, {
    double? distance,
  }) async {
    final db = await database;

    return await db.update(
      'users',
      {'status': status, if (distance != null) 'distanceParcourue': distance},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<User>> getAllLivreurs() async {
    final db = await database;

    final maps = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['livreur'],
    );

    return maps.map((e) => User.fromMap(e)).toList();
  }

  Future<List<User>> getLivreursDisponibles() async {
    final db = await database;

    final maps = await db.query(
      'users',
      where: 'role = ? AND status = ?',
      whereArgs: ['livreur', 'disponible'],
    );

    return maps.map((e) => User.fromMap(e)).toList();
  }

  // =========================
  // LIVRAISONS
  // =========================

  Future<int> addLivraison(String client, String adresse) async {
    final db = await database;

    return await db.insert('livraison', {
      'client': client,
      'adresse': adresse,
      'statut': 'en_attente',
      'livreurId': null,
      'photos': '',
    });
  }

  Future<List<Livraison>> getAllLivraisons() async {
    final db = await database;

    final maps = await db.query('livraison');

    return maps.map((e) => Livraison.fromMap(e)).toList();
  }

  Future<int> assignerLivraison(int livraisonId, int livreurId) async {
    final db = await database;

    return await db.update(
      'livraison',
      {'livreurId': livreurId, 'statut': 'en_cours'},
      where: 'id = ?',
      whereArgs: [livraisonId],
    );
  }

  Future<int> deleteLivraison(int id) async {
    final db = await database;

    return await db.delete('livraison', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updatePhotos(int id, List<String> photos) async {
    final db = await database;

    return await db.update(
      'livraison',
      {'photos': photos.join(',')},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
