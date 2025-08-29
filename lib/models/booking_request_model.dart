class BookingRequestModel {
  final String destination;
  final String departure;
  final String carDimensions;
  final List<Map<String, dynamic>> availableSlots;
  final bool needShelter;
  final bool needCCTV;
  final bool needEVCharging;

  const BookingRequestModel({
    required this.destination,
    required this.departure,
    required this.carDimensions,
    required this.availableSlots,
    required this.needShelter,
    required this.needCCTV,
    required this.needEVCharging,
  });

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'departure': departure,
      'car_dimensions': carDimensions,
      'available_slots': availableSlots,
      'need_shelter': needShelter,
      'need_cctv': needCCTV,
      'need_ev_charging': needEVCharging,
    };
  }
}
