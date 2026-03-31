import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/cafe.dart';
import '../models/menu_item.dart';
import '../models/event.dart';
import '../models/coupon.dart';
import '../models/agency.dart';
import '../models/order.dart';
import '../models/reservation.dart';

class ApiService {
  static http.Client? _client;

  static http.Client get _httpClient => _client ?? http.Client();

  static void setMockClient(http.Client client) {
    _client = client;
  }
  // Replace with your Hostinger subdomain URL once uploaded
  // For mobile testing (USB), use your PC's local IP address
  // Changed to local backend
  // static const String baseUrl = 'https://api.sfw-digital.com/api'; 
  static const String baseUrl = 'http://192.168.100.40:8000/api'; 
  static String get storageUrl {
    if (baseUrl.endsWith('/api')) {
      return '${baseUrl.substring(0, baseUrl.length - 4)}/storage';
    }
    return '$baseUrl/storage';
  }
  
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('assets/')) return path;
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final fullUrl = '$storageUrl/$cleanPath';
    debugPrint('API_LOG: Generated Image URL: $fullUrl');
    return fullUrl;
  }
  
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
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static String get _headersJson => jsonEncode(_headers);

  static Future<Map<String, dynamic>> socialLogin(String provider, String token, {String? email, String? name}) async {
    print('ApiService: socialLogin connecting to $baseUrl/social-login');
    print('ApiService: provider=$provider, email=$email');
    
    final response = await http.post(
      Uri.parse('$baseUrl/social-login'),
      headers: _headers,
      body: jsonEncode({
        'provider': provider,
        'token': token,
        'email': email,
        'name': name,
      }),
    );

    print('ApiService: response status=${response.statusCode}');
    print('ApiService: response body=${response.body}');

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, {String? phone, String? address}) async {
    final response = await _httpClient.post(
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
    print('ApiService register: status code = ${response.statusCode}');
    print('ApiService register: body = ${response.body}');
    
    final payload = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      if (payload['errors'] != null) {
        String errorMsg = payload['errors'].values.map((e) => (e as List).join(', ')).join('\n');
        throw Exception(errorMsg);
      }
      throw Exception(payload['message'] ?? 'Erreur lors de l\'inscription');
    }
    return payload;
  }


  static Future<Map<String, dynamic>> updateProfile(String name, String email, String phone, {String? address, String? password}) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
    };
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (password != null && password.isNotEmpty) body['password'] = password;

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  static Future<bool> addManager(String name, String email, String password, String phone, String cafeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/managers'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'cafe_id': cafeId,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> addDelivery(String name, String email, String password, String phone, String cafeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/delivery'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'cafe_id': cafeId,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/user/notifications'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getUser() async {
    final response = await http.get(Uri.parse('$baseUrl/user'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load user');
  }

  // Favorites
  static Future<List<MenuItem>> getFavorites() async {
    final response = await http.get(Uri.parse('$baseUrl/favorites'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => MenuItem.fromJson(json)).toList();
    }
    return [];
  }

  static Future<bool> toggleFavorite(String menuItemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites/toggle'),
      headers: _headers,
      body: jsonEncode({'menu_item_id': menuItemId}),
    );
    return response.statusCode == 200;
  }

  // Cafes
  static Future<List<Cafe>> getCafes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cafes'), headers: _headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Cafe.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error in getCafes: $e');
    }
    return [];
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

  static Future<bool> toggleReservationsBlock(String cafeId, bool blocked) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cafes/$cafeId/toggle-reservations'),
      headers: _headers,
      body: jsonEncode({'reservations_blocked': blocked}),
    );
    return response.statusCode == 200;
  }

  // Orders
  static Future<List<OrderItem>> getOrders({String? status, String? type}) async {
    String url = '$baseUrl/orders';
    List<String> params = [];
    if (status != null) params.add('status=$status');
    if (type != null) params.add('type=$type');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => OrderItem.fromJson(json)).toList();
    }
    return [];
  }

  static Future<bool> createOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
      body: jsonEncode(orderData),
    );
    return response.statusCode == 201;
  }

  // Reservations
  static Future<List<Reservation>> getReservations({String? status, String? type}) async {
    String url = '$baseUrl/reservations';
    List<String> params = [];
    if (status != null) params.add('status=$status');
    if (type != null) params.add('type=$type');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Reservation.fromJson(json)).toList();
    }
    return [];
  }

  static Future<bool> createReservation(Map<String, dynamic> reservationData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservations'),
      headers: _headers,
      body: jsonEncode(reservationData),
    );
    return response.statusCode == 201;
  }

  static Future<bool> updateReservationStatus(int id, String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservations/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
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
        'title': 'BUFFET RAMADAN 2',
        'subtitle': '',
        'type': 'image',
        'url': 'assets/images/BUFFET RAMADAN (2).jpg.jpeg',
      },
      {
        'id': 2,
        'title': 'BUFFET RAMADAN',
        'subtitle': '',
        'type': 'image',
        'url': 'assets/images/BUFFET RAMADAN.jpg.jpeg',
      },
    ];
  }

  static Future<bool> updateSliderItem(int id, String title, String subtitle, {File? imageFile, bool showText = true}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/sliders/update'));
    request.headers.addAll(_headers);

    request.fields['id'] = id.toString();
    request.fields['title'] = title;
    request.fields['subtitle'] = subtitle;
    request.fields['show_text'] = showText.toString();

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    return streamedResponse.statusCode == 200;
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


  // Coupons
  static Future<List<Coupon>> getCoupons(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/coupons?user_id=$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Coupon.fromJson(json)).toList();
    }
    throw Exception('Failed to load coupons');
  }

  static Future<Map<String, dynamic>> validateCoupon(String code, int userId, {String? orderType}) async {
    final body = <String, dynamic>{
      'code': code,
      'user_id': userId,
    };
    if (orderType != null) body['order_type'] = orderType;

    final response = await http.post(
      Uri.parse('$baseUrl/coupons/validate'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  static Future<List<Coupon>> getActiveCoupons() async {
    final response = await http.get(
      Uri.parse('$baseUrl/coupons/active'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Coupon.fromJson(json)).toList();
    }
    throw Exception('Failed to load active coupons');
  }

  static Future<bool> addMenuItem(MenuItem item, {File? imageFile, required String userId}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/menu-items'));
    request.headers.addAll({
      'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    });

    request.fields['name'] = item.name;
    request.fields['price'] = item.price.toString();
    request.fields['category'] = item.category;
    request.fields['cafe_id'] = item.cafeId;
    request.fields['user_id'] = userId;
    request.fields['description'] = item.description;

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    } else if (item.imageUrl.isNotEmpty) {
      request.fields['image_url'] = item.imageUrl;
    }

    final response = await request.send();
    return response.statusCode == 201;
  }

  static Future<bool> updateMenuItem(String id, {String? name, String? description, double? price, String? category, File? imageFile, String? userId, bool? isAvailable}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/menu-items/$id'));
    request.headers.addAll({
      if (_token != null) 'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    });

    if (name != null) request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    if (price != null) request.fields['price'] = price.toString();
    if (category != null) request.fields['category'] = category;
    if (userId != null) request.fields['user_id'] = userId;
    if (isAvailable != null) request.fields['is_available'] = isAvailable.toString();

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> addEvent(Event event, {File? imageFile, required String userId, String? cafeId}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/events'));
    request.headers.addAll({
      'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    });

    request.fields['title'] = event.title;
    request.fields['description'] = event.description;
    request.fields['date'] = event.date.toIso8601String();
    request.fields['location'] = event.location;
    request.fields['user_id'] = userId;
    
    if (cafeId != null) {
      request.fields['cafe_id'] = cafeId;
    } else if (event.cafe?.id != null) {
      request.fields['cafe_id'] = event.cafe!.id.toString();
    }
    if (event.videoUrl != null && event.videoUrl!.isNotEmpty) {
      request.fields['video_url'] = event.videoUrl!;
    }

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    } else if (event.imageUrl.isNotEmpty) {
      request.fields['image_url'] = event.imageUrl;
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'Évènement ajouté avec succès'};
    } else {
      try {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? "Erreur lors de l'ajout (Code ${response.statusCode})"};
      } catch (_) {
        return {'success': false, 'message': "Erreur serveur (${response.statusCode})"};
      }
    }
  }

  static Future<bool> requestCoupon(int userId, File imageFile, double amount, {int? cafeId}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/coupon-requests'));
      request.headers.addAll({
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      });

      request.fields['user_id'] = userId.toString();
      request.fields['amount'] = amount.toString();
      if (cafeId != null) request.fields['cafe_id'] = cafeId.toString();
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('API_LOG: Coupon Request Status: ${response.statusCode}');
      debugPrint('API_LOG: Coupon Request Body: ${response.body}');
      
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('API_LOG_ERROR: requestCoupon failed: $e');
      rethrow;
    }
  }


  static Future<List<Map<String, dynamic>>> getCouponRequests({int? userId}) async {
    String url = '$baseUrl/coupon-requests';
    if (userId != null) url += '?user_id=$userId';
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Failed to load coupon requests');
  }

  static Future<bool> approveCouponRequest(int requestId, {double discountAmount = 50.0}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/coupon-requests/$requestId/approve'),
      headers: _headers,
      body: jsonEncode({'discount_amount': discountAmount}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> rejectCouponRequest(int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/coupon-requests/$requestId/reject'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }

  // Agencies
  static Future<List<Agency>> getAgencies() async {
    final response = await http.get(Uri.parse('$baseUrl/agencies'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Agency.fromJson(json)).toList();
    }
    throw Exception('Failed to load agencies');
  }

  static Future<bool> addAgency(Map<String, dynamic> agencyData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agencies'),
      headers: _headers,
      body: jsonEncode(agencyData),
    );
    return response.statusCode == 201;
  }

  static Future<bool> deleteAgency(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/agencies/$id'),
      headers: _headers,
    );
    return response.statusCode == 204;
  }

  // Agency Auth
  static Future<Map<String, dynamic>> agencyLogin(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agency/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // Agency Visits
  static Future<List<Map<String, dynamic>>> getAgencyVisits() async {
    final response = await http.get(Uri.parse('$baseUrl/agency-visits'), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  static Future<bool> submitAgencyVisit(Map<String, dynamic> visitData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agency-visits'),
      headers: _headers,
      body: jsonEncode(visitData),
    );
    return response.statusCode == 201;
  }

  static Future<bool> updateVisitSpentAmount(dynamic visitId, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agency-visits/$visitId/spent-amount'),
      headers: _headers,
      body: jsonEncode({'spent_amount': amount}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> confirmVisitPayment(dynamic visitId, File proofFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/agency-visits/$visitId/confirm-payment'));
    
    // Copy headers but remove Content-Type because MultipartRequest handles it
    final headers = Map<String, String>.from(_headers);
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    
    request.files.add(await http.MultipartFile.fromPath('proof', proofFile.path));
    
    final streamedResponse = await request.send();
    return streamedResponse.statusCode == 200;
  }

  static Future<bool> updateVisitStatus(dynamic visitId, String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agency-visits/$visitId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> changeUserPassword(
      String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: _headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      }),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> changeAgencyPassword(
      String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agency/change-password'),
      headers: _headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      }),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> claimFirstTryCoupon(String userId, String deviceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/coupons/claim-first-try'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'device_id': deviceId,
      }),
    );
    return jsonDecode(response.body);
  }


  static Future<bool> updateOrderStatus(String id, String status, {int? rating, String? reason, String? ratingComment}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$id/status'),
      headers: _headers,
      body: jsonEncode({
        'status': status,
        if (rating != null) 'rating': rating,
        if (reason != null) 'cancellation_reason': reason,
        if (ratingComment != null) 'rating_comment': ratingComment,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<bool> takeOrder(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$id/take'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }

  static Future<List<Coupon>> getUserCoupons(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/coupons?user_id=$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Coupon.fromJson(json)).toList();
    }
    return [];
  }

  static Future<bool> markCouponAsUsed(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/coupons/$id/mark-as-used'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> claimDailyCoupon(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/coupons/claim-daily'),
      headers: _headers,
      body: jsonEncode({'user_id': userId}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resendVerificationEmail() async {
    final response = await http.post(
      Uri.parse('$baseUrl/email/verification-notification'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<bool> deleteMenuItem(int id, int userId, {String? token}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/menu-items/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'user_id': userId}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> updateFcmToken(String fcmToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fcm-token'),
      headers: _headers,
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    return response.statusCode == 200;
  }
} // End of file
