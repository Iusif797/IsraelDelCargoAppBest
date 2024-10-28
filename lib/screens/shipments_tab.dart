// lib/screens/shipments_tab.dart
import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../theme_extensions.dart';

class ShipmentsTab extends StatefulWidget {
  const ShipmentsTab({Key? key}) : super(key: key);

  @override
  _ShipmentsTabState createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends State<ShipmentsTab> {
  late Future<List<Map<String, dynamic>>> _shipmentsFuture;

  @override
  void initState() {
    super.initState();
    _shipmentsFuture = DatabaseHelper().getAllShipments();
  }

  @override
  Widget build(BuildContext context) {
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои отправления'),
        backgroundColor: const Color(0xFF0F2027),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradientTheme.backgroundGradient,
        ),
        padding: const EdgeInsets.all(24.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _shipmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Нет отправлений'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var shipment = snapshot.data![index];
                  return Card(
                    color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    elevation: 8.0,
                    child: ListTile(
                      title: Text(
                        'Отслеживание: ${shipment['trackingNumber']}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      subtitle: Text(
                        'Статус: ${shipment['status']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          bool updated = await DatabaseHelper().updateShipmentStatus(shipment['trackingNumber'], 'В пути');
                          if (updated) {
                            setState(() {
                              _shipmentsFuture = DatabaseHelper().getAllShipments();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Статус обновлен')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ошибка при обновлении статуса')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          elevation: 5.0,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text(
                          'Обновить статус',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
