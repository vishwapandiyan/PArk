import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import '../models/parking_slot_model.dart';

class SlotState extends Equatable {
  final bool isLoading;
  final List<ParkingSlotModel> slots;
  final String? errorMessage;

  const SlotState({
    this.isLoading = false,
    this.slots = const [],
    this.errorMessage,
  });

  SlotState copyWith({
    bool? isLoading,
    List<ParkingSlotModel>? slots,
    String? errorMessage,
  }) {
    return SlotState(
      isLoading: isLoading ?? this.isLoading,
      slots: slots ?? this.slots,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, slots, errorMessage];
}

class SlotController extends Cubit<SlotState> {
  SlotController() : super(const SlotState());
  SupabaseClient get _client => AppSupabase.client;

  Future<void> fetchNearby({required double lat, required double lng, double radiusKm = 5}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      // Example: fetch all slots now; later replace with PostGIS/geo query
      final response = await _client.from('parking_slots').select();
      final slots = (response as List)
          .map((e) => ParkingSlotModel.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(isLoading: false, slots: slots));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> upsertSlot(ParkingSlotModel slot) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _client.from('parking_slots').upsert(slot.toJson());
      await fetchNearby(lat: 0, lng: 0); // refresh
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}


