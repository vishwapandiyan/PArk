class ParkingSpace {
  final String id;
  final String ownerId;
  final String slotNumber;
  final String placeName;
  final String address;
  final double latitude;
  final double longitude;
  final double length;
  final double width;
  final double height;
  final String? landProofUrl;
  final String? placeImageUrl;
  
  // Facilities
  final bool hasEvCharging;
  final bool hasShelter;
  final bool hasCctv;
  
  // Availability
  final String availableFrom; // time format
  final String availableTo; // time format
  final DateTime rentalDurationFrom;
  final DateTime rentalDurationTo;
  
  // Pricing
  final String rentalMode; // hourly, monthly, yearly
  final int pricePerUnit;
  final bool isPremium;
  
  // Status
  final bool isActive;
  final bool isPaused;
  
  // Stats
  final int totalBookings;
  final int currentBookings;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingSpace({
    required this.id,
    required this.ownerId,
    required this.slotNumber,
    required this.placeName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.length,
    required this.width,
    required this.height,
    this.landProofUrl,
    this.placeImageUrl,
    required this.hasEvCharging,
    required this.hasShelter,
    required this.hasCctv,
    required this.availableFrom,
    required this.availableTo,
    required this.rentalDurationFrom,
    required this.rentalDurationTo,
    required this.rentalMode,
    required this.pricePerUnit,
    required this.isPremium,
    required this.isActive,
    required this.isPaused,
    required this.totalBookings,
    required this.currentBookings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParkingSpace.fromJson(Map<String, dynamic> json) {
    return ParkingSpace(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      slotNumber: json['slot_number'] as String,
      placeName: json['place_name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      length: (json['length'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      landProofUrl: json['land_proof_url'] as String?,
      placeImageUrl: json['place_image_url'] as String?,
      hasEvCharging: json['has_ev_charging'] as bool? ?? false,
      hasShelter: json['has_shelter'] as bool? ?? false,
      hasCctv: json['has_cctv'] as bool? ?? false,
      availableFrom: json['available_from'] as String,
      availableTo: json['available_to'] as String,
      rentalDurationFrom: DateTime.parse(json['rental_duration_from'] as String),
      rentalDurationTo: DateTime.parse(json['rental_duration_to'] as String),
      rentalMode: json['rental_mode'] as String,
      pricePerUnit: json['price_per_unit'] as int,
      isPremium: json['is_premium'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isPaused: json['is_paused'] as bool? ?? false,
      totalBookings: json['total_bookings'] as int? ?? 0,
      currentBookings: json['current_bookings'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'slot_number': slotNumber,
      'place_name': placeName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'length': length,
      'width': width,
      'height': height,
      'land_proof_url': landProofUrl,
      'place_image_url': placeImageUrl,
      'has_ev_charging': hasEvCharging,
      'has_shelter': hasShelter,
      'has_cctv': hasCctv,
      'available_from': availableFrom,
      'available_to': availableTo,
      'rental_duration_from': rentalDurationFrom.toIso8601String().split('T')[0],
      'rental_duration_to': rentalDurationTo.toIso8601String().split('T')[0],
      'rental_mode': rentalMode,
      'price_per_unit': pricePerUnit,
      'is_premium': isPremium,
      'is_active': isActive,
      'is_paused': isPaused,
      'total_bookings': totalBookings,
      'current_bookings': currentBookings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  String get dimensions => '${length.toStringAsFixed(1)}m × ${width.toStringAsFixed(1)}m × ${height.toStringAsFixed(1)}m';
  
  List<String> get facilities {
    List<String> facilityList = [];
    if (hasEvCharging) facilityList.add('EV Charging');
    if (hasShelter) facilityList.add('Shelter');
    if (hasCctv) facilityList.add('CCTV');
    return facilityList;
  }

  String get facilityText => facilities.isEmpty ? 'Basic Parking' : facilities.join(', ');
  
  String get priceDisplay {
    switch (rentalMode) {
      case 'hourly':
        return '₹$pricePerUnit/hour';
      case 'monthly':
        return '₹$pricePerUnit/month';
      case 'yearly':
        return '₹$pricePerUnit/year';
      default:
        return '₹$pricePerUnit';
    }
  }

  String get statusText {
    if (isPaused) return 'Paused';
    if (!isActive) return 'Inactive';
    return 'Active';
  }

  ParkingSpace copyWith({
    String? id,
    String? ownerId,
    String? slotNumber,
    String? placeName,
    String? address,
    double? latitude,
    double? longitude,
    double? length,
    double? width,
    double? height,
    String? landProofUrl,
    String? placeImageUrl,
    bool? hasEvCharging,
    bool? hasShelter,
    bool? hasCctv,
    String? availableFrom,
    String? availableTo,
    DateTime? rentalDurationFrom,
    DateTime? rentalDurationTo,
    String? rentalMode,
    int? pricePerUnit,
    bool? isPremium,
    bool? isActive,
    bool? isPaused,
    int? totalBookings,
    int? currentBookings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParkingSpace(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      slotNumber: slotNumber ?? this.slotNumber,
      placeName: placeName ?? this.placeName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      landProofUrl: landProofUrl ?? this.landProofUrl,
      placeImageUrl: placeImageUrl ?? this.placeImageUrl,
      hasEvCharging: hasEvCharging ?? this.hasEvCharging,
      hasShelter: hasShelter ?? this.hasShelter,
      hasCctv: hasCctv ?? this.hasCctv,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      rentalDurationFrom: rentalDurationFrom ?? this.rentalDurationFrom,
      rentalDurationTo: rentalDurationTo ?? this.rentalDurationTo,
      rentalMode: rentalMode ?? this.rentalMode,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      isPremium: isPremium ?? this.isPremium,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      totalBookings: totalBookings ?? this.totalBookings,
      currentBookings: currentBookings ?? this.currentBookings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
