import 'dart:convert';
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

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'routepulse.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table utilisateurs
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        isAdmin INTEGER NOT NULL
      )
    ''');

    // Table livraisons
    await db.execute('''
      CREATE TABLE deliveries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client TEXT NOT NULL,
        address TEXT NOT NULL,
        status TEXT NOT NULL,
        assignedTo TEXT DEFAULT ''
      )
    ''');

    // Compte admin par défaut
    await db.insert('users', {
      'email': 'admin@routepulse.com',
      'password': hashPassword('admin123'),
      'isAdmin': 1,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE deliveries ADD COLUMN assignedTo TEXT DEFAULT ""',
      );
    }
  }

  // ================= HASH PASSWORD =================
  static String hashPassword(String password) {
    return base64Encode(utf8.encode(password));
  }

  // ================= CRUD USERS =================
  Future<int> insertUser(User user) async {
    final db = await database;
    final map = user.toMap();
    map['password'] = hashPassword(user.password);
    return await db.insert('users', map);
  }

  Future<User?> getUser(String email, String password) async {
    final db = await database;
    final hashed = hashPassword(password);

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashed],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final res = await db.query('users', orderBy: 'id ASC');
    return res.map((e) => User.fromMap(e)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final map = user.toMap();
    map['password'] = hashPassword(user.password);
    return await db.update('users', map, where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> userExists(String email) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return res.isNotEmpty;
  }

  // ================= CRUD DELIVERIES =================
  Future<int> insertDelivery(Delivery delivery) async {
    final db = await database;
    return await db.insert('deliveries', delivery.toMap());
  }

  Future<List<Delivery>> getDeliveries() async {
    final db = await database;
    final res = await db.query('deliveries', orderBy: 'id DESC');
    return res.map((e) => Delivery.fromMap(e)).toList();
  }

  Future<List<Delivery>> getDeliveriesByUser(String email) async {
    final db = await database;
    final res = await db.query(
      'deliveries',
      where: 'assignedTo = ?',
      whereArgs: [email],
      orderBy: 'id DESC',
    );
    return res.map((e) => Delivery.fromMap(e)).toList();
  }

  Future<int> updateDelivery(Delivery delivery) async {
    final db = await database;
    if (delivery.id == null) return 0;
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

  // ================= RESET DATABASE =================
  Future<void> resetDatabase() async {
    final path = join(await getDatabasesPath(), 'routepulse.db');
    await deleteDatabase(path);
  }

  Future<void> ensureAdminExists() async {
    final dbClient = await database;
    final res = await dbClient.query(
      'users',
      where: 'isAdmin = ?',
      whereArgs: [1],
    );
    if (res.isEmpty) {
      await dbClient.insert('users', {
        'email': 'admin@routepulse.com',
        'password': hashPassword('admin123'),
        'isAdmin': 1,
      });
    }
  }
}
