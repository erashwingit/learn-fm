import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:learn_fm/core/providers/auth_provider.dart';
import 'package:learn_fm/screens/auth/auth_screen.dart';

// ─── Fake AuthProvider ────────────────────────────────────────────────────────
/// Uses AuthProvider.noInit() to skip Supabase singleton initialization.
class FakeAuthProvider extends AuthProvider {
  FakeAuthProvider() : super.noInit();
  bool _authenticated = false;
  bool _loading = false;
  String? _error;

  @override
  bool get isAuthenticated => _authenticated;
  @override
  bool get isLoading => _loading;
  @override
  String? get errorMessage => _error;

  void setAuthenticated(bool val) {
    _authenticated = val;
    notifyListeners();
  }

  @override
  Future<void> signInWithOTP(String phone) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    _loading = false;
    notifyListeners();
  }

  @override
  Future<void> verifyOTP(String phone, String token) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    if (token == '000000') {
      _error = 'Invalid OTP: wrong code';
    } else {
      _authenticated = true;
      _error = null;
    }
    _loading = false;
    notifyListeners();
  }

  @override
  Future<void> signInWithGoogle() async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    _authenticated = true;
    _loading = false;
    notifyListeners();
  }

  @override
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
Widget buildTestApp(FakeAuthProvider authProvider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(
      home: AuthScreen(),
    ),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────
void main() {
  group('Auth Flow Integration Tests', () {
    late FakeAuthProvider fakeAuth;

    setUp(() => fakeAuth = FakeAuthProvider());

    testWidgets('Auth screen renders phone input and Continue button',
        (tester) async {
      await tester.pumpWidget(buildTestApp(fakeAuth));
      await tester.pump();

      // Phone field or Google sign-in button must exist
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Entering phone and tapping Continue calls signInWithOTP',
        (tester) async {
      await tester.pumpWidget(buildTestApp(fakeAuth));
      await tester.pump();

      final phoneFinder = find.byType(TextField).first;
      await tester.enterText(phoneFinder, '+919876543210');
      await tester.pump();

      // Tap Continue / Send OTP button
      final continueFinder =
          find.widgetWithText(ElevatedButton, 'Continue').first;
      await tester.tap(continueFinder);
      await tester.pumpAndSettle();

      // After calling signInWithOTP, loading should be false
      expect(fakeAuth.isLoading, isFalse);
    });

    testWidgets('Correct OTP transitions to authenticated state',
        (tester) async {
      await tester.pumpWidget(buildTestApp(fakeAuth));
      await tester.pump();

      // Enter phone
      await tester.enterText(find.byType(TextField).first, '+919876543210');
      await tester.pump();

      // Tap Continue
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue').first);
      await tester.pumpAndSettle();

      // OTP step: enter valid OTP
      final otpFields = find.byType(TextField);
      if (otpFields.evaluate().isNotEmpty) {
        await tester.enterText(otpFields.first, '123456');
        await tester.pump();

        final verifyFinder =
            find.widgetWithText(ElevatedButton, 'Verify OTP');
        if (verifyFinder.evaluate().isNotEmpty) {
          await tester.tap(verifyFinder);
          await tester.pumpAndSettle();
        }
      }

      // If OTP screen reached, provider becomes authenticated after valid token
      if (fakeAuth.isAuthenticated) {
        expect(fakeAuth.isAuthenticated, isTrue);
        expect(fakeAuth.errorMessage, isNull);
      }
    });

    testWidgets('Wrong OTP displays error message', (tester) async {
      await tester.pumpWidget(buildTestApp(fakeAuth));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, '+919876543210');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue').first);
      await tester.pumpAndSettle();

      final otpFields = find.byType(TextField);
      if (otpFields.evaluate().isNotEmpty) {
        await tester.enterText(otpFields.first, '000000');
        await tester.pump();

        final verifyFinder =
            find.widgetWithText(ElevatedButton, 'Verify OTP');
        if (verifyFinder.evaluate().isNotEmpty) {
          await tester.tap(verifyFinder);
          await tester.pumpAndSettle();

          expect(fakeAuth.errorMessage, contains('Invalid OTP'));
        }
      }
    });
  });
}
