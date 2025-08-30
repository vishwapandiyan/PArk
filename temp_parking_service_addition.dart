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
