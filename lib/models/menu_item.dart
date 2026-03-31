class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String cafeId;
  final bool available;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.cafeId,
    this.available = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      category: json['category'] is Map ? json['category']['name'] : (json['category'] ?? ''),
      cafeId: json['cafe_id'].toString(),
      available: json['is_available'] != null ? json['is_available'] == true || json['is_available'] == 1 : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'cafe_id': cafeId,
      'available': available,
    };
  }
}
