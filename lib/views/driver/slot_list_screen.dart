import 'package:flutter/material.dart';
import '../../models/parking_slot_model.dart';
import '../../widgets/slot_card.dart';

class SlotListScreen extends StatefulWidget {
  const SlotListScreen({super.key});

  @override
  State<SlotListScreen> createState() => _SlotListScreenState();
}

class _SlotListScreenState extends State<SlotListScreen> {
  List<ParkingSlotModel> _filteredSlots = [];
  String _destination = '';
  String _carModel = '';
  Map<String, bool> _preferences = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadArguments();
  }

  void _loadArguments() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      setState(() {
        _filteredSlots = List<ParkingSlotModel>.from(args['slots'] ?? []);
        _destination = args['destination'] ?? '';
        _carModel = args['carModel'] ?? '';
        _preferences = Map<String, bool>.from(args['preferences'] ?? {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Parking Spaces'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Trip Summary Header
            _buildTripSummary(),
            
            // Results Summary
            _buildResultsSummary(),
            
            // Slots List
            Expanded(
              child: _filteredSlots.isEmpty
                  ? _buildEmptyState()
                  : _buildSlotsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.navigation,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Trip Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Icon(Icons.place, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _destination,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),

            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                _carModel,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          
          if (_preferences.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _preferences.entries
                  .where((entry) => entry.value)
                  .map((entry) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPreferenceIcon(entry.key),
                              size: 14,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPreferenceLabel(entry.key),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${_filteredSlots.length} Available Space${_filteredSlots.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  'Spaces matching your preferences',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Matching Spaces Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your preferences or search in a different area',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _filteredSlots.length,
      itemBuilder: (context, index) {
        final slot = _filteredSlots[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SlotCard(
            slot: slot,
            onTap: () {
              Navigator.of(context).pushNamed(
                '/slot_detail',
                arguments: slot,
              );
            },
          ),
        );
      },
    );
  }

  IconData _getPreferenceIcon(String key) {
    switch (key) {
      case 'shelter':
        return Icons.roofing;
      case 'cctv':
        return Icons.security;
      case 'evCharging':
        return Icons.electric_car;
      default:
        return Icons.check;
    }
  }

  String _getPreferenceLabel(String key) {
    switch (key) {
      case 'shelter':
        return 'Shelter';
      case 'cctv':
        return 'CCTV';
      case 'evCharging':
        return 'EV Charging';
      default:
        return key;
    }
  }
}


