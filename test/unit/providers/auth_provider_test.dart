import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:learn_fm/core/providers/auth_provider.dart';
import 'package:learn_fm/core/models/user_profile.dart';

import 'auth_provider_test.mocks.dart';

// Run: dart run build_runner build --delete-conflicting-outputs
@GenerateMocks([SupabaseClient, GoTrueClient])
void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(mockSupabase.auth).thenReturn(mockAuth);
    when(mockAuth.currentUser).thenReturn(null);
    when(mockAuth.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
  });

  // ─── Initial State ────────────────────────────────────────────────────────
  group('Initial state', () {
    test('isAuthenticated is false when no user', () {
      final provider = AuthProvider.withClient(mockSupabase);

      expect(provider.isAuthenticated, isFalse);
      expect(provider.user, isNull);
      expect(provider.userProfile, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });

  // ─── signInWithOTP ─────────────────────────────────────────────────────────
  group('signInWithOTP', () {
    test('calls supabase signInWithOtp and clears loading on success',
        () async {
      when(mockAuth.signInWithOtp(phone: anyNamed('phone')))
          .thenAnswer((_) async {});

      final provider = AuthProvider.withClient(mockSupabase);
      await provider.signInWithOTP('+919876543210');

      verify(mockAuth.signInWithOtp(phone: '+919876543210')).called(1);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage on exception', () async {
      when(mockAuth.signInWithOtp(phone: anyNamed('phone')))
          .thenThrow(Exception('Network error'));

      final provider = AuthProvider.withClient(mockSupabase);
      await provider.signInWithOTP('+919999999999');

      expect(provider.errorMessage, contains('Failed to send OTP'));
      expect(provider.isLoading, isFalse);
    });
  });

  // ─── verifyOTP ─────────────────────────────────────────────────────────────
  group('verifyOTP', () {
    test('calls supabase verifyOTP with correct params', () async {
      when(mockAuth.verifyOTP(
        phone: anyNamed('phone'),
        token: anyNamed('token'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => AuthResponse());

      final provider = AuthProvider.withClient(mockSupabase);
      await provider.verifyOTP('+919876543210', '123456');

      verify(mockAuth.verifyOTP(
        phone: '+919876543210',
        token: '123456',
        type: OtpType.sms,
      )).called(1);
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage on invalid OTP', () async {
      when(mockAuth.verifyOTP(
        phone: anyNamed('phone'),
        token: anyNamed('token'),
        type: anyNamed('type'),
      )).thenThrow(Exception('Invalid token'));

      final provider = AuthProvider.withClient(mockSupabase);
      await provider.verifyOTP('+919876543210', '000000');

      expect(provider.errorMessage, contains('Invalid OTP'));
    });
  });

  // ─── signOut ───────────────────────────────────────────────────────────────
  group('signOut', () {
    test('calls supabase signOut and clears userProfile', () async {
      when(mockAuth.signOut()).thenAnswer((_) async {});

      final provider = AuthProvider.withClient(mockSupabase);
      await provider.signOut();

      verify(mockAuth.signOut()).called(1);
      expect(provider.userProfile, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('sets errorMessage when signOut throws', () async {
      when(mockAuth.signOut()).thenThrow(Exception('Sign out failed'));

      final provider = AuthProvider.withClient(mockSupabase);
      await provider.signOut();

      expect(provider.errorMessage, contains('Failed to sign out'));
    });
  });

  // ─── clearError ────────────────────────────────────────────────────────────
  group('clearError', () {
    test('clears errorMessage and notifies listeners', () async {
      when(mockAuth.signInWithOtp(phone: anyNamed('phone')))
          .thenThrow(Exception('err'));

      final provider = AuthProvider.withClient(mockSupabase);
      await provider.signInWithOTP('+910000000000');

      expect(provider.errorMessage, isNotNull);

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });
}
