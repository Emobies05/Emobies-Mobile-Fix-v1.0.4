class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String? avatar;
  final DateTime createdAt;
  final bool isActive;
  final bool isFirstLogin;
  final String? emoKey;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.avatar,
    required this.createdAt,
    this.isActive = true,
    this.isFirstLogin = false,
    this.emoKey,
    this.metadata,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      avatar: json['avatar'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
      isFirstLogin: json['is_first_login'] ?? false,
      emoKey: json['emo_key'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'role': role,
    'avatar': avatar,
    'created_at': createdAt.toIso8601String(),
    'is_active': isActive,
    'is_first_login': isFirstLogin,
    'emo_key': emoKey,
    'metadata': metadata,
  };

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? avatar,
    DateTime? createdAt,
    bool? isActive,
    bool? isFirstLogin,
    String? emoKey,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      emoKey: emoKey ?? this.emoKey,
      metadata: metadata ?? this.metadata,
    );
  }

  String get displayName => name.isNotEmpty ? name : phone;
  bool get isStaff => role != 'customer';
  bool get canManageStaff => role == 'super_admin' || role == 'supervisor';
}

class StaffModel extends UserModel {
  final String? assignedZone;
  final bool isOnDuty;
  final DateTime? lastLocationUpdate;
  final double? latitude;
  final double? longitude;

  const StaffModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    required super.role,
    super.avatar,
    required super.createdAt,
    super.isActive,
    super.isFirstLogin,
    super.emoKey,
    super.metadata,
    this.assignedZone,
    this.isOnDuty = false,
    this.lastLocationUpdate,
    this.latitude,
    this.longitude,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    final base = UserModel.fromJson(json);
    return StaffModel(
      id: base.id,
      name: base.name,
      phone: base.phone,
      email: base.email,
      role: base.role,
      avatar: base.avatar,
      createdAt: base.createdAt,
      isActive: base.isActive,
      isFirstLogin: base.isFirstLogin,
      emoKey: base.emoKey,
      metadata: base.metadata,
      assignedZone: json['assigned_zone'],
      isOnDuty: json['is_on_duty'] ?? false,
      lastLocationUpdate: json['last_location_update'] != null
          ? DateTime.parse(json['last_location_update'])
          : null,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'assigned_zone': assignedZone,
    'is_on_duty': isOnDuty,
    'last_location_update': lastLocationUpdate?.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };
}