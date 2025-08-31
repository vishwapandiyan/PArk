import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/parking_slot_model.dart';
import '../../models/parking_time_slot_model.dart';
import '../../models/booking_model.dart';
import '../../models/wallet_model.dart';
import '../../services/parking_time_slot_service.dart';
import '../../services/wallet_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/booking_controller.dart';

class SlotDetailScreen extends StatefulWidget {
  const SlotDetailScreen({super.key});

  @override
  State<SlotDetailScreen> createState() => _SlotDetailScreenState();
}

class _SlotDetailScreenState extends State<SlotDetailScreen> {
  ParkingSlotModel? _slot;
  List<ParkingTimeSlot> _availableSlots = [];
  List<ParkingTimeSlot> _selectedSlots = [];
  Wallet? _userWallet;
  bool _isLoading = true;
  bool _isGeneratingSlots = false;
  bool _isBooking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSlotData();
  }

  Future<void> _loadSlotData() async {
    try {
      setState(() => _isLoading = true);

      // Get slot from route arguments
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is ParkingSlotModel) {
        _slot = args;

        // Load available time slots using the parking space ID
        print('🔍 Loading time slots for parking space ID: ${_slot!.id}');

        // First check if any time slots exist for this parking space
        final hasSlots = await ParkingTimeSlotService.hasTimeSlots(_slot!.id);
        print('🔍 Time slots exist for this parking space: $hasSlots');

        // Get all time slots to see what's available
        final allSlots = await ParkingTimeSlotService.getAllTimeSlots(
          _slot!.id,
        );
        print('🔍 Total time slots found: ${allSlots.length}');

        final slots = await ParkingTimeSlotService.getActiveSlots(_slot!.id);
        print('🔍 Found ${slots.length} available time slots');

        // Load user wallet
        final authState = context.read<AuthController>().state;
        if (authState.profile?.id != null) {
          _userWallet = await WalletService.getUserWallet(
            authState.profile!.id,
          );
        }

        setState(() {
          _availableSlots = slots;
          _isLoading = false;
        });

        // Show message if no slots were found even after generation attempt
        if (slots.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Time slots are being generated for this parking space. Please refresh in a moment.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load slot data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateTimeSlots() async {
    if (_slot == null) return;

    try {
      setState(() => _isGeneratingSlots = true);

      // This will trigger the automatic generation in the service
      final slots = await ParkingTimeSlotService.getActiveSlots(_slot!.id);

      setState(() {
        _availableSlots = slots;
        _isGeneratingSlots = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${slots.length} time slots successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingSlots = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate time slots: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSlotSelection(ParkingTimeSlot slot) {
    setState(() {
      if (_selectedSlots.contains(slot)) {
        _selectedSlots.remove(slot);
      } else {
        _selectedSlots.add(slot);
      }
    });
  }

  double get _totalPrice {
    if (_slot == null) return 0;
    final hourlyPrice = (_slot!.pricing['hour'] as num?)?.toDouble() ?? 0;
    return _selectedSlots.length * hourlyPrice;
  }

  bool get _canBook {
    return _selectedSlots.isNotEmpty &&
        _userWallet != null &&
        _userWallet!.balance >= _totalPrice;
  }

  Future<void> _showBookingConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected Slots: ${_selectedSlots.length}'),
            const SizedBox(height: 8),
            Text('Total Price: ₹${_totalPrice.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Text('Wallet Balance: ₹${_userWallet?.balance ?? 0}'),
            const SizedBox(height: 8),
            Text(
              'Balance After Booking: ₹${(_userWallet?.balance ?? 0) - _totalPrice}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _processBooking();
    }
  }

  Future<void> _processBooking() async {
    if (!_canBook) return;

    setState(() => _isBooking = true);

    try {
      final authState = context.read<AuthController>().state;
      if (authState.profile?.id == null)
        throw Exception('User not authenticated');

      // Deduct money from wallet
      final success = await WalletService.deductMoney(
        authState.profile!.id,
        _totalPrice.toInt(),
        'Parking booking for ${_selectedSlots.length} slot(s)',
        referenceId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      if (!success) {
        throw Exception('Insufficient wallet balance');
      }

      // Create bookings for each selected slot
      final bookingController = context.read<BookingController>();

      for (final slot in _selectedSlots) {
        final startTime = DateTime.parse(slot.slotStartTime);
        final endTime = DateTime.parse(slot.slotEndTime);

        final booking = BookingModel(
          id: '', // Will be generated by Supabase
          driverId: authState.profile!.id,
          ownerId: _slot!.ownerId,
          slotId: slot.id,
          startTime: startTime,
          endTime: endTime,
          duration: '${slot.rentalMode}',
          price: (_slot!.pricing['hour'] as num?)?.toDouble() ?? 0,
          status: BookingStatus.confirmed,
        );

        await bookingController.createBooking(booking);
      }

      // Mark slots as booked
      for (final slot in _selectedSlots) {
        await ParkingTimeSlotService.bookSlot(slot.id);
      }

      // Refresh wallet data
      await _loadSlotData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully booked ${_selectedSlots.length} slot(s)!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to dashboard
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Booking failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Slot Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_slot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Slot Details')),
        body: const Center(child: Text('Slot not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Slot Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_parking_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _slot!.address,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Details Grid
                    _buildDetailRow(
                      context,
                      'Dimensions',
                      _slot!.dimensions ?? 'Not specified',
                      Icons.straighten_outlined,
                    ),
                    _buildDetailRow(
                      context,
                      'Available Time',
                      '${_slot!.timeFrom ?? '--'} - ${_slot!.timeTo ?? '--'}',
                      Icons.access_time_outlined,
                    ),
                    _buildDetailRow(
                      context,
                      'Price per Hour',
                      '₹${(_slot!.pricing['hour'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'}',
                      Icons.attach_money_outlined,
                    ),
                    _buildDetailRow(
                      context,
                      'Rating',
                      '${_slot!.rating?.toStringAsFixed(1) ?? '-'} (${_slot!.reviewCount ?? 0} reviews)',
                      Icons.star_outlined,
                    ),
                    _buildDetailRow(
                      context,
                      'Location',
                      '${_slot!.latitude.toStringAsFixed(6)}, ${_slot!.longitude.toStringAsFixed(6)}',
                      Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Wallet Information
            if (_userWallet != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wallet Balance',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '₹${_userWallet!.balance}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Available Time Slots
            Text(
              'Available Time Slots',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            if (_availableSlots.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        if (_isGeneratingSlots)
                          const CircularProgressIndicator()
                        else
                          Icon(
                            Icons.schedule_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _isGeneratingSlots
                              ? 'Generating time slots...'
                              : 'No available time slots found',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isGeneratingSlots
                              ? 'Please wait while we create time slots for this parking space.'
                              : 'Time slots are being generated for this parking space. Please try refreshing in a moment.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (!_isGeneratingSlots)
                          ElevatedButton.icon(
                            onPressed: _generateTimeSlots,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Generate Time Slots'),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _availableSlots
                    .map((slot) => _buildSlotCard(slot))
                    .toList(),
              ),

            const SizedBox(height: 24),

            // Selection Summary
            if (_selectedSlots.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selection Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Selected Slots: ${_selectedSlots.length}'),
                      Text('Total Price: ₹${_totalPrice.toStringAsFixed(0)}'),
                      if (_userWallet != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Balance After Booking: ₹${(_userWallet!.balance - _totalPrice)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _canBook ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed('/navigation', arguments: _slot),
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed('/ar_view', arguments: _slot),
                    icon: const Icon(Icons.view_in_ar_outlined),
                    label: const Text('AR View'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Book Now Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canBook ? _showBookingConfirmation : null,
                icon: _isBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.book_online_outlined),
                label: Text(_isBooking ? 'Processing...' : 'Book Now'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _canBook
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
            ),

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

  Widget _buildSlotCard(ParkingTimeSlot slot) {
    final isSelected = _selectedSlots.contains(slot);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _toggleSlotSelection(slot),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.12),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${slot.slotStartTime} - ${slot.slotEndTime}',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      '${slot.rentalMode} • ₹${(_slot!.pricing['hour'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
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
}
