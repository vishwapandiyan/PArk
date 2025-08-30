enum UserRole { driver, owner }

class AppUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime? dob;
  final UserRole role;
  final String? licenseUrl; // driver
  final String? landProofUrl; // owner
  final String? carModelId; // driver - foreign key to car_models
  final bool? isVerified; // driver verification

  const AppUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.dob,
    this.licenseUrl,
    this.landProofUrl,
    this.carModelId,
    this.isVerified,
  });

  // Calculate age from date of birth
  int? get age {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob!.year;
    if (now.month < dob!.month || (now.month == dob!.month && now.day < dob!.day)) {
      age--;
    }
    return age;
  }

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      role: (json['role'] as String?) == 'owner' ? UserRole.owner : UserRole.driver,
      licenseUrl: json['license_url'] as String?,
      landProofUrl: json['land_proof_url'] as String?,
      carModelId: json['car_model_id'] as String?,
      isVerified: json['is_verified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'dob': dob?.toIso8601String().split('T')[0], // Store as date string (YYYY-MM-DD)
      'role': role == UserRole.owner ? 'owner' : 'driver',
      'license_url': licenseUrl,
      'land_proof_url': landProofUrl,
      'car_model_id': carModelId,
      'is_verified': isVerified,
    };
  }
}


