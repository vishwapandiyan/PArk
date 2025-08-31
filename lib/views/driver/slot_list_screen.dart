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
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Available Parking Spaces',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.surface,
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
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                          Icon(
              Icons.navigation_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Trip Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(
                Icons.place_outlined, 
                color: theme.colorScheme.error, 
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _destination,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.directions_car_outlined, 
                color: theme.colorScheme.secondary, 
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _carModel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          if (_preferences.isNotEmpty) 
            const SizedBox(height: 12),
          if (_preferences.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _preferences.entries
                  .where((entry) => entry.value)
                  .map((entry) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPreferenceIcon(entry.key),
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPreferenceLabel(entry.key),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outlined,
            color: theme.colorScheme.secondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${_filteredSlots.length} Available Space${_filteredSlots.length != 1 ? 's' : ''}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Text(
                  'Spaces matching your preferences',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary.withOpacity(0.8),
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
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Matching Spaces Found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your preferences or search in a different area',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_outlined),
              label: const Text('Back to Search'),
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
        return Icons.roofing_outlined;
      case 'cctv':
        return Icons.security_outlined;
      case 'evCharging':
        return Icons.electric_car_outlined;
      default:
        return Icons.check_outlined;
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


