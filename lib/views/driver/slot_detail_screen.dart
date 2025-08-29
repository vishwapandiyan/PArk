import 'package:flutter/material.dart';
import '../../models/parking_slot_model.dart';

class SlotDetailScreen extends StatelessWidget {
  const SlotDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final slot = ModalRoute.of(context)!.settings.arguments as ParkingSlotModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Slot Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(slot.address, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Dimensions: ${slot.dimensions ?? '-'}'),
            Text('Available: ${slot.timeFrom ?? '--'} - ${slot.timeTo ?? '--'}'),
            Text('Rating: ${slot.rating?.toStringAsFixed(1) ?? '-'} (${slot.reviewCount ?? 0})'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/navigation', arguments: slot),
                child: const Text('Navigate & AR View'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


