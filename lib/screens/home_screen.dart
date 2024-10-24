// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'shipments_tab.dart';
import 'tracking_tab.dart';
import 'profile_tab.dart';
import 'shipment_screen.dart';
import 'edit_profile_screen.dart';
import 'shipment_history_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String email;

  const HomeScreen({Key? key, required this.userName, required this.email}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeTab(
        userName: widget.userName,
        onTabChange: _onItemTapped,
      ),
      const ShipmentsTab(),
      const TrackingTab(),
      ProfileTab(
        userName: widget.userName,
        email: widget.email,
        onEditProfile: _navigateToEditProfile,
        onViewHistory: _navigateToShipmentHistory,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Метод для перехода на экран редактирования профиля
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userName: widget.userName,
          email: widget.email,
        ),
      ),
    );
  }

  // Метод для перехода на экран истории отправлений
  void _navigateToShipmentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShipmentHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ISRAELDELCARGO',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F2027),
        centerTitle: true,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Отправления',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Отслеживание',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFE100FF),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8.0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Переход на экран создания нового отправления
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ShipmentScreen()),
          );
        },
        backgroundColor: const Color(0xFFE100FF),
        child: const Icon(Icons.add),
      ),
    );
  }
}
