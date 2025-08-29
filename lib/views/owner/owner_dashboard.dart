import 'package:flutter/material.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Earnings Summary'),
                subtitle: const Text('Daily / Weekly / Monthly'),
                trailing: const Icon(Icons.bar_chart),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Manage Space'),
                trailing: const Icon(Icons.edit),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}


