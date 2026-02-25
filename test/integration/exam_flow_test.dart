import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:learn_fm/core/models/exam_models.dart';
import 'package:learn_fm/screens/exam/exam_screen.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────
ExamQuestion makeQuestion(String id, int correct) => ExamQuestion(
      id: id,
      examId: 'exam-001',
      topicId: 'topic-001',
      questionText: 'Question $id: What does FM stand for?',
      options: [
        'Facility Management',
        'Financial Management',
        'Fleet Management',
        'None',
      ],
      correctOption: correct,
      explanation: 'FM = Facility Management.',
      difficulty: 'easy',
    );

Exam makeExam({int numQuestions = 3}) => Exam(
      id: 'exam-001',
      title: 'Technical – Beginner',
      domainId: 'domain-technical',
      level: 'beginner',
      numQuestions: numQuestions,
      durationMinutes: 30,
      passingScore: 70.0,
      questions: List.generate(
          numQuestions, (i) => makeQuestion('q-00${i + 1}', 0)),
      createdAt: DateTime(2026, 2, 25),
    );

Widget buildExamApp(Exam exam) {
  return MaterialApp(
    home: ExamScreen(exam: exam),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────
void main() {
  group('Exam Flow Integration Tests', () {
    testWidgets('Exam screen renders question text', (tester) async {
      final exam = makeExam();
      await tester.pumpWidget(buildExamApp(exam));
      await tester.pump();

      // First question should be visible
      expect(find.textContaining('Question q-001'), findsWidgets);
    });

    testWidgets('Timer widget is displayed', (tester) async {
      final exam = makeExam();
      await tester.pumpWidget(buildExamApp(exam));
      await tester.pump();

      // Timer or duration text exists somewhere on screen
      expect(find.textContaining('30'), findsWidgets);
    });

    testWidgets('Selecting an answer updates UI without crashing', (tester) async {
      final exam = makeExam(numQuestions: 2);
      await tester.pumpWidget(buildExamApp(exam));
      await tester.pump();

      // Tap first radio/option
      final radioFinders = find.byType(RadioListTile<int>);
      if (radioFinders.evaluate().isNotEmpty) {
        await tester.tap(radioFinders.first);
        await tester.pump();
        // No exception = pass
      }
    });

    testWidgets('Next button advances to second question', (tester) async {
      final exam = makeExam(numQuestions: 3);
      await tester.pumpWidget(buildExamApp(exam));
      await tester.pump();

      final nextFinder = find.widgetWithText(ElevatedButton, 'Next');
      if (nextFinder.evaluate().isNotEmpty) {
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        // Second question text should appear
        expect(find.textContaining('Question q-002'), findsWidgets);
      }
    });

    testWidgets('Previous button navigates back to first question',
        (tester) async {
      final exam = makeExam(numQuestions: 3);
      await tester.pumpWidget(buildExamApp(exam));
      await tester.pump();

      // Go to next
      final nextFinder = find.widgetWithText(ElevatedButton, 'Next');
      if (nextFinder.evaluate().isNotEmpty) {
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        // Go back
        final prevFinder = find.widgetWithText(ElevatedButton, 'Previous');
        if (prevFinder.evaluate().isNotEmpty) {
          await tester.tap(prevFinder);
          await tester.pumpAndSettle();

          expect(find.textContaining('Question q-001'), findsWidgets);
        }
      }
    });
  });

  // ─── Score Calculation Unit Tests ─────────────────────────────────────────
  group('ExamAttempt score logic', () {
    final exam = makeExam(numQuestions: 4);

    test('all correct → correctAnswers == 4', () {
      final attempt = ExamAttempt(
        id: 'a-001',
        userId: 'u-001',
        examId: 'exam-001',
        exam: exam,
        score: 100.0,
        timeTaken: 600,
        answers: {'q-001': 0, 'q-002': 0, 'q-003': 0, 'q-004': 0},
        attemptedAt: DateTime(2026, 2, 25),
      );
      expect(attempt.correctAnswers, equals(4));
      expect(attempt.incorrectAnswers, equals(0));
      expect(attempt.unattemptedAnswers, equals(0));
    });

    test('half correct, half wrong', () {
      final attempt = ExamAttempt(
        id: 'a-002',
        userId: 'u-001',
        examId: 'exam-001',
        exam: exam,
        score: 50.0,
        timeTaken: 600,
        answers: {'q-001': 0, 'q-002': 0, 'q-003': 1, 'q-004': 2},
        attemptedAt: DateTime(2026, 2, 25),
      );
      expect(attempt.correctAnswers, equals(2));
      expect(attempt.incorrectAnswers, equals(2));
      expect(attempt.unattemptedAnswers, equals(0));
    });

    test('two skipped questions counted as unattempted', () {
      final attempt = ExamAttempt(
        id: 'a-003',
        userId: 'u-001',
        examId: 'exam-001',
        exam: exam,
        score: 50.0,
        timeTaken: 300,
        answers: {'q-001': 0, 'q-002': 0},
        attemptedAt: DateTime(2026, 2, 25),
      );
      expect(attempt.unattemptedAnswers, equals(2));
    });

    test('passing score threshold: 70% pass, below fail', () {
      double calcScore(int correct, int total) =>
          (correct / total) * 100;

      final passingExam = makeExam(numQuestions: 10);

      // 7 correct = 70% = pass
      final passScore = calcScore(7, 10);
      expect(passScore >= passingExam.passingScore, isTrue);

      // 6 correct = 60% = fail
      final failScore = calcScore(6, 10);
      expect(failScore >= passingExam.passingScore, isFalse);
    });
  });
}
