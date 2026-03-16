class Coupon {
  final int id;
  final int userId;
  final String code;
  final double discountAmount;
  final bool isUsed;
  final DateTime? expiryDate;
  final DateTime createdAt;

  Coupon({
    required this.id,
    required this.userId,
    required this.code,
    required this.discountAmount,
    required this.isUsed,
    this.expiryDate,
    required this.createdAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'],
      userId: json['user_id'],
      code: json['code'],
      discountAmount: double.parse(json['discount_amount'].toString()),
      isUsed: json['is_used'] == 1 || json['is_used'] == true,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'code': code,
      'discount_amount': discountAmount,
      'is_used': isUsed,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
