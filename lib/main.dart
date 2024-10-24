// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'screens/tracking_tab.dart';
import 'screens/shipments_tab.dart';
import 'screens/home_screen.dart';
import 'screens/profile_tab.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/shipment_history_screen.dart';
import 'screens/shipment_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const IsraelDelCargoApp(),
    ),
  );
}

class IsraelDelCargoApp extends StatelessWidget {
  const IsraelDelCargoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'ISRAELDELCARGO',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpScreen(),
        '/tracking': (context) => const TrackingTab(),
        '/shipments': (context) => const ShipmentsTab(),
        '/home': (context) => HomeScreen(
              userName: 'User', // Замените на актуальные данные
              email: 'user@example.com', // Замените на актуальные данные
            ),
        '/profile': (context) => ProfileTab(
              userName: 'User', // Замените на актуальные данные
              email: 'user@example.com', // Замените на актуальные данные
              onEditProfile: () {
                Navigator.pushNamed(context, '/editProfile');
              },
              onViewHistory: () {
                Navigator.pushNamed(context, '/shipmentHistory');
              },
            ),
        '/editProfile': (context) => const EditProfileScreen(
              userName: 'User', // Замените на актуальные данные
              email: 'user@example.com', // Замените на актуальные данные
            ),
        '/shipmentHistory': (context) => const ShipmentHistoryScreen(),
        // Добавьте другие маршруты здесь
      },
    );
  }
}
