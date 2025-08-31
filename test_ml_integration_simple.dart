import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/services/enhanced_ml_service.dart';
import 'lib/models/ml_request_model.dart';

/// Simple test for ML integration
void main() async {
  print('🧪 Testing ML Integration...');
  print('=' * 50);
  
  try {
    // Test the ML API directly
    print('1️⃣ Testing ML API call...');
    
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
    
    final results = await EnhancedMLService.getMLRecommendations(testRequest);
    
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
  
  print('\n' + '=' * 50);
  print('🎯 Test Complete!');
  print('=' * 50);
}
