import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      
      if (response.containsKey('access_token')) {
        _token = response['access_token'];
        _user = User.fromJson(response['user']);
        ApiService.setToken(_token!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, {String? phone, String? address}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.register(name, email, password, phone: phone, address: address);
      
      if (response.containsKey('access_token')) {
        _token = response['access_token'];
        _user = User.fromJson(response['user']);
        ApiService.setToken(_token!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _user = null;
    _token = null;
    ApiService.setToken('');
    notifyListeners();
  }
}
