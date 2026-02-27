import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/courses/course_detail_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/upload_content_screen.dart';
import 'screens/admin/upload_lesson_screen.dart';
import 'screens/admin/manage_courses_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseUrl = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zlpoxljnsqgefktkhprk.supabase.co',
  );
  final supabaseAnonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpscG94bGpuc3FnZWZrdGtocHJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwNzMzODMsImV4cCI6MjA4NzY0OTM4M30.wYqXUEn6oQHuKRPbeCWlyRuqnLy4VieugCnAViWrvHU',
  );

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/course-detail': (context) => const CourseDetailScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/admin/upload-course': (context) => const UploadCourseScreen(),
        '/admin/upload-lesson': (context) => const UploadLessonScreen(),
        '/admin/manage-courses': (context) => const ManageCoursesScreen(),
      },
    );
  }
}
