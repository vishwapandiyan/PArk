import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../services/parking_space_service.dart';

class AddSpaceScreen extends StatefulWidget {
  const AddSpaceScreen({super.key});

  @override
  State<AddSpaceScreen> createState() => _AddSpaceScreenState();
}

class _AddSpaceScreenState extends State<AddSpaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final _slotNumberCtrl = TextEditingController();
  final _placeNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  // Form state
  String? _landProofPath;
  String? _placeImagePath;
  bool _hasEvCharging = false;
  bool _hasShelter = false;
  bool _hasCctv = false;
  double? _latitude;
  double? _longitude;
  DateTimeRange? _rentalDuration;
  TimeOfDay? _availableFrom;
  TimeOfDay? _availableTo;
  String _rentalMode = 'hourly';
  int? _selectedPrice;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _slotNumberCtrl.dispose();
    _placeNameCtrl.dispose();
    _addressCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Parking Space'),
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
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                
                const SizedBox(height: 24),

                // Section 1: Basic Information
                _buildSection(
                  'Basic Information',
                  Icons.info,
                  [
                    _buildTextFormField(
                      controller: _slotNumberCtrl,
                      label: 'Slot Number',
                      hint: 'e.g., PS001, A-123',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a slot number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _placeNameCtrl,
                      label: 'Place Name',
                      hint: 'e.g., Downtown Premium Parking',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a place name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section 2: Location
                _buildSection(
                  'Location',
                  Icons.location_on,
                  [
                    _buildTextFormField(
                      controller: _addressCtrl,
                      label: 'Address',
                      hint: 'Enter the full address',
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLocationPicker(),
                  ],
                ),

                const SizedBox(height: 24),

                // Section 3: Dimensions
                _buildSection(
                  'Dimensions (in meters)',
                  Icons.straighten,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _lengthCtrl,
                            label: 'Length (m)',
                            hint: '5.5',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final num = double.tryParse(value);
                              if (num == null || num <= 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _widthCtrl,
                            label: 'Width (m)',
                            hint: '3.0',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final num = double.tryParse(value);
                              if (num == null || num <= 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _heightCtrl,
                            label: 'Height (m)',
                            hint: '2.5',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final num = double.tryParse(value);
                              if (num == null || num <= 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section 4: File Uploads
                _buildSection(
                  'Documentation',
                  Icons.upload_file,
                  [
                    _buildFileUploadField(
                      'Land Proof Document',
                      'Upload ownership/lease document',
                      _landProofPath,
                      (path) => setState(() => _landProofPath = path),
                      Icons.description,
                    ),
                    const SizedBox(height: 16),
                    _buildFileUploadField(
                      'Place Image',
                      'Upload a photo of the parking space',
                      _placeImagePath,
                      (path) => setState(() => _placeImagePath = path),
                      Icons.photo_camera,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section 5: Facilities
                _buildSection(
                  'Available Facilities',
                  Icons.build,
                  [
                    _buildFacilityCheckbox(
                      'EV Charging',
                      'Electric vehicle charging station available',
                      Icons.electric_car,
                      _hasEvCharging,
                      (value) => setState(() => _hasEvCharging = value ?? false),
                    ),
                    _buildFacilityCheckbox(
                      'Shelter',
                      'Covered parking with roof protection',
                      Icons.roofing,
                      _hasShelter,
                      (value) => setState(() => _hasShelter = value ?? false),
                    ),
                    _buildFacilityCheckbox(
                      'CCTV',
                      '24/7 video surveillance for security',
                      Icons.security,
                      _hasCctv,
                      (value) => setState(() => _hasCctv = value ?? false),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section 6: Rental Settings
                _buildSection(
                  'Rental Settings',
                  Icons.schedule,
                  [
                    _buildRentalDurationPicker(),
                    const SizedBox(height: 16),
                    _buildAvailabilityTimePicker(),
                    const SizedBox(height: 16),
                    _buildRentalModeSelector(),
                    const SizedBox(height: 16),
                    _buildPriceSelector(),
                  ],
                ),

                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
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
                              Text('Creating Parking Space...'),
                            ],
                          )
                        : const Text(
                            'Create Parking Space',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'New Parking Space Setup',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill out all sections below to add your parking space to the platform.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _buildLocationPicker() {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.map, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Location Coordinates',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_latitude != null && _longitude != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
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
                        'No location selected. Please pick location on map.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_latitude != null ? 'Change Location' : 'Pick Location on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
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

  Widget _buildFileUploadField(
    String title,
    String subtitle,
    String? currentPath,
    Function(String?) onPathChanged,
    IconData icon,
  ) {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (currentPath != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'File selected: ${currentPath.split('/').last}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onPathChanged(null),
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _pickFile(onPathChanged),
                icon: const Icon(Icons.upload),
                label: const Text('Choose File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityCheckbox(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Card(
      color: value ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.grey[50],
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(
              icon,
              color: value ? Theme.of(context).primaryColor : Colors.grey[600],
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

  Widget _buildRentalDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rental Duration',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickRentalDuration,
          icon: const Icon(Icons.date_range),
          label: Text(
            _rentalDuration != null
                ? '${_formatDate(_rentalDuration!.start)} - ${_formatDate(_rentalDuration!.end)}'
                : 'Select rental period',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
            side: BorderSide(color: Theme.of(context).primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Hours',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickTime(true),
                icon: const Icon(Icons.schedule),
                label: Text(_availableFrom?.format(context) ?? 'From'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickTime(false),
                icon: const Icon(Icons.schedule),
                label: Text(_availableTo?.format(context) ?? 'To'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRentalModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rental Mode',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _rentalMode,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
          ],
          onChanged: (value) {
            setState(() {
              _rentalMode = value!;
              _selectedPrice = null; // Reset price when mode changes
            });
          },
        ),
      ],
    );
  }

  Widget _buildPriceSelector() {
    final isPremium = ParkingSpaceService.isPremiumSpace(_hasEvCharging, _hasShelter, _hasCctv);
    final priceOptions = ParkingSpaceService.getPriceOptions(_rentalMode, isPremium);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Price per Unit',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            if (isPremium)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: priceOptions.contains(_selectedPrice) ? _selectedPrice : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            hintText: 'Select price',
          ),
          items: priceOptions.map((price) {
            return DropdownMenuItem(
              value: price,
              child: Text('₹$price'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedPrice = value);
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a price';
            }
            return null;
          },
        ),
        if (isPremium)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Premium pricing applied due to shelter + additional facilities',
              style: TextStyle(
                color: Colors.amber[700],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickFile(Function(String?) onPathChanged) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        onPathChanged(result.files.single.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickLocation() async {
    // For now, use a simple dialog to input coordinates
    // This will be replaced with Google Maps integration
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => _LocationPickerDialog(
        initialLat: _latitude,
        initialLng: _longitude,
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['lat'];
        _longitude = result['lng'];
      });
    }
  }

  Future<void> _pickRentalDuration() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
      initialDateRange: _rentalDuration,
    );

    if (picked != null) {
      setState(() => _rentalDuration = picked);
    }
  }

  Future<void> _pickTime(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom 
          ? (_availableFrom ?? const TimeOfDay(hour: 8, minute: 0))
          : (_availableTo ?? const TimeOfDay(hour: 18, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _availableFrom = picked;
        } else {
          _availableTo = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Additional validation
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_rentalDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select rental duration'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_availableFrom == null || _availableTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set available hours'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authState = context.read<AuthController>().state;
      final isPremium = ParkingSpaceService.isPremiumSpace(_hasEvCharging, _hasShelter, _hasCctv);

      final spaceData = {
        'owner_id': authState.profile!.id,
        'slot_number': _slotNumberCtrl.text.trim(),
        'place_name': _placeNameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'latitude': _latitude!,
        'longitude': _longitude!,
        'length': double.parse(_lengthCtrl.text.trim()),
        'width': double.parse(_widthCtrl.text.trim()),
        'height': double.parse(_heightCtrl.text.trim()),
        'land_proof_url': _landProofPath, // TODO: Upload to Supabase Storage
        'place_image_url': _placeImagePath, // TODO: Upload to Supabase Storage
        'has_ev_charging': _hasEvCharging,
        'has_shelter': _hasShelter,
        'has_cctv': _hasCctv,
        'available_from': '${_availableFrom!.hour.toString().padLeft(2, '0')}:${_availableFrom!.minute.toString().padLeft(2, '0')}:00',
        'available_to': '${_availableTo!.hour.toString().padLeft(2, '0')}:${_availableTo!.minute.toString().padLeft(2, '0')}:00',
        'rental_duration_from': _rentalDuration!.start.toIso8601String().split('T')[0],
        'rental_duration_to': _rentalDuration!.end.toIso8601String().split('T')[0],
        'rental_mode': _rentalMode,
        'price_per_unit': _selectedPrice!,
        'is_premium': isPremium,
        'is_active': true,
        'is_paused': false,
        'total_bookings': 0,
        'current_bookings': 0,
      };

      await ParkingSpaceService.createParkingSpace(spaceData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parking space created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Return to manage spaces screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create parking space: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _LocationPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const _LocationPickerDialog({this.initialLat, this.initialLng});

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null) {
      _latCtrl.text = widget.initialLat!.toStringAsFixed(6);
    }
    if (widget.initialLng != null) {
      _lngCtrl.text = widget.initialLng!.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Set Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter coordinates or use the map integration coming soon!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _latCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Latitude',
              hintText: '12.9716',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lngCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Longitude',
              hintText: '77.5946',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: You can use Google Maps to find coordinates for your location.',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final lat = double.tryParse(_latCtrl.text);
            final lng = double.tryParse(_lngCtrl.text);
            
            if (lat == null || lng == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter valid coordinates'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            Navigator.of(context).pop({'lat': lat, 'lng': lng});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Set Location'),
        ),
      ],
    );
  }
}
