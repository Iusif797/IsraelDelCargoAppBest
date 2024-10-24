// lib/screens/shipment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:israeldelcargoapplication/database_helper.dart';

class ShipmentHistoryScreen extends StatefulWidget {
  const ShipmentHistoryScreen({Key? key}) : super(key: key);

  @override
  _ShipmentHistoryScreenState createState() => _ShipmentHistoryScreenState();
}

class _ShipmentHistoryScreenState extends State<ShipmentHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _shipmentsFuture;

  @override
  void initState() {
    super.initState();
    _shipmentsFuture = DatabaseHelper().getAllShipments();
  }

  Future<void> _refreshShipments() async {
    setState(() {
      _shipmentsFuture = DatabaseHelper().getAllShipments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История отправлений'),
        backgroundColor: const Color(0xFF0F2027),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _shipmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет отправлений'));
          } else {
            return RefreshIndicator(
              onRefresh: _refreshShipments,
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var shipment = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    color: Colors.white.withOpacity(0.1),
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping, color: Colors.white),
                      title: Text(
                        'Номер: ${shipment['trackingNumber']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Статус: ${shipment['status']}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.info, color: Colors.white),
                      onTap: () {
                        // Здесь можно добавить логику для отображения деталей отправления
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Отправление ${shipment['trackingNumber']}'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Тип отправления: ${shipment['productType']}'),
                                Text('Статус: ${shipment['status']}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Закрыть'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
