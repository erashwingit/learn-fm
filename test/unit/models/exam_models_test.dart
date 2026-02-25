import 'package:flutter_test/flutter_test.dart';
import 'package:learn_fm/core/models/exam_models.dart';

void main() {
  // ─── Shared Fixtures ──────────────────────────────────────────────────────
  final now = DateTime(2026, 2, 25, 10, 0, 0);

  Map<String, dynamic> questionJson(String id, int correct) => {
        'id': id,
        'exam_id': 'exam-001',
        'topic_id': 'topic-001',
        'question_text': 'What does HVAC stand for?',
        'options': [
          'Heating, Ventilation, and Air Conditioning',
          'High Voltage AC',
          'Hydraulic Valve Alternating Current',
          'None of the above',
        ],
        'correct_option': correct,
        'explanation': 'HVAC = Heating, Ventilation, and Air Conditioning.',
        'difficulty': 'easy',
      };

  Map<String, dynamic> examJson() => {
        'id': 'exam-001',
        'title': 'Technical Services – Beginner',
        'domain_id': 'domain-technical',
        'level': 'beginner',
        'num_questions': 2,
        'duration_minutes': 30,
        'passing_score': 70.0,
        'questions': [questionJson('q-001', 0), questionJson('q-002', 1)],
        'created_at': now.toIso8601String(),
        'is_active': true,
      };

  // ─── ExamQuestion ─────────────────────────────────────────────────────────
  group('ExamQuestion', () {
    test('fromJson parses all fields correctly', () {
      final q = ExamQuestion.fromJson(questionJson('q-001', 0));

      expect(q.id, equals('q-001'));
      expect(q.examId, equals('exam-001'));
      expect(q.questionText, equals('What does HVAC stand for?'));
      expect(q.options.length, equals(4));
      expect(q.correctOption, equals(0));
      expect(q.difficulty, equals('easy'));
    });

    test('toJson serializes correctly', () {
      final q = ExamQuestion.fromJson(questionJson('q-001', 0));
      final json = q.toJson();

      expect(json['id'], equals('q-001'));
      expect(json['correct_option'], equals(0));
      expect((json['options'] as List).length, equals(4));
    });

    test('round-trip fromJson → toJson preserves data', () {
      final q = ExamQuestion.fromJson(questionJson('q-001', 2));
      final q2 = ExamQuestion.fromJson(q.toJson());

      expect(q2.id, equals(q.id));
      expect(q2.correctOption, equals(2));
    });
  });

  // ─── Exam ─────────────────────────────────────────────────────────────────
  group('Exam', () {
    test('fromJson parses all fields including nested questions', () {
      final exam = Exam.fromJson(examJson());

      expect(exam.id, equals('exam-001'));
      expect(exam.title, equals('Technical Services – Beginner'));
      expect(exam.level, equals('beginner'));
      expect(exam.durationMinutes, equals(30));
      expect(exam.passingScore, equals(70.0));
      expect(exam.questions.length, equals(2));
      expect(exam.isActive, isTrue);
    });

    test('fromJson handles empty questions list', () {
      final json = examJson()..['questions'] = null;
      final exam = Exam.fromJson(json);

      expect(exam.questions, isEmpty);
    });

    test('toJson serializes correctly', () {
      final exam = Exam.fromJson(examJson());
      final json = exam.toJson();

      expect(json['id'], equals('exam-001'));
      expect(json['passing_score'], equals(70.0));
      expect(json['is_active'], isTrue);
    });
  });

  // ─── ExamAttempt ─────────────────────────────────────────────────────────
  group('ExamAttempt', () {
    late Exam exam;

    setUp(() => exam = Exam.fromJson(examJson()));

    ExamAttempt makeAttempt(Map<String, int> answers) => ExamAttempt(
          id: 'attempt-001',
          userId: 'user-001',
          examId: 'exam-001',
          exam: exam,
          score: 50.0,
          timeTaken: 900,
          answers: answers,
          attemptedAt: now,
        );

    test('correctAnswers counts right answers', () {
      // q-001 correct=0, q-002 correct=1
      final attempt = makeAttempt({'q-001': 0, 'q-002': 1});
      expect(attempt.correctAnswers, equals(2));
    });

    test('correctAnswers returns 0 when all wrong', () {
      final attempt = makeAttempt({'q-001': 3, 'q-002': 3});
      expect(attempt.correctAnswers, equals(0));
    });

    test('incorrectAnswers counts wrong answers (answered only)', () {
      final attempt = makeAttempt({'q-001': 3, 'q-002': 0});
      expect(attempt.incorrectAnswers, equals(2));
    });

    test('unattemptedAnswers reflects skipped questions', () {
      final attempt = makeAttempt({'q-001': 0}); // skipped q-002
      expect(attempt.unattemptedAnswers, equals(1));
    });

    test('toJson serializes answers map', () {
      final attempt = makeAttempt({'q-001': 0, 'q-002': 1});
      final json = attempt.toJson();

      expect(json['answers'], equals({'q-001': 0, 'q-002': 1}));
      expect(json['time_taken'], equals(900));
      expect(json['is_completed'], isTrue);
    });
  });

  // ─── DailyQuiz ────────────────────────────────────────────────────────────
  group('DailyQuiz', () {
    test('fromJson parses date and questions', () {
      final json = {
        'date': '2026-02-25',
        'questions': [questionJson('dq-001', 0)],
        'created_at': now.toIso8601String(),
      };
      final quiz = DailyQuiz.fromJson(json);

      expect(quiz.date, equals('2026-02-25'));
      expect(quiz.questions.length, equals(1));
    });

    test('toJson round-trip preserves date', () {
      final json = {
        'date': '2026-02-25',
        'questions': [questionJson('dq-001', 1)],
        'created_at': now.toIso8601String(),
      };
      final quiz = DailyQuiz.fromJson(json);
      final out = quiz.toJson();

      expect(out['date'], equals('2026-02-25'));
    });
  });

  // ─── DailyQuizAttempt ─────────────────────────────────────────────────────
  group('DailyQuizAttempt', () {
    test('fromJson parses score and answers', () {
      final json = {
        'user_id': 'user-001',
        'date': '2026-02-25',
        'score': 80.0,
        'answers': {'dq-001': 0},
        'attempted_at': now.toIso8601String(),
      };
      final attempt = DailyQuizAttempt.fromJson(json);

      expect(attempt.score, equals(80.0));
      expect(attempt.answers['dq-001'], equals(0));
    });

    test('toJson serializes correctly', () {
      final json = {
        'user_id': 'user-001',
        'date': '2026-02-25',
        'score': 60.0,
        'answers': {'dq-001': 2},
        'attempted_at': now.toIso8601String(),
      };
      final attempt = DailyQuizAttempt.fromJson(json);
      final out = attempt.toJson();

      expect(out['score'], equals(60.0));
      expect(out['answers'], equals({'dq-001': 2}));
    });
  });
}
