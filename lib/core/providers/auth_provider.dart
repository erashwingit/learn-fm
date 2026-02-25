import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  late final SupabaseClient _supabase;

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ────────────────────────────────────────────────────────────────
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // ─── Constructors ───────────────────────────────────────────────────────────

  /// Default production constructor — uses the Supabase singleton.
  AuthProvider() {
    _supabase = Supabase.instance.client;
    _initialize();
  }

  /// Testability constructor — accepts an injectable [SupabaseClient].
  /// Does NOT call [_initialize] so unit tests can set up mocks cleanly.
  @visibleForTesting
  AuthProvider.withClient(SupabaseClient client) {
    _supabase = client;
    // Skip _initialize() — tests wire up auth-state manually.
  }

  /// Protected no-op constructor for test subclasses (e.g. FakeAuthProvider).
  /// Avoids touching the Supabase singleton at construction time.
  @protected
  AuthProvider.noInit() {
    // _supabase is never accessed in subclasses that override all methods.
    // Assign a non-null sentinel to satisfy late final; it's never called.
    _supabase = _NullSupabaseClient._instance;
  }

  // ─── Initialization ─────────────────────────────────────────────────────────
  void _initialize() {
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.user;
      if (_user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });

    if (_user != null) {
      _loadUserProfile();
    }
  }

  // ─── Auth Operations ────────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.learnfm://login-callback/',
      );
    } catch (e) {
      _setError('Failed to sign in with Google. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithOTP(String phone) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.auth.signInWithOtp(phone: phone);
    } catch (e) {
      _setError('Failed to send OTP. Please check the number and try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyOTP(String phone, String token) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
    } catch (e) {
      _setError('Invalid OTP. Please check the code and try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _supabase.auth.signOut();
      _userProfile = null;
    } catch (e) {
      _setError('Failed to sign out. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // ─── Profile Operations ──────────────────────────────────────────────────────
  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .single();

      _userProfile = UserProfile.fromJson(response);
      notifyListeners();
    } catch (_) {
      _userProfile = null; // Profile not yet created — user needs setup flow
    }
  }

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('profiles').insert(profile.toJson());
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      _setError('Failed to create profile. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);

      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}

// ─── Sentinel for noInit() constructor ───────────────────────────────────────
/// Never actually used at runtime — exists only to satisfy the late final
/// assignment requirement in the [AuthProvider.noInit] constructor.
class _NullSupabaseClient extends SupabaseClient {
  static final _NullSupabaseClient _instance =
      _NullSupabaseClient._('', '');

  _NullSupabaseClient._(super.supabaseUrl, super.supabaseKey);
}
