class CarModel {
  final String id;
  final String name;
  final String brand;
  final double length;
  final double width;
  final double height;
  final double wheelbase;
  final DateTime? createdAt;

  const CarModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.length,
    required this.width,
    required this.height,
    required this.wheelbase,
    this.createdAt,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      length: (json['length'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      wheelbase: (json['wheelbase'] as num).toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'length': length,
      'width': width,
      'height': height,
      'wheelbase': wheelbase,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get displayName => '$brand $name';

  String get dimensions => '${length.toStringAsFixed(1)}m × ${width.toStringAsFixed(1)}m × ${height.toStringAsFixed(1)}m';

  Map<String, double> get dimensionsMap => {
    'length': length,
    'width': width,
    'height': height,
  };

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}