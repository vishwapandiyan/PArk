class ParkingSlotModel {
  final String id;
  final String ownerId;
  final String address;
  final double latitude;
  final double longitude;
  final String? dimensions; // LxW
  final List<String> photos;
  final Map<String, dynamic> pricing; // {hour: 2.5, day: 15, ...}
  final List<String> availableDurations; // [hour, day, month, year]
  final String? timeFrom; // HH:mm
  final String? timeTo; // HH:mm
  final double? rating;
  final int? reviewCount;

  const ParkingSlotModel({
    required this.id,
    required this.ownerId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.photos,
    required this.pricing,
    required this.availableDurations,
    this.dimensions,
    this.timeFrom,
    this.timeTo,
    this.rating,
    this.reviewCount,
  });

  factory ParkingSlotModel.fromJson(Map<String, dynamic> json) {
    return ParkingSlotModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      dimensions: json['dimensions'] as String?,
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      pricing: (json['pricing'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? <String, dynamic>{},
      availableDurations: (json['available_durations'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      timeFrom: json['time_from'] as String?,
      timeTo: json['time_to'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'dimensions': dimensions,
      'photos': photos,
      'pricing': pricing,
      'available_durations': availableDurations,
      'time_from': timeFrom,
      'time_to': timeTo,
      'rating': rating,
      'review_count': reviewCount,
    };
  }
}


