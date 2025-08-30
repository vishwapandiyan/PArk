class MLParkingRequest {
  final String area;
  final double latitude;
  final double longitude;
  final bool wantsCctv;
  final bool wantsCovered; // shelter
  final bool wantsEv;
  final bool wantsPremium;
  final int maxPrice;
  final Map<String, double> carDimensions; // For dimension filtering
  final String carModelId;

  const MLParkingRequest({
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.wantsCctv,
    required this.wantsCovered,
    required this.wantsEv,
    required this.wantsPremium,
    required this.maxPrice,
    required this.carDimensions,
    required this.carModelId,
  });

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'wants_cctv': wantsCctv,
      'wants_covered': wantsCovered,
      'wants_ev': wantsEv,
      'wants_premium': wantsPremium,
      'max_price': maxPrice,
      // Include car dimensions for server-side filtering
      'car_dimensions': carDimensions,
      'car_model_id': carModelId,
    };
  }

  /// Extract area from destination address
  static String extractAreaFromAddress(String address) {
    // Extract city/area from address
    // Examples:
    // "123 Main St, Pondicherry, Tamil Nadu" -> "Pondicherry"
    // "Brigade Road, Bangalore, Karnataka" -> "Bangalore"
    
    final parts = address.split(',');
    if (parts.length >= 2) {
      // Take the second-to-last part as the city/area
      final area = parts[parts.length - 2].trim();
      return area;
    } else if (parts.isNotEmpty) {
      // If only one part, use it
      return parts[0].trim();
    }
    return 'Unknown Area';
  }

  /// Convert car dimensions string to map
  static Map<String, double> parseCarDimensions(String dimensionsStr) {
    // Parse "4.2m x 1.8m x 1.5m" format
    try {
      final parts = dimensionsStr.split(' x ');
      if (parts.length >= 3) {
        return {
          'length': double.parse(parts[0].replaceAll('m', '')),
          'width': double.parse(parts[1].replaceAll('m', '')),
          'height': double.parse(parts[2].replaceAll('m', '')),
        };
      }
    } catch (e) {
      print('Error parsing car dimensions: $e');
    }
    
    // Default dimensions if parsing fails
    return {
      'length': 4.0,
      'width': 1.7,
      'height': 1.5,
    };
  }
}

class MLParkingResponse {
  final String id;
  final String ownerId;
  final String slotNumber;
  final int? priceHourly;   // ML dynamic price (nullable)
  final int? priceMonthly;  // ML dynamic price (nullable)
  final int? priceYearly;   // ML dynamic price (nullable)
  final double score;       // ML confidence score

  const MLParkingResponse({
    required this.id,
    required this.ownerId,
    required this.slotNumber,
    this.priceHourly,
    this.priceMonthly,
    this.priceYearly,
    required this.score,
  });

  factory MLParkingResponse.fromJson(Map<String, dynamic> json) {
    return MLParkingResponse(
      id: json['id'],
      ownerId: json['owner_id'],
      slotNumber: json['slot_number'],
      priceHourly: json['price_hourly']?.toInt(),
      priceMonthly: json['price_monthly']?.toInt(),
      priceYearly: json['price_yearly']?.toInt(),
      score: (json['score'] ?? 0.0).toDouble(),
    );
  }

  /// Check if ML provided dynamic pricing
  bool get hasDynamicPricing => 
      priceHourly != null || priceMonthly != null || priceYearly != null;

  /// Get the dynamic price for a specific rental mode
  int? getDynamicPrice(String rentalMode) {
    switch (rentalMode.toLowerCase()) {
      case 'hourly':
        return priceHourly;
      case 'monthly':
        return priceMonthly;
      case 'yearly':
        return priceYearly;
      default:
        return priceHourly;
    }
  }
}
