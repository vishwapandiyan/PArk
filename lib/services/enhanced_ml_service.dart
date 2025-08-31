import 'dart:convert';
import 'dart:math' as m;
import 'package:http/http.dart' as http;
import '../models/ml_request_model.dart';
import '../services/parking_space_service.dart';
import '../models/parking_space_model.dart';

class EnhancedMLService {
  // Fixed URL (remove endpoint)
  static const String _baseUrl = 'https://484e2ff79fed.ngrok-free.app';
  
  /// Get ML-based parking recommendations
  static Future<List<MLParkingResponse>> getMLRecommendations(
    MLParkingRequest request
  ) async {
    try {
      print('🚀 Calling ML API with request: ${request.toJson()}');
      print('🌐 API URL: $_baseUrl/predict_best_parking');
      
      final requestBody = _convertToFlaskFormat(request);
      print('📤 Request body being sent to Flask: $requestBody');
      print('📤 Request body JSON: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/predict_best_parking'), // Correct endpoint
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Add ngrok header
        },
        body: jsonEncode(requestBody), // Convert format
      );

      print('📡 ML API Response Status: ${response.statusCode}');
      print('📡 ML API Response Headers: ${response.headers}');
      print('📡 ML API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('📊 Parsed response data: $data');
        
        if (!data.containsKey('best_spots')) {
          print('⚠️ Response missing "best_spots" key. Available keys: ${data.keys.toList()}');
          return [];
        }
        
        final bestSpots = data['best_spots'] as List; // Fix response parsing
        print('🎯 Found ${bestSpots.length} best spots from ML API');
        
        final results = bestSpots
            .map((json) {
              print('🔄 Parsing ML spot: $json');
              try {
                return MLParkingResponse.fromJson(json);
              } catch (e) {
                print('❌ Error parsing ML spot $json: $e');
                rethrow;
              }
            })
            .toList();
        
        print('✅ Successfully parsed ${results.length} ML responses');
        return results;
      } else {
        print('❌ ML API Error: ${response.statusCode} - ${response.body}');
        print('❌ Response headers: ${response.headers}');
        throw Exception('ML API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error calling ML API: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is http.ClientException) {
        print('❌ Network error details: ${e.message}');
      }
      // Return empty list if ML fails - will trigger fallback
      return [];
    }
  }

  /// Convert MLParkingRequest to Flask API format
  /// Note: Flask ML model only needs these specific fields
  static Map<String, dynamic> _convertToFlaskFormat(MLParkingRequest request) {
    final flaskRequest = {
      'area': request.area,
      'latitude': request.latitude,
      'longitude': request.longitude,
      'wants_cctv': request.wantsCctv,
      'wants_covered': request.wantsCovered,
      'wants_ev': request.wantsEv,
      'wants_premium': request.wantsPremium,
      'max_price': request.maxPrice,
    };
    
    print('🔄 Converting to Flask format: $flaskRequest');
    return flaskRequest;
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
      print('🎯 Starting Enhanced ML Service for area: $area');
      print('📍 Location: $latitude, $longitude');
      print('🚗 Car dimensions: $carDimensions');
      print('💰 Max price: $maxPrice');
      
      // Step 1: Get all parking spaces from database
      print('📊 Step 1: Fetching all parking spaces from database...');
      final allSpaces = await _getAllParkingSpaces();
      print('📊 Found ${allSpaces.length} total parking spaces');
      
      // Step 2: Filter by car dimensions (owner space vs car compatibility)
      print('🔍 Step 2: Filtering by car dimensions...');
      final compatibleSpaces = _filterByDimensions(allSpaces, carDimensions);
      print('🔍 Found ${compatibleSpaces.length} dimensionally compatible spaces');
      
      if (compatibleSpaces.isEmpty) {
        print('⚠️ No dimensionally compatible spaces found');
        return [];
      }

      // Step 3: Call ML API for recommendations
      print('🤖 Step 3: Calling ML API for recommendations...');
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
      print('🤖 ML API returned ${mlRecommendations.length} recommendations');
      
      // Step 4: Merge ML results with database parking spaces
      print('🔄 Step 4: Merging ML results with database spaces...');
      final enhancedSlots = _mergeMLWithSpaces(compatibleSpaces, mlRecommendations);
      print('🔄 Created ${enhancedSlots.length} enhanced slots');
      
      // Step 5: Sort by ML score (highest first)
      print('📈 Step 5: Sorting by ML score...');
      enhancedSlots.sort((a, b) => b.mlScore.compareTo(a.mlScore));
      
      print('✅ Enhanced ML Service completed successfully!');
      return enhancedSlots;
      
    } catch (e) {
      print('❌ Error in getEnhancedSlots: $e');
      print('🔄 Falling back to basic dimension filtering...');
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
    print('🔄 Merging ${spaces.length} parking spaces with ${mlRecommendations.length} ML recommendations');
    
    // Create a map of ML recommendations by ID for quick lookup
    final mlMap = <String, MLParkingResponse>{};
    for (final ml in mlRecommendations) {
      mlMap[ml.id] = ml;
      print('📊 ML recommendation ID: ${ml.id}, Score: ${ml.score}');
    }
    
    // Create a map of parking spaces by ID for quick lookup
    final spaceMap = <String, ParkingSpace>{};
    for (final space in spaces) {
      spaceMap[space.id] = space;
      print('🏠 Parking space ID: ${space.id}, Name: ${space.placeName}');
    }

    // Try to match by ID first, then by other criteria if needed
    return spaces.map((space) {
      MLParkingResponse? mlData = mlMap[space.id];
      
      // If no direct ID match, try to find by location or other criteria
      if (mlData == null && mlRecommendations.isNotEmpty) {
        // Find the best matching ML recommendation based on location
        MLParkingResponse? bestMatch;
        double bestDistance = double.infinity;
        
        for (final ml in mlRecommendations) {
          if (ml.latitude != null && ml.longitude != null) {
            final distance = _calculateDistance(
              space.latitude, 
              space.longitude, 
              ml.latitude!, 
              ml.longitude!
            );
            if (distance < bestDistance) {
              bestDistance = distance;
              bestMatch = ml;
            }
          }
        }
        
        if (bestMatch != null && bestDistance < 0.1) { // Within 100m
          mlData = bestMatch;
          print('📍 Matched space ${space.id} with ML recommendation ${bestMatch.id} by location (distance: ${bestDistance.toStringAsFixed(3)}km)');
        }
      }
      
      if (mlData != null) {
        print('✅ Successfully matched space ${space.id} with ML recommendation ${mlData.id}');
      } else {
        print('⚠️ No ML recommendation found for space ${space.id}');
      }
      
      return EnhancedParkingSlot.fromParkingSpace(
        space, 
        mlRecommendation: mlData
      );
    }).toList();
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in kilometers
    
    final lat1Rad = lat1 * (m.pi / 180);
    final lon1Rad = lon1 * (m.pi / 180);
    final lat2Rad = lat2 * (m.pi / 180);
    final lon2Rad = lon2 * (m.pi / 180);
    
    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;
    
    final a = m.sin(dLat / 2) * m.sin(dLat / 2) + 
               m.cos(lat1Rad) * m.cos(lat2Rad) * m.sin(dLon / 2) * m.sin(dLon / 2);
    final c = 2 * m.atan(m.sqrt(a) / m.sqrt(1 - a));
    
    return R * c;
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

  /// Test method to verify ML API integration
  static Future<void> testMLAPI() async {
    print('🧪 Testing ML API Integration...');
    
    try {
      final testRequest = MLParkingRequest(
        area: 'pondy',
        latitude: 11.9323,
        longitude: 79.7924,
        wantsCctv: false,
        wantsCovered: false,
        wantsEv: false,
        wantsPremium: false,
        maxPrice: 1000,
        carDimensions: {'length': 4.0, 'width': 1.7, 'height': 1.5},
        carModelId: 'test_car_001',
      );
      
      print('📋 Test request: ${testRequest.toJson()}');
      
      final results = await getMLRecommendations(testRequest);
      
      print('✅ ML API Test Result: ${results.length} recommendations received');
      
      if (results.isNotEmpty) {
        final first = results.first;
        print('   - First recommendation:');
        print('     ID: ${first.id}');
        print('     Score: ${first.score}');
        print('     Price: ${first.priceHourly}');
        print('     Distance: ${first.distanceToUser}');
      }
      
    } catch (e) {
      print('❌ ML API Test Failed: $e');
    }
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
  
  // Add missing dimension properties
  double get length => parkingSpace.length;
  double get width => parkingSpace.width;
  double get height => parkingSpace.height;
}