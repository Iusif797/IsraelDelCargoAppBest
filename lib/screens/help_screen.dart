import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  Widget buildHelpItem({required IconData icon, required String title, required String description}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.white.withOpacity(0.1),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(description, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощь'),
        backgroundColor: const Color(0xFF0F2027),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          children: [
            buildHelpItem(
              icon: Icons.info_outline,
              title: 'О приложении',
              description: 'ISRAELDELCARGO - ваше надежное решение для доставки.',
            ),
            buildHelpItem(
              icon: Icons.email,
              title: 'Связаться с поддержкой',
              description: 'Email: support@israeldelcargo.com',
            ),
            buildHelpItem(
              icon: Icons.phone,
              title: 'Позвонить нам',
              description: 'Телефон: +1 (234) 567-890',
            ),
          ],
        ),
      ),
    );
  }
}
