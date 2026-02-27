import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/courses/course_list_screen.dart';
import 'screens/courses/course_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/upload_content_screen.dart';
import 'screens/admin/upload_lesson_screen.dart';
import 'screens/admin/manage_courses_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase — credentials are compile-time constants baked into
  // the APK via app_config.dart (String.fromEnvironment with real defaults).
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    debug: false,
  );

  runApp(const LearnFMApp());
}

class LearnFMApp extends StatelessWidget {
  const LearnFMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learn FM',
      debugShowCheckedModeBanner: false,

      // ─── Theme ──────────────────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ─── Auth-state gate ─────────────────────────────────────────────────
      // Listens to Supabase auth changes (e.g. Google OAuth redirect) and
      // routes accordingly. SplashScreen handles the initial check.
      home: const _AuthGate(),

      // ─── Named routes ────────────────────────────────────────────────────
      routes: {
        '/':                      (ctx) => const SplashScreen(),
        '/login':                 (ctx) => const LoginScreen(),
        '/register':              (ctx) => const RegisterScreen(),
        '/dashboard':             (ctx) => const DashboardScreen(),
        '/courses':               (ctx) => const CourseListScreen(),
        '/profile':               (ctx) => const ProfileScreen(),
        '/admin':                 (ctx) => const AdminDashboardScreen(),
        '/admin/upload-course':   (ctx) => const UploadCourseScreen(),
        '/admin/upload-lesson':   (ctx) => const UploadLessonScreen(),
        '/admin/manage-courses':  (ctx) => const ManageCoursesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/course-detail') {
          return MaterialPageRoute(
            builder: (_) => const CourseDetailScreen(),
            settings: settings,
          );
        }
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      },
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────
/// Reacts to Supabase auth state changes globally (sign-in / sign-out /
/// OAuth browser redirects) so any screen transition is handled in one place.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (event == AuthChangeEvent.signedOut) {
        Navigator.pushReplacementNamed(context, '/');
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
