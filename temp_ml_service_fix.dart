  /// Get all parking spaces from database
  static Future<List<ParkingSpace>> _getAllParkingSpaces() async {
    try {
      return await ParkingSpaceService.getAllActiveParkingSpaces();
    } catch (e) {
      print('Error fetching all parking spaces: $e');
      return [];
    }
  }
