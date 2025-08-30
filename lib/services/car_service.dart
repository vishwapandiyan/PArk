import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import '../models/car_model.dart';

class CarService {
  static SupabaseClient get _client => AppSupabase.client;

  /// Fetch all car models from the database
  static Future<List<CarModel>> getAllCarModels() async {
    try {
      print('🚗 CarService: Fetching car models...');
      final response = await _client
          .from('car_models')
          .select()
          .order('brand, name');

      print('🚗 CarService: Raw response received: ${response.length} items');
      
      final carModels = (response as List)
          .map((json) => CarModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('🚗 CarService: Successfully parsed ${carModels.length} car models');
      print('🚗 CarService: First few models: ${carModels.take(3).map((c) => c.displayName).toList()}');
      
      return carModels;
    } catch (e) {
      print('❌ CarService: Error fetching car models: $e');
      throw Exception('Failed to fetch car models: $e');
    }
  }

  /// Fetch car models by brand
  static Future<List<CarModel>> getCarModelsByBrand(String brand) async {
    try {
      final response = await _client
          .from('car_models')
          .select()
          .eq('brand', brand)
          .order('name');

      return (response as List)
          .map((json) => CarModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch car models for brand $brand: $e');
    }
  }

  /// Fetch a specific car model by ID
  static Future<CarModel?> getCarModelById(String id) async {
    try {
      final response = await _client
          .from('car_models')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return CarModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch car model with ID $id: $e');
    }
  }

  /// Get unique car brands
  static Future<List<String>> getAllBrands() async {
    try {
      final response = await _client
          .from('car_models')
          .select('brand')
          .order('brand');

      final brands = (response as List)
          .map((json) => json['brand'] as String)
          .toSet()
          .toList();

      return brands;
    } catch (e) {
      throw Exception('Failed to fetch car brands: $e');
    }
  }

  /// Search car models by name or brand
  static Future<List<CarModel>> searchCarModels(String query) async {
    try {
      final response = await _client
          .from('car_models')
          .select()
          .or('name.ilike.%$query%,brand.ilike.%$query%')
          .order('brand, name');

      return (response as List)
          .map((json) => CarModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search car models: $e');
    }
  }
}
