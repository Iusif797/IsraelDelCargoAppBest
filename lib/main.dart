import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// Добавляем импорты для flutter_map и latlong2
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

/// Модель пользователя
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

/// Модель элемента корзины
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

/// Модель отправления
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

/// Синглтон класс DatabaseHelper
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

  // Создание таблиц
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

  // Обновление базы данных для добавления новых полей
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Добавьте логику обновления, если необходимо
    }
  }

  // Пользователь CRUD
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

  // Отправление CRUD
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

  // Корзина CRUD
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

  // Новый метод для обновления количества товара в корзине
  Future<int> updateCartItemQuantity(String trackingNumber, int quantity) async {
    Database db = await database;
    return await db.update(
      'cart',
      {'quantity': quantity},
      where: 'trackingNumber = ?',
      whereArgs: [trackingNumber],
    );
  }
}

/// ==================== State Management ====================

/// AppState для управления темой, пользователем и корзиной
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
    final existingItemIndex =
        _cartItems.indexWhere((item) => item.serviceName == serviceName);

    if (existingItemIndex == -1) {
      final newItem = CartItem(
        serviceName: serviceName,
        quantity: 1,
        price: price,
        trackingNumber: trackingNumber,
      );
      _cartItems.add(newItem);
      DatabaseHelper.instance.addToCart(newItem);
    } else {
      _cartItems[existingItemIndex].quantity++;
      DatabaseHelper.instance.updateCartItemQuantity(
          _cartItems[existingItemIndex].trackingNumber,
          _cartItems[existingItemIndex].quantity);
    }
    notifyListeners();
  }

  void removeFromCart(String serviceName) {
    final existingItemIndex =
        _cartItems.indexWhere((item) => item.serviceName == serviceName);
    if (existingItemIndex != -1) {
      _cartItems.removeAt(existingItemIndex);
      DatabaseHelper.instance.clearCart();
      for (var item in _cartItems) {
        DatabaseHelper.instance.addToCart(item);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    DatabaseHelper.instance.clearCart();
    notifyListeners();
  }

  // Новый метод для увеличения количества товара
  Future<void> increaseQuantity(CartItem item) async {
    item.quantity++;
    await DatabaseHelper.instance.updateCartItemQuantity(
        item.trackingNumber, item.quantity);
    notifyListeners();
  }

  // Новый метод для уменьшения количества товара
  Future<void> decreaseQuantity(CartItem item) async {
    if (item.quantity > 1) {
      item.quantity--;
      await DatabaseHelper.instance.updateCartItemQuantity(
          item.trackingNumber, item.quantity);
    } else {
      removeFromCart(item.serviceName);
    }
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

  // Новый метод для загрузки корзины из базы данных
  Future<void> loadCart() async {
    _cartItems.clear();
    _cartItems.addAll(await DatabaseHelper.instance.getCartItems());
    notifyListeners();
  }
}

/// ==================== Application Widgets ====================

/// Главный виджет приложения
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
          headlineLarge: TextStyle(
              color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(
              color: Colors.black, fontSize:  20.0, fontWeight: FontWeight.bold),
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
          headlineLarge: TextStyle(
              color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(
              color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
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

/// Обертка для определения, какой экран показать в зависимости от аутентификации
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
            appState.tryAutoLogin().then((_) {
              appState.loadCart();
            });
          }
        });
      } else {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.tryAutoLogin().then((_) {
          appState.loadCart();
        });
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
      await appState.loadCart();
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
      await appState.loadCart();
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
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade200,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style:
                            TextStyle(color: isDark ? Colors.white : Colors.black),
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
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade200,
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style:
                            TextStyle(color: isDark ? Colors.white : Colors.black),
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
                          style:
                              TextStyle(color: isDark ? Colors.white : Colors.blue),
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
                        style:
                            TextStyle(color: isDark ? Colors.white : Colors.blue),
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
                      // Поле имени
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Имя',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade200,
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style:
                            TextStyle(color: isDark ? Colors.white : Colors.black),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите имя';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Поле Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade200,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style:
                            TextStyle(color: isDark ? Colors.white : Colors.black),
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
                      // Поле телефона
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Номер телефона',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade200,
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        style:
                            TextStyle(color: isDark ? Colors.white : Colors.black),
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
                      // Поле адреса
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Адрес',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade200,
                          prefixIcon: const Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style:
                            TextStyle(color: isDark ? Colors.white : Colors.black),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите адрес';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Поле пароля
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade200,
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style:
                            TextStyle(color: isDark ? Colors.white : Colors.black),
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
            // Drawer Header
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
            // Пункт "Карта"
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Карта'),
              onTap: () {
                Navigator.pop(context); // Закрыть меню
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              },
            ),
            // Пункт "О нас"
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('О нас'),
              onTap: () {
                Navigator.pop(context); // Закрыть меню
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

/// Карта Screen
class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта'),
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
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(55.7249, 37.6443), // Координаты офиса
            zoom: 16.0,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.israel_del_cargo_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(55.7249, 37.6443),
                  builder: (ctx) => const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
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
  final _lengthController = TextEditingController(); // Новый контроллер
  final _widthController = TextEditingController(); // Новый контроллер

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
      BuildContext context, String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
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
      double weight = double.parse(_weightController.text.trim());
      double length = double.parse(_lengthController.text.trim());
      double width = double.parse(_widthController.text.trim());

      // Пример формулы расчета: базовая стоимость за кг + стоимость за объем
      double deliveryCost = (weight * 500.0) + (length * width * 10.0);

      final appState = Provider.of<AppState>(context, listen: false);
      double cartTotal = appState.cartItems.fold(0.0,
          (sum, item) => sum + item.price * item.quantity);

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

  void _showApplicationForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ApplicationFormDialog();
      },
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose(); // Освобождаем контроллер
    _widthController.dispose(); // Освобождаем контроллер
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
            // Вертикальные кнопки
            _buildMainButton(
              context,
              'Оформить заявку',
              Icons.assignment,
              () => _showApplicationForm(context),
            ),
            _buildMainButton(
              context,
              'Отследить',
              Icons.track_changes,
              () => _navigateTo(context, const TrackingTab()),
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
              color:
                  isDark ? Colors.white.withOpacity(0.1) : Colors.blue.shade50,
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
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Страна отправления и назначения
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Страна отправления',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.shade200,
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
                                : Colors.grey.shade200,
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
                  // Поле ввода веса
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'Вес (кг)',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.shade200,
                      prefixIcon: const Icon(Icons.line_weight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
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
                  const SizedBox(height: 16),
                  // Поле ввода длины
                  TextFormField(
                    controller: _lengthController,
                    decoration: InputDecoration(
                      labelText: 'Длина (см)',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.shade200,
                      prefixIcon: const Icon(Icons.straighten),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите длину';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Пожалуйста, введите корректную длину';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Поле ввода ширины
                  TextFormField(
                    controller: _widthController,
                    decoration: InputDecoration(
                      labelText: 'Ширина (см)',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.shade200,
                      prefixIcon: const Icon(Icons.straighten),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите ширину';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Пожалуйста, введите корректную ширину';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Кнопка "Рассчитать"
                  ElevatedButton(
                    onPressed: () => _calculateTotal(context),
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
                      'Рассчитать',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
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

  void _showApplicationForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ApplicationFormDialog();
      },
    );
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
                  subtitle: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          appState.decreaseQuantity(item);
                        },
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          appState.increaseQuantity(item);
                        },
                      ),
                    ],
                  ),
                  trailing: Text('${item.price * item.quantity} ₽'),
                  onLongPress: () {
                    appState.removeFromCart(item.serviceName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('${item.serviceName} удалено из корзины')),
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
      floatingActionButton: appState.cartItems.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showApplicationForm(context),
              label: const Text('Оформить заявку'),
              icon: const Icon(Icons.assignment),
              backgroundColor: const Color(0xFF1C3D5A),
            ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Application Form Dialog
class ApplicationFormDialog extends StatefulWidget {
  @override
  _ApplicationFormDialogState createState() => _ApplicationFormDialogState();
}

class _ApplicationFormDialogState extends State<ApplicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProduct;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _originCountry;
  String? _destinationCountry;
  final _descriptionController = TextEditingController();

  final List<String> countries = [
    'Россия',
    'Израиль',
    'Грузия',
    'Казахстан',
  ];

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.currentUser != null) {
      _nameController.text = appState.currentUser!.name;
      _phoneController.text = appState.currentUser!.phone;
      _emailController.text = appState.currentUser!.email;
    }
  }

  void _sendApplication(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      double total = appState.cartItems.fold(
        0.0,
        (sum, item) => sum + item.price * item.quantity,
      );

      final message = Uri.encodeComponent(
        'Здравствуйте!\n'
        'Я хочу оформить заявку на услугу: $_selectedProduct\n'
        'Имя: ${_nameController.text}\n'
        'Телефон: ${_phoneController.text}\n'
        'Email: ${_emailController.text}\n'
        'Страна отправления: $_originCountry\n'
        'Страна прибытия: $_destinationCountry\n'
        'Описание: ${_descriptionController.text}\n'
        'Итого к оплате: $total ₽',
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
  }

  void _makePayment(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    double total = appState.cartItems.fold(
      0.0,
      (sum, item) => sum + item.price * item.quantity,
    );

    final url =
        'https://www.tbank.ru/rm/rabaev.natan1/qBQMJ15331/?amount=$total';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку для оплаты')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final products = appState.cartItems.isNotEmpty
        ? appState.cartItems.map((item) => item.serviceName).toList()
        : [
            'Доставка документов',
            'Религиозные атрибуты (книги, иудайка)',
            'Одежда, обувь, головные уборы',
            'Кошерное питание',
            'Товары из Duty Free',
            'Маленькие посылки (до 1кг)',
          ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Оформление заявки'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Выбор товара
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Выбор товара',
                  filled: true,
                  fillColor:
                      isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: products
                    .map((product) => DropdownMenuItem(
                          value: product,
                          child: Text(product),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProduct = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите товар';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Поле имени
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Поле телефона
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер телефона';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Поле Email
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
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !value.contains('@')) {
                    return 'Введите корректный email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Страна отправления
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Страна отправления',
                  filled: true,
                  fillColor:
                      isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: countries
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _originCountry = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите страну отправления';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Страна прибытия
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Страна прибытия',
                  filled: true,
                  fillColor:
                      isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: countries
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _destinationCountry = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите страну прибытия';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  filled: true,
                  fillColor:
                      isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _makePayment(context),
          child: const Text('Оплатить'),
        ),
        ElevatedButton(
          onPressed: () => _sendApplication(context),
          child: const Text('Отправить заявку'),
        ),
      ],
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
        width: double.infinity,
        height: double.infinity,
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                'ISRAELDELCARGO',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'ISRAELDELCARGO - ваш надежный партнер в доставке товаров и документов между Россией, Израилем, Грузией и Казахстаном. Мы предлагаем быстрые и надежные услуги доставки для ваших нужд.',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title:
                            const Text('Москва, Олимпийский просп., 22'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text(
                            'Рабочий WhatsApp: +7 (991) 499-24-20'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.telegram),
                        title:
                            const Text('Рабочий Telegram: @israeldelcargo'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          const phoneNumber = '79914992420';
                          final url = 'https://wa.me/$phoneNumber';
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Не удалось открыть WhatsApp')),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _logout(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _editProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: const Color(0xFF1C3D5A),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editProfile(context);
              } else if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Редактировать профиль'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Выйти'),
              ),
            ],
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Text('Пользователь не найден'),
            )
          : Container(
              width: double.infinity,
              height: double.infinity,
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: user.avatarPath != null
                        ? FileImage(File(user.avatarPath!)) as ImageProvider
                        : const AssetImage('assets/images/avatar.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.phone,
                    style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.address,
                    style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Edit Profile Screen
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // New field
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // New field
  final _addressController = TextEditingController(); // New field
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _addressController.text = user.address;
      _avatarPath = user.avatarPath;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    await appState.updateUserProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      avatarPath: _avatarPath,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль обновлен')),
    );
    Navigator.pop(context);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _avatarPath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _avatarPath != null
                      ? FileImage(File(_avatarPath!)) as ImageProvider
                      : const AssetImage('assets/images/avatar.png'),
                  child: const Icon(Icons.camera_alt, size: 30, color: Colors.white),
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
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.shade200,
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style:
                          TextStyle(color: isDark ? Colors.white : Colors.black),
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
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.shade200,
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style:
                          TextStyle(color: isDark ? Colors.white : Colors.black),
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
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.shade200,
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      style:
                          TextStyle(color: isDark ? Colors.white : Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите номер телефона';
                        }
                        if (!RegExp(r'^\+?\d{7,15}$')
                            .hasMatch(value)) {
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
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.shade200,
                        prefixIcon: const Icon(Icons.home),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style:
                          TextStyle(color: isDark ? Colors.white : Colors.black),
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
