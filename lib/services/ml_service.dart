import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking_request_model.dart';

class MLService {
  // Replace with your Flask backend URL
  static const String _baseUrl = 'http://10.0.2.2:5000'; // For Android emulator
  // For iOS simulator use: 'http://localhost:5000'
  // For physical device use your computer's IP address: 'http://192.168.1.100:5000'
  
  static Future<Map<String, dynamic>> getOptimalParkingSlot(BookingRequestModel request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/parking-recommendation'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to get parking recommendation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to ML service: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getRankedSlots(BookingRequestModel request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/rank-slots'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to rank slots: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to ML service: $e');
    }
  }
}
