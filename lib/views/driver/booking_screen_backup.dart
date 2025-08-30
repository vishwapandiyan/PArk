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

  @override
  void initState() {
    super.initState();
    _loadUserCarModel();
    _loadAvailableCarModels();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserCarModel() async {
    try {
      final authState = context.read<AuthController>().state;
      if (authState.profile?.carModelId != null) {
        final carModel = await CarService.getCarModelById(authState.profile!.carModelId!);
        setState(() {
          _userDefaultCarModel = carModel;
          _selectedCarModel = carModel; // Set as default selection
        });
        print('🚗 Loaded user default car model: ${carModel?.displayName}');
      }
    } catch (e) {
      print('❌ Error loading user car model: $e');
    }
  }

  Future<void> _loadAvailableCarModels() async {
    setState(() => _isLoadingCarModels = true);
    try {
      final carModels = await CarService.getAllCarModels();
      setState(() {
        _availableCarModels = carModels;
        _isLoadingCarModels = false;
      });
      print('🚗 Loaded ${carModels.length} available car models');
    } catch (e) {
      setState(() => _isLoadingCarModels = false);
      print('❌ Error loading car models: $e');
    }
  }

  Future<void> _findParkingSpaces() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation
    if (_destinationAddress.isEmpty || _destinationLat == null || _destinationLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination on the map'),
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
      // Get available slots from controller
      final slots = context.read<SlotController>().state.slots;
      if (slots.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No parking slots available')),
        );
        return;
      }

      // Filter slots based on user preferences
      final filteredSlots = slots.where((slot) {
        bool meetsPreferences = true;
        
        if (_needShelter && (slot.hasShelter != true)) {
          meetsPreferences = false;
        }
        if (_needCCTV && (slot.hasCCTV != true)) {
          meetsPreferences = false;
        }
        if (_needEVCharging && (slot.hasEVCharging != true)) {
          meetsPreferences = false;
        }
        
        return meetsPreferences;
      }).toList();

      if (!mounted) return;

      if (filteredSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No parking spaces match your preferences. Try adjusting your requirements.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Navigate to slot list screen with filtered results
      Navigator.of(context).pushNamed(
        '/slot_list',
        arguments: {
          'slots': filteredSlots,
          'destination': _destinationAddress,
          'destinationLat': _destinationLat,
          'destinationLng': _destinationLng,
          'carModel': _selectedCarModel!.displayName,
          'preferences': {
            'shelter': _needShelter,
            'cctv': _needCCTV,
            'evCharging': _needEVCharging,
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                _buildHeaderCard(),
                
                const SizedBox(height: 24),

                // Destination Card
                _buildDestinationCard(),
                
                const SizedBox(height: 24),

                // Car Model Card
                _buildCarModelCard(),

                const SizedBox(height: 24),

                // Parking Preferences Card
                _buildPreferencesCard(),

                const SizedBox(height: 32),

                // Find Parking Button
                _buildFindParkingButton(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.local_parking,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Find Available Parking Spaces',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Search for parking spaces that match your preferences',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
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
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Destination Selected',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _destinationAddress,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coordinates: ${_destinationLat?.toStringAsFixed(4)}, ${_destinationLng?.toStringAsFixed(4)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 11,
                        fontFamily: 'monospace',
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
                        'Please select your destination using the map',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDestination,
                icon: const Icon(Icons.map),
                label: Text(_destinationAddress.isNotEmpty ? 'Change Destination' : 'Pick Destination on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '🚗 Vehicle Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_selectedCarModel != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
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
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected Car Model',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedCarModel == _userDefaultCarModel) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedCarModel!.displayName,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dimensions: ${_selectedCarModel!.dimensions}',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 12,
                        fontFamily: 'monospace',
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
                        'Please select your car model',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            if (_isLoadingCarModels)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              DropdownButtonFormField<CarModel>(
                value: _selectedCarModel,
                decoration: InputDecoration(
                  labelText: 'Car Model',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  prefixIcon: const Icon(Icons.directions_car),
                ),
                hint: const Text('Select your car model'),
                isDense: true,
                isExpanded: true,
                menuMaxHeight: 300,
                items: _availableCarModels.map((carModel) {
                  return DropdownMenuItem<CarModel>(
                    value: carModel,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            carModel.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            carModel.dimensions,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
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
                  '⚙️ Parking Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildPreferenceSwitch(
              'Shelter Required',
              'Covered parking space',
              Icons.roofing,
              _needShelter,
              (value) => setState(() => _needShelter = value),
            ),
            const SizedBox(height: 12),
            _buildPreferenceSwitch(
              'CCTV Security',
              '24/7 video surveillance',
              Icons.security,
              _needCCTV,
              (value) => setState(() => _needCCTV = value),
            ),
            const SizedBox(height: 12),
            _buildPreferenceSwitch(
              'EV Charging',
              'Electric vehicle charging station',
              Icons.electric_car,
              _needEVCharging,
              (value) => setState(() => _needEVCharging = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: value ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(
              icon,
              color: value ? Theme.of(context).primaryColor : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value ? Theme.of(context).primaryColor : null,
              ),
            ),
          ],
        ),
        subtitle: Text(subtitle),
        activeColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  Text('Searching Parking Spaces...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 8),
                  Text(
                    'Find Parking Spaces',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickDestination() async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DestinationMapsPicker(
            initialDestinationLat: _destinationLat,
            initialDestinationLng: _destinationLng,
            onDestinationSelected: (lat, lng, address) {
              setState(() {
                _destinationLat = lat;
                _destinationLng = lng;
                _destinationAddress = address;
              });
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open destination picker: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


