import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../network/secure_http_client.dart';

/// Secure AI Service — all Claude API calls are proxied through the
/// Supabase Edge Function (supabase/functions/ai-chat/index.ts).
///
/// The Anthropic API key NEVER leaves the server.
class AiServiceSecure extends ChangeNotifier {
  final SupabaseClient _supabase;
  http.Client? _httpClient;

  List<_ChatMessage> _history = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _dailyQueriesUsed = 0;

  AiServiceSecure(this._supabase);

  // ─── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<_ChatMessage> get history => List.unmodifiable(_history);
  bool get isRateLimited => _dailyQueriesUsed >= AppConfig.maxAiQueriesPerDay;
  int get remainingQueries =>
      (AppConfig.maxAiQueriesPerDay - _dailyQueriesUsed).clamp(0, AppConfig.maxAiQueriesPerDay);

  // ─── Initialization ────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _httpClient = await SecureHttpClient.create();
    await _loadDailyUsage();
  }

  Future<void> _loadDailyUsage() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _supabase
          .from('ai_usage_log')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', '${today}T00:00:00.000Z');

      _dailyQueriesUsed = (response as List).length;
      notifyListeners();
    } catch (_) {
      // Non-fatal: usage display may be inaccurate but feature still works
    }
  }

  // ─── Send a message ────────────────────────────────────────────────────────
  Future<String?> sendMessage(
    String question, {
    String? domainContext,
    String language = 'en',
  }) async {
    if (isRateLimited) {
      _errorMessage = 'You have reached your daily AI query limit (${AppConfig.maxAiQueriesPerDay}/day). Try again tomorrow!';
      notifyListeners();
      return null;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _errorMessage = 'Please sign in to use the AI assistant.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    _history = [
      ..._history,
      _ChatMessage(role: 'user', content: question),
    ];
    notifyListeners();

    try {
      // Get a fresh JWT for the Edge Function call
      final session = _supabase.auth.currentSession;
      if (session == null) throw Exception('Session expired');

      final client = _httpClient!;
      final response = await client.post(
        Uri.parse(AppConfig.aiEdgeFunctionUrl),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': question,
          'conversationHistory': _history
              .take(_history.length - 1) // exclude the message we just added
              .map((m) => m.toJson())
              .toList(),
          'domainContext': domainContext,
          'language': language,
        }),
      );

      if (response.statusCode == 429) {
        _errorMessage = 'Daily AI query limit reached. Try again tomorrow!';
        _history = _history..removeLast();
        notifyListeners();
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception('Edge Function returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final answer = data['answer'] as String? ?? '';

      // Append assistant reply to history
      _history = [
        ..._history,
        _ChatMessage(role: 'assistant', content: answer),
      ];
      _dailyQueriesUsed++;

      notifyListeners();
      return answer;
    } catch (e) {
      _errorMessage = 'Unable to get AI response. Please try again.';
      // Remove the user message we added optimistically
      _history = _history..removeLast();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  void clearHistory() {
    _history = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _httpClient?.close();
    super.dispose();
  }
}

// ─── Internal model ──────────────────────────────────────────────────────────
class _ChatMessage {
  final String role;
  final String content;

  const _ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
