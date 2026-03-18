import 'package:flutter/material.dart';
import '../models/agency.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class AgencyProvider with ChangeNotifier {
  Agency? _agency;
  String? _token;
  bool _isLoading = false;

  Agency? get agency => _agency;
  String? get token => _token;
  bool get isAgencyAuthenticated => _agency != null;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password,
      {AuthProvider? authProvider}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // If a regular user is logged in, log them out first
      if (authProvider != null && authProvider.isAuthenticated) {
        authProvider.logout();
      }

      final response = await ApiService.agencyLogin(email, password);

      if (response.containsKey('token')) {
        _token = response['token'];
        _agency = Agency.fromJson(response['agency']);
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
    _agency = null;
    _token = null;
    ApiService.setToken('');
    notifyListeners();
  }
}
