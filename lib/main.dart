// main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Для отправки сообщения в WhatsApp

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.initDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const IsraelDelCargoApp(),
    ),
  );
}

/// ==================== Models ====================

/// User model
class UserModel {
  final int? id;
  String name;
  String email;
  String phone;
  String address;
  String? avatarPath;
  final String password;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.avatarPath,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'avatarPath': avatarPath,
      'password': password,
    };
  }
}

/// CartItem model
class CartItem {
  final String serviceName;
  int quantity;
  final double price;
  final String trackingNumber;

  CartItem({
    required this.serviceName,
    this.quantity = 1,
    required this.price,
    required this.trackingNumber,
  });
}

/// Shipment model
class Shipment {
  final int? id;
  final String trackingNumber;
  final String status;
  final String origin;
  final String destination;
  final String estimatedDelivery;
  final int userId;

  Shipment({
    this.id,
    required this.trackingNumber,
    required this.status,
    required this.origin,
    required this.destination,
    required this.estimatedDelivery,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'status': status,
      'origin': origin,
      'destination': destination,
      'estimatedDelivery': estimatedDelivery,
      'userId': userId,
    };
  }
}

/// ==================== Database Helper ====================

/// DatabaseHelper singleton class
class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await initDatabase();

  Future<Database> initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String dbPath = path.join(databasesPath, 'israeldelcargo.db');

    return await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        phone TEXT,
        address TEXT,
        avatarPath TEXT,
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
        estimatedDelivery TEXT,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cart(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serviceName TEXT,
        quantity INTEGER,
        price REAL,
        trackingNumber TEXT
      )
    ''');
  }

  // Upgrade database to add new fields
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Implement upgrade logic if necessary
    }
  }

  // User CRUD
  Future<int> addUser(UserModel user) async {
    Database db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<UserModel?> getUser(String email, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      return UserModel(
        id: maps.first['id'],
        name: maps.first['name'] ?? '',
        email: maps.first['email'],
        phone: maps.first['phone'] ?? '',
        address: maps.first['address'] ?? '',
        avatarPath: maps.first['avatarPath'],
        password: maps.first['password'],
      );
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UserModel(
        id: maps.first['id'],
        name: maps.first['name'] ?? '',
        email: maps.first['email'],
        phone: maps.first['phone'] ?? '',
        address: maps.first['address'] ?? '',
        avatarPath: maps.first['avatarPath'],
        password: maps.first['password'],
      );
    }
    return null;
  }

  Future<int> updateUser(UserModel user) async {
    Database db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Shipment CRUD
  Future<int> addShipment(Shipment shipment) async {
    Database db = await database;
    return await db.insert(
      'shipments',
      shipment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Shipment>> getShipmentsByUser(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'shipments',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) {
      return Shipment(
        id: maps[i]['id'],
        trackingNumber: maps[i]['trackingNumber'],
        status: maps[i]['status'],
        origin: maps[i]['origin'],
        destination: maps[i]['destination'],
        estimatedDelivery: maps[i]['estimatedDelivery'],
        userId: maps[i]['userId'],
      );
    });
  }

  // Cart CRUD
  Future<int> addToCart(CartItem item) async {
    Database db = await database;
    return await db.insert('cart', {
      'serviceName': item.serviceName,
      'quantity': item.quantity,
      'price': item.price,
      'trackingNumber': item.trackingNumber,
    });
  }

  Future<List<CartItem>> getCartItems() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('cart');
    return List.generate(maps.length, (i) {
      return CartItem(
        serviceName: maps[i]['serviceName'],
        quantity: maps[i]['quantity'],
        price: maps[i]['price'],
        trackingNumber: maps[i]['trackingNumber'],
      );
    });
  }

  Future<int> clearCart() async {
    Database db = await database;
    return await db.delete('cart');
  }
}

/// ==================== State Management ====================

/// AppState to manage theme, user, and cart
class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  final List<CartItem> _cartItems = [];
  UserModel? _currentUser;

  ThemeMode get themeMode => _themeMode;
  List<CartItem> get cartItems => _cartItems;
  UserModel? get currentUser => _currentUser;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void addToCart(String serviceName, double price) {
    final trackingNumber = 'TRK${DateTime.now().millisecondsSinceEpoch}';
    final existingItemIndex = _cartItems.indexWhere((item) => item.serviceName == serviceName);

    if (existingItemIndex == -1) {
      _cartItems.add(CartItem(
        serviceName: serviceName,
        quantity: 1,
        price: price,
        trackingNumber: trackingNumber,
      ));
    } else {
      _cartItems[existingItemIndex].quantity++;
    }
    notifyListeners();
  }

  void removeFromCart(String serviceName) {
    _cartItems.removeWhere((item) => item.serviceName == serviceName);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    UserModel? user = await DatabaseHelper.instance.getUser(email, password);
    if (user != null) {
      _currentUser = user;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', user.id!);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    if (userId != null) {
      UserModel? user = await DatabaseHelper.instance.getUserById(userId);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
    String? avatarPath,
  }) async {
    if (_currentUser != null) {
      _currentUser!
        ..name = name
        ..email = email
        ..phone = phone
        ..address = address;
      if (avatarPath != null) {
        _currentUser!.avatarPath = avatarPath;
      }
      await DatabaseHelper.instance.updateUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> updateUserAvatar(String avatarPath) async {
    if (_currentUser != null) {
      _currentUser!.avatarPath = avatarPath;
      await DatabaseHelper.instance.updateUser(_currentUser!);
      notifyListeners();
    }
  }
}

/// ==================== Application Widgets ====================

/// Main Application Widget
class IsraelDelCargoApp extends StatelessWidget {
  const IsraelDelCargoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      title: 'ISRAELDELCARGO',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          headlineLarge:
              TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold),
          headlineMedium:
              TextStyle(color: Colors.black, fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C3D5A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0A1929),
        scaffoldBackgroundColor: const Color(0xFF0A1929),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          headlineLarge:
              TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold),
          headlineMedium:
              TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C3D5A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper to decide which screen to show based on authentication
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isAuthenticated = false;

  Future<void> _checkBiometrics() async {
    try {
      _canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException {
      _canCheckBiometrics = false;
    }
    if (!mounted) return;
  }

  Future<void> _authenticate() async {
    try {
      _isAuthenticated = await auth.authenticate(
        localizedReason: 'Пожалуйста, подтвердите свою личность',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } on PlatformException {
      _isAuthenticated = false;
    }
    if (!mounted) return;
  }

  @override
  void initState() {
    super.initState();
    _checkBiometrics().then((_) {
      if (_canCheckBiometrics) {
        _authenticate().then((_) {
          if (_isAuthenticated) {
            final appState = Provider.of<AppState>(context, listen: false);
            appState.tryAutoLogin();
          }
        });
      } else {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.tryAutoLogin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (appState.currentUser != null) {
      return const MainPage();
    } else {
      return const LoginScreen();
    }
  }
}

/// ==================== Screens ====================

/// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isAuthenticated = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    await appState.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (appState.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный email или пароль')),
      );
    }
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  Future<void> _authenticate() async {
    try {
      _isAuthenticated = await auth.authenticate(
        localizedReason: 'Пожалуйста, подтвердите свою личность',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } on PlatformException {
      _isAuthenticated = false;
    }
    if (_isAuthenticated) {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.tryAutoLogin();
      if (appState.currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось выполнить вход')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? const Color(0xFF0A1929) : Colors.white,
              isDark ? const Color(0xFF1C3D5A) : Colors.blue.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ISRAELDELCARGO',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor:
                              isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Пожалуйста, введите корректный email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          filled: true,
                          fillColor:
                              isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Пароль должен быть не менее 6 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text('Войти'),
                            ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _navigateToSignup,
                        child: Text(
                          'Нет учетной записи? Зарегистрируйтесь',
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _authenticate,
                        child: Icon(
                          Icons.fingerprint,
                          size: 50,
                          color: isDark ? Colors.white : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Войти с помощью Face ID',
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.blue),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Signup Screen
class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // Новое поле
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Новое поле
  final _addressController = TextEditingController(); // Новое поле
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    UserModel newUser = UserModel(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      password: _passwordController.text.trim(),
    );

    int userId = await DatabaseHelper.instance.addUser(newUser);
    if (userId > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Регистрация успешна. Войдите в систему.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь с таким email уже существует')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        backgroundColor: const Color(0xFF1C3D5A),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? const Color(0xFF0A1929) : Colors.white,
              isDark ? const Color(0xFF1C3D5A) : Colors.blue.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ISRAELDELCARGO',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Имя',
                          filled: true,
                          fillColor:
                              isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите имя';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor:
                              isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Пожалуйста, введите корректный email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Номер телефона',
                          filled: true,
                          fillColor:
                              isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите номер телефона';
                          }
                          if (!RegExp(r'^\+?\d{7,15}$').hasMatch(value)) {
                            return 'Пожалуйста, введите корректный номер телефона';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Address Field
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Адрес',
                          filled: true,
                          fillColor:
                              isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                          prefixIcon: const Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите адрес';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          filled: true,
                          fillColor:
                              isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Пароль должен быть не менее 6 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _signup,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text('Зарегистрироваться'),
                            ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Main Page with Bottom Navigation and Drawer
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static const List<Widget> _widgetOptions = <Widget>[
    HomeContent(),
    TrackingTab(),
    CartScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1C3D5A),
              ),
              child: const Text(
                'Меню',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('О нас'),
              onTap: () {
                Navigator.pop(context); // Закрываем Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('ISRAELDELCARGO'),
        backgroundColor: const Color(0xFF1C3D5A),
      ),
      body: PageView(
        controller: _pageController,
        children: _widgetOptions,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF0A1929) : Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF0D47A1),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Трекеры',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Корзина',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

/// Home Content with Country Selection, Weight Input, and Services
class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _formKey = GlobalKey<FormState>();
  String? _countryOrigin;
  String? _countryDestination;
  final _weightController = TextEditingController();

  // List of services with their prices
  final List<Map<String, dynamic>> services = const [
    {
      'name': 'Доставка документов',
      'icon': Icons.description,
      'price': 3000.0,
    },
    {
      'name': 'Религиозные атрибуты (книги, иудайка)',
      'icon': Icons.book,
      'price': 2500.0,
    },
    {
      'name': 'Одежда, обувь, головные уборы',
      'icon': Icons.shopping_bag,
      'price': 2300.0,
    },
    {
      'name': 'Кошерное питание',
      'icon': Icons.fastfood,
      'price': 2600.0,
    },
    {
      'name': 'Товары из Duty Free',
      'icon': Icons.airplane_ticket,
      'price': 3000.0,
    },
    {
      'name': 'Маленькие посылки (до 1кг)',
      'icon': Icons.local_shipping,
      'price': 3000.0,
    },
  ];

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity:
                Tween<double>(begin: 0.0, end: 1.0).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildMainButton(
      BuildContext context, String text, IconData icon, Widget screen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: () => _navigateTo(context, screen),
        icon: Icon(icon, size: 24, color: Colors.white),
        label: Text(text, style: const TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return Card(
      elevation: 4,
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.addToCart(service['name'], service['price']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${service['name']} добавлено в корзину')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(service['icon'], size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                service['name'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'От ${service['price']} ₽',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _calculateTotal(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      double cartTotal = 0.0;
      for (var item in appState.cartItems) {
        cartTotal += item.price * item.quantity;
      }

      double weight = double.parse(_weightController.text.trim());
      double deliveryCost = weight * 500.0; // 500 ₽ per kg
      double total = cartTotal + deliveryCost;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Итоговая стоимость'),
          content: Text('Общая стоимость: ${total.toStringAsFixed(2)} ₽'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? const Color(0xFF0A1929) : Colors.white,
              isDark ? const Color(0xFF1C3D5A) : Colors.blue.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ISRAELDELCARGO',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Country of Origin and Destination
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Страна отправления',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Россия',
                          child: Text('Россия'),
                        ),
                        DropdownMenuItem(
                          value: 'Израиль',
                          child: Text('Израиль'),
                        ),
                        DropdownMenuItem(
                          value: 'Грузия',
                          child: Text('Грузия'),
                        ),
                        DropdownMenuItem(
                          value: 'Казахстан',
                          child: Text('Казахстан'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _countryOrigin = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Выберите страну отправления';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Страна назначения',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Россия',
                          child: Text('Россия'),
                        ),
                        DropdownMenuItem(
                          value: 'Израиль',
                          child: Text('Израиль'),
                        ),
                        DropdownMenuItem(
                          value: 'Грузия',
                          child: Text('Грузия'),
                        ),
                        DropdownMenuItem(
                          value: 'Казахстан',
                          child: Text('Казахстан'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _countryDestination = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Выберите страну назначения';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Weight Input
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Вес (кг)',
                  filled: true,
                  fillColor:
                      isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                  prefixIcon: const Icon(Icons.line_weight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите вес';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Пожалуйста, введите корректный вес';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Calculate Button
              ElevatedButton(
                onPressed: () => _calculateTotal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C3D5A),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Рассчитать',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              // Vertical buttons
              _buildMainButton(
                context,
                'Оформить доставку',
                Icons.local_shipping,
                const DeliveryScreen(),
              ),
              _buildMainButton(
                context,
                'Отследить',
                Icons.track_changes,
                const TrackingTab(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Выберите услугу',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 3 / 4,
                ),
                itemBuilder: (context, index) {
                  return _buildServiceCard(context, services[index]);
                },
              ),
              const SizedBox(height: 24),
              Card(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Мы предлагаем надежные и быстрые услуги доставки для ваших нужд.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile Screen with Improved Design
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  File? _avatarImageFile;
  bool _isEditing = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.currentUser != null) {
      _nameController.text = appState.currentUser!.name;
      _emailController.text = appState.currentUser!.email;
      _phoneController.text = appState.currentUser!.phone;
      _addressController.text = appState.currentUser!.address;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile =
          await _picker.pickImage(source: source, maxWidth: 600, maxHeight: 600);
      if (pickedFile != null) {
        setState(() {
          _avatarImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Обработка ошибок
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе изображения: $e')),
      );
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (builderContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _pickImage(ImageSource.gallery);
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _pickImage(ImageSource.camera);
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);

    await appState.updateUserProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      avatarPath: _avatarImageFile?.path,
    );

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль обновлен успешно')),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение выхода'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text(
              'Выйти',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (appState.currentUser == null) {
      return const Center(child: Text('Нет доступа'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: const Color(0xFF1C3D5A),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              appState.toggleTheme(!appState.isDarkMode);
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity, // Добавлено для полного экрана
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? const Color(0xFF0A1929) : Colors.white,
              isDark ? const Color(0xFF1C3D5A) : Colors.blue.shade100,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isEditing ? _buildEditProfileForm() : _buildProfileView(),
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () {
              _showImageSourceActionSheet();
            },
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF1C3D5A),
              backgroundImage: _avatarImageFile != null
                  ? FileImage(_avatarImageFile!)
                  : (appState.currentUser!.avatarPath != null
                      ? FileImage(File(appState.currentUser!.avatarPath!))
                      : null),
              child: _avatarImageFile == null &&
                      appState.currentUser!.avatarPath == null
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            appState.currentUser!.name,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            appState.currentUser!.email,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            appState.currentUser!.phone,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            appState.currentUser!.address,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Редактировать профиль'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C3D5A),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileForm() {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _showImageSourceActionSheet,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF1C3D5A),
                backgroundImage: _avatarImageFile != null
                    ? FileImage(_avatarImageFile!)
                    : (appState.currentUser!.avatarPath != null
                        ? FileImage(File(appState.currentUser!.avatarPath!))
                        : null),
                child: _avatarImageFile == null &&
                        appState.currentUser!.avatarPath == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Имя',
                      filled: true,
                      fillColor:
                          isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите имя';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor:
                          isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Пожалуйста, введите корректный email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Номер телефона',
                      filled: true,
                      fillColor:
                          isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите номер телефона';
                      }
                      if (!RegExp(r'^\+?\d{7,15}$').hasMatch(value)) {
                        return 'Пожалуйста, введите корректный номер телефона';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Address Field
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Адрес',
                      filled: true,
                      fillColor:
                          isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                      prefixIcon: const Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите адрес';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C3D5A),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Сохранить',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Tracking Screen
class TrackingTab extends StatelessWidget {
  const TrackingTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final trackingItems = appState.cartItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отслеживание'),
        backgroundColor: const Color(0xFF1C3D5A),
      ),
      body: trackingItems.isEmpty
          ? const Center(
              child: Text(
                'У вас нет активных трек-номеров.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: trackingItems.length,
              itemBuilder: (context, index) {
                final item = trackingItems[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping),
                    title: Text(item.serviceName),
                    subtitle: Text('Трек-номер: ${item.trackingNumber}'),
                    trailing: const Text('Статус: В обработке'),
                  ),
                );
              },
            ),
    );
  }
}

/// Cart Screen with "Submit Application" feature
class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  Future<void> _submitApplication(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final total = appState.cartItems.fold(
      0.0,
      (sum, item) => sum + item.price * item.quantity,
    );
    final message = Uri.encodeComponent(
      'Здравствуйте! Я хочу оформить заявку на следующие услуги:\n' +
          appState.cartItems
              .map((item) => '- ${item.serviceName} x${item.quantity}')
              .join('\n') +
          '\nИтого: $total ₽',
    );
    final phoneNumber = '79914992420';
    final url = 'https://wa.me/$phoneNumber?text=$message';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        backgroundColor: const Color(0xFF1C3D5A),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              appState.clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Корзина очищена')),
              );
            },
          ),
        ],
      ),
      body: appState.cartItems.isEmpty
          ? const Center(
              child: Text(
                'Корзина пуста',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: appState.cartItems.length,
              itemBuilder: (context, index) {
                final item = appState.cartItems[index];
                return ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: Text(item.serviceName),
                  subtitle: Text('Количество: ${item.quantity}'),
                  trailing: Text('${item.price * item.quantity} ₽'),
                  onLongPress: () {
                    appState.removeFromCart(item.serviceName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.serviceName} удалено из корзины')),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: Theme.of(context).primaryColor,
        child: Text(
          'Итого: ${appState.cartItems.fold(0.0, (sum, item) => sum + item.price * item.quantity)} ₽',
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _submitApplication(context),
        label: const Text('Оформить заявку'),
        icon: const Icon(Icons.send),
        backgroundColor: const Color(0xFF1C3D5A),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Delivery Screen Placeholder
class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Реализуйте логику оформления доставки здесь
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформить доставку'),
        backgroundColor: const Color(0xFF1C3D5A),
      ),
      body: Center(
        child: const Text(
          'Тут будет экран оформления доставки.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

/// About Us Screen
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('О нас'),
        backgroundColor: const Color(0xFF1C3D5A),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? const Color(0xFF0A1929) : Colors.white,
              isDark ? const Color(0xFF1C3D5A) : Colors.blue.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'ISraelDelCargo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Москва, Олимпийский просп., 22',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text(
                'Рабочий WhatsApp: +7 (991) 499-24-20',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text(
                'Рабочий Telegram: @israeldelcargo',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  const phoneNumber = '79914992420';
                  const url = 'https://wa.me/$phoneNumber';
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Не удалось открыть WhatsApp')),
                    );
                  }
                },
                icon: const Icon(Icons.chat),
                label: const Text('Связаться через WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C3D5A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
