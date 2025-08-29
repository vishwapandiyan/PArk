import 'package:flutter/material.dart';

class ManageSpaceScreen extends StatefulWidget {
  const ManageSpaceScreen({super.key});

  @override
  State<ManageSpaceScreen> createState() => _ManageSpaceScreenState();
}

class _ManageSpaceScreenState extends State<ManageSpaceScreen> {
  final _dimensionsCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _timeFromCtrl = TextEditingController();
  final _timeToCtrl = TextEditingController();
  final _priceHourCtrl = TextEditingController(text: '2.5');
  final _priceDayCtrl = TextEditingController(text: '15');

  @override
  void dispose() {
    _dimensionsCtrl.dispose();
    _addressCtrl.dispose();
    _timeFromCtrl.dispose();
    _timeToCtrl.dispose();
    _priceHourCtrl.dispose();
    _priceDayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Space')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _dimensionsCtrl, decoration: const InputDecoration(labelText: 'Dimensions (LxW)')),
            const SizedBox(height: 12),
            TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _timeFromCtrl, decoration: const InputDecoration(labelText: 'From (HH:mm)'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _timeToCtrl, decoration: const InputDecoration(labelText: 'To (HH:mm)'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _priceHourCtrl, decoration: const InputDecoration(labelText: 'Price / Hour'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _priceDayCtrl, decoration: const InputDecoration(labelText: 'Price / Day'))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


