import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../models/car_model.dart';
import '../../services/car_service.dart';
import '../../widgets/loading_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  UserRole _role = UserRole.driver;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedDob;
  CarModel? _selectedCarModel;
  List<CarModel> _carModels = [];
  List<CarModel> _filteredCarModels = [];
  bool _loadingCarModels = false;
  String _carSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCarModels();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCarModels() async {
    print('📱 RegisterScreen: Starting to load car models...');
    setState(() => _loadingCarModels = true);
    try {
      final carModels = await CarService.getAllCarModels();
      print('📱 RegisterScreen: Received ${carModels.length} car models');
      setState(() {
        _carModels = carModels;
        _filteredCarModels = carModels;
        _loadingCarModels = false;
      });
      print('📱 RegisterScreen: Car models loaded successfully');
    } catch (e) {
      print('❌ RegisterScreen: Error loading car models: $e');
      setState(() => _loadingCarModels = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load car models: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterCarModels(String query) {
    setState(() {
      _carSearchQuery = query;
      if (query.isEmpty) {
        _filteredCarModels = _carModels;
      } else {
        _filteredCarModels = _carModels
            .where((car) =>
                car.name.toLowerCase().contains(query.toLowerCase()) ||
                car.brand.toLowerCase().contains(query.toLowerCase()) ||
                car.displayName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for driver-specific fields
    if (_role == UserRole.driver) {
      if (_selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your date of birth'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedCarModel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your car model'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      // For owners, DOB is still required
      if (_selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your date of birth'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthController>().signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        dob: _selectedDob,
        role: _role,
        carModelId: _selectedCarModel?.id,
      );
      
      if (!mounted) return;
      
      // AuthWrapper will automatically handle navigation based on the user's role
      // Just show a success message and let the AuthWrapper handle navigation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Welcome to Smart Parking!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)), // Default to 25 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)), // 100 years ago
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Must be at least 18 years old
      helpText: 'Select Date of Birth',
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  String? _getFormattedDate(DateTime? date) {
    if (date == null) return null;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Logo and Title
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.local_parking_outlined,
                        size: 40,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Create Account',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: theme.colorScheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join Smart Parking today',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Registration Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role Selection
                        Text(
                          'I am a:',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildRoleCard(
                                  context,
                                  title: 'Driver',
                                  subtitle: 'Find parking spots',
                                  icon: Icons.drive_eta,
                                  isSelected: _role == UserRole.driver,
                                  onTap: () => setState(() {
                                    _role = UserRole.driver;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildRoleCard(
                                  context,
                                  title: 'Owner',
                                  subtitle: 'Rent out spaces',
                                  icon: Icons.business,
                                  isSelected: _role == UserRole.owner,
                                  onTap: () => setState(() {
                                    _role = UserRole.owner;
                                    _selectedCarModel = null; // Reset car model when switching to owner
                                  }),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                        // Name Field
                        TextFormField(
                          controller: _nameCtrl,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Email Field
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordCtrl,
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Phone Field
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter your phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Date of Birth Field
                        GestureDetector(
                          onTap: _selectDateOfBirth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              color: theme.colorScheme.surfaceVariant,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: theme.colorScheme.onSurface,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedDob != null
                                            ? 'Date of Birth (Age: ${_calculateAge(_selectedDob)})'
                                            : 'Date of Birth',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      if (_selectedDob != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _getFormattedDate(_selectedDob)!,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          'Select your date of birth',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down_outlined,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ],
                            ),
                          ),
                        ),

                          const SizedBox(height: 24),

                        // Car Model Selection (for drivers)
                        if (_role == UserRole.driver) ...[
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Car Model *',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  color: theme.colorScheme.surfaceVariant,
                                ),
                                  child: _loadingCarModels
                                      ? const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                              SizedBox(width: 16),
                                              Text('Loading car models...'),
                                            ],
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Search field
                                            TextFormField(
                                              onChanged: _filterCarModels,
                                              decoration: const InputDecoration(
                                                hintText: 'Search car models...',
                                                prefixIcon: Icon(Icons.search),
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                              ),
                                            ),
                                            if (_filteredCarModels.isNotEmpty) ...[
                                              const Divider(height: 1),
                                              // Car model dropdown
                                              DropdownButtonFormField<CarModel>(
                                                value: _selectedCarModel,
                                                decoration: const InputDecoration(
                                                  hintText: 'Select from filtered results',
                                                  prefixIcon: Icon(Icons.directions_car),
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 16,
                                                  ),
                                                ),
                                                isExpanded: true,
                                                menuMaxHeight: 200,
                                                items: _filteredCarModels.map((CarModel carModel) {
                                                  return DropdownMenuItem<CarModel>(
                                                    value: carModel,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            carModel.displayName,
                                                            style: theme.textTheme.bodyMedium?.copyWith(
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          Text(
                                                            carModel.dimensions,
                                                            style: theme.textTheme.bodySmall?.copyWith(
                                                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                            ),
                                                            maxLines: 1,
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
                                                  if (_role == UserRole.driver && value == null) {
                                                    return 'Please select your car model';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ] else if (_carSearchQuery.isNotEmpty) ...[
                                              const Divider(height: 1),
                                              Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: Text(
                                                  'No car models found for "$_carSearchQuery"',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                ),
                                if (_carModels.isEmpty && !_loadingCarModels)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_outlined, 
                                          color: theme.colorScheme.tertiary, 
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Failed to load car models. Please check your internet connection.',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.tertiary,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _loadCarModels,
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            'Retry', 
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          if (_selectedCarModel != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Car Details:',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Model: ${_selectedCarModel!.displayName}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Dimensions: ${_selectedCarModel!.dimensions}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Wheelbase: ${_selectedCarModel!.wheelbase.toStringAsFixed(1)}m',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        // Register Button
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const LoadingIndicator()
                              : const Text('Create Account'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Additional Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Secure registration',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? theme.colorScheme.primary.withOpacity(0.8)
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


