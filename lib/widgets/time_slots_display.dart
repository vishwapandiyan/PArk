import 'package:flutter/material.dart';
import '../models/parking_time_slot_model.dart';
import '../services/parking_time_slot_service.dart';

class TimeSlotsDisplay extends StatefulWidget {
  final List<ParkingTimeSlot> slots;
  final Function(List<ParkingTimeSlot>)? onSlotsUpdated;
  final bool isPreview; // True when showing preview in form, false when managing existing slots

  const TimeSlotsDisplay({
    super.key,
    required this.slots,
    this.onSlotsUpdated,
    this.isPreview = false,
  });

  @override
  State<TimeSlotsDisplay> createState() => _TimeSlotsDisplayState();
}

class _TimeSlotsDisplayState extends State<TimeSlotsDisplay> {
  late List<ParkingTimeSlot> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List.from(widget.slots);
  }

  @override
  void didUpdateWidget(TimeSlotsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slots != oldWidget.slots) {
      setState(() {
        _slots = List.from(widget.slots);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_slots.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildSlotsList(),
        if (!widget.isPreview && _slots.any((slot) => !slot.isBooked))
          _buildRegenerateButton(),
      ],
    );
  }

  Widget _buildHeader() {
    final totalSlots = _slots.length;
    final activeSlots = _slots.where((slot) => slot.isActive).length;
    final pausedSlots = _slots.where((slot) => slot.isPaused).length;
    final bookedSlots = _slots.where((slot) => slot.isBooked).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isPreview ? 'Generated Time Slots' : 'Time Slots Management',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip('Total', totalSlots, Colors.blue),
              const SizedBox(width: 8),
              _buildStatusChip('Active', activeSlots, Colors.green),
              const SizedBox(width: 8),
              _buildStatusChip('Paused', pausedSlots, Colors.orange),
              if (bookedSlots > 0) ...[
                const SizedBox(width: 8),
                _buildStatusChip('Booked', bookedSlots, Colors.red),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildSlotsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _slots.length,
        itemBuilder: (context, index) {
          return _buildSlotCard(_slots[index], index);
        },
      ),
    );
  }

  Widget _buildSlotCard(ParkingTimeSlot slot, int index) {
    final isPaused = slot.isPaused;
    final isBooked = slot.isBooked;

    Color cardColor;
    Color textColor;
    IconData statusIcon;
    String statusText;

    if (isBooked) {
      cardColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      statusIcon = Icons.event_busy;
      statusText = 'Booked';
    } else if (isPaused) {
      cardColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      statusIcon = Icons.pause_circle;
      statusText = 'Paused';
    } else {
      cardColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      statusIcon = Icons.check_circle;
      statusText = 'Active';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Slot number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Time range
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.displayTimeRange,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: textColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${slot.durationMinutes} min',
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action button (only for non-preview and non-booked slots)
          if (!widget.isPreview && slot.canTogglePause)
            _buildActionButton(slot),
        ],
      ),
    );
  }

  Widget _buildActionButton(ParkingTimeSlot slot) {
    final isPaused = slot.isPaused;
    
    return IconButton(
      onPressed: () => _toggleSlotStatus(slot),
      icon: Icon(
        isPaused ? Icons.play_circle : Icons.pause_circle,
        color: isPaused ? Colors.green : Colors.orange,
      ),
      tooltip: isPaused ? 'Activate slot' : 'Pause slot',
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No time slots generated',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set available hours and rental mode to generate slots',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegenerateButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showRegenerateDialog,
          icon: const Icon(Icons.refresh),
          label: const Text('Regenerate Slots'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSlotStatus(ParkingTimeSlot slot) async {
    final newStatus = slot.isPaused 
        ? ParkingTimeSlotStatus.active 
        : ParkingTimeSlotStatus.paused;

    final success = await ParkingTimeSlotService.toggleSlotStatus(slot.id, newStatus);
    
    if (success) {
      setState(() {
        final index = _slots.indexWhere((s) => s.id == slot.id);
        if (index != -1) {
          _slots[index] = slot.copyWith(status: newStatus);
        }
      });
      
      widget.onSlotsUpdated?.call(_slots);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            slot.isPaused 
                ? 'Slot activated successfully' 
                : 'Slot paused successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update slot status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRegenerateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Time Slots'),
        content: const Text(
          'This will delete all current slots (except booked ones) and generate new slots based on current settings.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // This would need to be handled by the parent widget
              // as it has access to the form data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please update available hours first, then slots will be regenerated automatically'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }
}
