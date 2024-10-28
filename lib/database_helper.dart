// lib/database_helper.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Singleton Pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Getter для базы данных
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Инициализация базы данных
    _database = await _initDatabase();
    return _database!;
  }

  // Инициализация базы данных
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'israeldelcargo.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Создание таблиц
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
        origin TEXT,
        destination TEXT,
        estimatedDelivery TEXT
      )
    ''');
    // Добавьте другие таблицы по необходимости
  }

  // Обновление базы данных
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Добавьте изменения в схеме базы данных здесь
      // Например, добавление новых колонок или таблиц
    }
  }

  // Метод для регистрации пользователя
  Future<bool> registerUser(String name, String email, String password) async {
    final db = await database;
    try {
      await db.insert(
        'users',
        {'name': name, 'email': email, 'password': password},
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      return true;
    } catch (e) {
      // Обработка ошибок, например, если email уже существует
      return false;
    }
  }

  // Метод для получения пользователя по email и паролю
  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  // Метод для добавления отправления
  Future<bool> addShipment(String trackingNumber, String origin, String destination, String estimatedDelivery) async {
    final db = await database;
    try {
      await db.insert(
        'shipments',
        {
          'trackingNumber': trackingNumber,
          'status': 'Создано',
          'origin': origin,
          'destination': destination,
          'estimatedDelivery': estimatedDelivery,
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      return true;
    } catch (e) {
      // Обработка ошибок, например, если trackingNumber уже существует
      return false;
    }
  }

  // Метод для получения отправления по номеру отслеживания
  Future<Map<String, dynamic>?> getShipment(String trackingNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shipments',
      where: 'trackingNumber = ?',
      whereArgs: [trackingNumber],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  // Метод для получения всех отправлений
  Future<List<Map<String, dynamic>>> getAllShipments() async {
    final db = await database;
    return await db.query('shipments');
  }

  // Метод для обновления статуса отправления
  Future<bool> updateShipmentStatus(String trackingNumber, String newStatus) async {
    final db = await database;
    int count = await db.update(
      'shipments',
      {'status': newStatus},
      where: 'trackingNumber = ?',
      whereArgs: [trackingNumber],
    );
    return count > 0;
  }

  // Добавьте другие методы по необходимости
}
