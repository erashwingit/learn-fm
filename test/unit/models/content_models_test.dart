import 'package:flutter_test/flutter_test.dart';
import 'package:learn_fm/core/providers/content_provider.dart';

void main() {
  // ─── Domain ───────────────────────────────────────────────────────────────
  group('Domain', () {
    final domainJson = {
      'id': 'domain-technical',
      'name': 'Technical Services',
      'description': 'HVAC, plumbing, electrical systems and more.',
      'icon_url': 'https://cdn.learnfm.com/icons/technical.png',
      'order_index': 1,
    };

    test('fromJson parses all fields', () {
      final domain = Domain.fromJson(domainJson);

      expect(domain.id, equals('domain-technical'));
      expect(domain.name, equals('Technical Services'));
      expect(domain.orderIndex, equals(1));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'domain-x',
        'name': 'Domain X',
        'description': null,
        'icon_url': null,
        'order_index': null,
      };
      final domain = Domain.fromJson(json);

      expect(domain.iconUrl, isNull);
      expect(domain.description, equals(''));
      expect(domain.orderIndex, equals(0));
    });

    test('toJson round-trip preserves data', () {
      final domain = Domain.fromJson(domainJson);
      final json = domain.toJson();
      final domain2 = Domain.fromJson(json);

      expect(domain2.id, equals(domain.id));
      expect(domain2.name, equals(domain.name));
      expect(domain2.orderIndex, equals(domain.orderIndex));
    });
  });

  // ─── Topic ────────────────────────────────────────────────────────────────
  group('Topic', () {
    final topicJson = {
      'id': 'topic-001',
      'domain_id': 'domain-technical',
      'title': 'Introduction to HVAC',
      'content': 'HVAC systems provide thermal comfort...',
      'level': 'beginner',
      'media_urls': ['https://youtube.com/watch?v=abc'],
      'sop_urls': ['https://cdn.learnfm.com/sops/hvac-intro.pdf'],
      'order_index': 1,
      'estimated_minutes': 20,
    };

    test('fromJson parses all fields', () {
      final topic = Topic.fromJson(topicJson);

      expect(topic.id, equals('topic-001'));
      expect(topic.domainId, equals('domain-technical'));
      expect(topic.title, equals('Introduction to HVAC'));
      expect(topic.level, equals('beginner'));
      expect(topic.mediaUrls.length, equals(1));
      expect(topic.sopUrls.length, equals(1));
      expect(topic.estimatedMinutes, equals(20));
    });

    test('fromJson applies defaults for null optional fields', () {
      final json = {
        'id': 'topic-002',
        'domain_id': 'domain-technical',
        'title': 'Basics',
        'content': null,
        'level': null,
        'media_urls': null,
        'sop_urls': null,
        'order_index': null,
        'estimated_minutes': null,
      };
      final topic = Topic.fromJson(json);

      expect(topic.content, equals(''));
      expect(topic.level, equals('beginner'));
      expect(topic.mediaUrls, isEmpty);
      expect(topic.sopUrls, isEmpty);
      expect(topic.orderIndex, equals(0));
      expect(topic.estimatedMinutes, equals(15));
    });

    test('toJson round-trip preserves all data', () {
      final topic = Topic.fromJson(topicJson);
      final json = topic.toJson();
      final topic2 = Topic.fromJson(json);

      expect(topic2.id, equals(topic.id));
      expect(topic2.title, equals(topic.title));
      expect(topic2.mediaUrls, equals(topic.mediaUrls));
    });
  });

  // ─── UserProgress ─────────────────────────────────────────────────────────
  group('UserProgress', () {
    final completedAt = DateTime(2026, 2, 25, 12, 0, 0);

    final progressJson = {
      'user_id': 'user-001',
      'topic_id': 'topic-001',
      'status': 'completed',
      'time_spent': 1200,
      'last_position': 5,
      'completed_at': completedAt.toIso8601String(),
    };

    test('fromJson parses completed progress', () {
      final progress = UserProgress.fromJson(progressJson);

      expect(progress.userId, equals('user-001'));
      expect(progress.topicId, equals('topic-001'));
      expect(progress.status, equals('completed'));
      expect(progress.timeSpent, equals(1200));
      expect(progress.lastPosition, equals(5));
      expect(progress.completedAt, equals(completedAt));
    });

    test('fromJson handles null completedAt', () {
      final json = Map<String, dynamic>.from(progressJson)
        ..['completed_at'] = null
        ..['status'] = 'in_progress';
      final progress = UserProgress.fromJson(json);

      expect(progress.completedAt, isNull);
      expect(progress.status, equals('in_progress'));
    });

    test('toJson round-trip preserves status', () {
      final progress = UserProgress.fromJson(progressJson);
      final json = progress.toJson();
      final progress2 = UserProgress.fromJson(json);

      expect(progress2.status, equals('completed'));
      expect(progress2.timeSpent, equals(1200));
    });
  });
}
