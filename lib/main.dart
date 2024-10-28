import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

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

// AppState to manage theme, user, and cart
class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  List<CartItem> _cartItems = [];
  User? _currentUser;

  ThemeMode get themeMode => _themeMode;
  List<CartItem> get cartItems => _cartItems;
  User? get currentUser => _currentUser;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void addToCart(String serviceName, double price) {
    final existingItem = _cartItems.firstWhere(
      (item) => item.serviceName == serviceName,
      orElse: () => CartItem(serviceName: serviceName, quantity: 0, price: price),
    );

    if (existingItem.quantity == 0) {
      _cartItems.add(CartItem(serviceName: serviceName, quantity: 1, price: price));
    } else {
      existingItem.quantity++;
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
    User? user = await DatabaseHelper.instance.getUser(email, password);
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
      User? user = await DatabaseHelper.instance.getUserById(userId);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }
  }
}

// User model
class User {
  final int? id;
  final String email;
  final String password;

  User({this.id, required this.email, required this.password});

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email, 'password': password};
  }
}

// CartItem model
class CartItem {
  final String serviceName;
  int quantity;
  final double price;

  CartItem({required this.serviceName, this.quantity = 1, required this.price});
}

// Shipment model
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

// DatabaseHelper singleton class
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
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        price REAL
      )
    ''');
  }

  // User CRUD
  Future<int> addUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<User?> getUser(String email, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      return User(
        id: maps.first['id'],
        email: maps.first['email'],
        password: maps.first['password'],
      );
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User(
        id: maps.first['id'],
        email: maps.first['email'],
        password: maps.first['password'],
      );
    }
    return null;
  }

  // Shipment CRUD
  Future<int> addShipment(Shipment shipment) async {
    Database db = await database;
    return await db.insert('shipments', shipment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
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
      );
    });
  }

  Future<int> clearCart() async {
    Database db = await database;
    return await db.delete('cart');
  }
}

// Main Application Widget
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
              color: Colors.black, fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C3D5A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            padding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
            padding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// Wrapper to decide which screen to show based on authentication
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return FutureBuilder(
      future: appState.tryAutoLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          if (appState.currentUser != null) {
            return const MainPage();
          } else {
            return const LoginScreen();
          }
        }
      },
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

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
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 16),
                const Text(
                  'ISRAELDELCARGO',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
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
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white,
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
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
                        child: const Text(
                          'Нет учетной записи? Зарегистрируйтесь',
                          style: TextStyle(color: Colors.white),
                        ),
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

// Signup Screen
class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    User newUser = User(
      email: _emailController.text.trim(),
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
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 16),
                const Text(
                  'ISRAELDELCARGO',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
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
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white,
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
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

// Main Page with Bottom Navigation
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeContent(),
    ProfileScreen(),
    TrackingTab(),
    CartScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
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
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Трекеры',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Корзина',
          ),
        ],
      ),
    );
  }
}

// Home Content with Vertical Buttons and Services
class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

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
      MaterialPageRoute(builder: (context) => screen),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ISRAELDELCARGO',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Vertical buttons
                _buildMainButton(
                  context,
                  'Рассчитать',
                  Icons.calculate,
                  const CalculateScreen(),
                ),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      ),
    );
  }
}

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Widget _buildProfileItem(String title, String content, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle:
            Text(content, style: const TextStyle(color: Colors.white)),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.blueAccent),
          onPressed: () {
            // Handle profile edit
            // Можно добавить функционал редактирования профиля
          },
        ),
      ),
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF1C3D5A),
                  child: Text(
                    appState.currentUser!.email[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileItem('Email', appState.currentUser!.email, context),
                // Можно добавить дополнительные поля профиля
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle Edit Profile
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Редактировать профиль'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C3D5A),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final appState = Provider.of<AppState>(context, listen: false);
                    appState.logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Выйти'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Calculate Screen
class CalculateScreen extends StatefulWidget {
  const CalculateScreen({Key? key}) : super(key: key);

  @override
  _CalculateScreenState createState() => _CalculateScreenState();
}

class _CalculateScreenState extends State<CalculateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deliveriesController = TextEditingController();
  double _totalCost = 0.0;

  void _calculateCost() {
    if (_formKey.currentState!.validate()) {
      int deliveries = int.parse(_deliveriesController.text);

      // Each delivery costs 5000 rubles
      setState(() {
        _totalCost = deliveries * 5000.0;
      });
    }
  }

  @override
  void dispose() {
    _deliveriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рассчитать стоимость'),
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _deliveriesController,
                  decoration: const InputDecoration(
                    labelText: 'Количество доставок',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите количество доставок';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 1) {
                      return 'Пожалуйста, введите корректное число';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _calculateCost,
                  child: const Text('Рассчитать'),
                ),
                const SizedBox(height: 24),
                if (_totalCost > 0)
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
                            'Расчетная стоимость:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_totalCost.toStringAsFixed(2)} руб.',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Delivery Screen
class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({Key? key}) : super(key: key);

  @override
  _DeliveryScreenState createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _estimatedDeliveryController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitDeliveryRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не авторизован')),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    // Generate unique tracking number
    String trackingNumber = _generateTrackingNumber();

    Shipment shipment = Shipment(
      trackingNumber: trackingNumber,
      status: 'Создано',
      origin: _originController.text.trim(),
      destination: _destinationController.text.trim(),
      estimatedDelivery: _estimatedDeliveryController.text.trim(),
      userId: appState.currentUser!.id!,
    );

    int shipmentId = await DatabaseHelper.instance.addShipment(shipment);

    if (shipmentId > 0) {
      // Send to Telegram
      bool telegramSuccess = await _sendTelegramMessage(shipment);
      if (telegramSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Доставка успешно оформлена')),
        );
        appState.clearCart();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при отправке в Telegram')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при оформлении доставки')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  String _generateTrackingNumber() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String result = '';
    for (int i = 0; i < 10; i++) {
      result += chars[Random().nextInt(chars.length)];
    }
    return result;
  }

  Future<bool> _sendTelegramMessage(Shipment shipment) async {
    final String botToken = '<YOUR_BOT_TOKEN>'; // Замените на токен вашего бота
    final String chatId = '<YOUR_GROUP_CHAT_ID>'; // Замените на chat_id вашей группы

    final Uri url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
    final response = await http.post(
      url,
      body: {
        'chat_id': chatId,
        'text': 'Новая заявка на доставку:\n'
            'Номер отправления: ${shipment.trackingNumber}\n'
            'Откуда: ${shipment.origin}\n'
            'Куда: ${shipment.destination}\n'
            'Ожидаемая дата доставки: ${shipment.estimatedDelivery}',
      },
    );

    return response.statusCode == 200;
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _estimatedDeliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформить доставку'),
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
          child: _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _originController,
                        decoration: const InputDecoration(
                          labelText: 'Откуда',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите место отправления';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          labelText: 'Куда',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите место назначения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _estimatedDeliveryController,
                        decoration: const InputDecoration(
                          labelText: 'Ожидаемая дата доставки',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите ожидаемую дату доставки';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitDeliveryRequest,
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
                          'Оформить доставку',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// TrackingTab
class TrackingTab extends StatelessWidget {
  const TrackingTab({Key? key}) : super(key: key);

  Future<List<Shipment>> _fetchShipments(AppState appState) async {
    if (appState.currentUser == null) return [];
    return await DatabaseHelper.instance.getShipmentsByUser(appState.currentUser!.id!);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Трекеры'),
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
        child: FutureBuilder<List<Shipment>>(
          future: _fetchShipments(appState),
          builder:
              (BuildContext context, AsyncSnapshot<List<Shipment>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else {
              if (snapshot.hasError) {
                return const Center(child: Text('Ошибка загрузки трекеров'));
              } else {
                final shipments = snapshot.data!;
                if (shipments.isEmpty) {
                  return const Center(
                      child: Text('У вас нет трекеров. Оформите доставку!'));
                }
                return ListView.builder(
                  itemCount: shipments.length,
                  itemBuilder: (context, index) {
                    final shipment = shipments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ListTile(
                        title: Text(
                          'Трекер: ${shipment.trackingNumber}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Статус: ${shipment.status}',
                                style: const TextStyle(color: Colors.white)),
                            Text('Откуда: ${shipment.origin}',
                                style: const TextStyle(color: Colors.white)),
                            Text('Куда: ${shipment.destination}',
                                style: const TextStyle(color: Colors.white)),
                            Text('Ожидаемая доставка: ${shipment.estimatedDelivery}',
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            }
          },
        ),
      ),
    );
  }
}

// Cart Screen
class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  void _navigateToOrderForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double totalPrice = 0.0;
    for (var item in appState.cartItems) {
      totalPrice += item.price * item.quantity;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
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
        child: appState.cartItems.isEmpty
            ? const Center(child: Text('Корзина пуста'))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: appState.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = appState.cartItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.blue.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: ListTile(
                            title: Text(
                              item.serviceName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            subtitle: Text(
                              'Цена: ${item.price} ₽',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                            onLongPress: () {
                              appState.removeFromCart(item.serviceName);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${item.serviceName} удалено из корзины')),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Итого:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$totalPrice ₽',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _navigateToOrderForm(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1C3D5A),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  'Оформить заказ',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  appState.clearCart();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Корзина очищена')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  'Очистить корзину',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
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

// Order Form Screen
class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({Key? key}) : super(key: key);

  @override
  _OrderFormScreenState createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _estimatedDeliveryController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не авторизован')),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    // Generate unique tracking number
    String trackingNumber = _generateTrackingNumber();

    // Gather cart items
    String cartItems = appState.cartItems
        .map((item) => '${item.serviceName} x${item.quantity}')
        .join(', ');

    // Create Shipment
    Shipment shipment = Shipment(
      trackingNumber: trackingNumber,
      status: 'Создано',
      origin: _originController.text.trim(),
      destination: _destinationController.text.trim(),
      estimatedDelivery: _estimatedDeliveryController.text.trim(),
      userId: appState.currentUser!.id!,
    );

    // Add Shipment to Database
    int shipmentId = await DatabaseHelper.instance.addShipment(shipment);

    if (shipmentId > 0) {
      // Prepare message
      String message = '''
Новая заявка на заказ:
Имя: ${_nameController.text.trim()}
Телефон: ${_phoneController.text.trim()}
Email: ${_emailController.text.trim()}
Описание: ${_descriptionController.text.trim()}
Откуда: ${shipment.origin}
Куда: ${shipment.destination}
Ожидаемая доставка: ${shipment.estimatedDelivery}
Услуги: $cartItems
Номер трекера: $trackingNumber
''';

      // Send to Telegram
      bool telegramSuccess = await _sendTelegramMessage(message);

      if (telegramSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ успешно оформлен')),
        );
        appState.clearCart();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при отправке в Telegram')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при оформлении заказа')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  String _generateTrackingNumber() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String result = '';
    for (int i = 0; i < 10; i++) {
      result += chars[Random().nextInt(chars.length)];
    }
    return result;
  }

  Future<bool> _sendTelegramMessage(String message) async {
    final String botToken = '<YOUR_BOT_TOKEN>'; // Замените на токен вашего бота
    final String chatId = '<YOUR_GROUP_CHAT_ID>'; // Замените на chat_id вашей группы

    final Uri url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
    final response = await http.post(
      url,
      body: {
        'chat_id': chatId,
        'text': message,
      },
    );

    return response.statusCode == 200;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _estimatedDeliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформить заказ'),
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
          child: _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // User Information
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите имя';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Номер телефона',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
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
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
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
                      // Shipment Details
                      TextFormField(
                        controller: _originController,
                        decoration: const InputDecoration(
                          labelText: 'Откуда',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите место отправления';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          labelText: 'Куда',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите место назначения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _estimatedDeliveryController,
                        decoration: const InputDecoration(
                          labelText: 'Ожидаемая дата доставки',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите ожидаемую дату доставки';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите описание';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitOrder,
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
                          'Отправить заказ',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
