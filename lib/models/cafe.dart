import 'dart:convert';

class Cafe {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String description;
  final List<String> openingHours;
  bool reservationsBlocked;

  Cafe({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.openingHours,
    this.reservationsBlocked = false,
  });

  factory Cafe.fromJson(Map<String, dynamic> json) {
    List<String> hours = [];
    try {
      var hoursData = json['opening_hours'];
      if (hoursData != null) {
        if (hoursData is List) {
          hours = hoursData.map((e) => e.toString()).toList();
        } else if (hoursData is String) {
          if (hoursData.startsWith('[') && hoursData.endsWith(']')) {
            var decoded = jsonDecode(hoursData);
            if (decoded is List) {
              hours = decoded.map((e) => e.toString()).toList();
            } else {
              hours = [hoursData];
            }
          } else {
            hours = [hoursData];
          }
        }
      }
    } catch (e) {
      print('Error parsing opening_hours: $e');
    }

    return Cafe(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      description: json['description']?.toString() ?? '',
      openingHours: hours,
      reservationsBlocked: json['reservations_blocked'] == true || json['reservations_blocked'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'openingHours': openingHours,
    };
  }
}
