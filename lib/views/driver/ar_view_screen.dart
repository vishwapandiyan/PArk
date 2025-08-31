import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/parking_slot_model.dart';

class ARViewScreen extends StatefulWidget {
  const ARViewScreen({super.key});

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  ParkingSlotModel? _parkingSlot;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  double? _distanceToSpot;
  bool _isWithin10Meters = false;

  @override
  void initState() {
    super.initState();
    _initializeAR();
  }

  Future<void> _initializeAR() async {
    try {
      setState(() => _isLoading = true);

      // Get parking slot from route arguments
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is ParkingSlotModel) {
        _parkingSlot = args;

        // Get current location
        await _getCurrentLocation();

        // Calculate distance
        if (_currentPosition != null) {
          _calculateDistance();
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize AR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions
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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentPosition = position);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to get location: $e');
    }
  }

  void _calculateDistance() {
    if (_currentPosition == null || _parkingSlot == null) return;

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _parkingSlot!.latitude,
      _parkingSlot!.longitude,
    );

    setState(() {
      _distanceToSpot = distance;
      _isWithin10Meters = distance <= 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AR View'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_parkingSlot == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AR View'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'Parking slot not found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR View'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _initializeAR,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // AR Camera Background (simulated)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade900, Colors.black],
              ),
            ),
          ),

          // Distance Information
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: _isWithin10Meters ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distance to Parking Spot',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _distanceToSpot != null
                              ? '${_distanceToSpot!.toStringAsFixed(1)} meters'
                              : 'Calculating...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isWithin10Meters ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isWithin10Meters ? 'NEAR' : 'FAR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AR Parking Spot Indicator
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Parking Spot Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _isWithin10Meters
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isWithin10Meters ? Colors.green : Colors.orange,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.local_parking,
                    size: 60,
                    color: _isWithin10Meters ? Colors.green : Colors.orange,
                  ),
                ),

                const SizedBox(height: 20),

                // Direction Arrow (only show when within 10 meters)
                if (_isWithin10Meters) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PARKING SPOT AHEAD!',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You are within 10 meters',
                          style: TextStyle(
                            color: Colors.green.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          color: Colors.orange,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Continue Walking',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You are ${_distanceToSpot?.toStringAsFixed(1) ?? "..."} meters away',
                          style: TextStyle(
                            color: Colors.orange.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Parking Spot Details
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_parking_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _parkingSlot!.address,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_parkingSlot!.dimensions != null) ...[
                    Text(
                      'Dimensions: ${_parkingSlot!.dimensions}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (_parkingSlot!.timeFrom != null &&
                      _parkingSlot!.timeTo != null) ...[
                    Text(
                      'Available: ${_parkingSlot!.timeFrom} - ${_parkingSlot!.timeTo}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'Coordinates: ${_parkingSlot!.latitude.toStringAsFixed(6)}, ${_parkingSlot!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Error Message
          if (_errorMessage != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _errorMessage = null),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
