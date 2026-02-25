import 'package:flutter_test/flutter_test.dart';
import 'package:learn_fm/core/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    final now = DateTime(2026, 2, 25, 10, 0, 0);

    final sampleJson = {
      'id': 'user-001',
      'name': 'Ashwin Chuck',
      'email': 'ashwin@learnfm.com',
      'phone': '+919876543210',
      'company': 'FM Corp',
      'photo_url': 'https://cdn.learnfm.com/photos/user-001.png',
      'selected_domains': ['technical', 'housekeeping'],
      'created_at': now.toIso8601String(),
      'updated_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final profile = UserProfile.fromJson(sampleJson);

      expect(profile.id, equals('user-001'));
      expect(profile.name, equals('Ashwin Chuck'));
      expect(profile.email, equals('ashwin@learnfm.com'));
      expect(profile.phone, equals('+919876543210'));
      expect(profile.company, equals('FM Corp'));
      expect(profile.photoUrl,
          equals('https://cdn.learnfm.com/photos/user-001.png'));
      expect(profile.selectedDomains, equals(['technical', 'housekeeping']));
      expect(profile.createdAt, equals(now));
      expect(profile.updatedAt, isNull);
    });

    test('fromJson handles null optional fields gracefully', () {
      final minimalJson = {
        'id': 'user-002',
        'name': 'Test User',
        'email': 'test@learnfm.com',
        'phone': null,
        'company': null,
        'photo_url': null,
        'selected_domains': null,
        'created_at': now.toIso8601String(),
        'updated_at': null,
      };
      final profile = UserProfile.fromJson(minimalJson);

      expect(profile.phone, isNull);
      expect(profile.company, isNull);
      expect(profile.photoUrl, isNull);
      expect(profile.selectedDomains, isEmpty);
    });

    test('toJson serializes all fields correctly', () {
      final profile = UserProfile.fromJson(sampleJson);
      final json = profile.toJson();

      expect(json['id'], equals('user-001'));
      expect(json['name'], equals('Ashwin Chuck'));
      expect(json['email'], equals('ashwin@learnfm.com'));
      expect(json['phone'], equals('+919876543210'));
      expect(json['selected_domains'], equals(['technical', 'housekeeping']));
    });

    test('copyWith updates only specified fields', () {
      final profile = UserProfile.fromJson(sampleJson);
      final updated = profile.copyWith(name: 'Ashwin S Chuck', company: 'New FM Inc');

      expect(updated.name, equals('Ashwin S Chuck'));
      expect(updated.company, equals('New FM Inc'));
      // Unchanged fields remain the same
      expect(updated.id, equals(profile.id));
      expect(updated.email, equals(profile.email));
      expect(updated.phone, equals(profile.phone));
      expect(updated.selectedDomains, equals(profile.selectedDomains));
      // updatedAt should be set
      expect(updated.updatedAt, isNotNull);
    });

    test('copyWith with selectedDomains updates domain list', () {
      final profile = UserProfile.fromJson(sampleJson);
      final updated =
          profile.copyWith(selectedDomains: ['security', 'landscaping']);

      expect(updated.selectedDomains, equals(['security', 'landscaping']));
    });

    test('fromJson then toJson round-trip preserves data', () {
      final profile = UserProfile.fromJson(sampleJson);
      final json = profile.toJson();
      final profileAgain = UserProfile.fromJson(json);

      expect(profileAgain.id, equals(profile.id));
      expect(profileAgain.name, equals(profile.name));
      expect(profileAgain.email, equals(profile.email));
      expect(profileAgain.selectedDomains, equals(profile.selectedDomains));
    });
  });
}
