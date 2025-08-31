import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../models/car_model.dart';
import '../../services/car_service.dart';
import '../../services/parking_space_service.dart';

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
  final _availableFromController = TextEditingController();
  final _availableToController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedRentalMode = 'hourly';
  String? _selectedRentalDuration = '1 month';
  double? _latitude;
  double? _longitude;
  String _selectedAddress = '';
  String? _landProofPath;
  String? _placeImagePath;
  bool _hasEvCharging = false;
  bool _hasShelter = false;
  bool _hasCctv = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _placeNameController.dispose();
    _addressController.dispose();
    _slotNumberController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _availableFromController.dispose();
    _availableToController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

              // Rental Settings Section
              _buildSection(
                'Rental Settings',
                Icons.schedule_outlined,
                [
                  _buildTextFormField(
                    controller: _availableFromController,
                    label: 'Available From',
                    hint: 'From',
                    icon: Icons.access_time_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter available time';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _availableToController,
                    label: 'Available To',
                    hint: 'To',
                    icon: Icons.access_time_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter available time';
                      }
                      return null;
                    },
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
                  _buildDropdownFormField(
                    value: _selectedRentalDuration,
                    label: 'Rental Duration',
                    hint: 'Select rental period',
                    icon: Icons.date_range_outlined,
                    items: const [
                      DropdownMenuItem(value: '1 month', child: Text('1 Month')),
                      DropdownMenuItem(value: '3 months', child: Text('3 Months')),
                      DropdownMenuItem(value: '6 months', child: Text('6 Months')),
                      DropdownMenuItem(value: '1 year', child: Text('1 Year')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRentalDuration = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select rental duration';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _priceController,
                    label: 'Price per Unit',
                    hint: 'Select price',
                    icon: Icons.attach_money_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Facilities Section
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
                      });
                    },
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

              // Description Section
              _buildSection(
                'Additional Information',
                Icons.info_outline,
                [
                  _buildTextFormField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: '24/7 video surveillance for security',
                    icon: Icons.edit_outlined,
                    maxLines: 3,
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
    bool enabled = true,
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
          enabled: enabled,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
    required void Function(String?) onChanged,
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
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: items,
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.my_location_outlined),
                label: const Text('Pick Location on Map'),
              ),
            ),
          ],
        ),
      ),
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
                        'File selected: ${currentPath.split('/').last}',
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

  Widget _buildFacilityCheckbox(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool?) onChanged,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      color: value ? theme.colorScheme.primary.withOpacity(0.05) : null,
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(
              icon,
              color: value ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        activeColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Future<void> _pickLocation() async {
    // TODO: Implement location picker
    // For now, just set some dummy coordinates
    setState(() {
      _latitude = 37.7749;
      _longitude = -122.4194;
      _selectedAddress = '123 Main St, San Francisco, CA';
    });
  }

  Future<void> _pickFile(Function(String?) onPathChanged) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        onPathChanged(result.files.first.path);
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = context.read<AuthController>().state;
      if (authState.profile?.id == null) {
        throw Exception('User not authenticated');
      }

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
        'available_from': _availableFromController.text,
        'available_to': _availableToController.text,
        'rental_mode': _selectedRentalMode,
        'rental_duration_from': DateTime.now().toIso8601String(),
        'rental_duration_to': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'price_per_unit': int.parse(_priceController.text),
        'has_ev_charging': _hasEvCharging,
        'has_shelter': _hasShelter,
        'has_cctv': _hasCctv,
        'is_premium': _hasShelter && (_hasEvCharging || _hasCctv),
        'is_active': true,
        'is_paused': false,
        'total_bookings': 0,
        'current_bookings': 0,
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


