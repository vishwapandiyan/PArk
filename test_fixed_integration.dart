import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/services/enhanced_ml_service.dart';
import 'lib/models/ml_request_model.dart';

/// Test file to verify ML integration works after fixes
void main() async {
  print('🧪 Testing Fixed ML Integration...');
  print('=' * 60);
  
  try {
    // Test 1: Test the ML API directly
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
    
    // Test 2: Test the test endpoints
    print('\n2️⃣ Testing Flask server endpoints...');
    
    final baseUrl = 'https://484e2ff79fed.ngrok-free.app';
    
    // Test /test endpoint
    try {
      final testResponse = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      print('📡 /test endpoint: ${testResponse.statusCode} - ${testResponse.body}');
    } catch (e) {
      print('❌ /test endpoint failed: $e');
    }
    
    // Test /health endpoint
    try {
      final healthResponse = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      print('📡 /health endpoint: ${healthResponse.statusCode} - ${healthResponse.body}');
    } catch (e) {
      print('❌ /health endpoint failed: $e');
    }
    
  } catch (e) {
    print('❌ ML Integration Test Failed: $e');
    print('❌ Error type: ${e.runtimeType}');
  }
  
  print('\n' + '=' * 60);
  print('🎯 Test Complete!');
  print('=' * 60);
}
