class Reservation {
  final String id;
  final String cafeId;
  final String cafeName;
  final String userId;
  final DateTime dateTime;
  final int numberOfPeople;
  final String? specialRequests;
  final double depositAmount;
  final String type; // 'table', 'birthday'
  final String status; // pending, confirmed, cancelled
  final String? paymentIntentId;

  Reservation({
    required this.id,
    required this.cafeId,
    required this.cafeName,
    required this.userId,
    required this.dateTime,
    required this.numberOfPeople,
    this.specialRequests,
    this.depositAmount = 0.0,
    this.type = 'table',
    this.status = 'pending',
    this.paymentIntentId,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'].toString(),
      cafeId: json['cafe_id']?.toString() ?? json['cafeId']?.toString() ?? json['cafe']?['id']?.toString() ?? '',
      cafeName: json['cafe_name'] ?? json['cafeName'] ?? json['cafe']?['name'] ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      dateTime: DateTime.parse(json['date_time'] ?? json['dateTime']),
      numberOfPeople: int.tryParse(json['number_of_people']?.toString() ?? json['numberOfPeople']?.toString() ?? '0') ?? 0,
      specialRequests: json['special_requests'] ?? json['specialRequests'],
      depositAmount: double.tryParse(json['deposit_amount']?.toString() ?? json['depositAmount']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? 'table',
      status: json['status'] ?? 'pending',
      paymentIntentId: json['payment_intent_id'] ?? json['paymentIntentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cafeId': cafeId,
      'cafeName': cafeName,
      'userId': userId,
      'dateTime': dateTime.toIso8601String(),
      'numberOfPeople': numberOfPeople,
      'specialRequests': specialRequests,
      'depositAmount': depositAmount,
      'type': type,
      'status': status,
      'paymentIntentId': paymentIntentId,
    };
  }

  String get displayType => type == 'birthday' ? 'Anniversaire' : 'Table';
}
