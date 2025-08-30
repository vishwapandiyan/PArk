# Read the enhanced ML service file
$content = Get-Content 'lib/services/enhanced_ml_service.dart' -Raw

# Replace the _getAllParkingSpaces method
$oldMethod = @'
  /// Get all parking spaces from database
  static Future<List<ParkingSpace>> _getAllParkingSpaces() async {
    // This would need to be implemented in ParkingSpaceService
    // For now, we'll call the owner-specific method
    try {
      // We need a method to get ALL parking spaces, not just owner-specific
      // This is a placeholder - you'll need to add this method to ParkingSpaceService
      return [];
    } catch (e) {
      print('Error fetching all parking spaces: $e');
      return [];
    }
  }
'@

$newMethod = @'
  /// Get all parking spaces from database
  static Future<List<ParkingSpace>> _getAllParkingSpaces() async {
    try {
      return await ParkingSpaceService.getAllActiveParkingSpaces();
    } catch (e) {
      print('Error fetching all parking spaces: $e');
      return [];
    }
  }
'@

# Replace and save
$content = $content -replace [regex]::Escape($oldMethod), $newMethod
$content | Set-Content 'lib/services/enhanced_ml_service.dart'

Write-Host "Fixed enhanced ML service to use the correct method!"
