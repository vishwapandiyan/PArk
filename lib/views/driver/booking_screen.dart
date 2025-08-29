import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _destinationCtrl = TextEditingController();
  String _durationType = 'hour';
  int _durationValue = 1;
  String _carModel = 'Sedan';

  @override
  void dispose() {
    _destinationCtrl.dispose();
    super.dispose();
  }

  void _search() {
    Navigator.of(context).pushNamed('/slots', arguments: {
      'destination': _destinationCtrl.text,
      'durationType': _durationType,
      'durationValue': _durationValue,
      'carModel': _carModel,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Parking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _destinationCtrl,
              decoration: const InputDecoration(
                labelText: 'Destination address',
                hintText: 'Search or paste address',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _carModel,
              items: const [
                DropdownMenuItem(value: 'Sedan', child: Text('Sedan')),
                DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                DropdownMenuItem(value: 'Hatchback', child: Text('Hatchback')),
              ],
              onChanged: (v) => setState(() => _carModel = v ?? 'Sedan'),
              decoration: const InputDecoration(labelText: 'Car model'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _durationType,
                    items: const [
                      DropdownMenuItem(value: 'hour', child: Text('Hour')),
                      DropdownMenuItem(value: 'day', child: Text('Day')),
                      DropdownMenuItem(value: 'month', child: Text('Month')),
                      DropdownMenuItem(value: 'year', child: Text('Year')),
                    ],
                    onChanged: (v) => setState(() => _durationType = v ?? 'hour'),
                    decoration: const InputDecoration(labelText: 'Duration type'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: '1',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Value'),
                    onChanged: (v) => _durationValue = int.tryParse(v) ?? 1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _search,
                child: const Text('Find nearby slots'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


