import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/cafe.dart';
import '../models/menu_item.dart';
import '../models/event.dart';

class ApiService {
  // Replace with your Hostinger subdomain URL once uploaded
  // For mobile testing (USB), use your PC's local IP address
  // Changed to local backend
  static const String baseUrl = 'https://api.sfw-digital.com/api'; 
  
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, {String? phone, String? address}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      }),
    );
    return jsonDecode(response.body);
  }

  // Cafes
  static Future<List<Cafe>> getCafes() async {
    final response = await http.get(Uri.parse('$baseUrl/cafes'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Cafe.fromJson(json)).toList();
    }
    throw Exception('Failed to load cafes');
  }

  // Menu Items
  static Future<List<MenuItem>> getMenuItems({int? cafeId}) async {
    String url = '$baseUrl/menu-items';
    if (cafeId != null) url += '?cafe_id=$cafeId';
    
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => MenuItem.fromJson(json)).toList();
    }
    throw Exception('Failed to load menu items');
  }

  // Orders
  static Future<bool> createOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
      body: jsonEncode(orderData),
    );
    return response.statusCode == 201;
  }

  // Reservations
  static Future<bool> createReservation(Map<String, dynamic> reservationData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservations'),
      headers: _headers,
      body: jsonEncode(reservationData),
    );
    return response.statusCode == 201;
  }

  // Events
  static Future<List<Event>> getEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/events'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    }
    // Fallback Mock Data if API fails for now
    return [
      Event(
        id: '1',
        title: 'Hamid el Mardi',
        description: 'Une offre parfaite vous attend, ne la ratez pas !',
        date: DateTime(2026, 3, 28), // 28 MARS
        imageUrl: 'assets/images/singer.jpeg',
        location: 'El Massira',
        cafe: Cafe(
          id: '2',
          name: 'Massira',
          address: 'MASSIRA Rue Agadir',
          phone: '+212661894296',
          imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=1447&auto=format&fit=crop',
          latitude: 33.5892,
          longitude: -7.6309,
          description: 'Ambiance chaleureuse dans le quartier Maarif',
          openingHours: ['Lun-Dim: 8h00 - 23h00'],
        ),
      ),
      Event(
        id: '2',
        title: 'Soirée Spéciale',
        description: 'Découvrez une ambiance unique avec notre invité surprise.',
        date: DateTime.now().add(const Duration(days: 5)),
        imageUrl: 'assets/images/singer2.jpeg',
        location: 'Marrakech',
        cafe: Cafe(
          id: '1',
          name: 'MOHAMED VI',
          address: 'Avenue Mohamed VI, Marrakech',
          phone: '+212661894296',
          imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=1447&auto=format&fit=crop',
          latitude: 31.6292,
          longitude: -1.6309,
          description: 'Notre café principal au cœur de Marrakech',
          openingHours: ['Lun-Dim: 8h00 - 23h00'],
        ),
      ),
    ];
  }

  // Content Management (Slider & Items)
  static Future<List<Map<String, dynamic>>> getSliders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sliders'), headers: _headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      // Ignored
    }
    // Fallback Mock Data
    return [
      {
        'id': 1,
        'title': 'HAPPY HOUR',
        'subtitle': '-50% sur le 2ème café',
        'type': 'image',
        'url': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085',
      },
      {
        'id': 2,
        'title': 'NOUVEAU',
        'subtitle': 'Découvrez nos gâteaux fait maison',
        'type': 'video',
        'url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      },
      {
        'id': 3,
        'title': 'PETIT DÉJEUNER',
        'subtitle': 'Menu complet à 35 DH',
        'type': 'image',
        'url': 'https://images.unsplash.com/photo-1447078806655-40579c2520d6',
      },
    ];
  }

  static Future<bool> updateSliderItem(int id, String title, String subtitle, {File? imageFile}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/sliders/update'));
    request.headers.addAll({
      'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    });

    request.fields['id'] = id.toString();
    request.fields['title'] = title;
    request.fields['subtitle'] = subtitle;

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  static Future<bool> addMenuItem(MenuItem item, {File? imageFile}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/menu-items'));
    request.headers.addAll({
      'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    });

    request.fields['name'] = item.name;
    request.fields['price'] = item.price.toString();
    request.fields['category'] = item.category;
    request.fields['cafe_id'] = item.cafeId;
    if (item.description != null) request.fields['description'] = item.description!;

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    } else if (item.imageUrl.isNotEmpty) {
      request.fields['image_url'] = item.imageUrl;
    }

    final response = await request.send();
    return response.statusCode == 201;
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'), headers: _headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => json['name'].toString()).toList();
      }
    } catch (e) {
      // Ignored error, will fallback
    }
    // Fallback Mock Data
    return ['Café', 'Thé', 'Boissons', 'Pâtisserie', 'Entrées', 'Sushi', 'Plats Chauds', 'Assortiments', 'Desserts'];
  }

  static Future<bool> addEvent(Event event, {File? imageFile}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/events'));
    request.headers.addAll({
      'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    });

    request.fields['title'] = event.title;
    request.fields['description'] = event.description;
    request.fields['date'] = event.date.toIso8601String();
    request.fields['location'] = event.location;
    
    if (event.cafe?.id != null) request.fields['cafe_id'] = event.cafe!.id.toString();
    if (event.videoUrl != null && event.videoUrl!.isNotEmpty) {
      request.fields['video_url'] = event.videoUrl!;
    }

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    } else if (event.imageUrl.isNotEmpty) {
      request.fields['image_url'] = event.imageUrl;
    }

    final response = await request.send();
    return response.statusCode == 201;
  }
}
