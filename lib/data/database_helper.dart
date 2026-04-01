import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/delivery_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  // Singleton
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  // Initialisation de la BDD
  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'routepulse.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE deliveries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client TEXT NOT NULL,
        address TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        isAdmin INTEGER NOT NULL
      )
    ''');
    // 🔹 Compte admin par défaut
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123', // 🔑 mot de passe test
      'isAdmin': 1, // 1 = admin
    });

    // 🔹 Compte livreur test
    await db.insert('users', {
      'username': 'livreur1',
      'password': 'livreur123',
      'isAdmin': 0, // 0 = livreur
    });
  }

  // ================= CRUD Livraisons =================
  Future<int> insertDelivery(Delivery delivery) async {
    final db = await database;
    return await db.insert('deliveries', delivery.toMap());
  }

  Future<List<Delivery>> getDeliveries() async {
    final db = await database;
    final res = await db.query('deliveries', orderBy: 'id DESC');
    return res.map((e) => Delivery.fromMap(e)).toList();
  }

  Future<int> updateDelivery(Delivery delivery) async {
    final db = await database;
    if (delivery.id == null) return 0; // Sécurité
    return await db.update(
      'deliveries',
      delivery.toMap(),
      where: 'id = ?',
      whereArgs: [delivery.id],
    );
  }

  Future<int> deleteDelivery(int id) async {
    final db = await database;
    return await db.delete('deliveries', where: 'id = ?', whereArgs: [id]);
  }

  // ================= CRUD Users =================
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUser(String username, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return User.fromMap(res.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final res = await db.query('users', orderBy: 'id ASC');
    return res.map((e) => User.fromMap(e)).toList();
  }
}
