import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import '../models/parking_slot_model.dart';

class SlotState extends Equatable {
  final bool isLoading;
  final List<ParkingSlotModel> slots;
  final String? error;

  const SlotState({
    this.isLoading = false,
    this.slots = const [],
    this.error,
  });

  SlotState copyWith({
    bool? isLoading,
    List<ParkingSlotModel>? slots,
    String? error,
  }) {
    return SlotState(
      isLoading: isLoading ?? this.isLoading,
      slots: slots ?? this.slots,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, slots, error];
}

class SlotController extends Cubit<SlotState> {
  SlotController() : super(const SlotState());
  SupabaseClient get _client => AppSupabase.client;

  Future<void> loadSlots() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      // Example: fetch all slots now; later replace with PostGIS/geo query
      final response = await _client.from('parking_slots').select();
      final slots = (response as List)
          .map((e) => ParkingSlotModel.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(isLoading: false, slots: slots));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> fetchNearby({required double lat, required double lng, double radiusKm = 5}) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      // Example: fetch all slots now; later replace with PostGIS/geo query
      final response = await _client.from('parking_slots').select();
      final slots = (response as List)
          .map((e) => ParkingSlotModel.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(isLoading: false, slots: slots));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> upsertSlot(ParkingSlotModel slot) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _client.from('parking_slots').upsert(slot.toJson());
      await loadSlots(); // refresh
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}


