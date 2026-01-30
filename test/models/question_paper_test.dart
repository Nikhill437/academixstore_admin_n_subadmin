import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:academixstore_admin_n_subadmin/models/question_paper.dart';

void main() {
  group('QuestionPaper Model Tests', () {
    // Feature: question-paper-upload-for-books, Property 1: Serialization round trip
    // **Validates: Requirements 1.1**
    test('property: serialization round trip preserves all fields', () {
      // Run 100 iterations to ensure comprehensive coverage
      for (int i = 0; i < 100; i++) {
        // Generate a random QuestionPaper object
        final original = _generateRandomQuestionPaper(i);

        // Serialize to JSON
        final json = original.toJson();

        // Deserialize back to QuestionPaper
        final deserialized = QuestionPaper.fromJson(json);

        // Verify all required fields are preserved
        expect(deserialized.id, equals(original.id),
            reason: 'ID should be preserved in round trip');
        expect(deserialized.title, equals(original.title),
            reason: 'Title should be preserved in round trip');
        expect(deserialized.subject, equals(original.subject),
            reason: 'Subject should be preserved in round trip');
        expect(deserialized.year, equals(original.year),
            reason: 'Year should be preserved in round trip');
        expect(deserialized.semester, equals(original.semester),
            reason: 'Semester should be preserved in round trip');
        expect(deserialized.isActive, equals(original.isActive),
            reason: 'isActive should be preserved in round trip');

        // Verify optional fields are preserved
        expect(deserialized.description, equals(original.description),
            reason: 'Description should be preserved in round trip');
        expect(deserialized.examType, equals(original.examType),
            reason: 'Exam type should be preserved in round trip');
        expect(deserialized.marks, equals(original.marks),
            reason: 'Marks should be preserved in round trip');
        expect(deserialized.collegeId, equals(original.collegeId),
            reason: 'College ID should be preserved in round trip');
        expect(deserialized.pdfUrl, equals(original.pdfUrl),
            reason: 'PDF URL should be preserved in round trip');
        expect(deserialized.pdfAccessUrl, equals(original.pdfAccessUrl),
            reason: 'PDF access URL should be preserved in round trip');

        // Verify DateTime fields are preserved (comparing ISO strings for precision)
        expect(
            deserialized.createdAt.toIso8601String(),
            equals(original.createdAt.toIso8601String()),
            reason: 'Created at should be preserved in round trip');
        expect(
            deserialized.updatedAt?.toIso8601String(),
            equals(original.updatedAt?.toIso8601String()),
            reason: 'Updated at should be preserved in round trip');
      }
    });

    test('property: serialization round trip with minimal required fields', () {
      // Test with only required fields (no optional fields)
      for (int i = 0; i < 50; i++) {
        final original = QuestionPaper(
          id: 'id-$i',
          title: 'Title $i',
          subject: 'Subject $i',
          year: (i % 4) + 1,
          semester: (i % 8) + 1,
          createdAt: DateTime.now().subtract(Duration(days: i)),
        );

        final json = original.toJson();
        final deserialized = QuestionPaper.fromJson(json);

        expect(deserialized.id, equals(original.id));
        expect(deserialized.title, equals(original.title));
        expect(deserialized.subject, equals(original.subject));
        expect(deserialized.year, equals(original.year));
        expect(deserialized.semester, equals(original.semester));
        expect(deserialized.isActive, equals(original.isActive));
        expect(
            deserialized.createdAt.toIso8601String(),
            equals(original.createdAt.toIso8601String()));

        // Verify optional fields are null
        expect(deserialized.description, isNull);
        expect(deserialized.examType, isNull);
        expect(deserialized.marks, isNull);
        expect(deserialized.collegeId, isNull);
        expect(deserialized.pdfUrl, isNull);
        expect(deserialized.pdfAccessUrl, isNull);
        expect(deserialized.updatedAt, isNull);
      }
    });

    test('property: serialization round trip with all optional fields', () {
      // Test with all optional fields populated
      for (int i = 0; i < 50; i++) {
        final original = _generateRandomQuestionPaperWithAllFields(i);

        final json = original.toJson();
        final deserialized = QuestionPaper.fromJson(json);

        // Verify all fields including optional ones
        expect(deserialized.id, equals(original.id));
        expect(deserialized.title, equals(original.title));
        expect(deserialized.subject, equals(original.subject));
        expect(deserialized.year, equals(original.year));
        expect(deserialized.semester, equals(original.semester));
        expect(deserialized.description, equals(original.description));
        expect(deserialized.examType, equals(original.examType));
        expect(deserialized.marks, equals(original.marks));
        expect(deserialized.collegeId, equals(original.collegeId));
        expect(deserialized.pdfUrl, equals(original.pdfUrl));
        expect(deserialized.pdfAccessUrl, equals(original.pdfAccessUrl));
        expect(deserialized.isActive, equals(original.isActive));
        expect(
            deserialized.createdAt.toIso8601String(),
            equals(original.createdAt.toIso8601String()));
        expect(
            deserialized.updatedAt?.toIso8601String(),
            equals(original.updatedAt?.toIso8601String()));
      }
    });

    test('property: JSON keys use snake_case format', () {
      // Verify that JSON serialization uses snake_case for API compatibility
      final questionPaper = QuestionPaper(
        id: 'test-id',
        title: 'Test Title',
        subject: 'Test Subject',
        year: 2,
        semester: 3,
        examType: 'midterm',
        marks: 100,
        collegeId: 'college-123',
        pdfUrl: 'https://example.com/pdf.pdf',
        pdfAccessUrl: 'https://example.com/access.pdf',
        isActive: true,
        createdAt: DateTime.parse('2024-01-01T10:00:00Z'),
        updatedAt: DateTime.parse('2024-01-02T10:00:00Z'),
      );

      final json = questionPaper.toJson();

      // Verify snake_case keys
      expect(json.containsKey('exam_type'), isTrue,
          reason: 'JSON should use exam_type (snake_case)');
      expect(json.containsKey('college_id'), isTrue,
          reason: 'JSON should use college_id (snake_case)');
      expect(json.containsKey('pdf_url'), isTrue,
          reason: 'JSON should use pdf_url (snake_case)');
      expect(json.containsKey('pdf_access_url'), isTrue,
          reason: 'JSON should use pdf_access_url (snake_case)');
      expect(json.containsKey('is_active'), isTrue,
          reason: 'JSON should use is_active (snake_case)');
      expect(json.containsKey('created_at'), isTrue,
          reason: 'JSON should use created_at (snake_case)');
      expect(json.containsKey('updated_at'), isTrue,
          reason: 'JSON should use updated_at (snake_case)');

      // Verify values
      expect(json['exam_type'], equals('midterm'));
      expect(json['college_id'], equals('college-123'));
      expect(json['pdf_url'], equals('https://example.com/pdf.pdf'));
      expect(json['pdf_access_url'], equals('https://example.com/access.pdf'));
      expect(json['is_active'], equals(true));
    });

    test('property: fromJson handles snake_case keys correctly', () {
      // Test that fromJson correctly parses snake_case keys from API
      final json = {
        'id': 'test-id',
        'title': 'Test Title',
        'subject': 'Test Subject',
        'year': 2,
        'semester': 3,
        'exam_type': 'final',
        'marks': 150,
        'college_id': 'college-456',
        'pdf_url': 'https://example.com/test.pdf',
        'pdf_access_url': 'https://example.com/access-test.pdf',
        'is_active': false,
        'created_at': '2024-01-01T10:00:00Z',
        'updated_at': '2024-01-02T10:00:00Z',
      };

      final questionPaper = QuestionPaper.fromJson(json);

      expect(questionPaper.id, equals('test-id'));
      expect(questionPaper.title, equals('Test Title'));
      expect(questionPaper.subject, equals('Test Subject'));
      expect(questionPaper.year, equals(2));
      expect(questionPaper.semester, equals(3));
      expect(questionPaper.examType, equals('final'));
      expect(questionPaper.marks, equals(150));
      expect(questionPaper.collegeId, equals('college-456'));
      expect(questionPaper.pdfUrl, equals('https://example.com/test.pdf'));
      expect(questionPaper.pdfAccessUrl,
          equals('https://example.com/access-test.pdf'));
      expect(questionPaper.isActive, equals(false));
      expect(questionPaper.createdAt.toIso8601String(),
          equals('2024-01-01T10:00:00.000Z'));
      expect(questionPaper.updatedAt?.toIso8601String(),
          equals('2024-01-02T10:00:00.000Z'));
    });

    test('property: toJson excludes null optional fields', () {
      // Verify that null optional fields are not included in JSON
      final questionPaper = QuestionPaper(
        id: 'test-id',
        title: 'Test Title',
        subject: 'Test Subject',
        year: 2,
        semester: 3,
        createdAt: DateTime.parse('2024-01-01T10:00:00Z'),
      );

      final json = questionPaper.toJson();

      // Required fields should be present
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('subject'), isTrue);
      expect(json.containsKey('year'), isTrue);
      expect(json.containsKey('semester'), isTrue);
      expect(json.containsKey('is_active'), isTrue);
      expect(json.containsKey('created_at'), isTrue);

      // Null optional fields should be excluded
      expect(json.containsKey('description'), isFalse,
          reason: 'Null description should not be in JSON');
      expect(json.containsKey('exam_type'), isFalse,
          reason: 'Null exam_type should not be in JSON');
      expect(json.containsKey('marks'), isFalse,
          reason: 'Null marks should not be in JSON');
      expect(json.containsKey('college_id'), isFalse,
          reason: 'Null college_id should not be in JSON');
      expect(json.containsKey('pdf_url'), isFalse,
          reason: 'Null pdf_url should not be in JSON');
      expect(json.containsKey('pdf_access_url'), isFalse,
          reason: 'Null pdf_access_url should not be in JSON');
      expect(json.containsKey('updated_at'), isFalse,
          reason: 'Null updated_at should not be in JSON');
    });
  });
}

/// Generate a random QuestionPaper for property testing
QuestionPaper _generateRandomQuestionPaper(int seed) {
  final random = Random(seed);

  // Randomly decide which optional fields to include
  final includeDescription = random.nextBool();
  final includeExamType = random.nextBool();
  final includeMarks = random.nextBool();
  final includeCollegeId = random.nextBool();
  final includePdfUrl = random.nextBool();
  final includePdfAccessUrl = random.nextBool();
  final includeUpdatedAt = random.nextBool();

  final examTypes = ['midterm', 'final', 'quiz', 'practice'];

  return QuestionPaper(
    id: 'id-${random.nextInt(10000)}',
    title: 'Title ${random.nextInt(1000)} - ${_randomString(random, 20)}',
    subject: 'Subject ${random.nextInt(100)} - ${_randomString(random, 10)}',
    year: random.nextInt(4) + 1, // 1-4
    semester: random.nextInt(8) + 1, // 1-8
    description: includeDescription
        ? 'Description ${_randomString(random, 50)}'
        : null,
    examType: includeExamType ? examTypes[random.nextInt(examTypes.length)] : null,
    marks: includeMarks ? random.nextInt(200) : null,
    collegeId: includeCollegeId ? 'college-${random.nextInt(1000)}' : null,
    pdfUrl: includePdfUrl
        ? 'https://example.com/pdfs/${random.nextInt(1000)}.pdf'
        : null,
    pdfAccessUrl: includePdfAccessUrl
        ? 'https://example.com/access/${random.nextInt(1000)}.pdf'
        : null,
    isActive: random.nextBool(),
    createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
    updatedAt: includeUpdatedAt
        ? DateTime.now().subtract(Duration(days: random.nextInt(30)))
        : null,
  );
}

/// Generate a random QuestionPaper with all optional fields populated
QuestionPaper _generateRandomQuestionPaperWithAllFields(int seed) {
  final random = Random(seed);
  final examTypes = ['midterm', 'final', 'quiz', 'practice'];

  return QuestionPaper(
    id: 'id-${random.nextInt(10000)}',
    title: 'Title ${random.nextInt(1000)} - ${_randomString(random, 20)}',
    subject: 'Subject ${random.nextInt(100)} - ${_randomString(random, 10)}',
    year: random.nextInt(4) + 1,
    semester: random.nextInt(8) + 1,
    description: 'Description ${_randomString(random, 50)}',
    examType: examTypes[random.nextInt(examTypes.length)],
    marks: random.nextInt(200),
    collegeId: 'college-${random.nextInt(1000)}',
    pdfUrl: 'https://example.com/pdfs/${random.nextInt(1000)}.pdf',
    pdfAccessUrl: 'https://example.com/access/${random.nextInt(1000)}.pdf',
    isActive: random.nextBool(),
    createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
    updatedAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
  );
}

/// Generate a random string of specified length
String _randomString(Random random, int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
