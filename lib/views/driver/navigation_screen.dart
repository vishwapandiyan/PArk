import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/parking_slot_model.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = ModalRoute.of(context)!.settings.arguments as ParkingSlotModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Navigate to:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(slot.address),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openMaps(slot.latitude, slot.longitude),
                    child: const Text('Open in Google Maps'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/ar_view', arguments: slot),
                    child: const Text('AR View'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


