// lib/screens/shipment_history_screen.dart
import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../theme_extensions.dart';

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

  @override
  Widget build(BuildContext context) {
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История отправлений'),
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
              return const Center(child: Text('Нет отправлений в истории'));
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Статус: ${shipment['status']}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                          ),
                          Text(
                            'Откуда: ${shipment['origin']}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                          ),
                          Text(
                            'Куда: ${shipment['destination']}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                          ),
                          Text(
                            'Ожидаемая доставка: ${shipment['estimatedDelivery']}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                          ),
                        ],
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
