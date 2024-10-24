// lib/database_helper.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Создаем синглтон для DatabaseHelper
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Получаем базу данных или инициализируем ее
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Инициализация базы данных
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'israeldelcargo.db');
    return await openDatabase(
      path,
      version: 2, // Увеличиваем версию для добавления новой таблицы
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Создаем таблицы при первом запуске
  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE shipments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trackingNumber TEXT UNIQUE,
        status TEXT,
        productType TEXT
      )
    ''');
  }

  // Обновление базы данных для версии 2
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE shipments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          trackingNumber TEXT UNIQUE,
          status TEXT,
          productType TEXT
        )
      ''');
    }
  }

  // Регистрация пользователя
  Future<int> registerUser(String name, String email, String password) async {
    final db = await database;
    var res = await db.insert('users', {
      'name': name,
      'email': email,
      'password': password,
    });
    return res;
  }

  // Получение пользователя по email и паролю
  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await database;
    var res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  // Вставка отправления
  Future<int> insertShipment(String trackingNumber, String status, String productType) async {
    final db = await database;
    var res = await db.insert('shipments', {
      'trackingNumber': trackingNumber,
      'status': status,
      'productType': productType,
    });
    return res;
  }

  // Получение всех отправлений
  Future<List<Map<String, dynamic>>> getAllShipments() async {
    final db = await database;
    var res = await db.query('shipments', orderBy: 'id DESC');
    return res;
  }

  // Получение отправления по трек-номеру
  Future<Map<String, dynamic>?> getShipment(String trackingNumber) async {
    final db = await database;
    var res = await db.query(
      'shipments',
      where: 'trackingNumber = ?',
      whereArgs: [trackingNumber],
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  // Обновление статуса отправления
  Future<int> updateShipmentStatus(String trackingNumber, String newStatus) async {
    final db = await database;
    var res = await db.update(
      'shipments',
      {'status': newStatus},
      where: 'trackingNumber = ?',
      whereArgs: [trackingNumber],
    );
    return res;
  }
}
