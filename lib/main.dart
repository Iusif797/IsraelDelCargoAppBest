import 'package:flutter/material.dart';
import 'package:israeldelcargoapplication/screens/welcome_screen.dart';
import 'package:israeldelcargoapplication/screens/login_screen.dart';
import 'package:israeldelcargoapplication/screens/registration_screen.dart';

void main() {
  runApp(const IsraelDelCargoApp());
}

class IsraelDelCargoApp extends StatelessWidget {
  const IsraelDelCargoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISRAELDELCARGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationScreen(),
        // Мы удалили маршрут '/home' из-за обязательного параметра 'userName'
      },
    );
  }
}
