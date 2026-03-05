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
  });

  factory Cafe.fromJson(Map<String, dynamic> json) {
    return Cafe(
      id: json['id'].toString(),
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      imageUrl: json['image_url'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      description: json['description'] ?? '',
      openingHours: List<String>.from(json['opening_hours'] ?? []),
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
