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
    return Scaffold(
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo and Title
                  Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_parking,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join Smart Parking today',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Registration Form
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign Up',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Role Selection
                          Text(
                            'I am a:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
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
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2.0,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 2.0,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

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
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email address',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2.0,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 2.0,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

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
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2.0,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 2.0,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

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
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2.0,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 2.0,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

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
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: 'Enter your phone number',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2.0,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 2.0,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Date of Birth Field
                          GestureDetector(
                            onTap: _selectDateOfBirth,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.grey[600],
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
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (_selectedDob != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _getFormattedDate(_selectedDob)!,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ] else
                                          Text(
                                            'Select your date of birth',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Car Model Selection (for drivers)
                          if (_role == UserRole.driver) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Car Model *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
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
                                                menuMaxHeight: 300,
                                                items: _filteredCarModels.map((CarModel carModel) {
                                                  return DropdownMenuItem<CarModel>(
                                                    value: carModel,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            carModel.displayName,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            carModel.dimensions,
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                            ),
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
                                                padding: const EdgeInsets.all(16.0),
                                                child: Text(
                                                  'No car models found for "$_carSearchQuery"',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
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
                                        Icon(Icons.warning, color: Colors.orange[600], size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Failed to load car models. Please check your internet connection.',
                                            style: TextStyle(
                                              color: Colors.orange[600],
                                              fontSize: 12,
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
                                          child: const Text('Retry', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (_selectedCarModel != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected Car Details:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Model: ${_selectedCarModel!.displayName}'),
                                    Text('Dimensions: ${_selectedCarModel!.dimensions}'),
                                    Text('Wheelbase: ${_selectedCarModel!.wheelbase.toStringAsFixed(1)}m'),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                          ],

                          // Register Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const LoadingIndicator()
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                            ),
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
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Additional Info
                  Text(
                    '🔐 Secure registration with Supabase authentication',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? Theme.of(context).primaryColor.withOpacity(0.8)
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


