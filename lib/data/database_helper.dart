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
  // INIT
  // =========================
  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'routepulse.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await _createTables(db);
        await _insertDefaults(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Recréation propre à partir de la v5
        await db.execute('DROP TABLE IF EXISTS livraison');
        await db.execute('DROP TABLE IF EXISTS users');
        await _createTables(db);
        await _insertDefaults(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        status TEXT DEFAULT 'disponible',
        distanceParcourue REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS livraison(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client TEXT NOT NULL,
        adresse TEXT NOT NULL,
        statut TEXT DEFAULT 'en_attente',
        livreurId INTEGER,
        photos TEXT DEFAULT '',
        notes TEXT,
        motifAnnulation TEXT,
        creneau TEXT,
        articles TEXT,
        isSynced INTEGER DEFAULT 0,
        remoteId TEXT,
        updatedAt TEXT,
        createdAt TEXT
      )
    ''');
  }

  Future<void> _insertDefaults(Database db) async {
    await db.insert('users', {
      'email': 'admin@example.com',
      'password': User.hashPassword('admin123'),
      'role': 'admin',
      'status': 'disponible',
      'distanceParcourue': 0.0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('users', {
      'email': 'livreur@example.com',
      'password': User.hashPassword('livreur123'),
      'role': 'livreur',
      'status': 'disponible',
      'distanceParcourue': 0.0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
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

    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  // =========================
  // LIVREURS
  // =========================
  Future<int> addLivreur(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updateLivreurStatus(int userId, String status,
      {double? distance}) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'status': status,
        if (distance != null) 'distanceParcourue': distance,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteLivreur(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ? AND role = ?',
        whereArgs: [id, 'livreur']);
  }

  Future<List<User>> getAllLivreurs() async {
    final db = await database;
    final maps = await db.query('users',
        where: 'role = ?', whereArgs: ['livreur']);
    return maps.map((e) => User.fromMap(e)).toList();
  }

  Future<List<User>> getLivreursDisponibles() async {
    final db = await database;
    final maps = await db.query('users',
        where: 'role = ? AND status = ?',
        whereArgs: ['livreur', 'disponible']);
    return maps.map((e) => User.fromMap(e)).toList();
  }

  // =========================
  // LIVRAISONS
  // =========================
  Future<int> addLivraison(Livraison l) async {
    final db = await database;
    final map = l.toMap();
    map.remove('id');
    return await db.insert('livraison', map);
  }

  Future<int> updateLivraison(Livraison l) async {
    final db = await database;
    return await db.update(
      'livraison',
      l.toMap()..update('updatedAt', (_) => DateTime.now().toIso8601String()),
      where: 'id = ?',
      whereArgs: [l.id],
    );
  }

  Future<List<Livraison>> getAllLivraisons() async {
    final db = await database;
    final maps = await db.query('livraison', orderBy: 'createdAt DESC');
    return maps.map((e) => Livraison.fromMap(e)).toList();
  }

  Future<List<Livraison>> getLivraisonsByLivreur(int livreurId) async {
    final db = await database;
    final maps = await db.query(
      'livraison',
      where: 'livreurId = ?',
      whereArgs: [livreurId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((e) => Livraison.fromMap(e)).toList();
  }

  Future<List<Livraison>> getLivraisonsDuJour(int? livreurId) async {
    final db = await database;
    final today = DateTime.now();
    final start =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final end =
        DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    String where = 'createdAt >= ? AND createdAt <= ?';
    List<dynamic> args = [start, end];

    if (livreurId != null) {
      where += ' AND livreurId = ?';
      args.add(livreurId);
    }

    final maps = await db.query('livraison',
        where: where, whereArgs: args, orderBy: 'createdAt ASC');
    return maps.map((e) => Livraison.fromMap(e)).toList();
  }

  Future<int> updateStatut(int id, String statut,
      {String? motif, List<String>? photos}) async {
    final db = await database;
    final data = <String, dynamic>{
      'statut': statut,
      'isSynced': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (motif != null) data['motifAnnulation'] = motif;
    if (photos != null) data['photos'] = photos.join(',');

    return await db.update('livraison', data,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> assignerLivraison(int livraisonId, int livreurId) async {
    final db = await database;
    return await db.update(
      'livraison',
      {
        'livreurId': livreurId,
        'statut': 'en_cours',
        'isSynced': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [livraisonId],
    );
  }

  Future<int> deleteLivraison(int id) async {
    final db = await database;
    return await db.delete('livraison', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Livraison>> getUnsyncedLivraisons() async {
    final db = await database;
    final maps =
        await db.query('livraison', where: 'isSynced = 0');
    return maps.map((e) => Livraison.fromMap(e)).toList();
  }

  Future<void> markSynced(int localId, String remoteId) async {
    final db = await database;
    await db.update(
      'livraison',
      {
        'isSynced': 1,
        'remoteId': remoteId,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // =========================
  // STATS
  // =========================
  Future<Map<String, int>> getStatsStatuts() async {
    final all = await getAllLivraisons();
    final Map<String, int> stats = {
      'en_attente': 0,
      'en_cours': 0,
      'a_reporter': 0,
      'annulee': 0,
      'livree': 0,
    };
    for (final l in all) {
      stats[l.statut] = (stats[l.statut] ?? 0) + 1;
    }
    return stats;
  }
}
