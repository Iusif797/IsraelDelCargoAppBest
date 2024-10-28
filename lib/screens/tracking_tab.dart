// lib/screens/tracking_tab.dart
import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../theme_extensions.dart';

class TrackingTab extends StatefulWidget {
  const TrackingTab({Key? key}) : super(key: key);

  @override
  _TrackingTabState createState() => _TrackingTabState();
}

class _TrackingTabState extends State<TrackingTab> {
  final _formKey = GlobalKey<FormState>();
  String trackingNumber = '';
  bool isLoading = false;
  Map<String, dynamic>? shipmentInfo;

  @override
  Widget build(BuildContext context) {
    final gradientTheme = Theme.of(context).extension<GradientThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отслеживание отправлений'),
        backgroundColor: const Color(0xFF0F2027),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradientTheme.backgroundGradient,
        ),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(
                Icons.track_changes,
                size: 100.0,
                color: Colors.white,
              ),
              const SizedBox(height: 24.0),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.confirmation_number),
                        labelText: 'Номер отправления',
                        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      onChanged: (value) {
                        trackingNumber = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите номер отправления';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  isLoading = true;
                                  shipmentInfo = null;
                                });
                                // Получаем информацию об отправлении из базы данных
                                var shipment = await DatabaseHelper().getShipment(trackingNumber);
                                setState(() {
                                  isLoading = false;
                                  shipmentInfo = shipment;
                                });
                                if (shipment == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Отправление не найдено')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              elevation: 5.0,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text(
                              'Отслеживать',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              shipmentInfo != null
                  ? Card(
                      color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.85),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      elevation: 8.0,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Статус: ${shipmentInfo!['status']}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Откуда: ${shipmentInfo!['origin']}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Куда: ${shipmentInfo!['destination']}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Ожидаемая доставка: ${shipmentInfo!['estimatedDelivery']}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
