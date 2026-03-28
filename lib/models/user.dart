class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? address;
  final String? role; // 'client', 'manager', 'admin', 'content_manager', 'delivery'
  final int? cafeId;
  final String? emailVerifiedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.address,
    this.role = 'client',
    this.cafeId,
    this.emailVerifiedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      name: json['name'],
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      role: json['role']?.toString() ?? 'client',
      cafeId: json['cafe_id'] != null ? int.tryParse(json['cafe_id'].toString()) : null,
      emailVerifiedAt: json['email_verified_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'role': role,
      'cafe_id': cafeId,
      'email_verified_at': emailVerifiedAt,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isDelivery => role == 'delivery';
  bool get isContentManager => role == 'content_manager' || role == 'admin';
  bool get isClient => role == 'client';
  bool get isEmailVerified => emailVerifiedAt != null;
}
