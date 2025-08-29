import 'package:flutter/material.dart';
import '../models/parking_slot_model.dart';

class SlotCard extends StatelessWidget {
  final ParkingSlotModel slot;
  final VoidCallback? onTap;

  const SlotCard({super.key, required this.slot, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_parking, color: Colors.blue, size: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Rating: ${slot.rating?.toStringAsFixed(1) ?? '-'} (${slot.reviewCount ?? 0})'),
                    const SizedBox(height: 4),
                    Text('Durations: ${slot.availableDurations.join(', ')}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


