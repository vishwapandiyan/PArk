import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import '../models/booking_model.dart';
import '../models/parking_time_slot_model.dart';

class BookingService {
  static SupabaseClient get _client => AppSupabase.client;

  /// Create a new booking
  static Future<BookingModel?> createBooking(BookingModel booking) async {
    try {
      final response = await _client
          .from('bookings')
          .insert({
            'driver_id': booking.driverId,
            'owner_id': booking.ownerId,
            'slot_id': booking.slotId,
            'start_time': booking.startTime.toIso8601String(),
            'end_time': booking.endTime.toIso8601String(),
            'duration': booking.duration,
            'price': booking.price,
            'status': booking.status.name,
          })
          .select()
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  /// Get all bookings for a user (driver or owner)
  static Future<List<BookingModel>> getBookingsForUser(
    String userId, {
    String? role,
  }) async {
    try {
      dynamic response;

      if (role == 'driver') {
        response = await _client
            .from('bookings')
            .select()
            .eq('driver_id', userId)
            .order('created_at', ascending: false);
      } else if (role == 'owner') {
        response = await _client
            .from('bookings')
            .select()
            .eq('owner_id', userId)
            .order('created_at', ascending: false);
      } else {
        // Get all bookings where user is either driver or owner
        response = await _client
            .from('bookings')
            .select()
            .or('driver_id.eq.$userId,owner_id.eq.$userId')
            .order('created_at', ascending: false);
      }

      return (response as List)
          .map((data) => BookingModel.fromJson(data))
          .toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  /// Get active bookings for a user
  static Future<List<BookingModel>> getActiveBookings(
    String userId, {
    String? role,
  }) async {
    try {
      final allBookings = await getBookingsForUser(userId, role: role);
      return allBookings
          .where((b) => b.status == BookingStatus.active)
          .toList();
    } catch (e) {
      print('Error fetching active bookings: $e');
      return [];
    }
  }

  /// Update booking status
  static Future<bool> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    try {
      await _client
          .from('bookings')
          .update({
            'status': newStatus.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  /// Cancel a booking
  static Future<bool> cancelBooking(String bookingId) async {
    try {
      // Get booking details first
      final response = await _client
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();

      if (response == null) return false;

      final booking = BookingModel.fromJson(response);

      // Update booking status to cancelled
      await updateBookingStatus(bookingId, BookingStatus.completed);

      // Mark the time slot as available again
      await _client
          .from('parking_time_slots')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', booking.slotId);

      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  /// Extend booking time
  static Future<bool> extendBooking(
    String bookingId,
    Duration extension,
  ) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();

      if (response == null) return false;

      final booking = BookingModel.fromJson(response);
      final newEndTime = booking.endTime.add(extension);

      // Update booking end time
      await _client
          .from('bookings')
          .update({
            'end_time': newEndTime.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      // Update corresponding time slot
      await _client
          .from('parking_time_slots')
          .update({
            'slot_end_time': newEndTime.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', booking.slotId);

      return true;
    } catch (e) {
      print('Error extending booking: $e');
      return false;
    }
  }

  /// Complete a booking (when session ends)
  static Future<bool> completeBooking(String bookingId) async {
    try {
      // Update booking status to completed
      await updateBookingStatus(bookingId, BookingStatus.completed);

      // Mark the time slot as available again
      final response = await _client
          .from('bookings')
          .select('slot_id')
          .eq('id', bookingId)
          .single();

      if (response != null) {
        await _client
            .from('parking_time_slots')
            .update({
              'status': 'active',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', response['slot_id']);
      }

      return true;
    } catch (e) {
      print('Error completing booking: $e');
      return false;
    }
  }

  /// Get booking statistics for an owner
  static Future<Map<String, dynamic>> getOwnerStats(String ownerId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('status, price, created_at')
          .eq('owner_id', ownerId);

      final bookings = response as List;

      int totalBookings = bookings.length;
      int activeBookings = bookings
          .where((b) => b['status'] == 'active')
          .length;
      int completedBookings = bookings
          .where((b) => b['status'] == 'completed')
          .length;
      double totalEarnings = bookings
          .where((b) => b['status'] == 'active' || b['status'] == 'completed')
          .fold(0.0, (sum, b) => sum + (b['price'] as num));

      return {
        'totalBookings': totalBookings,
        'activeBookings': activeBookings,
        'completedBookings': completedBookings,
        'totalEarnings': totalEarnings,
      };
    } catch (e) {
      print('Error fetching owner stats: $e');
      return {
        'totalBookings': 0,
        'activeBookings': 0,
        'completedBookings': 0,
        'totalEarnings': 0.0,
      };
    }
  }

  /// Get recent bookings for dashboard
  static Future<List<BookingModel>> getRecentBookings(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .or('driver_id.eq.$userId,owner_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => BookingModel.fromJson(data))
          .toList();
    } catch (e) {
      print('Error fetching recent bookings: $e');
      return [];
    }
  }

  /// Check if a slot is available for booking
  static Future<bool> isSlotAvailable(
    String slotId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('slot_id', slotId)
          .eq('status', 'active');

      final activeBookings = response as List;

      // Check for time conflicts
      for (final booking in activeBookings) {
        final bookingStart = DateTime.parse(booking['start_time']);
        final bookingEnd = DateTime.parse(booking['end_time']);

        // Check if there's any overlap
        if (startTime.isBefore(bookingEnd) && endTime.isAfter(bookingStart)) {
          return false; // Slot is not available
        }
      }

      return true;
    } catch (e) {
      print('Error checking slot availability: $e');
      return false;
    }
  }

  /// Get all bookings for a specific parking slot
  static Future<List<BookingModel>> getBookingsForSlot(String slotId) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('slot_id', slotId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => BookingModel.fromJson(data))
          .toList();
    } catch (e) {
      print('Error fetching bookings for slot: $e');
      return [];
    }
  }
}
