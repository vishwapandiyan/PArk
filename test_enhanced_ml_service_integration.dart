import 'package:http/http.dart' as http;
import 'lib/services/enhanced_ml_service.dart';
import 'lib/models/ml_request_model.dart';

/// Test the Enhanced ML Service integration
void main() async {
  print('🧪 Testing Enhanced ML Service Integration...');
  print('=' * 60);
  
  // Test 1: Test the service directly
  print('\n1️⃣ Testing Enhanced ML Service...');
  await EnhancedMLService.testMLAPI();
  
  // Test 2: Test with different scenarios
  print('\n2️⃣ Testing Different Scenarios...');
  await testDifferentScenarios();
  
  // Test 3: Test error handling
  print('\n3️⃣ Testing Error Handling...');
  await testErrorHandling();
  
  print('\n' + '=' * 60);
  print('🎯 Integration Test Complete!');
  print('=' * 60);
}

/// Test different request scenarios
Future<void> testDifferentScenarios() async {
  final scenarios = [
    {
      'name': 'Basic Request',
      'request': MLParkingRequest(
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
      )
    },
    {
      'name': 'With CCTV',
      'request': MLParkingRequest(
        area: 'pondy',
        latitude: 11.9323,
        longitude: 79.7924,
        wantsCctv: true,
        wantsCovered: false,
        wantsEv: false,
        wantsPremium: false,
        maxPrice: 1500,
        carDimensions: {'length': 4.2, 'width': 1.8, 'height': 1.6},
        carModelId: 'test_car_002',
      )
    },
    {
      'name': 'Premium Request',
      'request': MLParkingRequest(
        area: 'pondy',
        latitude: 11.9323,
        longitude: 79.7924,
        wantsCctv: false,
        wantsCovered: false,
        wantsEv: false,
        wantsPremium: true,
        maxPrice: 2000,
        carDimensions: {'length': 4.5, 'width': 1.9, 'height': 1.7},
        carModelId: 'test_car_003',
      )
    }
  ];
  
  for (final scenario in scenarios) {
    print('\n📋 Testing: ${scenario['name']}');
    
    try {
      final request = scenario['request'] as MLParkingRequest;
      final results = await EnhancedMLService.getMLRecommendations(request);
      print('   ✅ ${scenario['name']}: Found ${results.length} spots');
      
      if (results.isNotEmpty) {
        final first = results.first;
        print('     - First spot: ID=${first.id}, Score=${first.score.toStringAsFixed(3)}');
      }
    } catch (e) {
      print('   ❌ ${scenario['name']}: Error - $e');
    }
  }
}

/// Test error handling
Future<void> testErrorHandling() async {
  print('\n⚠️ Testing Error Handling...');
  
  // Test with invalid coordinates
  try {
    final invalidRequest = MLParkingRequest(
      area: 'pondy',
      latitude: 999.0, // Invalid latitude
      longitude: 79.7924,
      wantsCctv: false,
      wantsCovered: false,
      wantsEv: false,
      wantsPremium: false,
      maxPrice: 1000,
      carDimensions: {'length': 4.0, 'width': 1.7, 'height': 1.5},
      carModelId: 'test_car_error',
    );
    
    final results = await EnhancedMLService.getMLRecommendations(invalidRequest);
    print('   📊 Invalid coordinates: ${results.length} results (should be 0 or error)');
    
  } catch (e) {
    print('   ✅ Invalid coordinates: Correctly handled error - $e');
  }
  
  // Test with empty area
  try {
    final emptyAreaRequest = MLParkingRequest(
      area: '',
      latitude: 11.9323,
      longitude: 79.7924,
      wantsCctv: false,
      wantsCovered: false,
      wantsEv: false,
      wantsPremium: false,
      maxPrice: 1000,
      carDimensions: {'length': 4.0, 'width': 1.7, 'height': 1.5},
      carModelId: 'test_car_empty',
    );
    
    final results = await EnhancedMLService.getMLRecommendations(emptyAreaRequest);
    print('   📊 Empty area: ${results.length} results');
    
  } catch (e) {
    print('   ✅ Empty area: Correctly handled error - $e');
  }
}
