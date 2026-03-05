import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/cafe.dart';
import '../models/menu_item.dart';

class ApiService {
  // Replace with your Hostinger subdomain URL once uploaded
  // For mobile testing (USB), use your PC's local IP address
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
}
