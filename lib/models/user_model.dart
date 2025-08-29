enum UserRole { driver, owner }

class AppUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int? age;
  final UserRole role;
  final String? licenseUrl; // driver
  final String? landProofUrl; // owner
  final String? dimensions; // owner (LxW)
  final String? address; // owner
  final bool? isVerified; // driver verification

  const AppUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.age,
    this.licenseUrl,
    this.landProofUrl,
    this.dimensions,
    this.address,
    this.isVerified,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      age: json['age'] as int?,
      role: (json['role'] as String?) == 'owner' ? UserRole.owner : UserRole.driver,
      licenseUrl: json['license_url'] as String?,
      landProofUrl: json['land_proof_url'] as String?,
      dimensions: json['dimensions'] as String?,
      address: json['address'] as String?,
      isVerified: json['is_verified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'age': age,
      'role': role == UserRole.owner ? 'owner' : 'driver',
      'license_url': licenseUrl,
      'land_proof_url': landProofUrl,
      'dimensions': dimensions,
      'address': address,
      'is_verified': isVerified,
    };
  }
}


