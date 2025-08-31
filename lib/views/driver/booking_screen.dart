import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/slot_controller.dart';

import '../../models/car_model.dart';
import '../../models/ml_request_model.dart';

import '../../services/car_service.dart';
import '../../services/enhanced_ml_service.dart';

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
  int _maxPrice = 150;

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
            backgroundColor: Colors.red,
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

  Future<void> _findParkingSpaces() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (_destinationLat == null || _destinationLng == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a destination first'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (_selectedCarModel == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select your car model'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Extract area from destination address
    final area = MLParkingRequest.extractAreaFromAddress(_destinationAddress);
    
    // Call ML service for enhanced recommendations
    final enhancedSlots = await EnhancedMLService.getEnhancedSlots(
      area: area,
      latitude: _destinationLat!,
      longitude: _destinationLng!,
      wantsCctv: _needCCTV,
      wantsCovered: _needShelter,
      wantsEv: _needEVCharging,
      wantsPremium: false,
      maxPrice: _maxPrice,
      carDimensions: _selectedCarModel!.dimensionsMap,
      carModelId: _selectedCarModel!.id,
    );

    // Debug: Print what we received
    print('🎯 BookingScreen: Enhanced ML Service returned ${enhancedSlots.length} slots');
    if (enhancedSlots.isNotEmpty) {
      print('   - First slot: ${enhancedSlots.first.parkingSpace.placeName}');
      print('   - ML Score: ${enhancedSlots.first.mlScore}');
      print('   - Price: ${enhancedSlots.first.getCurrentPrice('hourly')}');
    }

    // Navigate to slot list with ML-enhanced results
    Navigator.of(context).pushNamed(
      '/slot_list',
      arguments: {
        'enhancedSlots': enhancedSlots,
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
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Parking'),
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_parking,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Find Your Perfect Parking Spot',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Search for parking spaces that match your preferences',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.navigation,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '📍 Destination',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_destinationAddress.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected Destination',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _destinationAddress,
                      style: TextStyle(
                        color: Colors.green[700],
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please select your destination',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickDestination,
                icon: const Icon(Icons.map),
                label: Text(_destinationAddress.isEmpty 
                    ? 'Pick Destination on Map' 
                    : 'Change Destination'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarModelCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced from 20
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: Theme.of(context).primaryColor,
                  size: 18, // Reduced icon size
                ),
                const SizedBox(width: 8),
                Text(
                  '🚗 Vehicle Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith( // Changed from titleLarge
                    fontWeight: FontWeight.bold,
                    fontSize: 15, // Explicit smaller size
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced from 16
            
            if (_selectedCarModel != null) ...[
              Container(
                padding: const EdgeInsets.all(12), // Reduced from 16
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.blue[700],
                          size: 16, // Reduced icon size
                        ),
                        const SizedBox(width: 6), // Reduced spacing
                        Text(
                          'Selected Car Model',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12, // Reduced font size
                          ),
                        ),
                        if (_selectedCarModel == _userDefaultCarModel) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 8, // Reduced badge size
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    Text(
                      _selectedCarModel!.displayName,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13, // Reduced font size
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dimensions: ${_selectedCarModel!.dimensions}',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 10, // Reduced font size
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10), // Reduced spacing
            ] else
              Container(
                padding: const EdgeInsets.all(12), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16), // Reduced icon
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Please select your car model',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12, // Reduced font size
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
                  labelStyle: const TextStyle(fontSize: 12), // Smaller label
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  prefixIcon: const Icon(Icons.directions_car, size: 16), // Smaller icon
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Compact padding
                  isDense: true, // Make field more compact
                ),
                hint: const Text(
                  'Select your car model',
                  style: TextStyle(fontSize: 12), // Smaller hint
                ),
                isDense: true,
                isExpanded: true,
                menuMaxHeight: 180, // Reduced height to prevent overflow
                style: const TextStyle(fontSize: 12, color: Colors.black87), // Smaller text
                itemHeight: null, // Allow variable item heights
                items: _availableCarModels.map((carModel) {
                  return DropdownMenuItem<CarModel>(
                    value: carModel,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 28), // Limit item height
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            carModel.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 11, // Smaller font
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            carModel.dimensions,
                            style: TextStyle(
                              fontSize: 8, // Much smaller font for dimensions
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '⚙ Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Select your preferred amenities:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            
            _buildPreferenceCheckbox(
              title: 'Shelter',
              subtitle: 'Covered parking space',
              icon: Icons.roofing,
              value: _needShelter,
              onChanged: (value) => setState(() => _needShelter = value ?? false),
            ),
            _buildPreferenceCheckbox(
              title: 'CCTV Surveillance',
              subtitle: '24/7 security monitoring',
              icon: Icons.security,
              value: _needCCTV,
              onChanged: (value) => setState(() => _needCCTV = value ?? false),
            ),
            _buildPreferenceCheckbox(
              title: 'EV Charging',
              subtitle: 'Electric vehicle charging station',
              icon: Icons.electric_car,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? Theme.of(context).primaryColor : Colors.grey.shade300,
        ),
        color: value ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: value ? Theme.of(context).primaryColor : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        secondary: Icon(
          icon,
          color: value ? Theme.of(context).primaryColor : Colors.grey,
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildFindParkingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _findParkingSpaces,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Searching...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  Text(
                    'Find Parking Spaces',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}