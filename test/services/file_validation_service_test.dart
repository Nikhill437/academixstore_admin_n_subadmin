import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:academixstore_admin_n_subadmin/services/file_validation_service.dart';

void main() {
  group('FileValidationService Tests', () {
    late FileValidationService service;

    setUp(() {
      service = FileValidationService();
    });

    // Feature: question-paper-upload-for-books, Property 3: PDF File Type Validation
    // **Validates: Requirements 3.3, 7.1**
    test('property: non-PDF files are rejected', () {
      // List of non-PDF file extensions to test
      final nonPdfExtensions = [
        'txt', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
        'jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg',
        'mp3', 'mp4', 'avi', 'mov', 'wav',
        'zip', 'rar', '7z', 'tar', 'gz',
        'exe', 'dll', 'bat', 'sh',
        'html', 'css', 'js', 'json', 'xml',
        'csv', 'sql', 'db',
        '', // No extension
      ];

      // Run 100 iterations with different file names and extensions
      for (int i = 0; i < 100; i++) {
        final random = Random(i);
        
        // Pick a random non-PDF extension
        final extension = nonPdfExtensions[random.nextInt(nonPdfExtensions.length)];
        
        // Generate a random file name
        final fileName = extension.isEmpty 
            ? 'file_$i' 
            : 'file_$i.$extension';
        
        // Use a valid file size (under 50MB)
        final fileSizeBytes = random.nextInt(52428800);

        // Validate the file
        final result = service.validatePdfFile(
          fileName: fileName,
          fileSizeBytes: fileSizeBytes,
        );

        // Verify that validation fails
        expect(result.isValid, isFalse,
            reason: 'File with extension ".$extension" should be rejected');
        
        // Verify that error message is specific about file type
        expect(result.errorMessage, equals('Only PDF files are allowed'),
            reason: 'Error message should indicate PDF files are required');
      }
    });

    test('property: PDF files with various names are accepted (type check only)', () {
      // Test that files with .pdf extension pass the type validation
      // (size validation is tested separately)
      final random = Random(42);

      for (int i = 0; i < 100; i++) {
        // Generate various PDF file names
        final fileNames = [
          'document.pdf',
          'Document.PDF', // Test case-insensitivity
          'Document.Pdf',
          'my-file-$i.pdf',
          'file_with_underscores_$i.pdf',
          'file with spaces $i.pdf',
          'file.name.with.dots.$i.pdf',
          'UPPERCASE_$i.PDF',
          'MixedCase_$i.PdF',
        ];

        final fileName = fileNames[random.nextInt(fileNames.length)];
        
        // Use a valid file size (under 50MB)
        final fileSizeBytes = random.nextInt(52428800);

        final result = service.validatePdfFile(
          fileName: fileName,
          fileSizeBytes: fileSizeBytes,
        );

        // Should pass validation (type check)
        expect(result.isValid, isTrue,
            reason: 'PDF file "$fileName" should pass type validation');
        expect(result.errorMessage, isNull,
            reason: 'Valid PDF should have no error message');
      }
    });

    test('property: files with .pdf in name but different extension are rejected', () {
      // Test edge cases where .pdf appears in the filename but isn't the extension
      final invalidFileNames = [
        'document.pdf.txt',
        'file.pdf.doc',
        'my.pdf.backup',
        'test.pdf.old',
        'document.pdf_backup',
        'file.pdf-copy',
      ];

      for (final fileName in invalidFileNames) {
        final result = service.validatePdfFile(
          fileName: fileName,
          fileSizeBytes: 1000000, // 1MB
        );

        expect(result.isValid, isFalse,
            reason: 'File "$fileName" should be rejected (not ending with .pdf)');
        expect(result.errorMessage, equals('Only PDF files are allowed'));
      }
    });

    // Feature: question-paper-upload-for-books, Property 4: PDF File Size Validation
    // **Validates: Requirements 3.4, 7.2**
    test('property: PDF files larger than 50MB are rejected', () {
      final random = Random(123);
      
      // Run 100 iterations with different oversized files
      for (int i = 0; i < 100; i++) {
        // Generate a random file name with .pdf extension
        final fileName = 'document_$i.pdf';
        
        // Generate file sizes larger than 50MB (52,428,800 bytes)
        // Test various sizes from just over 50MB to very large files
        final minSize = FileValidationService.maxFileSizeBytes + 1;
        final maxSize = FileValidationService.maxFileSizeBytes * 10; // Up to 500MB
        final fileSizeBytes = minSize + random.nextInt(maxSize - minSize);

        final result = service.validatePdfFile(
          fileName: fileName,
          fileSizeBytes: fileSizeBytes,
        );

        // Verify that validation fails
        expect(result.isValid, isFalse,
            reason: 'PDF file of size $fileSizeBytes bytes (>${FileValidationService.maxFileSizeBytes}) should be rejected');
        
        // Verify that error message is specific about file size
        expect(result.errorMessage, equals('PDF file must be less than 50MB'),
            reason: 'Error message should indicate 50MB size limit');
      }
    });

    test('property: PDF files at or under 50MB are accepted (size check only)', () {
      final random = Random(456);
      
      // Run 100 iterations with different valid file sizes
      for (int i = 0; i < 100; i++) {
        final fileName = 'document_$i.pdf';
        
        // Generate file sizes from 0 to exactly 50MB
        final fileSizeBytes = random.nextInt(FileValidationService.maxFileSizeBytes + 1);

        final result = service.validatePdfFile(
          fileName: fileName,
          fileSizeBytes: fileSizeBytes,
        );

        // Should pass validation (size check)
        expect(result.isValid, isTrue,
            reason: 'PDF file of size $fileSizeBytes bytes (<=${FileValidationService.maxFileSizeBytes}) should pass size validation');
        expect(result.errorMessage, isNull,
            reason: 'Valid PDF size should have no error message');
      }
    });

    test('property: exactly 50MB PDF files are accepted', () {
      // Edge case: exactly at the limit
      final result = service.validatePdfFile(
        fileName: 'exactly_50mb.pdf',
        fileSizeBytes: FileValidationService.maxFileSizeBytes,
      );

      expect(result.isValid, isTrue,
          reason: 'PDF file of exactly 50MB should be accepted');
      expect(result.errorMessage, isNull);
    });

    test('property: 50MB + 1 byte PDF files are rejected', () {
      // Edge case: just over the limit
      final result = service.validatePdfFile(
        fileName: 'just_over_50mb.pdf',
        fileSizeBytes: FileValidationService.maxFileSizeBytes + 1,
      );

      expect(result.isValid, isFalse,
          reason: 'PDF file of 50MB + 1 byte should be rejected');
      expect(result.errorMessage, equals('PDF file must be less than 50MB'));
    });

    // Feature: question-paper-upload-for-books, Property 13: Validation Error Messages
    // **Validates: Requirements 7.3**
    test('property: validation failures return specific error messages', () {
      final random = Random(789);

      // Test 100 iterations of various validation failures
      for (int i = 0; i < 100; i++) {
        // Randomly choose between file type error and file size error
        final testFileTypeError = random.nextBool();

        if (testFileTypeError) {
          // Test file type validation error
          final nonPdfExtensions = ['txt', 'doc', 'jpg', 'png', 'zip', 'exe'];
          final extension = nonPdfExtensions[random.nextInt(nonPdfExtensions.length)];
          final fileName = 'file_$i.$extension';
          final fileSizeBytes = random.nextInt(52428800); // Valid size

          final result = service.validatePdfFile(
            fileName: fileName,
            fileSizeBytes: fileSizeBytes,
          );

          // Verify specific error message for file type
          expect(result.isValid, isFalse,
              reason: 'Non-PDF file should fail validation');
          expect(result.errorMessage, isNotNull,
              reason: 'Failed validation should have an error message');
          expect(result.errorMessage, equals('Only PDF files are allowed'),
              reason: 'File type error should have specific message about PDF requirement');
        } else {
          // Test file size validation error
          final fileName = 'file_$i.pdf';
          final fileSizeBytes = FileValidationService.maxFileSizeBytes + 
              random.nextInt(100000000); // Over 50MB

          final result = service.validatePdfFile(
            fileName: fileName,
            fileSizeBytes: fileSizeBytes,
          );

          // Verify specific error message for file size
          expect(result.isValid, isFalse,
              reason: 'Oversized PDF should fail validation');
          expect(result.errorMessage, isNotNull,
              reason: 'Failed validation should have an error message');
          expect(result.errorMessage, equals('PDF file must be less than 50MB'),
              reason: 'File size error should have specific message about 50MB limit');
        }
      }
    });

    test('property: valid files have no error message', () {
      final random = Random(101112);

      // Test 100 iterations of valid files
      for (int i = 0; i < 100; i++) {
        final fileName = 'valid_file_$i.pdf';
        final fileSizeBytes = random.nextInt(FileValidationService.maxFileSizeBytes + 1);

        final result = service.validatePdfFile(
          fileName: fileName,
          fileSizeBytes: fileSizeBytes,
        );

        // Verify no error message for valid files
        expect(result.isValid, isTrue,
            reason: 'Valid PDF should pass validation');
        expect(result.errorMessage, isNull,
            reason: 'Valid file should have null error message');
      }
    });

    test('property: error messages are distinct for different failure types', () {
      // Verify that file type errors and file size errors have different messages
      
      // File type error
      final typeErrorResult = service.validatePdfFile(
        fileName: 'document.txt',
        fileSizeBytes: 1000000,
      );

      // File size error
      final sizeErrorResult = service.validatePdfFile(
        fileName: 'document.pdf',
        fileSizeBytes: FileValidationService.maxFileSizeBytes + 1,
      );

      // Both should fail
      expect(typeErrorResult.isValid, isFalse);
      expect(sizeErrorResult.isValid, isFalse);

      // Error messages should be different
      expect(typeErrorResult.errorMessage, isNotNull);
      expect(sizeErrorResult.errorMessage, isNotNull);
      expect(typeErrorResult.errorMessage, isNot(equals(sizeErrorResult.errorMessage)),
          reason: 'File type and file size errors should have distinct messages');

      // Verify specific messages
      expect(typeErrorResult.errorMessage, equals('Only PDF files are allowed'));
      expect(sizeErrorResult.errorMessage, equals('PDF file must be less than 50MB'));
    });
  });

  group('FileValidationService Unit Tests', () {
    late FileValidationService service;

    setUp(() {
      service = FileValidationService();
    });

    test('validatePdfFile accepts valid PDF under 50MB', () {
      final result = service.validatePdfFile(
        fileName: 'valid_document.pdf',
        fileSizeBytes: 10485760, // 10MB
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('validatePdfFile rejects non-PDF file', () {
      final result = service.validatePdfFile(
        fileName: 'document.txt',
        fileSizeBytes: 1000000, // 1MB
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Only PDF files are allowed'));
    });

    test('validatePdfFile rejects PDF over 50MB', () {
      final result = service.validatePdfFile(
        fileName: 'large_document.pdf',
        fileSizeBytes: 52428801, // 50MB + 1 byte
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('PDF file must be less than 50MB'));
    });

    test('validatePdfFile accepts PDF exactly at 50MB', () {
      final result = service.validatePdfFile(
        fileName: 'exactly_50mb.pdf',
        fileSizeBytes: 52428800, // Exactly 50MB
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('validatePdfFile accepts zero-byte PDF', () {
      // Edge case: empty file
      final result = service.validatePdfFile(
        fileName: 'empty.pdf',
        fileSizeBytes: 0,
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('validatePdfFile is case-insensitive for .pdf extension', () {
      final testCases = [
        'document.pdf',
        'document.PDF',
        'document.Pdf',
        'document.pDf',
        'document.pdF',
      ];

      for (final fileName in testCases) {
        final result = service.validatePdfFile(
          fileName: fileName,
          fileSizeBytes: 1000000,
        );

        expect(result.isValid, isTrue,
            reason: 'File "$fileName" should be accepted (case-insensitive)');
        expect(result.errorMessage, isNull);
      }
    });

    test('validatePdfFile rejects common non-PDF extensions', () {
      final testCases = {
        'document.txt': 'Only PDF files are allowed',
        'document.doc': 'Only PDF files are allowed',
        'document.docx': 'Only PDF files are allowed',
        'image.jpg': 'Only PDF files are allowed',
        'image.png': 'Only PDF files are allowed',
        'archive.zip': 'Only PDF files are allowed',
        'program.exe': 'Only PDF files are allowed',
      };

      for (final entry in testCases.entries) {
        final result = service.validatePdfFile(
          fileName: entry.key,
          fileSizeBytes: 1000000,
        );

        expect(result.isValid, isFalse,
            reason: 'File "${entry.key}" should be rejected');
        expect(result.errorMessage, equals(entry.value));
      }
    });

    test('validatePdfFile error message for file type is specific', () {
      final result = service.validatePdfFile(
        fileName: 'document.txt',
        fileSizeBytes: 1000000,
      );

      expect(result.errorMessage, equals('Only PDF files are allowed'));
      expect(result.errorMessage, contains('PDF'));
      expect(result.errorMessage, contains('allowed'));
    });

    test('validatePdfFile error message for file size is specific', () {
      final result = service.validatePdfFile(
        fileName: 'document.pdf',
        fileSizeBytes: 100000000, // 100MB
      );

      expect(result.errorMessage, equals('PDF file must be less than 50MB'));
      expect(result.errorMessage, contains('50MB'));
      expect(result.errorMessage, contains('less than'));
    });

    test('validatePdfFile handles file with no extension', () {
      final result = service.validatePdfFile(
        fileName: 'document',
        fileSizeBytes: 1000000,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Only PDF files are allowed'));
    });

    test('validatePdfFile handles file with multiple dots', () {
      final result = service.validatePdfFile(
        fileName: 'my.document.file.pdf',
        fileSizeBytes: 1000000,
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('validatePdfFile rejects file with .pdf in middle of name', () {
      final result = service.validatePdfFile(
        fileName: 'document.pdf.backup',
        fileSizeBytes: 1000000,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Only PDF files are allowed'));
    });

    test('FileValidationService.maxFileSizeBytes is 50MB', () {
      expect(FileValidationService.maxFileSizeBytes, equals(52428800));
      expect(FileValidationService.maxFileSizeBytes, equals(50 * 1024 * 1024));
    });

    test('validatePdfFile prioritizes file type error over size error', () {
      // When both validations fail, file type error should be returned first
      final result = service.validatePdfFile(
        fileName: 'document.txt',
        fileSizeBytes: 100000000, // Over 50MB
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Only PDF files are allowed'),
          reason: 'File type validation should be checked first');
    });

    test('validatePdfFile with various valid PDF sizes', () {
      final validSizes = [
        1024, // 1KB
        1048576, // 1MB
        10485760, // 10MB
        26214400, // 25MB
        52428799, // 50MB - 1 byte
        52428800, // Exactly 50MB
      ];

      for (final size in validSizes) {
        final result = service.validatePdfFile(
          fileName: 'document.pdf',
          fileSizeBytes: size,
        );

        expect(result.isValid, isTrue,
            reason: 'PDF of size $size bytes should be valid');
        expect(result.errorMessage, isNull);
      }
    });

    test('validatePdfFile with various invalid PDF sizes', () {
      final invalidSizes = [
        52428801, // 50MB + 1 byte
        104857600, // 100MB
        157286400, // 150MB
        209715200, // 200MB
      ];

      for (final size in invalidSizes) {
        final result = service.validatePdfFile(
          fileName: 'document.pdf',
          fileSizeBytes: size,
        );

        expect(result.isValid, isFalse,
            reason: 'PDF of size $size bytes should be invalid');
        expect(result.errorMessage, equals('PDF file must be less than 50MB'));
      }
    });
  });
}
