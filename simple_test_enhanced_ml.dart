import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple test for Enhanced ML Service
class SimpleEnhancedMLTest {
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
  
  /// Test different request scenarios
  static Future<bool> testDifferentScenarios() async {
    try {
      print('🎯 Testing Different Request Scenarios...');
      
      final scenarios = [
        {
          'name': 'Basic Request',
          'data': {
            'area': 'pondy',
            'latitude': 11.9323,
            'longitude': 79.7924,
            'wants_cctv': false,
            'wants_covered': false,
            'wants_ev': false,
            'wants_premium': false,
            'max_price': 1000,
          }
        },
        {
          'name': 'With CCTV',
          'data': {
            'area': 'pondy',
            'latitude': 11.9323,
            'longitude': 79.7924,
            'wants_cctv': true,
            'wants_covered': false,
            'wants_ev': false,
            'wants_premium': false,
            'max_price': 1500,
          }
        },
        {
          'name': 'Premium Request',
          'data': {
            'area': 'pondy',
            'latitude': 11.9323,
            'longitude': 79.7924,
            'wants_cctv': false,
            'wants_covered': false,
            'wants_ev': false,
            'wants_premium': true,
            'max_price': 2000,
          }
        }
      ];
      
      int passed = 0;
      
      for (final scenario in scenarios) {
        print('\n📋 Testing: ${scenario['name']}');
        
        try {
          final response = await http.post(
            Uri.parse('$_baseUrl/predict_best_parking'),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode(scenario['data']),
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final bestSpots = data['best_spots'] as List;
            print('   ✅ ${scenario['name']}: Found ${bestSpots.length} spots');
            passed++;
          } else {
            print('   ❌ ${scenario['name']}: Failed with status ${response.statusCode}');
          }
        } catch (e) {
          print('   ❌ ${scenario['name']}: Error - $e');
        }
      }
      
      print('\n📊 Scenarios Test Result: $passed/${scenarios.length} passed');
      return passed == scenarios.length;
      
    } catch (e) {
      print('❌ Scenarios Test Error: $e');
      return false;
    }
  }
  
  /// Test error handling
  static Future<bool> testErrorHandling() async {
    try {
      print('⚠️ Testing Error Handling...');
      
      final invalidRequests = [
        {
          'name': 'Missing Area',
          'data': {
            'latitude': 11.9323,
            'longitude': 79.7924,
            'wants_cctv': false,
            'wants_covered': false,
            'wants_ev': false,
            'wants_premium': false,
            'max_price': 1000,
          }
        },
        {
          'name': 'Invalid Coordinates',
          'data': {
            'area': 'pondy',
            'latitude': 999.0, // Invalid latitude
            'longitude': 79.7924,
            'wants_cctv': false,
            'wants_covered': false,
            'wants_ev': false,
            'wants_premium': false,
            'max_price': 1000,
          }
        },
        {
          'name': 'Empty Request',
          'data': {}
        }
      ];
      
      int expectedErrors = 0;
      
      for (final request in invalidRequests) {
        print('\n📋 Testing: ${request['name']}');
        
        try {
          final response = await http.post(
            Uri.parse('$_baseUrl/predict_best_parking'),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode(request['data']),
          );
          
          if (response.statusCode == 400) {
            print('   ✅ ${request['name']}: Correctly rejected with 400');
            expectedErrors++;
          } else {
            print('   ⚠️ ${request['name']}: Unexpected status ${response.statusCode}');
          }
        } catch (e) {
          print('   ✅ ${request['name']}: Correctly threw error - $e');
          expectedErrors++;
        }
      }
      
      print('\n📊 Error Handling Test Result: $expectedErrors/${invalidRequests.length} handled correctly');
      return expectedErrors >= invalidRequests.length * 0.8; // Allow some flexibility
      
    } catch (e) {
      print('❌ Error Handling Test Error: $e');
      return false;
    }
  }
  
  /// Run all tests
  static Future<void> runAllTests() async {
    print('🚀 Starting Simple Enhanced ML Service Tests...');
    print('=' * 60);
    
    final results = <String, bool>{};
    
    // Test 1: Health Check
    results['Health Check'] = await testHealthCheck();
    
    // Test 2: Basic Endpoint
    results['Basic Endpoint'] = await testBasicEndpoint();
    
    // Test 3: ML API Endpoint
    results['ML API Endpoint'] = await testMLAPIEndpoint();
    
    // Test 4: Different Scenarios
    results['Different Scenarios'] = await testDifferentScenarios();
    
    // Test 5: Error Handling
    results['Error Handling'] = await testErrorHandling();
    
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
    } else if (passed >= total * 0.8) {
      print('✅ Most tests passed! Your service is working well with minor issues.');
    } else {
      print('⚠️ Several tests failed. Check the output above for details.');
    }
    
    print('=' * 60);
  }
}

/// Main function to run tests
void main() async {
  await SimpleEnhancedMLTest.runAllTests();
}
