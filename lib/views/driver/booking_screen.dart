import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/slot_controller.dart';

import '../../models/car_model.dart';
import '../../services/car_service.dart';

import '../../widgets/destination_maps_picker.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Destination data
  String _destinationAddress = '';
  double? _destinationLat;
  double? _destinationLng;
  
  // Car model data
  CarModel? _selectedCarModel;
  CarModel? _userDefaultCarModel;
  List<CarModel> _availableCarModels = [];
  bool _isLoadingCarModels = false;
  
  // Preferences
  bool _needShelter = false;
  bool _needCCTV = false;
  bool _needEVCharging = false;
  bool _isLoading = false;
  
  // Max price
  final _maxPriceCtrl = TextEditingController(text: '150');

  @override
  void initState() {
    super.initState();
    _loadUserCarModel();
    _loadAvailableCarModels();
  }

  @override
  void dispose() {
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserCarModel() async {
    try {
      final authState = context.read<AuthController>().state;
      if (authState.profile?.carModelId != null) {
        final carModel = await CarService.getCarModelById(authState.profile!.carModelId!);
        if (mounted) {
          setState(() {
            _userDefaultCarModel = carModel;
            _selectedCarModel = carModel; // Set as default selection
          });
        }
      }
    } catch (e) {
      print('Error loading user car model: $e');
    }
  }

  Future<void> _loadAvailableCarModels() async {
    setState(() => _isLoadingCarModels = true);
    try {
      final carModels = await CarService.getAllCarModels();
      if (mounted) {
        setState(() {
          _availableCarModels = carModels;
          _isLoadingCarModels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCarModels = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load car models: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDestination() async {
    await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => DestinationMapsPicker(
          onDestinationSelected: (lat, lng, address) {
            setState(() {
              _destinationLat = lat;
              _destinationLng = lng;
              _destinationAddress = address;
            });
            // Navigator.pop() is already called by DestinationMapsPicker
          },
        ),
      ),
    );
  }

  void _findParkingSpaces() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_destinationLat == null || _destinationLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a destination first'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      return;
    }

    if (_selectedCarModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your car model'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get all slots (you would normally filter by location/distance here)
      final slotController = context.read<SlotController>();
      final allSlots = slotController.state.slots;

      // Manual filtering based on preferences
      final filteredSlots = allSlots.where((slot) {
        bool matches = true;
        
        // Filter by shelter preference
        if (_needShelter && (slot.hasShelter != true)) {
          matches = false;
        }
        
        // Filter by CCTV preference
        if (_needCCTV && (slot.hasCCTV != true)) {
          matches = false;
        }
        
        // Filter by EV Charging preference
        if (_needEVCharging && (slot.hasEVCharging != true)) {
          matches = false;
        }
        
        return matches;
      }).toList();

      // Navigate to slot list with filtered results
      Navigator.of(context).pushNamed(
        '/slot_list',
        arguments: {
          'slots': filteredSlots,
          'destination': _destinationAddress,
          'carModel': _selectedCarModel!.displayName,
          'preferences': {
            'shelter': _needShelter,
            'cctv': _needCCTV,
            'evCharging': _needEVCharging,
          },
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error finding parking spaces: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Parking',
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                _buildDestinationCard(),
                const SizedBox(height: 20),
                _buildCarModelCard(),
                const SizedBox(height: 20),
                _buildPreferencesCard(),
                const SizedBox(height: 30),
                _buildFindParkingButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.primary,
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_parking_outlined,
              size: 48,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Find Your Perfect Parking Spot',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Search for parking spaces that match your preferences',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.navigation_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Destination',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_destinationAddress.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outlined,
                          color: theme.colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected Destination',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _destinationAddress,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined, 
                      color: theme.colorScheme.tertiary, 
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please select your destination',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _pickDestination,
                icon: const Icon(Icons.map_outlined),
                label: Text(_destinationAddress.isEmpty 
                    ? 'Pick Destination on Map' 
                    : 'Change Destination'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarModelCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Vehicle Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced from 16
            
            if (_selectedCarModel != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outlined,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Selected Car Model',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedCarModel == _userDefaultCarModel) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.colorScheme.secondary),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    Text(
                      _selectedCarModel!.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dimensions: ${_selectedCarModel!.dimensions}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.8),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10), // Reduced spacing
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined, 
                      color: theme.colorScheme.tertiary, 
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Please select your car model',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12), // Reduced spacing
            
            if (_isLoadingCarModels)
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              DropdownButtonFormField<CarModel>(
                value: _selectedCarModel,
                decoration: InputDecoration(
                  labelText: 'Car Model',
                  prefixIcon: const Icon(Icons.directions_car_outlined, size: 16),
                ),
                hint: Text(
                  'Select your car model',
                  style: theme.textTheme.bodySmall,
                ),
                isDense: true,
                isExpanded: true,
                menuMaxHeight: 180,
                style: theme.textTheme.bodyMedium,
                itemHeight: null,
                items: _availableCarModels.map((carModel) {
                  return DropdownMenuItem<CarModel>(
                    value: carModel,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 28),
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            carModel.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            carModel.dimensions,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontFamily: 'monospace',
                              fontSize: 8,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (CarModel? newValue) {
                  setState(() {
                    _selectedCarModel = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select your car model';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preferences',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Select your preferred amenities:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            
            _buildPreferenceCheckbox(
              title: 'Shelter',
              subtitle: 'Covered parking space',
              icon: Icons.roofing_outlined,
              value: _needShelter,
              onChanged: (value) => setState(() => _needShelter = value ?? false),
            ),
            _buildPreferenceCheckbox(
              title: 'CCTV Surveillance',
              subtitle: '24/7 security monitoring',
              icon: Icons.security_outlined,
              value: _needCCTV,
              onChanged: (value) => setState(() => _needCCTV = value ?? false),
            ),
            _buildPreferenceCheckbox(
              title: 'EV Charging',
              subtitle: 'Electric vehicle charging station',
              icon: Icons.electric_car_outlined,
              value: _needEVCharging,
              onChanged: (value) => setState(() => _needEVCharging = value ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceCheckbox({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        color: value ? theme.colorScheme.primary.withOpacity(0.05) : null,
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: value ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        secondary: Icon(
          icon,
          color: value ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildFindParkingButton() {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _findParkingSpaces,
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Searching...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Find Parking Spaces',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}





