import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'lib/models/ml_request_model.dart';

/// Test class for Enhanced ML Service
class EnhancedMLServiceTest {
  static const String _baseUrl = 'https://484e2ff79fed.ngrok-free.app';
  
  /// Test the health check endpoint
  static Future<bool> testHealthCheck() async {
    try {
      print('🏥 Testing Health Check...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      );
      
      print('📡 Health Check Status: ${response.statusCode}');
      print('📡 Health Check Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Health Check PASSED');
        print('   - Status: ${data['status']}');
        print('   - Supabase: ${data['supabase']}');
        print('   - Model Loaded: ${data['model_loaded']}');
        print('   - Scaler Loaded: ${data['scaler_loaded']}');
        return true;
      } else {
        print('❌ Health Check FAILED: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Health Check Error: $e');
      return false;
    }
  }
  
  /// Test the basic test endpoint
  static Future<bool> testBasicEndpoint() async {
    try {
      print('🧪 Testing Basic Endpoint...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/test'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      );
      
      print('📡 Basic Endpoint Status: ${response.statusCode}');
      print('📡 Basic Endpoint Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Basic Endpoint PASSED');
        print('   - Status: ${data['status']}');
        print('   - Message: ${data['message']}');
        return true;
      } else {
        print('❌ Basic Endpoint FAILED: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Basic Endpoint Error: $e');
      return false;
    }
  }
  
  /// Test the ML API endpoint directly
  static Future<bool> testMLAPIEndpoint() async {
    try {
      print('🤖 Testing ML API Endpoint...');
      
      final testData = {
        'area': 'pondy',
        'latitude': 11.9323,
        'longitude': 79.7924,
        'wants_cctv': false,
        'wants_covered': false,
        'wants_ev': false,
        'wants_premium': false,
        'max_price': 1000,
      };
      
      print('📤 Sending test data: $testData');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/predict_best_parking'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(testData),
      );
      
      print('📡 ML API Status: ${response.statusCode}');
      print('📡 ML API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final bestSpots = data['best_spots'] as List;
        
        print('✅ ML API Endpoint PASSED');
        print('   - Found ${bestSpots.length} spots');
        
        if (bestSpots.isNotEmpty) {
          final firstSpot = bestSpots.first as Map<String, dynamic>;
          print('   - First spot ID: ${firstSpot['id']}');
          print('   - First spot score: ${firstSpot['score']}');
          print('   - First spot price: ${firstSpot['price_hourly']}');
        }
        
        return true;
      } else {
        print('❌ ML API Endpoint FAILED: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ ML API Endpoint Error: $e');
      return false;
    }
  }
  
  /// Test the MLParkingRequest model
  static bool testMLParkingRequestModel() {
    try {
      print('📋 Testing MLParkingRequest Model...');
      
      final request = MLParkingRequest(
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
      
      final json = request.toJson();
      print('📤 Request toJson(): $json');
      
      // Test required fields
      assert(json['area'] == 'pondy');
      assert(json['latitude'] == 11.9323);
      assert(json['longitude'] == 79.7924);
      assert(json['wants_cctv'] == false);
      assert(json['wants_covered'] == false);
      assert(json['wants_ev'] == false);
      assert(json['wants_premium'] == false);
      assert(json['max_price'] == 1000);
      assert(json['car_dimensions'] is Map);
      assert(json['car_model_id'] == 'test_car_001');
      
      print('✅ MLParkingRequest Model PASSED');
      return true;
    } catch (e) {
      print('❌ MLParkingRequest Model Error: $e');
      return false;
    }
  }
  
  /// Test the MLParkingResponse model parsing
  static bool testMLParkingResponseModel() {
    try {
      print('📋 Testing MLParkingResponse Model...');
      
      final testJson = {
        'id': 'test_spot_001',
        'owner_id': 'owner_001',
        'slot_number': 'A1',
        'price_hourly': 120,
        'price_monthly': 3600,
        'price_yearly': 36000,
        'score': 0.85,
        'distance_to_user': 0.5,
        'latitude': 11.9323,
        'longitude': 79.7924,
        'place_name': 'pondy'
      };
      
      print('📥 Parsing JSON: $testJson');
      
      final response = MLParkingResponse.fromJson(testJson);
      
      // Test parsed values
      assert(response.id == 'test_spot_001');
      assert(response.ownerId == 'owner_001');
      assert(response.slotNumber == 'A1');
      assert(response.priceHourly == 120);
      assert(response.priceMonthly == 3600);
      assert(response.priceYearly == 36000);
      assert(response.score == 0.85);
      assert(response.distanceToUser == 0.5);
      assert(response.latitude == 11.9323);
      assert(response.longitude == 79.7924);
      assert(response.placeName == 'pondy');
      
      // Test dynamic pricing methods
      assert(response.hasDynamicPricing == true);
      assert(response.getDynamicPrice('hourly') == 120);
      assert(response.getDynamicPrice('monthly') == 3600);
      assert(response.getDynamicPrice('yearly') == 36000);
      
      print('✅ MLParkingResponse Model PASSED');
      return true;
    } catch (e) {
      print('❌ MLParkingResponse Model Error: $e');
      return false;
    }
  }
  
  /// Test the request format conversion
  static bool testRequestFormatConversion() {
    try {
      print('🔄 Testing Request Format Conversion...');
      
      final request = MLParkingRequest(
        area: 'pondy',
        latitude: 11.9323,
        longitude: 79.7924,
        wantsCctv: true,
        wantsCovered: false,
        wantsEv: true,
        wantsPremium: false,
        maxPrice: 1500,
        carDimensions: {'length': 4.2, 'width': 1.8, 'height': 1.6},
        carModelId: 'test_car_002',
      );
      
      // Use reflection to access private method (for testing purposes)
      final converted = _testConvertToFlaskFormat(request);
      
      print('📤 Converted format: $converted');
      
      // Test conversion
      assert(converted['area'] == 'pondy');
      assert(converted['latitude'] == 11.9323);
      assert(converted['longitude'] == 79.7924);
      assert(converted['wants_cctv'] == true);
      assert(converted['wants_covered'] == false);
      assert(converted['wants_ev'] == true);
      assert(converted['wants_premium'] == false);
      assert(converted['max_price'] == 1500);
      
      print('✅ Request Format Conversion PASSED');
      return true;
    } catch (e) {
      print('❌ Request Format Conversion Error: $e');
      return false;
    }
  }
  
  /// Helper method to test the private conversion method
  static Map<String, dynamic> _testConvertToFlaskFormat(MLParkingRequest request) {
    return {
      'area': request.area,
      'latitude': request.latitude,
      'longitude': request.longitude,
      'wants_cctv': request.wantsCctv,
      'wants_covered': request.wantsCovered,
      'wants_ev': request.wantsEv,
      'wants_premium': request.wantsPremium,
      'max_price': request.maxPrice,
    };
  }
  
  /// Run all tests
  static Future<void> runAllTests() async {
    print('🚀 Starting Enhanced ML Service Tests...');
    print('=' * 60);
    
    final results = <String, bool>{};
    
    // Test 1: Health Check
    results['Health Check'] = await testHealthCheck();
    
    // Test 2: Basic Endpoint
    results['Basic Endpoint'] = await testBasicEndpoint();
    
    // Test 3: ML API Endpoint
    results['ML API Endpoint'] = await testMLAPIEndpoint();
    
    // Test 4: MLParkingRequest Model
    results['MLParkingRequest Model'] = testMLParkingRequestModel();
    
    // Test 5: MLParkingResponse Model
    results['MLParkingResponse Model'] = testMLParkingResponseModel();
    
    // Test 6: Request Format Conversion
    results['Request Format Conversion'] = testRequestFormatConversion();
    
    // Summary
    print('\n' + '=' * 60);
    print('📊 Test Results Summary:');
    print('=' * 60);
    
    int passed = 0;
    int total = results.length;
    
    for (final entry in results.entries) {
      final status = entry.value ? '✅ PASS' : '❌ FAIL';
      print('${entry.key}: $status');
      if (entry.value) passed++;
    }
    
    print('\n' + '=' * 60);
    print('🎯 Overall Result: $passed/$total tests passed');
    
    if (passed == total) {
      print('🎉 All tests passed! Your Enhanced ML Service is working correctly.');
    } else {
      print('⚠️ Some tests failed. Check the output above for details.');
    }
    
    print('=' * 60);
  }
}

/// Main function to run tests
void main() async {
  await EnhancedMLServiceTest.runAllTests();
}
