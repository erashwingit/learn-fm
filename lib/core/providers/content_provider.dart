import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContentProvider with ChangeNotifier {
  late final SupabaseClient _supabase;

  List<Domain> _domains = [];
  List<Topic> _topics = [];
  Map<String, List<Topic>> _domainTopics = {};
  bool _isLoading = false;
  String? _error;

  // ─── Getters ────────────────────────────────────────────────────────────────
  List<Domain> get domains => _domains;
  List<Topic> get topics => _topics;
  Map<String, List<Topic>> get domainTopics => _domainTopics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Constructors ───────────────────────────────────────────────────────────

  /// Default production constructor — uses the Supabase singleton.
  ContentProvider() {
    _supabase = Supabase.instance.client;
  }

  /// Testability constructor — accepts an injectable [SupabaseClient].
  @visibleForTesting
  ContentProvider.withClient(SupabaseClient client) {
    _supabase = client;
  }

  // ─── Test helpers ────────────────────────────────────────────────────────────
  /// Directly injects a domain list for unit testing without a Supabase call.
  @visibleForTesting
  void injectDomainsForTest(List<Domain> domains) {
    _domains = domains;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Directly injects an error string for unit testing error-state coverage.
  @visibleForTesting
  void injectErrorForTest(String errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }

  // ─── Data Operations ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    await loadDomains();
  }

  Future<void> loadDomains() async {
    try {
      _setLoading(true);
      _error = null;

      final response = await _supabase
          .from('domains')
          .select()
          .order('order_index');

      _domains = (response as List)
          .map((json) => Domain.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load domains: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Topic>> loadTopicsForDomain(
    String domainId, {
    String? level,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      var query = _supabase
          .from('topics')
          .select()
          .eq('domain_id', domainId)
          .order('order_index');

      if (level != null) {
        query = query.eq('level', level);
      }

      final response = await query;

      final topics = (response as List)
          .map((json) => Topic.fromJson(json))
          .toList();

      _domainTopics[domainId] = topics;
      notifyListeners();

      return topics;
    } catch (e) {
      _error = 'Failed to load topics: $e';
      notifyListeners();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Topic?> getTopicById(String topicId) async {
    try {
      final response = await _supabase
          .from('topics')
          .select()
          .eq('id', topicId)
          .single();

      return Topic.fromJson(response);
    } catch (e) {
      _error = 'Failed to load topic: $e';
      notifyListeners();
      return null;
    }
  }

  Future<List<Topic>> searchTopics(String query, {String? domainId}) async {
    try {
      _setLoading(true);
      _error = null;

      var supabaseQuery = _supabase
          .from('topics')
          .select()
          .textSearch('title', query);

      if (domainId != null) {
        supabaseQuery = supabaseQuery.eq('domain_id', domainId);
      }

      final response = await supabaseQuery.limit(20);

      final searchResults = (response as List)
          .map((json) => Topic.fromJson(json))
          .toList();

      return searchResults;
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markTopicCompleted(String topicId, int timeSpent) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_progress').upsert({
        'user_id': userId,
        'topic_id': topicId,
        'status': 'completed',
        'time_spent': timeSpent,
        'completed_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark topic as completed: $e';
      notifyListeners();
    }
  }

  Future<UserProgress?> getUserProgress(String topicId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_progress')
          .select()
          .eq('user_id', userId)
          .eq('topic_id', topicId)
          .maybeSingle();

      if (response != null) {
        return UserProgress.fromJson(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleBookmark(String topicId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final existing = await _supabase
          .from('bookmarks')
          .select()
          .eq('user_id', userId)
          .eq('topic_id', topicId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('user_id', userId)
            .eq('topic_id', topicId);
      } else {
        await _supabase.from('bookmarks').insert({
          'user_id': userId,
          'topic_id': topicId,
          'bookmarked_at': DateTime.now().toIso8601String(),
        });
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to toggle bookmark: $e';
      notifyListeners();
    }
  }

  Future<List<Topic>> getBookmarkedTopics() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('bookmarks')
          .select('topic_id, topics(*)')
          .eq('user_id', userId)
          .order('bookmarked_at', ascending: false);

      return (response as List)
          .map((item) => Topic.fromJson(item['topics']))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// ─── Content Models ───────────────────────────────────────────────────────────

class Domain {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final int orderIndex;

  Domain({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.orderIndex,
  });

  factory Domain.fromJson(Map<String, dynamic> json) {
    return Domain(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      iconUrl: json['icon_url'],
      orderIndex: json['order_index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'order_index': orderIndex,
    };
  }
}

class Topic {
  final String id;
  final String domainId;
  final String title;
  final String content;
  final String level;
  final List<String> mediaUrls;
  final List<String> sopUrls;
  final int orderIndex;
  final int estimatedMinutes;

  Topic({
    required this.id,
    required this.domainId,
    required this.title,
    required this.content,
    required this.level,
    required this.mediaUrls,
    required this.sopUrls,
    required this.orderIndex,
    required this.estimatedMinutes,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'],
      domainId: json['domain_id'],
      title: json['title'],
      content: json['content'] ?? '',
      level: json['level'] ?? 'beginner',
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      sopUrls: List<String>.from(json['sop_urls'] ?? []),
      orderIndex: json['order_index'] ?? 0,
      estimatedMinutes: json['estimated_minutes'] ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain_id': domainId,
      'title': title,
      'content': content,
      'level': level,
      'media_urls': mediaUrls,
      'sop_urls': sopUrls,
      'order_index': orderIndex,
      'estimated_minutes': estimatedMinutes,
    };
  }
}

class UserProgress {
  final String userId;
  final String topicId;
  final String status;
  final int timeSpent;
  final int? lastPosition;
  final DateTime? completedAt;

  UserProgress({
    required this.userId,
    required this.topicId,
    required this.status,
    required this.timeSpent,
    this.lastPosition,
    this.completedAt,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['user_id'],
      topicId: json['topic_id'],
      status: json['status'],
      timeSpent: json['time_spent'] ?? 0,
      lastPosition: json['last_position'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'topic_id': topicId,
      'status': status,
      'time_spent': timeSpent,
      'last_position': lastPosition,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
