import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../models/parking_slot_model.dart';
import '../../models/booking_model.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/auth_controller.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  ParkingSlotModel? _parkingSlot;
  BookingModel? _activeBooking;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNavigationData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadNavigationData() async {
    try {
      setState(() => _isLoading = true);

      // Get parking slot from route arguments
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is ParkingSlotModel) {
        _parkingSlot = args;

        // Load active booking for this slot
        await _loadActiveBooking();

        // Start timer if there's an active booking
        if (_activeBooking != null) {
          _startTimer();
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load navigation data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadActiveBooking() async {
    try {
      final authState = context.read<AuthController>().state;
      if (authState.profile?.id != null) {
        final bookingController = context.read<BookingController>();
        await bookingController.fetchForUser(authState.profile!.id);

        // Find active booking for this slot
        final activeBookings = bookingController.state.bookings
            .where(
              (b) =>
                  b.status == BookingStatus.active &&
                  b.slotId == _parkingSlot!.id,
            )
            .toList();

        if (activeBookings.isNotEmpty) {
          setState(() => _activeBooking = activeBookings.first);
        }
      }
    } catch (e) {
      print('Error loading active booking: $e');
    }
  }

  void _startTimer() {
    if (_activeBooking == null) return;

    // Calculate remaining time
    final now = DateTime.now();
    final endTime = _activeBooking!.endTime;

    if (endTime.isAfter(now)) {
      _remainingTime = endTime.difference(now);

      // Update timer every second
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            final newRemaining = endTime.difference(DateTime.now());
            if (newRemaining.isNegative) {
              _remainingTime = Duration.zero;
              timer.cancel();
              _onBookingExpired();
            } else {
              _remainingTime = newRemaining;
            }
          });
        }
      });
    }
  }

  void _onBookingExpired() {
    // Update booking status to completed
    if (_activeBooking != null) {
      // TODO: Update booking status in database
      setState(() => _activeBooking = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your parking session has expired!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Navigation')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_parkingSlot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Navigation')),
        body: const Center(child: Text('Parking slot not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadNavigationData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Booking Timer
            if (_activeBooking != null) ...[
              Card(
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Active Parking Session',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Time Remaining',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_remainingTime),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimeInfo(
                            'Start',
                            _activeBooking!.startTime
                                .toLocal()
                                .toString()
                                .substring(11, 16),
                            Icons.play_arrow,
                          ),
                          _buildTimeInfo(
                            'End',
                            _activeBooking!.endTime
                                .toLocal()
                                .toString()
                                .substring(11, 16),
                            Icons.stop,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Parking Spot Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_parking_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _parkingSlot!.address,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Details Grid
                    _buildDetailRow(
                      context,
                      'Dimensions',
                      _parkingSlot!.dimensions ?? 'Not specified',
                      Icons.straighten_outlined,
                    ),
                    _buildDetailRow(
                      context,
                      'Available Time',
                      '${_parkingSlot!.timeFrom ?? '--'} - ${_parkingSlot!.timeTo ?? '--'}',
                      Icons.access_time_outlined,
                    ),
                    _buildDetailRow(
                      context,
                      'Price per Hour',
                      '₹${(_parkingSlot!.pricing['hour'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'}',
                      Icons.attach_money_outlined,
                    ),
                    _buildDetailRow(
                      context,
                      'Rating',
                      '${_parkingSlot!.rating?.toStringAsFixed(1) ?? '-'} (${_parkingSlot!.reviewCount ?? 0} reviews)',
                      Icons.star_outlined,
                    ),
                    _buildDetailRow(
                      context,
                      'Location',
                      '${_parkingSlot!.latitude.toStringAsFixed(6)}, ${_parkingSlot!.longitude.toStringAsFixed(6)}',
                      Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Navigation Actions
            Text(
              'Navigation Options',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Column(
              children: [
                _buildActionButton(
                  context,
                  title: 'Open Maps Navigation',
                  subtitle: 'Navigate using your preferred maps app',
                  icon: Icons.map_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => _openMapsNavigation(),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context,
                  title: 'AR View',
                  subtitle: 'Use augmented reality to find your spot',
                  icon: Icons.view_in_ar_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed('/ar_view', arguments: _parkingSlot),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context,
                  title: 'Share Location',
                  subtitle: 'Share parking spot location with others',
                  icon: Icons.share_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => _shareLocation(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            if (_activeBooking != null) ...[
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _extendBooking(),
                      icon: const Icon(Icons.add_alarm_outlined),
                      label: const Text('Extend Time'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _endBookingEarly(),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('End Early'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_outlined,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: $value',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _openMapsNavigation() {
    // TODO: Implement maps navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening maps navigation...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareLocation() {
    // TODO: Implement location sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing location...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _extendBooking() {
    // TODO: Implement booking extension
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Extending booking time...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _endBookingEarly() {
    // TODO: Implement early booking termination
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ending booking early...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
