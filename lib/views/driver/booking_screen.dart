import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/slot_controller.dart';
import '../../models/booking_request_model.dart';
import '../../services/ml_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/loading_indicator.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationCtrl = TextEditingController();
  final _departureCtrl = TextEditingController();
  final _carModelCtrl = TextEditingController();
  final _carDimensionsCtrl = TextEditingController();
  
  bool _needShelter = false;
  bool _needCCTV = false;
  bool _needEVCharging = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _departureCtrl.dispose();
    _carModelCtrl.dispose();
    _carDimensionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _findOptimalSlot() async {
    if (!_formKey.currentState!.validate()) return;

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

      // Convert slots to JSON format for ML service
      final availableSlots = slots.map((slot) => {
        'id': slot.id,
        'address': slot.address,
        'latitude': slot.latitude,
        'longitude': slot.longitude,
        'dimensions': slot.dimensions,
        'pricing': slot.pricing,
        'has_shelter': slot.hasShelter,
        'has_cctv': slot.hasCCTV,
        'has_ev_charging': slot.hasEVCharging,
        'rating': slot.rating,
        'review_count': slot.reviewCount,
      }).toList();

      final request = BookingRequestModel(
        destination: _destinationCtrl.text.trim(),
        departure: _departureCtrl.text.trim(),
        carDimensions: _carDimensionsCtrl.text.trim(),
        availableSlots: availableSlots,
        needShelter: _needShelter,
        needCCTV: _needCCTV,
        needEVCharging: _needEVCharging,
      );

      final result = await MLService.getOptimalParkingSlot(request);
      
      if (!mounted) return;

      // Show result
      _showBookingResult(result);
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

  void _showBookingResult(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Optimal Parking Slot Found! 🎯'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Address: ${result['address'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('💰 Price: \$${result['price']?.toString() ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('⭐ Rating: ${result['rating']?.toString() ?? 'N/A'}/5'),
            const SizedBox(height: 8),
            Text('📏 Dimensions: ${result['dimensions'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            if (result['has_shelter'] == true) 
              const Text('🏠 Has Shelter'),
            if (result['has_cctv'] == true) 
              const Text('📹 Has CCTV'),
            if (result['has_ev_charging'] == true) 
              const Text('🔌 Has EV Charging'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to slot detail or booking confirmation
            },
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
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
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Find Your Perfect Parking Spot',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tell us your preferences and we\'ll find the best parking option for you',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Destination & Departure Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📍 Location Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomInput(
                          controller: _destinationCtrl,
                          label: 'Destination',
                          hint: 'Where are you going?',
                          icon: Icons.location_on,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your destination';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomInput(
                          controller: _departureCtrl,
                          label: 'Departure Time',
                          hint: 'When will you leave?',
                          icon: Icons.access_time,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your departure time';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Vehicle Details Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚗 Vehicle Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomInput(
                          controller: _carModelCtrl,
                          label: 'Car Model',
                          hint: 'e.g., Toyota Camry, Honda Civic',
                          icon: Icons.directions_car,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your car model';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomInput(
                          controller: _carDimensionsCtrl,
                          label: 'Car Dimensions',
                          hint: 'e.g., 4.8m x 1.8m x 1.4m',
                          icon: Icons.straighten,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your car dimensions';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Parking Preferences Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚙️ Parking Preferences',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(Icons.home, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 12),
                              const Text('Covered Parking (Shelter)'),
                            ],
                          ),
                          subtitle: const Text('Protection from weather'),
                          value: _needShelter,
                          onChanged: (value) => setState(() => _needShelter = value!),
                          activeColor: Theme.of(context).primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(Icons.videocam, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 12),
                              const Text('CCTV Surveillance'),
                            ],
                          ),
                          subtitle: const Text('Enhanced security monitoring'),
                          value: _needCCTV,
                          onChanged: (value) => setState(() => _needCCTV = value!),
                          activeColor: Theme.of(context).primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(Icons.ev_station, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 12),
                              const Text('EV Charging'),
                            ],
                          ),
                          subtitle: const Text('Electric vehicle charging available'),
                          value: _needEVCharging,
                          onChanged: (value) => setState(() => _needEVCharging = value!),
                          activeColor: Theme.of(context).primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Find Parking Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _findOptimalSlot,
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search),
                              const SizedBox(width: 12),
                              Text(
                                'Find Optimal Parking',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Info Text
                Text(
                  '💡 Tip: We use AI to find the best parking spot based on your preferences, location, and available options.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


