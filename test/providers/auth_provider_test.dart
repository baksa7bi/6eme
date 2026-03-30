import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_app/providers/auth_provider.dart';
import 'package:store_app/services/api_service.dart';

import 'auth_provider_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('AuthProvider Tests', () {
    late AuthProvider authProvider;
    late MockClient mockClient;

    setUp(() {
      authProvider = AuthProvider();
      mockClient = MockClient();
      ApiService.setMockClient(mockClient);
    });

    test('Initial state is unauthenticated', () {
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.token, isNull);
    });

    test('Login sets user and token on success', () async {
      final mockResponse = {
        'access_token': 'fake_token',
        'user': {
          'id': 1,
          'email': 'test@example.com',
          'name': 'Test User',
          'role': 'client'
        }
      };

      when(mockClient.post(
        Uri.parse('${ApiService.baseUrl}/login'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await authProvider.login('test@example.com', 'password');

      expect(result, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.token, 'fake_token');
      expect(authProvider.user?.email, 'test@example.com');
      expect(authProvider.isLoading, isFalse);
    });

    test('Login fails and does not set user on error', () async {
      when(mockClient.post(
        Uri.parse('${ApiService.baseUrl}/login'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"message": "Invalid"}', 401));

      final result = await authProvider.login('wrong@example.com', 'password');

      expect(result, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.token, isNull);
      expect(authProvider.user, isNull);
    });

    test('Logout clears user and token', () async {
      // First let's hack a login
      final mockResponse = {
        'access_token': 'fake_token',
        'user': {
          'id': 1,
          'email': 'test@example.com',
          'name': 'Test User'
        }
      };

      when(mockClient.post(
        Uri.parse('${ApiService.baseUrl}/login'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      await authProvider.login('test@example.com', 'password');
      expect(authProvider.isAuthenticated, isTrue);

      // Now logout
      authProvider.logout();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.token, isNull);
      expect(authProvider.user, isNull);
    });
  });
}
