// lib/screens/home_tab.dart
import 'package:flutter/material.dart';
import 'package:israeldelcargoapplication/screens/shipment_screen.dart';

class HomeTab extends StatelessWidget {
  final String userName;
  final Function(int) onTabChange;

  const HomeTab({
    Key? key,
    required this.userName,
    required this.onTabChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Здравствуйте, $userName!',
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Добро пожаловать в ISRAELDELCARGO. Мы рады видеть вас!',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24.0),
            Card(
              color: Colors.white.withOpacity(0.1),
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.white),
                title: const Text(
                  'Оформить новое отправление',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onTap: () {
                  // Переход на экран оформления отправления
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShipmentScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            Card(
              color: Colors.white.withOpacity(0.1),
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: ListTile(
                leading: const Icon(Icons.track_changes, color: Colors.white),
                title: const Text(
                  'Отследить посылку',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onTap: () {
                  // Переход на вкладку Отслеживание
                  onTabChange(2);
                },
              ),
            ),
            const SizedBox(height: 16.0),
            // Добавьте другие карточки или элементы по необходимости
          ],
        ),
      ),
    );
  }
}
