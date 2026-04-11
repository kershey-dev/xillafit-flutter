class ProfileModel {
  final String id;
  final String? email;
  final String? fullName;
  final String? role;

  /// Future-proof: not always present depending on schema version.
  final String? avatarUrl;

  final String? contactNumber;
  final String? address;
  final String? municipality;
  final String? barangay;
  final String? streetAddress;
  final String? zipCode;
  final String? province;
  final String? accountStatus;
  final DateTime? createdAt;

  const ProfileModel({
    required this.id,
    this.email,
    this.fullName,
    this.role,
    this.avatarUrl,
    this.contactNumber,
    this.address,
    this.municipality,
    this.barangay,
    this.streetAddress,
    this.zipCode,
    this.province,
    this.accountStatus,
    this.createdAt,
  });

  bool get hasFullName => (fullName ?? '').trim().isNotEmpty;
  bool get hasRole => (role ?? '').trim().isNotEmpty;
  bool get hasEmail => (email ?? '').trim().isNotEmpty;

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    final customerProfile = _extractCustomerProfile(map['customer_profiles']);
    final createdAtRaw = map['created_at'];
    DateTime? createdAt;
    if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    return ProfileModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString(),
      fullName: map['full_name']?.toString(),
      role: map['role']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      contactNumber: map['contact_number']?.toString(),
      address: map['address']?.toString(),
      municipality: customerProfile?['municipality']?.toString(),
      barangay: customerProfile?['barangay']?.toString(),
      streetAddress: customerProfile?['street_address']?.toString(),
      zipCode: customerProfile?['zip_code']?.toString(),
      province: customerProfile?['province']?.toString(),
      accountStatus: map['account_status']?.toString(),
      createdAt: createdAt,
    );
  }

  static Map<String, dynamic>? _extractCustomerProfile(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}
