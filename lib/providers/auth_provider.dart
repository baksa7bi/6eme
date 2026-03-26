import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../models/menu_item.dart';
import 'agency_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  MenuItem? _pendingFavorite;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  MenuItem? get pendingFavorite => _pendingFavorite;

  void setPendingFavorite(MenuItem? item) {
    _pendingFavorite = item;
    notifyListeners();
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

      print('Google sign in started...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('Google sign in user result: $googleUser');
      if (googleUser == null) {
        print('Google sign in cancelled by user');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('Google fetching authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Google idToken: ${googleAuth.idToken != null ? "PRESENT" : "MISSING"}');
      print('Google email: ${googleUser.email}');
      
      final response = await ApiService.socialLogin(
        'google', 
        googleAuth.idToken ?? '',
        email: googleUser.email,
        name: googleUser.displayName,
      );
      print('Social login backend response received');
      return _processAuthResponse(response);
    } catch (e) {
      print('Google sign in error: $e');
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

      print('Facebook sign in started...');
      final LoginResult result = await FacebookAuth.instance.login();
      print('Facebook login result status: ${result.status}');
      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        print('Facebook user data: $userData');
        final response = await ApiService.socialLogin(
          'facebook', 
          result.accessToken?.token ?? '',
          email: userData['email'],
          name: userData['name'],
        );
        print('Social login backend response received');
        return _processAuthResponse(response);
      }
      
      print('Facebook login failed or was cancelled');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Facebook sign in error: $e');
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

      final response = await ApiService.register(name, email, password, phone: phone, address: address);
      return _processAuthResponse(response);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(String name, String email, String phone, {String? address, String? password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.updateProfile(name, email, phone, address: address, password: password);
      if (response.containsKey('user')) {
        _user = User.fromJson(response['user']);
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
    _googleSignIn.signOut();
    FacebookAuth.instance.logOut();
    notifyListeners();
  }
}
