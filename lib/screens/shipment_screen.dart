// lib/screens/shipment_screen.dart
import 'package:flutter/material.dart';
import 'package:israeldelcargoapplication/database_helper.dart';
import 'package:uuid/uuid.dart'; // Импортируем пакет uuid

class ShipmentScreen extends StatefulWidget {
  const ShipmentScreen({Key? key}) : super(key: key);

  @override
  _ShipmentScreenState createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends State<ShipmentScreen> {
  final List<String> products = [
    'Документы',
    'Религиозные атрибуты',
    'Брендированная одежда',
    'Питание',
    'Duty Free',
  ];

  String? selectedProduct;

  // Убираем контроллер для номера отслеживания, так как он теперь генерируется автоматически
  // final TextEditingController _trackingNumberController = TextEditingController();

  Future<void> _saveShipment() async {
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите тип отправления')),
      );
      return;
    }

    // Генерируем уникальный номер отслеживания с учетом типа отправления
    var uuid = Uuid();
    String trackingNumber = '${selectedProduct!.substring(0, 3).toUpperCase()}-${uuid.v4().substring(0, 5).toUpperCase()}'; // Пример: DOC-ABCDE

    // Сохраняем отправление в базе данных
    await DatabaseHelper().insertShipment(
      trackingNumber,
      'Отправление создано',
      selectedProduct!,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Отправление создано успешно. Номер: $trackingNumber')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    // _trackingNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Обновленный градиентный фон, покрывающий весь экран
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформить новое отправление'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Выберите тип отправления:',
              style: TextStyle(fontSize: 18.0, color: Colors.white),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: RadioListTile<String>(
                      title: Text(products[index]),
                      value: products[index],
                      groupValue: selectedProduct,
                      onChanged: (value) {
                        setState(() {
                          selectedProduct = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _saveShipment,
              icon: const Icon(Icons.save),
              label: const Text('Создать отправление'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE100FF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                textStyle: const TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
