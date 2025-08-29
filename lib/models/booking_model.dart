enum BookingStatus { pending, confirmed, active, completed }

class BookingModel {
  final String id;
  final String driverId;
  final String ownerId;
  final String slotId;
  final DateTime startTime;
  final DateTime endTime;
  final String duration; // e.g., "2 hours"
  final double price;
  final BookingStatus status;

  const BookingModel({
    required this.id,
    required this.driverId,
    required this.ownerId,
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.price,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      ownerId: json['owner_id'] as String,
      slotId: json['slot_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      duration: json['duration'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: _statusFromString(json['status'] as String?),
    );
  }

  static BookingStatus _statusFromString(String? value) {
    switch (value) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'active':
        return BookingStatus.active;
      case 'completed':
        return BookingStatus.completed;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'owner_id': ownerId,
      'slot_id': slotId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration': duration,
      'price': price,
      'status': status.name,
    };
  }
}


