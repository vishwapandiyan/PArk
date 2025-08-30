import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import '../models/parking_space_model.dart';

class ParkingSpaceService {
  static SupabaseClient get _client => AppSupabase.client;

  /// Get all parking spaces for a specific owner
  static Future<List<ParkingSpace>> getOwnerParkingSpaces(String ownerId) async {
    try {
      print('🅿️ ParkingSpaceService: Fetching spaces for owner: $ownerId');
      
      final response = await _client
          .from('parking_spaces')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      print('🅿️ ParkingSpaceService: Raw response received: ${response.length} spaces');
      
      final spaces = (response as List)
          .map((json) => ParkingSpace.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('🅿️ ParkingSpaceService: Successfully parsed ${spaces.length} parking spaces');
      
      return spaces;
    } catch (e) {
      print('❌ ParkingSpaceService: Error fetching spaces: $e');
      throw Exception('Failed to fetch parking spaces: $e');
    }
  }

  /// Get all active parking spaces (for ML recommendations)
  static Future<List<ParkingSpace>> getAllActiveParkingSpaces() async {
    try {
      print('🅿️ ParkingSpaceService: Fetching all active parking spaces...');
      
      final response = await _client
          .from('parking_spaces')
          .select()
          .eq('is_active', true)
          .eq('is_paused', false)
          .order('created_at', ascending: false);

      print('🅿️ ParkingSpaceService: Raw response received: ${response.length} spaces');
      
      final spaces = (response as List)
          .map((json) => ParkingSpace.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('🅿️ ParkingSpaceService: Successfully parsed ${spaces.length} active parking spaces');
      
      return spaces;
    } catch (e) {
      print('❌ ParkingSpaceService: Error fetching all active spaces: $e');
      throw Exception('Failed to fetch all active parking spaces: $e');
    }
  }

  /// Create a new parking space
  static Future<ParkingSpace> createParkingSpace(Map<String, dynamic> spaceData) async {
    try {
      print('🅿️ ParkingSpaceService: Creating new parking space...');
      
      final response = await _client
          .from('parking_spaces')
          .insert(spaceData)
          .select()
          .single();

      print('🅿️ ParkingSpaceService: Parking space created successfully');
      
      return ParkingSpace.fromJson(response);
    } catch (e) {
      print('❌ ParkingSpaceService: Error creating space: $e');
      throw Exception('Failed to create parking space: $e');
    }
  }

  /// Update a parking space
  static Future<ParkingSpace> updateParkingSpace(String spaceId, Map<String, dynamic> updates) async {
    try {
      print('🅿️ ParkingSpaceService: Updating parking space: $spaceId');
      
      // Add updated_at timestamp
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client
          .from('parking_spaces')
          .update(updates)
          .eq('id', spaceId)
          .select()
          .single();

      print('🅿️ ParkingSpaceService: Parking space updated successfully');
      
      return ParkingSpace.fromJson(response);
    } catch (e) {
      print('❌ ParkingSpaceService: Error updating space: $e');
      throw Exception('Failed to update parking space: $e');
    }
  }

  /// Delete a parking space
  static Future<void> deleteParkingSpace(String spaceId) async {
    try {
      print('🅿️ ParkingSpaceService: Deleting parking space: $spaceId');
      
      await _client
          .from('parking_spaces')
          .delete()
          .eq('id', spaceId);

      print('🅿️ ParkingSpaceService: Parking space deleted successfully');
    } catch (e) {
      print('❌ ParkingSpaceService: Error deleting space: $e');
      throw Exception('Failed to delete parking space: $e');
    }
  }

  /// Toggle pause status of a parking space
  static Future<ParkingSpace> togglePauseSpace(String spaceId, bool isPaused) async {
    try {
      print('🅿️ ParkingSpaceService: ${isPaused ? 'Pausing' : 'Resuming'} space: $spaceId');
      
      return await updateParkingSpace(spaceId, {'is_paused': isPaused});
    } catch (e) {
      print('❌ ParkingSpaceService: Error toggling pause: $e');
      throw Exception('Failed to ${isPaused ? 'pause' : 'resume'} parking space: $e');
    }
  }

  /// Get a single parking space by ID
  static Future<ParkingSpace?> getParkingSpaceById(String spaceId) async {
    try {
      print('🅿️ ParkingSpaceService: Fetching space by ID: $spaceId');
      
      final response = await _client
          .from('parking_spaces')
          .select()
          .eq('id', spaceId)
          .maybeSingle();

      if (response == null) {
        print('🅿️ ParkingSpaceService: Space not found');
        return null;
      }

      print('🅿️ ParkingSpaceService: Space found');
      return ParkingSpace.fromJson(response);
    } catch (e) {
      print('❌ ParkingSpaceService: Error fetching space by ID: $e');
      throw Exception('Failed to fetch parking space: $e');
    }
  }

  /// Calculate premium pricing based on facilities
  static bool isPremiumSpace(bool hasEvCharging, bool hasShelter, bool hasCctv) {
    // Premium if shelter + any other facility
    return hasShelter && (hasEvCharging || hasCctv);
  }

  /// Get price ranges based on rental mode and premium status
  static Map<String, int> getPriceRanges(String rentalMode, bool isPremium) {
    if (isPremium) {
      switch (rentalMode) {
        case 'hourly':
          return {'min': 100, 'max': 150, 'step': 10};
        case 'monthly':
          return {'min': 19000, 'max': 24000, 'step': 500};
        case 'yearly':
          return {'min': 200000, 'max': 250000, 'step': 10000};
        default:
          return {'min': 100, 'max': 150, 'step': 10};
      }
    } else {
      switch (rentalMode) {
        case 'hourly':
          return {'min': 20, 'max': 60, 'step': 5};
        case 'monthly':
          return {'min': 5000, 'max': 7500, 'step': 500};
        case 'yearly':
          return {'min': 60000, 'max': 70000, 'step': 1000};
        default:
          return {'min': 20, 'max': 60, 'step': 5};
      }
    }
  }

  /// Generate list of price options for dropdown
  static List<int> getPriceOptions(String rentalMode, bool isPremium) {
    final ranges = getPriceRanges(rentalMode, isPremium);
    final List<int> options = [];
    
    // Extract values safely with null coalescing
    final int minPrice = ranges['min'] ?? 0;
    final int maxPrice = ranges['max'] ?? 0;
    final int stepPrice = ranges['step'] ?? 1;
    
    // Safety check to avoid infinite loop
    if (stepPrice <= 0) {
      throw Exception('Step value must be greater than 0');
    }
    
    for (int price = minPrice; price <= maxPrice; price += stepPrice) {
      options.add(price);
    }
    
    return options;
  }
}
