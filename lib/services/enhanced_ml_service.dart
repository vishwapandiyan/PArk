import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ml_request_model.dart';
import '../services/parking_space_service.dart';
import '../models/parking_space_model.dart';

class EnhancedMLService {
  // TODO: Replace with your ML API endpoint
  static const String _baseUrl = 'YOUR_ML_API_URL_HERE';
  
  /// Get ML-based parking recommendations
  static Future<List<MLParkingResponse>> getMLRecommendations(
    MLParkingRequest request
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/parking-recommendation'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => MLParkingResponse.fromJson(json))
            .toList();
      } else {
        throw Exception('ML API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling ML API: $e');
      // Return empty list if ML fails - will trigger fallback
      return [];
    }
  }

  /// Get enhanced parking slots with ML scores and dynamic pricing
  static Future<List<EnhancedParkingSlot>> getEnhancedSlots({
    required String area,
    required double latitude,
    required double longitude,
    required bool wantsCctv,
    required bool wantsCovered,
    required bool wantsEv,
    required bool wantsPremium,
    required int maxPrice,
    required Map<String, double> carDimensions,
    required String carModelId,
  }) async {
    try {
      // Step 1: Get all parking spaces from database
      final allSpaces = await _getAllParkingSpaces();
      
      // Step 2: Filter by car dimensions (owner space vs car compatibility)
      final compatibleSpaces = _filterByDimensions(allSpaces, carDimensions);
      
      if (compatibleSpaces.isEmpty) {
        return [];
      }

      // Step 3: Call ML API for recommendations
      final mlRequest = MLParkingRequest(
        area: area,
        latitude: latitude,
        longitude: longitude,
        wantsCctv: wantsCctv,
        wantsCovered: wantsCovered,
        wantsEv: wantsEv,
        wantsPremium: wantsPremium,
        maxPrice: maxPrice,
        carDimensions: carDimensions,
        carModelId: carModelId,
      );

      final mlRecommendations = await getMLRecommendations(mlRequest);
      
      // Step 4: Merge ML results with database parking spaces
      final enhancedSlots = _mergeMLWithSpaces(compatibleSpaces, mlRecommendations);
      
      // Step 5: Sort by ML score (highest first)
      enhancedSlots.sort((a, b) => b.mlScore.compareTo(a.mlScore));
      
      return enhancedSlots;
      
    } catch (e) {
      print('Error in getEnhancedSlots: $e');
      // Fallback: return compatible spaces without ML scoring
      final allSpaces = await _getAllParkingSpaces();
      final compatibleSpaces = _filterByDimensions(allSpaces, carDimensions);
      return compatibleSpaces.map((space) => EnhancedParkingSlot.fromParkingSpace(space)).toList();
    }
  }

  /// Get all parking spaces from database
  static Future<List<ParkingSpace>> _getAllParkingSpaces() async {
    try {
      return await ParkingSpaceService.getAllActiveParkingSpaces();
    } catch (e) {
      print('Error fetching all parking spaces: $e');
      return [];
    }
  }

  /// Filter parking spaces by car dimensions compatibility
  static List<ParkingSpace> _filterByDimensions(
    List<ParkingSpace> spaces, 
    Map<String, double> carDimensions
  ) {
    return spaces.where((space) {
      // Check if car fits in the parking space
      // Add some margin for maneuvering (10cm on each side)
      const margin = 0.1; // 10cm in meters
      
      final carLength = carDimensions['length'] ?? 4.0;
      final carWidth = carDimensions['width'] ?? 1.7;
      final carHeight = carDimensions['height'] ?? 1.5;
      
      return space.length >= (carLength + margin) &&
             space.width >= (carWidth + margin) &&
             space.height >= (carHeight + margin);
    }).toList();
  }

  /// Merge ML recommendations with parking space data
  static List<EnhancedParkingSlot> _mergeMLWithSpaces(
    List<ParkingSpace> spaces,
    List<MLParkingResponse> mlRecommendations
  ) {
    final mlMap = <String, MLParkingResponse>{};
    for (final ml in mlRecommendations) {
      mlMap[ml.id] = ml;
    }

    return spaces.map((space) {
      final mlData = mlMap[space.id];
      return EnhancedParkingSlot.fromParkingSpace(
        space, 
        mlRecommendation: mlData
      );
    }).toList();
  }

  /// Apply filters to enhanced slots
  static List<EnhancedParkingSlot> applyFilters({
    required List<EnhancedParkingSlot> slots,
    int? maxPrice,
    String? timeFilter, // 'hourly', 'monthly', 'yearly'
    double? maxDistance,
    bool? requiresCctv,
    bool? requiresShelter,
    bool? requiresEV,
  }) {
    return slots.where((slot) {
      // Price filter
      if (maxPrice != null) {
        final currentPrice = slot.getCurrentPrice(timeFilter ?? 'hourly');
        if (currentPrice > maxPrice) return false;
      }

      // Facility filters
      if (requiresCctv == true && !slot.hasCctv) return false;
      if (requiresShelter == true && !slot.hasShelter) return false;
      if (requiresEV == true && !slot.hasEvCharging) return false;

      // Distance filter would need lat/lng calculation
      // TODO: Implement distance calculation if needed

      return true;
    }).toList();
  }
}

/// Enhanced parking slot that combines database data with ML insights
class EnhancedParkingSlot {
  final ParkingSpace parkingSpace;
  final MLParkingResponse? mlRecommendation;
  final double mlScore;

  const EnhancedParkingSlot({
    required this.parkingSpace,
    this.mlRecommendation,
    required this.mlScore,
  });

  factory EnhancedParkingSlot.fromParkingSpace(
    ParkingSpace space, {
    MLParkingResponse? mlRecommendation,
  }) {
    return EnhancedParkingSlot(
      parkingSpace: space,
      mlRecommendation: mlRecommendation,
      mlScore: mlRecommendation?.score ?? 0.0,
    );
  }

  /// Get current price with ML dynamic pricing if available
  int getCurrentPrice(String rentalMode) {
    // Check if ML provided dynamic pricing for this rental mode
    final dynamicPrice = mlRecommendation?.getDynamicPrice(rentalMode);
    if (dynamicPrice != null) {
      return dynamicPrice; // Use ML hiked price
    }
    
    // Fallback to owner's original price
    return parkingSpace.pricePerUnit;
  }

  /// Check if this slot has dynamic (hiked) pricing
  bool get hasDynamicPricing => mlRecommendation?.hasDynamicPricing ?? false;

  // Delegate properties to parking space
  String get id => parkingSpace.id;
  String get slotNumber => parkingSpace.slotNumber;
  String get placeName => parkingSpace.placeName;
  String get address => parkingSpace.address;
  double get latitude => parkingSpace.latitude;
  double get longitude => parkingSpace.longitude;
  bool get hasCctv => parkingSpace.hasCctv;
  bool get hasShelter => parkingSpace.hasShelter;
  bool get hasEvCharging => parkingSpace.hasEvCharging;
  bool get isPremium => parkingSpace.isPremium;
  String get rentalMode => parkingSpace.rentalMode;
}

