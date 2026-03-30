import 'package:flutter_test/flutter_test.dart';
import 'package:store_app/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('User is parsed correctly from JSON', () {
      final Map<String, dynamic> json = {
        'id': 1,
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'manager',
        'cafe_id': 2,
      };

      final user = User.fromJson(json);

      expect(user.id, '1');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.role, 'manager');
      expect(user.cafeId, 2);
    });

    test('User role validation properties work correctly', () {
      final admin = User(id: '1', email: 'admin@test.com', name: 'Admin', role: 'admin');
      final manager = User(id: '2', email: 'manager@test.com', name: 'Manager', role: 'manager');
      final client = User(id: '3', email: 'client@test.com', name: 'Client', role: 'client');
      final unverifiedClient = User(id: '4', email: 'uclient@test.com', name: 'UClient', role: 'client');
      final verifiedClient = User(id: '5', email: 'vclient@test.com', name: 'VClient', role: 'client', emailVerifiedAt: '2023-01-01');

      expect(admin.isAdmin, isTrue);
      expect(manager.isManager, isTrue);
      expect(client.isClient, isTrue);
      
      expect(client.isAdmin, isFalse);
      
      expect(unverifiedClient.isEmailVerified, isFalse);
      expect(verifiedClient.isEmailVerified, isTrue);
    });

    test('User serializes correctly to JSON', () {
      final user = User(
        id: '10',
        email: 'serialize@test.com',
        name: 'Serialize User',
        role: 'delivery',
        cafeId: 5,
        emailVerifiedAt: '2024-01-01',
      );

      final json = user.toJson();

      expect(json['id'], '10');
      expect(json['email'], 'serialize@test.com');
      expect(json['name'], 'Serialize User');
      expect(json['role'], 'delivery');
      expect(json['cafe_id'], 5);
      expect(json['email_verified_at'], '2024-01-01');
    });
  });
}
