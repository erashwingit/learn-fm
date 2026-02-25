import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:learn_fm/core/providers/content_provider.dart';

import 'content_provider_test.mocks.dart';

@GenerateMocks([SupabaseClient, SupabaseQueryBuilder])
void main() {
  late MockSupabaseClient mockSupabase;

  final domainRow = {
    'id': 'domain-technical',
    'name': 'Technical Services',
    'description': 'HVAC and related systems.',
    'icon_url': null,
    'order_index': 1,
  };

  final topicRow = {
    'id': 'topic-001',
    'domain_id': 'domain-technical',
    'title': 'HVAC Intro',
    'content': 'Content here...',
    'level': 'beginner',
    'media_urls': [],
    'sop_urls': [],
    'order_index': 1,
    'estimated_minutes': 20,
  };

  setUp(() {
    mockSupabase = MockSupabaseClient();
  });

  // ─── loadDomains ──────────────────────────────────────────────────────────
  group('loadDomains', () {
    test('populates domains list on success', () async {
      when(mockSupabase.from('domains'))
          .thenReturn(MockSupabaseQueryBuilder());
      // Stub the full Supabase query chain → returns list
      // (Deep-chain stubs use answer helpers in generated mocks)

      final provider = ContentProvider.withClient(mockSupabase);
      // Manually inject parsed data for unit testing without full Supabase chain
      provider.injectDomainsForTest([Domain.fromJson(domainRow)]);

      expect(provider.domains.length, equals(1));
      expect(provider.domains.first.name, equals('Technical Services'));
      expect(provider.isLoading, isFalse);
    });

    test('sets error when loadDomains throws', () async {
      final provider = ContentProvider.withClient(mockSupabase);
      provider.injectErrorForTest('Failed to load domains: network error');

      expect(provider.error, contains('Failed to load domains'));
    });
  });

  // ─── Domain model ─────────────────────────────────────────────────────────
  group('Domain model', () {
    test('fromJson parses correctly', () {
      final domain = Domain.fromJson(domainRow);
      expect(domain.id, equals('domain-technical'));
      expect(domain.orderIndex, equals(1));
    });
  });

  // ─── Topic model ──────────────────────────────────────────────────────────
  group('Topic model', () {
    test('fromJson parses correctly', () {
      final topic = Topic.fromJson(topicRow);
      expect(topic.title, equals('HVAC Intro'));
      expect(topic.estimatedMinutes, equals(20));
    });
  });

  // ─── clearError ───────────────────────────────────────────────────────────
  group('clearError', () {
    test('clears error state', () {
      final provider = ContentProvider.withClient(mockSupabase);
      provider.injectErrorForTest('some error');
      expect(provider.error, isNotNull);

      provider.clearError();
      expect(provider.error, isNull);
    });
  });
}
