class ParkingTimeSlot {
  final String id;
  final String parkingSpaceId;
  final String slotStartTime; // HH:mm format
  final String slotEndTime; // HH:mm format
  final ParkingTimeSlotStatus status;
  final String rentalMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingTimeSlot({
    required this.id,
    required this.parkingSpaceId,
    required this.slotStartTime,
    required this.slotEndTime,
    required this.status,
    required this.rentalMode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParkingTimeSlot.fromJson(Map<String, dynamic> json) {
    return ParkingTimeSlot(
      id: json['id'],
      parkingSpaceId: json['parking_space_id'],
      slotStartTime: json['slot_start_time'],
      slotEndTime: json['slot_end_time'],
      status: ParkingTimeSlotStatus.fromString(json['status']),
      rentalMode: json['rental_mode'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parking_space_id': parkingSpaceId,
      'slot_start_time': slotStartTime,
      'slot_end_time': slotEndTime,
      'status': status.value,
      'rental_mode': rentalMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ParkingTimeSlot copyWith({
    String? id,
    String? parkingSpaceId,
    String? slotStartTime,
    String? slotEndTime,
    ParkingTimeSlotStatus? status,
    String? rentalMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParkingTimeSlot(
      id: id ?? this.id,
      parkingSpaceId: parkingSpaceId ?? this.parkingSpaceId,
      slotStartTime: slotStartTime ?? this.slotStartTime,
      slotEndTime: slotEndTime ?? this.slotEndTime,
      status: status ?? this.status,
      rentalMode: rentalMode ?? this.rentalMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display time range (e.g., "8:00 AM - 9:00 AM")
  String get displayTimeRange {
    return '$formattedStartTime - $formattedEndTime';
  }

  /// Get formatted start time (e.g., "8:00 AM")
  String get formattedStartTime {
    return _formatTime(slotStartTime);
  }

  /// Get formatted end time (e.g., "9:00 AM")
  String get formattedEndTime {
    return _formatTime(slotEndTime);
  }

  /// Duration in minutes
  int get durationMinutes {
    final start = _parseTime(slotStartTime);
    final end = _parseTime(slotEndTime);
    return end.difference(start).inMinutes;
  }

  /// Check if this slot is active (can be booked)
  bool get isActive => status == ParkingTimeSlotStatus.active;

  /// Check if this slot is paused by owner
  bool get isPaused => status == ParkingTimeSlotStatus.paused;

  /// Check if this slot is currently booked
  bool get isBooked => status == ParkingTimeSlotStatus.booked;

  /// Check if this slot can be paused/unpaused (not booked)
  bool get canTogglePause => status != ParkingTimeSlotStatus.booked;

  static DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static String _formatTime(String timeString) {
    final time = _parseTime(timeString);
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

enum ParkingTimeSlotStatus {
  active('active'),
  paused('paused'),
  booked('booked');

  const ParkingTimeSlotStatus(this.value);
  final String value;

  static ParkingTimeSlotStatus fromString(String value) {
    return ParkingTimeSlotStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ParkingTimeSlotStatus.active,
    );
  }
}
