import 'package:flutter/material.dart';
import '../../models/parking_slot_model.dart';

class SlotDetailScreen extends StatelessWidget {
  const SlotDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🎯 SlotDetailScreen: Starting build...');
    
    try {
      final slot = ModalRoute.of(context)!.settings.arguments as ParkingSlotModel;
      print('🎯 SlotDetailScreen: Successfully cast to ParkingSlotModel');
      print('🎯 SlotDetailScreen: Slot ID: ${slot.id}');
      print('🎯 SlotDetailScreen: Slot address: ${slot.address}');
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('Slot Details'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slot Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_parking_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              slot.address,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Details Grid
                      _buildDetailRow(context, 'Dimensions', slot.dimensions ?? 'Not specified', Icons.straighten_outlined),
                      _buildDetailRow(context, 'Available Time', '${slot.timeFrom ?? '--'} - ${slot.timeTo ?? '--'}', Icons.access_time_outlined),
                      _buildDetailRow(context, 'Rating', '${slot.rating?.toStringAsFixed(1) ?? '-'} (${slot.reviewCount ?? 0} reviews)', Icons.star_outlined),
                      _buildDetailRow(context, 'Location', '${slot.latitude.toStringAsFixed(6)}, ${slot.longitude.toStringAsFixed(6)}', Icons.location_on_outlined),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        '/navigation', 
                        arguments: slot,
                      ),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        '/ar_view', 
                        arguments: slot,
                      ),
                      icon: const Icon(Icons.view_in_ar_outlined),
                      label: const Text('AR View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Book Now Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking functionality coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.book_online_outlined),
                  label: const Text('Book Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ SlotDetailScreen: Error during build: $e');
      print('❌ SlotDetailScreen: Stack trace: $stackTrace');
      
      // Return error screen instead of crashing
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error Loading Slot Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}