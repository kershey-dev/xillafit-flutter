class ProfileModel {
  final String id;
  final String? email;
  final String? fullName;
  final String? role;

  /// Future-proof: not always present depending on schema version.
  final String? avatarUrl;

  final String? contactNumber;
  final String? address;
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
    this.accountStatus,
    this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
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
      accountStatus: map['account_status']?.toString(),
      createdAt: createdAt,
    );
  }
}

