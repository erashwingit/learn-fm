// Compatibility shim: main.dart imports CourseListScreen from this file.
// The full implementation lives in courses_screen.dart (CoursesScreen).
import 'courses_screen.dart';
export 'courses_screen.dart';

// Type alias so `CourseListScreen()` resolves to `CoursesScreen()`.
typedef CourseListScreen = CoursesScreen;
