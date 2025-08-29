import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import '../models/booking_model.dart';

class BookingState extends Equatable {
  final bool isLoading;
  final List<BookingModel> bookings;
  final String? errorMessage;

  const BookingState({
    this.isLoading = false,
    this.bookings = const [],
    this.errorMessage,
  });

  BookingState copyWith({
    bool? isLoading,
    List<BookingModel>? bookings,
    String? errorMessage,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      bookings: bookings ?? this.bookings,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, bookings, errorMessage];
}

class BookingController extends Cubit<BookingState> {
  BookingController() : super(const BookingState());
  SupabaseClient get _client => AppSupabase.client;

  Future<void> fetchForUser(String userId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final response = await _client
          .from('bookings')
          .select()
          .or('driver_id.eq.$userId,owner_id.eq.$userId');
      final bookings = (response as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(isLoading: false, bookings: bookings));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> createBooking(BookingModel booking) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _client.from('bookings').insert(booking.toJson());
      await fetchForUser(booking.driverId);
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}


