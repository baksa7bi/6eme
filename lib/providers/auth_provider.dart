import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../models/menu_item.dart';
import 'agency_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  MenuItem? _pendingFavorite;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  MenuItem? get pendingFavorite => _pendingFavorite;

  // Keys for SharedPreferences
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  void setPendingFavorite(MenuItem? item) {
    _pendingFavorite = item;
    notifyListeners();
  }

  /// Call this once at app startup to restore the session
  Future<void> tryAutoLogin() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final userJson = prefs.getString(_keyUser);

      if (token != null && userJson != null) {
        _token = token;
        _user = User.fromJson(jsonDecode(userJson));
        ApiService.setToken(token);
      }
    } catch (e) {
      // If restoration fails, just stay logged out
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveSession(String token, User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (e) {
      // Fail silently — user is still logged in for this session
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (e) {
      // Fail silently
    }
  }

  Future<bool> login(String email, String password,
      {AgencyProvider? agencyProvider}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (agencyProvider != null && agencyProvider.isAgencyAuthenticated) {
        agencyProvider.logout();
      }

      final response = await ApiService.login(email, password);
      return _processAuthResponse(response);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle({AgencyProvider? agencyProvider}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (agencyProvider != null && agencyProvider.isAgencyAuthenticated) {
        agencyProvider.logout();
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final response = await ApiService.socialLogin(
        'google',
        googleAuth.idToken ?? '',
        email: googleUser.email,
        name: googleUser.displayName,
      );
      return _processAuthResponse(response);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithFacebook({AgencyProvider? agencyProvider}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (agencyProvider != null && agencyProvider.isAgencyAuthenticated) {
        agencyProvider.logout();
      }

      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        final response = await ApiService.socialLogin(
          'facebook',
          result.accessToken?.token ?? '',
          email: userData['email'],
          name: userData['name'],
        );
        return _processAuthResponse(response);
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

  bool _processAuthResponse(Map<String, dynamic> response) {
    if (response.containsKey('access_token')) {
      _token = response['access_token'];
      _user = User.fromJson(response['user']);
      ApiService.setToken(_token!);
      _isLoading = false;
      notifyListeners();
      // Save persistently
      _saveSession(_token!, _user!);
      return true;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password,
      {String? phone, String? address, AgencyProvider? agencyProvider}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (agencyProvider != null && agencyProvider.isAgencyAuthenticated) {
        agencyProvider.logout();
      }

      final response = await ApiService.register(name, email, password,
          phone: phone, address: address);
      return _processAuthResponse(response);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> updateProfile(String name, String email, String phone,
      {String? address, String? password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.updateProfile(name, email, phone,
          address: address, password: password);
      if (response.containsKey('user')) {
        _user = User.fromJson(response['user']);
        // Update the saved session with new user data
        if (_token != null) await _saveSession(_token!, _user!);
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

  Future<void> refreshUser() async {
    if (_token == null) return;
    try {
      final userData = await ApiService.getUser();
      _user = User.fromJson(userData);
      await _saveSession(_token!, _user!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  void logout() {
    _user = null;
    _token = null;
    ApiService.setToken('');
    _googleSignIn.signOut();
    FacebookAuth.instance.logOut();
    _clearSession();
    notifyListeners();
  }
}
