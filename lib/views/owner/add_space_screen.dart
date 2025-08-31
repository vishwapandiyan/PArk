import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import '../../controllers/auth_controller.dart';
import '../../models/car_model.dart';
import '../../services/car_service.dart';
import '../../services/parking_space_service.dart';
import '../../config/storage_service.dart';
import '../../widgets/google_maps_location_picker.dart';

class AddSpaceScreen extends StatefulWidget {
  const AddSpaceScreen({super.key});

  @override
  State<AddSpaceScreen> createState() => _AddSpaceScreenState();
}

class _AddSpaceScreenState extends State<AddSpaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _slotNumberController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedRentalMode = 'hourly';
  DateTime? _rentalDurationFrom;
  DateTime? _rentalDurationTo;
  TimeOfDay? _availableFrom;
  TimeOfDay? _availableTo;
  double? _latitude;
  double? _longitude;
  String _selectedAddress = '';
  String? _landProofPath;
  String? _placeImagePath;
  bool _hasEvCharging = false;
  bool _hasShelter = false;
  bool _hasCctv = false;
  bool _isSubmitting = false;
  bool _isGettingCurrentLocation = false;

  // Generated time slots
  List<Map<String, String>> _generatedTimeSlots = [];

  // Price options based on rental mode and premium status
  List<int> _priceOptions = [];

  @override
  void initState() {
    super.initState();
    _updatePriceOptions();
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _addressController.dispose();
    _slotNumberController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updatePriceOptions() {
    final isPremium = ParkingSpaceService.isPremiumSpace(_hasEvCharging, _hasShelter, _hasCctv);
    _priceOptions = ParkingSpaceService.getPriceOptions(_selectedRentalMode ?? 'hourly', isPremium);
    
    // Set default price if current price is not in options
    if (_priceOptions.isNotEmpty && !_priceOptions.contains(int.tryParse(_priceController.text))) {
      _priceController.text = _priceOptions.first.toString();
    }
  }

  /// Generate time slots with 20-minute gaps
  void _generateTimeSlots() {
    if (_availableFrom == null || _availableTo == null) return;

    _generatedTimeSlots.clear();
    
    // Convert to minutes for easier calculation
    int startMinutes = _availableFrom!.hour * 60 + _availableFrom!.minute;
    int endMinutes = _availableTo!.hour * 60 + _availableTo!.minute;
    
    // Generate slots with 20-minute gaps
    int currentSlotStart = startMinutes;
    int slotNumber = 1;
    
    while (currentSlotStart < endMinutes) {
      int slotEnd = currentSlotStart + 60; // 1-hour slots
      if (slotEnd > endMinutes) break;
      
      String startTime = _formatTimeFromMinutes(currentSlotStart);
      String endTime = _formatTimeFromMinutes(slotEnd);
      
      _generatedTimeSlots.add({
        'slot': 'Slot $slotNumber',
        'time': '$startTime - $endTime',
        'start_minutes': currentSlotStart.toString(),
        'end_minutes': slotEnd.toString(),
        'is_available': 'true', // Default to available
      });
      
      currentSlotStart = slotEnd + 20; // 20-minute gap
      slotNumber++;
    }
    
    setState(() {});
  }

  String _formatTimeFromMinutes(int minutes) {
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    String period = hours >= 12 ? 'PM' : 'AM';
    
    if (hours > 12) hours -= 12;
    if (hours == 0) hours = 12;
    
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Parking Space',
          style: theme.textTheme.headlineMedium,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              _buildProgressIndicator(),

              const SizedBox(height: 32),

              // Location Section
              _buildSection(
                'Location',
                Icons.location_on_outlined,
                [
                  _buildLocationPicker(),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _placeNameController,
                    label: 'Place Name',
                    hint: 'Enter the name of your parking space',
                    icon: Icons.business_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a place name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Enter the full address',
                    icon: Icons.home_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _slotNumberController,
                    label: 'Slot Number',
                    hint: 'Enter slot number (e.g., A1, B2)',
                    icon: Icons.confirmation_number_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a slot number';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Dimensions Section
              _buildSection(
                'Dimensions (in meters)',
                Icons.straighten_outlined,
                [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _lengthController,
                          label: 'Length',
                          hint: 'Length...',
                          icon: Icons.straighten_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter length';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _widthController,
                          label: 'Width',
                          hint: 'Width...',
                          icon: Icons.straighten_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter width';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _heightController,
                          label: 'Height',
                          hint: 'Height...',
                          icon: Icons.height_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter height';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Available Facilities Section (moved before Rental Settings)
              _buildSection(
                'Available Facilities',
                Icons.build_outlined,
                [
                  _buildFacilityCheckbox(
                    'Shelter',
                    'Covered parking space',
                    Icons.roofing_outlined,
                    _hasShelter,
                    (value) {
                      setState(() {
                        _hasShelter = value ?? false;
                        _updatePriceOptions();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFacilityCheckbox(
                    'CCTV Surveillance',
                    '24/7 security monitoring',
                    Icons.security_outlined,
                    _hasCctv,
                    (value) {
                      setState(() {
                        _hasCctv = value ?? false;
                        _updatePriceOptions();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFacilityCheckbox(
                    'EV Charging',
                    'Electric vehicle charging station',
                    Icons.electric_car_outlined,
                    _hasEvCharging,
                    (value) {
                      setState(() {
                        _hasEvCharging = value ?? false;
                        _updatePriceOptions();
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Rental Settings Section
              _buildSection(
                'Rental Settings',
                Icons.schedule_outlined,
                [
                  // Time pickers for Available From - To
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePickerField(
                          label: 'Available From',
                          value: _availableFrom,
                          onChanged: (time) {
                            setState(() {
                              _availableFrom = time;
                              _generateTimeSlots();
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select start time';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePickerField(
                          label: 'Available To',
                          value: _availableTo,
                          onChanged: (time) {
                            setState(() {
                              _availableTo = time;
                              _generateTimeSlots();
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select end time';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  

                  
                  const SizedBox(height: 16),
                  _buildDropdownFormField(
                    value: _selectedRentalMode,
                    label: 'Rental Mode',
                    hint: 'Select rental mode',
                    icon: Icons.calendar_today_outlined,
                    items: const [
                      DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRentalMode = value;
                        _updatePriceOptions();
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select rental mode';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Calendar-based rental duration picker
                  _buildDateRangePicker(),
                  
                  const SizedBox(height: 16),
                  _buildPriceSelector(),
                ],
              ),

              const SizedBox(height: 32),

              // Time Slots Card (separate from Rental Settings)
              if (_generatedTimeSlots.isNotEmpty)
                _buildSection(
                  'Time Slots',
                  Icons.schedule_outlined,
                  [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Generated Time Slots (20-minute gaps)',
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...(_generatedTimeSlots.asMap().entries.map((entry) {
                            final index = entry.key;
                            final slot = entry.value;
                            final isAvailable = slot['is_available'] != 'false';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isAvailable 
                                    ? theme.colorScheme.primary.withOpacity(0.1)
                                    : theme.colorScheme.outline.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isAvailable 
                                      ? theme.colorScheme.primary.withOpacity(0.3)
                                      : theme.colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_outlined,
                                    size: 20,
                                    color: isAvailable 
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slot['slot'] ?? 'Slot ${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isAvailable 
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.outline,
                                          ),
                                        ),
                                        Text(
                                          slot['time'] ?? '',
                                          style: TextStyle(
                                            color: isAvailable 
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isAvailable,
                                    onChanged: (value) {
                                      setState(() {
                                        _generatedTimeSlots[index]['is_available'] = value.toString();
                                      });
                                    },
                                    activeColor: theme.colorScheme.primary,
                                    inactiveThumbColor: theme.colorScheme.outline,
                                  ),
                                ],
                              ),
                            );
                          }).toList()),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Documentation Section
              _buildSection(
                'Documentation',
                Icons.description_outlined,
                [
                  _buildFilePicker(
                    'Land Proof Document',
                    'Upload ownership/lease document',
                    _landProofPath,
                    (path) {
                      setState(() {
                        _landProofPath = path;
                      });
                    },
                    Icons.description_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildFilePicker(
                    'Place Image',
                    'Upload a photo of the parking space',
                    _placeImagePath,
                    (path) {
                      setState(() {
                        _placeImagePath = path;
                      });
                    },
                    Icons.camera_alt_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit Button
              _buildAddSpaceButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods...
  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'New Parking Space Setup',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Fill out all sections below to add your parking space to the platform.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleLarge,
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
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownFormField({
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: items,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required TimeOfDay? value,
    required ValueChanged<TimeOfDay?> onChanged,
    required String? Function(TimeOfDay?) validator,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: value ?? TimeOfDay.now(),
            );
            if (time != null) {
              onChanged(time);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_outlined, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null ? value.format(context) : 'Select Time',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: value != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),
        if (validator(value) != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              validator(value)!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rental Duration',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _rentalDurationFrom ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _rentalDurationFrom = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        _rentalDurationFrom != null 
                            ? '${_rentalDurationFrom!.day}/${_rentalDurationFrom!.month}/${_rentalDurationFrom!.year}'
                            : 'From Date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _rentalDurationFrom != null 
                              ? theme.colorScheme.onSurface 
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _rentalDurationTo ?? (_rentalDurationFrom ?? DateTime.now().add(const Duration(days: 30))),
                    firstDate: _rentalDurationFrom ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _rentalDurationTo = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        _rentalDurationTo != null 
                            ? '${_rentalDurationTo!.day}/${_rentalDurationTo!.month}/${_rentalDurationTo!.year}'
                            : 'To Date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _rentalDurationTo != null 
                              ? theme.colorScheme.onSurface 
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSelector() {
    final theme = Theme.of(context);
    final isPremium = ParkingSpaceService.isPremiumSpace(_hasEvCharging, _hasShelter, _hasCctv);
    final priceRanges = ParkingSpaceService.getPriceRanges(_selectedRentalMode ?? 'hourly', isPremium);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Price per Unit',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPremium 
                    ? theme.colorScheme.tertiary.withOpacity(0.2)
                    : theme.colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPremium ? 'Premium' : 'Standard',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPremium 
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Price range: ₹${priceRanges['min']} - ₹${priceRanges['max']}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _priceOptions.isNotEmpty ? int.tryParse(_priceController.text) : null,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _priceController.text = value.toString();
              });
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a price';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Select price',
            prefixIcon: Icon(Icons.attach_money_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _priceOptions.map((price) {
            return DropdownMenuItem(
              value: price,
              child: Text('₹$price'),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.map_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Location Coordinates',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_latitude != null && _longitude != null)
              Container(
                padding: const EdgeInsets.all(12),
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
                        Icon(Icons.check_circle_outlined, color: theme.colorScheme.secondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Location Selected',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedAddress.isNotEmpty)
                      Text(
                        _selectedAddress,
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      'Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: theme.colorScheme.secondary.withOpacity(0.8),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_outlined, color: theme.colorScheme.tertiary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No location selected. Please pick location on map.',
                        style: TextStyle(color: theme.colorScheme.tertiary),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56, // Increased button height
                    child: OutlinedButton.icon(
                      onPressed: _isGettingCurrentLocation ? null : _getCurrentLocation,
                      icon: _isGettingCurrentLocation 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.my_location_outlined, size: 24), // Increased icon size
                      label: Text(
                        _isGettingCurrentLocation ? 'Getting Location...' : 'Use Current Location',
                        style: theme.textTheme.labelLarge, // Larger text
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56, // Increased button height
                    child: FilledButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.map_outlined, size: 24), // Increased icon size
                      label: Text(
                        'Pick on Map',
                        style: theme.textTheme.labelLarge, // Larger text
                      ),
                    ),
                  ),
                ),
              ],
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
    ValueChanged<bool?> onChanged,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker(
    String title,
    String subtitle,
    String? currentPath,
    Function(String?) onPathChanged,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outlined, color: theme.colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'File uploaded: ${currentPath.split('/').last}',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onPathChanged(null),
                      icon: Icon(Icons.close_outlined, color: theme.colorScheme.error, size: 20),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _pickFile(onPathChanged),
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Choose File'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSpaceButton() {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _isSubmitting ? null : _submitForm,
        child: _isSubmitting
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
                  Text(
                    'Creating...',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              )
            : Text(
                'Create Parking Space',
                style: theme.textTheme.labelLarge,
              ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingCurrentLocation = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          final String address = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
            _selectedAddress = address;
            _addressController.text = address;
          });
        } else {
          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
          });
        }
      } catch (e) {
        // If geocoding fails, just use coordinates
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }

          if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Current location set successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get current location: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingCurrentLocation = false;
        });
      }
    }
  }

  Future<void> _pickLocation() async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GoogleMapsLocationPicker(
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            onLocationSelected: (lat, lng, address) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
                _selectedAddress = address;
                _addressController.text = address;
              });
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open location picker: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFile(Function(String?) onPathChanged) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        
        // Upload to Supabase Storage
        try {
          String? uploadedUrl;
          if (fileName.toLowerCase().contains('image') || fileName.toLowerCase().contains('photo')) {
            uploadedUrl = await StorageService.uploadFile(
              file: file,
              bucket: 'photos',
              path: 'parking_spaces/${DateTime.now().millisecondsSinceEpoch}_$fileName',
            );
          } else {
            uploadedUrl = await StorageService.uploadFile(
              file: file,
              bucket: 'documents',
              path: 'parking_spaces/${DateTime.now().millisecondsSinceEpoch}_$fileName',
            );
          }
          
          onPathChanged(uploadedUrl);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload file: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a location on the map'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_availableFrom == null || _availableTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select available time range'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_rentalDurationFrom == null || _rentalDurationTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select rental duration dates'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = context.read<AuthController>().state;
      if (authState.profile?.id == null) {
        throw Exception('User not authenticated');
      }

      // Use ParkingSpaceService to create the space
      final spaceData = {
        'owner_id': authState.profile!.id,
        'place_name': _placeNameController.text,
        'address': _addressController.text,
        'slot_number': _slotNumberController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'length': double.parse(_lengthController.text),
        'width': double.parse(_widthController.text),
        'height': double.parse(_heightController.text),
        'available_from': '${_availableFrom!.hour.toString().padLeft(2, '0')}:${_availableFrom!.minute.toString().padLeft(2, '0')}',
        'available_to': '${_availableTo!.hour.toString().padLeft(2, '0')}:${_availableTo!.minute.toString().padLeft(2, '0')}',
        'rental_mode': _selectedRentalMode,
        'rental_duration_from': _rentalDurationFrom!.toIso8601String(),
        'rental_duration_to': _rentalDurationTo!.toIso8601String(),
        'price_per_unit': int.parse(_priceController.text),
        'has_ev_charging': _hasEvCharging,
        'has_shelter': _hasShelter,
        'has_cctv': _hasCctv,
        'is_premium': ParkingSpaceService.isPremiumSpace(_hasEvCharging, _hasShelter, _hasCctv),
        'is_active': true,
        'is_paused': false,
        'total_bookings': 0,
        'current_bookings': 0,
        'land_proof_url': _landProofPath,
        'place_image_url': _placeImagePath,
        'generated_time_slots': _generatedTimeSlots, // Store time slots in database
      };

      await ParkingSpaceService.createParkingSpace(spaceData);

          if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Parking space created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create parking space: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}