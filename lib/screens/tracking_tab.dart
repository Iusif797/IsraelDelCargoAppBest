// lib/screens/tracking_tab.dart
import 'package:flutter/material.dart';
import 'package:israeldelcargoapplication/database_helper.dart';
import 'package:israeldelcargoapplication/widgets/custom_button.dart'; // Добавляем импорт CustomButton

class TrackingTab extends StatefulWidget {
  const TrackingTab({Key? key}) : super(key: key);

  @override
  _TrackingTabState createState() => _TrackingTabState();
}

class _TrackingTabState extends State<TrackingTab> {
  final TextEditingController _trackingController = TextEditingController();
  String? _status;
  String? _productType;
  bool _isLoading = false;

  Future<void> _trackShipment() async {
    String trackingNumber = _trackingController.text.trim();
    if (trackingNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите трек-номер')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _status = null;
      _productType = null;
    });

    var shipment = await DatabaseHelper().getShipment(trackingNumber);
    if (shipment != null) {
      setState(() {
        _status = shipment['status'];
        _productType = shipment['productType'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _status = null;
        _productType = null;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отправление с таким трек-номером не найдено')),
      );
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

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
          children: [
            const SizedBox(height: 40.0),
            const Text(
              'Отслеживание посылки',
              style: TextStyle(
                fontSize: 24.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24.0),
            TextField(
              controller: _trackingController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.local_shipping, color: Colors.white),
                labelText: 'Трек-номер',
                labelStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16.0),
            CustomButton(
              text: 'Отслеживать',
              onPressed: _trackShipment,
              gradientColors: [Color(0xFFe96443), Color(0xFF904e95)],
            ),
            const SizedBox(height: 24.0),
            if (_status != null && _productType != null)
              Card(
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  leading: const Icon(Icons.info, color: Colors.white),
                  title: Text(
                    'Статус: $_status',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Тип отправления: $_productType',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
