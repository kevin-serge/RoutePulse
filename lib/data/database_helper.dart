import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../model/user_model.dart';
import '../model/livraison_model.dart';
import '../model/client_model.dart';
import '../model/vehicule_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async => _db ??= await _initDb();

  // ──────────────────────────────────────
  // INIT — version 9 pour forcer migration
  // ──────────────────────────────────────
  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'routepulse.db');
    return await openDatabase(
      path,
      version: 9,
      onCreate: (db, _) async {
        await _createTables(db);
        await _insertDefaults(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS livraison');
        await db.execute('DROP TABLE IF EXISTS users');
        await db.execute('DROP TABLE IF EXISTS clients');
        await db.execute('DROP TABLE IF EXISTS vehicules');
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
        photos TEXT DEFAULT '[]',
        notes TEXT,
        motifAnnulation TEXT,
        creneau TEXT,
        articles TEXT,
        isSynced INTEGER DEFAULT 0,
        remoteId TEXT,
        isDeleted INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        telephone TEXT,
        adresseHabituelle TEXT,
        notes TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        immatriculation TEXT,
        type TEXT,
        notes TEXT,
        actif INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');
  }

  // ──────────────────────────────────────
  // COMPTE ADMIN PAR DÉFAUT
  // Modifie les valeurs ici, ou passe-les via --dart-define :
  //   flutter run \
  //     --dart-define=ADMIN_EMAIL=toi@tondomaine.com \
  //     --dart-define=ADMIN_PASSWORD=TonMotDePasse123
  // ──────────────────────────────────────
  Future<void> _insertDefaults(Database db) async {
    const adminEmail = String.fromEnvironment(
      'ADMIN_EMAIL',
      defaultValue: 'admin@routepulse.com', // ← CHANGE ICI
    );
    const adminPassword = String.fromEnvironment(
      'ADMIN_PASSWORD',
      defaultValue: 'Admin1234!', // ← CHANGE ICI
    );

    await db.insert(
      'users',
      {
        'email': adminEmail,
        'password': User.hashPassword(adminPassword),
        'role': 'admin',
        'status': 'disponible',
        'distanceParcourue': 0.0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ──────────────────────────────────────
  // AUTH
  // ──────────────────────────────────────
  Future<User?> getUserByEmailAndPassword(
      String email, String password) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final user = User.fromMap(rows.first);
    if (!User.verifyPassword(password, user.passwordHash)) return null;

    // Migration transparente : rehash sans sel → avec sel
    if (!user.passwordHash.contains(':')) {
      final newHash = User.hashPassword(password);
      await db.update('users', {'password': newHash},
          where: 'id = ?', whereArgs: [user.id]);
      user.passwordHash = newHash;
    }
    return user;
  }

  // ──────────────────────────────────────
  // LIVREURS
  // ──────────────────────────────────────
  Future<int> addLivreur(User user) async {
    final db = await database;
    return db.insert('users', user.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<User>> getAllLivreurs() async {
    final db = await database;
    final rows = await db.query('users',
        where: 'role = ?', whereArgs: ['livreur']);
    return rows.map(User.fromMap).toList();
  }

  Future<List<User>> getLivreursDisponibles() async {
    final db = await database;
    final rows = await db.query('users',
        where: 'role = ? AND status = ?',
        whereArgs: ['livreur', 'disponible']);
    return rows.map(User.fromMap).toList();
  }

  Future<void> updateLivreurStatus(int userId, String status,
      {double? distance}) async {
    final db = await database;
    final data = <String, dynamic>{'status': status};
    if (distance != null) data['distanceParcourue'] = distance;
    await db.update('users', data,
        where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> deleteLivreur(int id) async {
    final db = await database;
    await db.delete('users',
        where: 'id = ? AND role = ?', whereArgs: [id, 'livreur']);
  }

  // ──────────────────────────────────────
  // LIVRAISONS
  // ──────────────────────────────────────
  Future<int> addLivraison(Livraison l) async {
    final db = await database;
    final map = l.toMap()
      ..remove('id')
      ..['created_at'] = DateTime.now().toIso8601String();
    return db.insert('livraison', map);
  }

  Future<void> updateLivraison(Livraison l) async {
    final db = await database;
    await db.update(
      'livraison',
      l.toMap()
        ..['updated_at'] = DateTime.now().toIso8601String()
        ..['isSynced'] = 0,
      where: 'id = ?',
      whereArgs: [l.id],
    );
  }

  Future<List<Livraison>> getAllLivraisons() async {
    final db = await database;
    final rows = await db.query('livraison',
        where: 'isDeleted = 0', orderBy: 'created_at DESC');
    return rows.map(Livraison.fromMap).toList();
  }

  Future<Livraison?> getLivraisonById(int id) async {
    final db = await database;
    final rows = await db.query('livraison',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Livraison.fromMap(rows.first);
  }

  Future<List<Livraison>> getLivraisonsByLivreur(int livreurId) async {
    final db = await database;
    final rows = await db.query('livraison',
        where: 'livreurId = ? AND isDeleted = 0',
        whereArgs: [livreurId],
        orderBy: 'created_at DESC');
    return rows.map(Livraison.fromMap).toList();
  }

  Future<void> updateStatut(int id, String statut,
      {String? motif, List<String>? photos}) async {
    final db = await database;
    final data = <String, dynamic>{
      'statut': statut,
      'isSynced': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (motif != null) data['motifAnnulation'] = motif;
    if (photos != null) data['photos'] = photos.join(',');
    await db.update('livraison', data,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> softDeleteLivraison(int id) async {
    final db = await database;
    await db.update(
      'livraison',
      {
        'isDeleted': 1,
        'isSynced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> assignerLivraison(int livraisonId, int livreurId) async {
    final db = await database;
    await db.update(
      'livraison',
      {
        'livreurId': livreurId,
        'statut': 'en_cours',
        'isSynced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [livraisonId],
    );
  }

  Future<List<Livraison>> getUnsyncedLivraisons() async {
    final db = await database;
    final rows =
        await db.query('livraison', where: 'isSynced = 0');
    return rows.map(Livraison.fromMap).toList();
  }

  Future<void> markSynced(int localId, String remoteId) async {
    final db = await database;
    await db.update(
      'livraison',
      {'isSynced': 1, 'remoteId': remoteId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // Upsert depuis Supabase — ne pas écraser les modifs locales non-syncées
  Future<void> upsertFromRemote(Map<String, dynamic> item) async {
    final db = await database;
    final remoteId = item['id']?.toString();
    if (remoteId == null) return;

    final existing = await db.query('livraison',
        where: 'remoteId = ?', whereArgs: [remoteId]);

    final data = {
      'client': item['client'] ?? '',
      'adresse': item['adresse'] ?? '',
      'statut': item['statut'] ?? 'en_attente',
      'livreurId': item['livreur_id'],
      'photos': item['photos'] ?? '[]',
      'notes': item['notes'],
      'motifAnnulation': item['motif_annulation'],
      'creneau': item['creneau'],
      'articles': item['articles'],
      'remoteId': remoteId,
      'isDeleted': 0,
      'isSynced': 1,
      'updated_at':
          item['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
    };

    if (existing.isEmpty) {
      data['created_at'] = item['created_at']?.toString() ??
          DateTime.now().toIso8601String();
      await db.insert('livraison', data);
    } else {
      // Ne pas écraser une modification locale non syncée
      if ((existing.first['isSynced'] as int? ?? 1) == 0) return;
      await db.update('livraison', data,
          where: 'remoteId = ?', whereArgs: [remoteId]);
    }
  }

  // ──────────────────────────────────────
  // STATS
  // ──────────────────────────────────────
  Future<Map<String, int>> getStatsStatuts() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT statut, COUNT(*) as count
      FROM livraison WHERE isDeleted = 0
      GROUP BY statut
    ''');
    final stats = <String, int>{
      'en_attente': 0,
      'en_cours': 0,
      'livree': 0,
      'annulee': 0,
      'a_reporter': 0,
    };
    for (final row in rows) {
      stats[row['statut'] as String] = row['count'] as int;
    }
    return stats;
  }

  // ──────────────────────────────────────
  // CLIENTS
  // ──────────────────────────────────────
  Future<int> addClient(Client c) async {
    final db = await database;
    return db.insert('clients',
        c.toMap()..remove('id')..['created_at'] = DateTime.now().toIso8601String());
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    return (await db.query('clients', orderBy: 'nom ASC'))
        .map(Client.fromMap)
        .toList();
  }

  Future<void> updateClient(Client c) async {
    final db = await database;
    await db.update('clients', c.toMap(),
        where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteClient(int id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────────────────────────────
  // VEHICULES
  // ──────────────────────────────────────
  Future<int> addVehicule(Vehicule v) async {
    final db = await database;
    return db.insert('vehicules',
        v.toMap()..remove('id')..['created_at'] = DateTime.now().toIso8601String());
  }

  Future<List<Vehicule>> getAllVehicules() async {
    final db = await database;
    return (await db.query('vehicules', orderBy: 'nom ASC'))
        .map(Vehicule.fromMap)
        .toList();
  }

  Future<void> updateVehicule(Vehicule v) async {
    final db = await database;
    await db.update('vehicules', v.toMap(),
        where: 'id = ?', whereArgs: [v.id]);
  }

  Future<void> deleteVehicule(int id) async {
    final db = await database;
    await db.delete('vehicules', where: 'id = ?', whereArgs: [id]);
  }
}
