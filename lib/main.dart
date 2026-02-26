import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn FM'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'AI-Powered Learning Platform',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'For Facility Management Professionals',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
