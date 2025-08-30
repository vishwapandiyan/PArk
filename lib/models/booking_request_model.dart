class BookingRequestModel {
  final String destination;
  final double? destinationLat;
  final double? destinationLng;
  final double? distance;
  final String carDimensions; // Auto-filled from car model
  final String carModelId;
  final String carModelName;
  final List<Map<String, dynamic>> availableSlots;
  final bool needShelter;
  final bool needCCTV;
  final bool needEVCharging;

  const BookingRequestModel({
    required this.destination,
    this.destinationLat,
    this.destinationLng,
    this.distance,
    required this.carDimensions,
    required this.carModelId,
    required this.carModelName,
    required this.availableSlots,
    required this.needShelter,
    required this.needCCTV,
    required this.needEVCharging,
  });

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      'distance': distance,
      'car_dimensions': carDimensions,
      'car_model_id': carModelId,
      'car_model_name': carModelName,
      'available_slots': availableSlots,
      'need_shelter': needShelter,
      'need_cctv': needCCTV,
      'need_ev_charging': needEVCharging,
    };
  }
}
