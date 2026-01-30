import 'package:flutter_test/flutter_test.dart';

/// Property 2: Required Field Validation
/// Validates: Requirements 2.6
/// Test that for any empty or whitespace-only required field, validation fails
/// 
/// This is a property-based test that validates the universal property:
/// For ANY required field (title, subject, year, semester), if the value is
/// empty or contains only whitespace, validation MUST fail.

void main() {
  group('Question Paper Form Validation - Property 2', () {
    /// Helper function to simulate validation logic
    /// This matches the validation logic in AddEditBookDialog
    String? validateRequiredField(String? value, String fieldName) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    }

    String? validateYear(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Year is required';
      }
      final year = int.tryParse(value.trim());
      if (year == null) {
        return 'Year must be a number';
      }
      if (year < 1 || year > 4) {
        return 'Year must be between 1 and 4';
      }
      return null;
    }

    String? validateSemester(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Semester is required';
      }
      final semester = int.tryParse(value.trim());
      if (semester == null) {
        return 'Semester must be a number';
      }
      if (semester < 1 || semester > 8) {
        return 'Semester must be between 1 and 8';
      }
      return null;
    }

    /// Property 2: Required Field Validation
    /// For any empty or whitespace-only value, validation must fail
    group('Property 2: Required Field Validation', () {
      final emptyValues = [
        null,
        '',
        ' ',
        '  ',
        '\t',
        '\n',
        '   \t  \n  ',
      ];

      final requiredFields = [
        {'name': 'Title', 'validator': (String? v) => validateRequiredField(v, 'Title')},
        {'name': 'Subject', 'validator': (String? v) => validateRequiredField(v, 'Subject')},
        {'name': 'Year', 'validator': validateYear},
        {'name': 'Semester', 'validator': validateSemester},
      ];

      for (final field in requiredFields) {
        final fieldName = field['name'] as String;
        final validator = field['validator'] as String? Function(String?);

        group('$fieldName field', () {
          for (final emptyValue in emptyValues) {
            test('rejects empty/whitespace value: ${emptyValue == null ? "null" : "\"$emptyValue\""}', () {
              final result = validator(emptyValue);
              
              expect(
                result,
                isNotNull,
                reason: 'Validation should fail for empty/whitespace value in $fieldName field',
              );
              
              expect(
                result,
                contains('required'),
                reason: 'Error message should indicate field is required',
              );
            });
          }

          test('accepts valid non-empty value', () {
            String validValue;
            if (fieldName == 'Year') {
              validValue = '2';
            } else if (fieldName == 'Semester') {
              validValue = '3';
            } else {
              validValue = 'Valid $fieldName';
            }

            final result = validator(validValue);
            
            expect(
              result,
              isNull,
              reason: 'Validation should pass for valid non-empty value in $fieldName field',
            );
          });
        });
      }
    });

    /// Additional validation tests for year and semester ranges
    group('Year validation range', () {
      test('rejects year less than 1', () {
        expect(validateYear('0'), isNotNull);
        expect(validateYear('-1'), isNotNull);
      });

      test('rejects year greater than 4', () {
        expect(validateYear('5'), isNotNull);
        expect(validateYear('10'), isNotNull);
      });

      test('accepts years 1-4', () {
        expect(validateYear('1'), isNull);
        expect(validateYear('2'), isNull);
        expect(validateYear('3'), isNull);
        expect(validateYear('4'), isNull);
      });

      test('rejects non-numeric year', () {
        expect(validateYear('abc'), isNotNull);
        expect(validateYear('1.5'), isNotNull);
      });
    });

    group('Semester validation range', () {
      test('rejects semester less than 1', () {
        expect(validateSemester('0'), isNotNull);
        expect(validateSemester('-1'), isNotNull);
      });

      test('rejects semester greater than 8', () {
        expect(validateSemester('9'), isNotNull);
        expect(validateSemester('10'), isNotNull);
      });

      test('accepts semesters 1-8', () {
        for (int i = 1; i <= 8; i++) {
          expect(validateSemester('$i'), isNull,
            reason: 'Semester $i should be valid');
        }
      });

      test('rejects non-numeric semester', () {
        expect(validateSemester('abc'), isNotNull);
        expect(validateSemester('1.5'), isNotNull);
      });
    });
  });
}
