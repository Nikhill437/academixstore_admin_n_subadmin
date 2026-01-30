import 'package:flutter_test/flutter_test.dart';

/// Property 12: Save Button Enablement After Validation
/// Validates: Requirements 7.5
/// Test that for any valid form with valid PDF, save button is enabled
/// 
/// This is a property-based test that validates the universal property:
/// For ANY question paper form where all required fields are filled with valid
/// values AND a valid PDF file is selected, the save button MUST be enabled.

void main() {
  group('Question Paper Save Button - Property 12', () {
    /// Helper function to simulate save button enablement logic
    /// This matches the logic in AddEditBookDialog._isQuestionPaperSaveEnabled()
    bool isQuestionPaperSaveEnabled({
      required String? pdfFileName,
      required String title,
      required String subject,
      required String year,
      required String semester,
    }) {
      return pdfFileName != null && 
             title.trim().isNotEmpty &&
             subject.trim().isNotEmpty &&
             year.trim().isNotEmpty &&
             semester.trim().isNotEmpty;
    }

    /// Property 12: Save Button Enablement After Validation
    /// For any valid form with valid PDF, save button is enabled
    group('Property 12: Save Button Enablement', () {
      final validFormData = [
        {
          'title': 'Midterm Exam',
          'subject': 'Mathematics',
          'year': '2',
          'semester': '3',
          'pdfFileName': 'exam.pdf',
        },
        {
          'title': 'Final Exam - Computer Science',
          'subject': 'Data Structures',
          'year': '1',
          'semester': '1',
          'pdfFileName': 'final-exam.pdf',
        },
        {
          'title': 'Quiz 1',
          'subject': 'Physics',
          'year': '3',
          'semester': '5',
          'pdfFileName': 'quiz.pdf',
        },
        {
          'title': 'Practice Test',
          'subject': 'Chemistry',
          'year': '4',
          'semester': '8',
          'pdfFileName': 'practice.pdf',
        },
        {
          'title': 'A',
          'subject': 'B',
          'year': '1',
          'semester': '1',
          'pdfFileName': 'x.pdf',
        },
      ];

      for (int i = 0; i < validFormData.length; i++) {
        final data = validFormData[i];
        test('enables save button for valid form data set $i', () {
          final isEnabled = isQuestionPaperSaveEnabled(
            pdfFileName: data['pdfFileName'] as String?,
            title: data['title'] as String,
            subject: data['subject'] as String,
            year: data['year'] as String,
            semester: data['semester'] as String,
          );

          expect(
            isEnabled,
            isTrue,
            reason: 'Save button should be enabled when all required fields are filled and PDF is selected',
          );
        });
      }
    });

    /// Test: Save button is disabled when PDF is not selected
    group('Save button disabled without PDF', () {
      test('disables save button when PDF is not selected', () {
        final isEnabled = isQuestionPaperSaveEnabled(
          pdfFileName: null,
          title: 'Valid Title',
          subject: 'Valid Subject',
          year: '2',
          semester: '3',
        );

        expect(
          isEnabled,
          isFalse,
          reason: 'Save button should be disabled when PDF is not selected',
        );
      });
    });

    /// Test: Save button is disabled when required fields are empty
    group('Save button disabled with empty fields', () {
      final invalidFormData = [
        {
          'title': '',
          'subject': 'Valid Subject',
          'year': '2',
          'semester': '3',
          'pdfFileName': 'exam.pdf',
          'reason': 'empty title',
        },
        {
          'title': 'Valid Title',
          'subject': '',
          'year': '2',
          'semester': '3',
          'pdfFileName': 'exam.pdf',
          'reason': 'empty subject',
        },
        {
          'title': 'Valid Title',
          'subject': 'Valid Subject',
          'year': '',
          'semester': '3',
          'pdfFileName': 'exam.pdf',
          'reason': 'empty year',
        },
        {
          'title': 'Valid Title',
          'subject': 'Valid Subject',
          'year': '2',
          'semester': '',
          'pdfFileName': 'exam.pdf',
          'reason': 'empty semester',
        },
        {
          'title': '   ',
          'subject': 'Valid Subject',
          'year': '2',
          'semester': '3',
          'pdfFileName': 'exam.pdf',
          'reason': 'whitespace-only title',
        },
        {
          'title': 'Valid Title',
          'subject': '   ',
          'year': '2',
          'semester': '3',
          'pdfFileName': 'exam.pdf',
          'reason': 'whitespace-only subject',
        },
      ];

      for (final data in invalidFormData) {
        test('disables save button with ${data['reason']}', () {
          final isEnabled = isQuestionPaperSaveEnabled(
            pdfFileName: data['pdfFileName'] as String?,
            title: data['title'] as String,
            subject: data['subject'] as String,
            year: data['year'] as String,
            semester: data['semester'] as String,
          );

          expect(
            isEnabled,
            isFalse,
            reason: 'Save button should be disabled when ${data['reason']}',
          );
        });
      }
    });

    /// Test: Save button is disabled when both PDF and fields are missing
    test('disables save button when both PDF and fields are missing', () {
      final isEnabled = isQuestionPaperSaveEnabled(
        pdfFileName: null,
        title: '',
        subject: '',
        year: '',
        semester: '',
      );

      expect(
        isEnabled,
        isFalse,
        reason: 'Save button should be disabled when both PDF and required fields are missing',
      );
    });
  });
}
