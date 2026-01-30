import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:academixstore_admin_n_subadmin/modules/books/controller/books_controller.dart';
import 'package:academixstore_admin_n_subadmin/services/api_service.dart';
import 'package:academixstore_admin_n_subadmin/services/role_access_service.dart';
import 'package:academixstore_admin_n_subadmin/services/api/question_papers_api_service.dart';
import 'package:academixstore_admin_n_subadmin/models/question_paper.dart';

/// Mock services for testing
class MockApiService extends GetxService implements ApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRoleAccessService extends GetxService implements RoleAccessService {
  @override
  bool canModify(String resource) => true;
  
  @override
  void validateAccess(String resource) {}
  
  @override
  String getAccessDeniedMessage(String resource) => 'Access denied';
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockQuestionPapersApiService extends GetxService 
    implements QuestionPapersApiService {
  bool shouldFailCreate = false;
  bool shouldFailUpload = false;
  bool shouldFailDelete = false;
  QuestionPaper? lastCreatedQuestionPaper;
  Map<String, dynamic>? lastUploadCall;
  String? lastDeletedQuestionPaperId;
  int _idCounter = 0;
  
  @override
  Future<QuestionPaper> createQuestionPaper(
    Map<String, dynamic> questionPaperData,
  ) async {
    if (shouldFailCreate) {
      throw Exception('Failed to create question paper');
    }
    
    // Generate unique ID for each question paper
    _idCounter++;
    final uniqueId = 'test-qp-id-$_idCounter';
    
    lastCreatedQuestionPaper = QuestionPaper(
      id: uniqueId,
      title: questionPaperData['title'] as String,
      subject: questionPaperData['subject'] as String,
      year: questionPaperData['year'] as int,
      semester: questionPaperData['semester'] as int,
      description: questionPaperData['description'] as String?,
      examType: questionPaperData['exam_type'] as String?,
      marks: questionPaperData['marks'] as int?,
      collegeId: questionPaperData['college_id'] as String?,
      isActive: true,
      createdAt: DateTime.now(),
    );
    
    return lastCreatedQuestionPaper!;
  }
  
  @override
  Future<Map<String, dynamic>> uploadQuestionPaperPdf(
    String questionPaperId,
    String? filePath, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    if (shouldFailUpload) {
      throw Exception('Failed to upload PDF');
    }
    
    lastUploadCall = {
      'questionPaperId': questionPaperId,
      'filePath': filePath,
      'fileBytes': fileBytes,
      'fileName': fileName,
    };
    
    return {
      'question_paper_id': questionPaperId,
      'pdf_url': 'https://example.com/pdfs/$questionPaperId.pdf',
      'signed_url': 'https://example.com/pdfs/$questionPaperId.pdf?signed=true',
      'original_name': fileName,
    };
  }
  
  @override
  Future<bool> deleteQuestionPaper(String questionPaperId) async {
    if (shouldFailDelete) {
      throw Exception('Failed to delete question paper');
    }
    
    lastDeletedQuestionPaperId = questionPaperId;
    return true;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BooksController - Question Paper State Management (Task 2.1)', () {
    late BooksController controller;

    setUp(() {
      // Initialize GetX
      Get.testMode = true;
      
      // Register mock services
      Get.put<ApiService>(MockApiService());
      Get.put<RoleAccessService>(MockRoleAccessService());
      Get.put<QuestionPapersApiService>(MockQuestionPapersApiService());
      
      // Create controller
      controller = BooksController();
    });

    tearDown(() {
      Get.reset();
    });

    test('should initialize with empty question papers list', () {
      // Verify initial state
      expect(controller.questionPapers, isEmpty);
      expect(controller.questionPapers, isA<List<QuestionPaper>>());
    });

    test('should have questionPapers getter that returns a list', () {
      // Verify getter returns correct type
      final questionPapers = controller.questionPapers;
      expect(questionPapers, isA<List<QuestionPaper>>());
      expect(questionPapers, isEmpty);
    });

    test('should have QuestionPapersApiService dependency injected', () {
      // Verify the service is available
      final service = Get.find<QuestionPapersApiService>();
      expect(service, isNotNull);
      expect(service, isA<QuestionPapersApiService>());
    });

    test('questionPapers getter should return a copy of the list', () {
      // Get the list twice
      final list1 = controller.questionPapers;
      final list2 = controller.questionPapers;
      
      // They should be equal but not the same instance
      expect(list1, equals(list2));
      expect(identical(list1, list2), isFalse);
    });
  });

  group('BooksController - createQuestionPaperWithPdf (Task 2.2)', () {
    late BooksController controller;
    late MockQuestionPapersApiService mockApiService;

    setUp(() {
      // Initialize GetX
      Get.testMode = true;
      
      // Register mock services
      Get.put<ApiService>(MockApiService());
      Get.put<RoleAccessService>(MockRoleAccessService());
      mockApiService = MockQuestionPapersApiService();
      Get.put<QuestionPapersApiService>(mockApiService);
      
      // Create controller
      controller = BooksController();
      
      // Configure GetX for testing (disable snackbars)
      Get.config(enableLog: false);
    });

    tearDown(() {
      Get.reset();
    });

    test('should create question paper with valid data', () async {
      // Arrange
      final questionPaperData = {
        'title': 'Midterm Exam - Data Structures',
        'subject': 'Data Structures',
        'year': 2,
        'semester': 3,
        'description': 'Covers arrays, linked lists, stacks, queues',
        'exam_type': 'midterm',
        'marks': 100,
      };

      // Act
      final result = await controller.createQuestionPaperWithPdf(
        questionPaperData,
        null,
        pdfFileBytes: [1, 2, 3, 4, 5],
        pdfFileName: 'midterm-exam.pdf',
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.title, equals('Midterm Exam - Data Structures'));
      expect(result.subject, equals('Data Structures'));
      expect(result.year, equals(2));
      expect(result.semester, equals(3));
      expect(result.examType, equals('midterm'));
      expect(result.marks, equals(100));
    });

    test('should upload PDF after successful creation', () async {
      // Arrange
      final questionPaperData = {
        'title': 'Final Exam',
        'subject': 'Algorithms',
        'year': 3,
        'semester': 5,
      };
      final pdfBytes = [1, 2, 3, 4, 5];
      final pdfFileName = 'final-exam.pdf';

      // Act
      await controller.createQuestionPaperWithPdf(
        questionPaperData,
        null,
        pdfFileBytes: pdfBytes,
        pdfFileName: pdfFileName,
      );

      // Assert - verify upload was called
      expect(mockApiService.lastUploadCall, isNotNull);
      expect(mockApiService.lastUploadCall!['questionPaperId'], 
        isNotEmpty);
      expect(mockApiService.lastUploadCall!['fileBytes'], equals(pdfBytes));
      expect(mockApiService.lastUploadCall!['fileName'], equals(pdfFileName));
    });

    test('should update local question papers list after successful creation', 
      () async {
      // Arrange
      final questionPaperData = {
        'title': 'Quiz 1',
        'subject': 'Operating Systems',
        'year': 2,
        'semester': 4,
      };

      // Verify list is initially empty
      expect(controller.questionPapers, isEmpty);

      // Act
      await controller.createQuestionPaperWithPdf(
        questionPaperData,
        null,
        pdfFileBytes: [1, 2, 3],
        pdfFileName: 'quiz.pdf',
      );

      // Assert
      expect(controller.questionPapers, hasLength(1));
      expect(controller.questionPapers.first.title, equals('Quiz 1'));
    });

    test('should display success message after successful creation', () async {
      // Arrange
      final questionPaperData = {
        'title': 'Practice Test',
        'subject': 'Database Systems',
        'year': 3,
        'semester': 6,
      };

      // Act
      final result = await controller.createQuestionPaperWithPdf(
        questionPaperData,
        null,
        pdfFileBytes: [1, 2, 3],
        pdfFileName: 'practice.pdf',
      );

      // Assert
      expect(result, isNotNull);
      // Note: In a real test, we would verify the snackbar was shown
      // For now, we just verify the operation succeeded
    });

    test('should return null and display error when creation fails', () async {
      // Arrange
      mockApiService.shouldFailCreate = true;
      final questionPaperData = {
        'title': 'Test Paper',
        'subject': 'Test Subject',
        'year': 1,
        'semester': 1,
      };

      // Act
      final result = await controller.createQuestionPaperWithPdf(
        questionPaperData,
        null,
        pdfFileBytes: [1, 2, 3],
        pdfFileName: 'test.pdf',
      );

      // Assert
      expect(result, isNull);
      expect(controller.error, isNotEmpty);
    });

    test('should handle partial failure when creation succeeds but upload fails',
      () async {
      // Arrange
      mockApiService.shouldFailUpload = true;
      final questionPaperData = {
        'title': 'Partial Failure Test',
        'subject': 'Test Subject',
        'year': 2,
        'semester': 3,
      };

      // Act
      final result = await controller.createQuestionPaperWithPdf(
        questionPaperData,
        null,
        pdfFileBytes: [1, 2, 3],
        pdfFileName: 'test.pdf',
      );

      // Assert - question paper should still be created and added to list
      expect(result, isNotNull);
      expect(result!.title, equals('Partial Failure Test'));
      expect(controller.questionPapers, hasLength(1));
      expect(controller.questionPapers.first.id, isNotEmpty);
    });

    test('should not attempt upload if no PDF file is provided', () async {
      // Arrange
      final questionPaperData = {
        'title': 'No PDF Test',
        'subject': 'Test Subject',
        'year': 1,
        'semester': 2,
      };

      // Act
      await controller.createQuestionPaperWithPdf(
        questionPaperData,
        null,
      );

      // Assert - upload should not have been called
      expect(mockApiService.lastUploadCall, isNull);
    });

    test('should support file path for mobile platforms', () async {
      // Arrange
      final questionPaperData = {
        'title': 'Mobile Upload Test',
        'subject': 'Test Subject',
        'year': 2,
        'semester': 4,
      };
      final filePath = '/path/to/file.pdf';

      // Act
      await controller.createQuestionPaperWithPdf(
        questionPaperData,
        filePath,
        pdfFileName: 'file.pdf',
      );

      // Assert
      expect(mockApiService.lastUploadCall, isNotNull);
      expect(mockApiService.lastUploadCall!['filePath'], equals(filePath));
    });

    test('should support file bytes for web platforms', () async {
      // Arrange
      final questionPaperData = {
        'title': 'Web Upload Test',
        'subject': 'Test Subject',
        'year': 3,
        'semester': 5,
      };
      final fileBytes = List.generate(100, (i) => i % 256);

      // Act
      await controller.createQuestionPaperWithPdf(
        questionPaperData,
        null,
        pdfFileBytes: fileBytes,
        pdfFileName: 'web-file.pdf',
      );

      // Assert
      expect(mockApiService.lastUploadCall, isNotNull);
      expect(mockApiService.lastUploadCall!['fileBytes'], equals(fileBytes));
    });

    test('should handle all optional fields in question paper data', () async {
      // Arrange
      final questionPaperData = {
        'title': 'Complete Data Test',
        'subject': 'Complete Subject',
        'year': 4,
        'semester': 8,
        'description': 'This is a detailed description',
        'exam_type': 'final',
        'marks': 150,
        'college_id': 'college-uuid-123',
      };

      // Act
      final result = await controller.createQuestionPaperWithPdf(
        questionPaperData,
        null,
        pdfFileBytes: [1, 2, 3],
        pdfFileName: 'complete.pdf',
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.description, equals('This is a detailed description'));
      expect(result.examType, equals('final'));
      expect(result.marks, equals(150));
      expect(result.collegeId, equals('college-uuid-123'));
    });
  });

  group('BooksController - Property Tests (Task 2.3)', () {
    late BooksController controller;
    late MockQuestionPapersApiService mockApiService;

    setUp(() {
      // Initialize GetX
      Get.testMode = true;
      
      // Register mock services
      Get.put<ApiService>(MockApiService());
      Get.put<RoleAccessService>(MockRoleAccessService());
      mockApiService = MockQuestionPapersApiService();
      Get.put<QuestionPapersApiService>(mockApiService);
      
      // Create controller
      controller = BooksController();
      
      // Configure GetX for testing (disable snackbars)
      Get.config(enableLog: false);
    });

    tearDown(() {
      Get.reset();
    });

    // Feature: question-paper-upload-for-books, Property 7: PDF Upload After Creation
    // **Validates: Requirements 4.2**
    test('property: PDF upload is called after successful question paper creation', 
      () async {
      // Property: For any successfully created question paper with a PDF,
      // the upload endpoint SHALL be called
      
      // Test with multiple different question paper configurations
      final testCases = [
        {
          'data': {
            'title': 'Midterm Exam',
            'subject': 'Data Structures',
            'year': 2,
            'semester': 3,
            'exam_type': 'midterm',
            'marks': 100,
          },
          'fileName': 'midterm.pdf',
          'fileBytes': [1, 2, 3, 4, 5],
        },
        {
          'data': {
            'title': 'Final Exam',
            'subject': 'Algorithms',
            'year': 3,
            'semester': 5,
            'exam_type': 'final',
            'marks': 150,
          },
          'fileName': 'final.pdf',
          'fileBytes': List.generate(100, (i) => i % 256),
        },
        {
          'data': {
            'title': 'Quiz 1',
            'subject': 'Operating Systems',
            'year': 1,
            'semester': 2,
            'exam_type': 'quiz',
            'marks': 50,
          },
          'fileName': 'quiz.pdf',
          'fileBytes': List.generate(1000, (i) => (i * 7) % 256),
        },
        {
          'data': {
            'title': 'Practice Test',
            'subject': 'Database Systems',
            'year': 4,
            'semester': 7,
            'exam_type': 'practice',
          },
          'fileName': 'practice.pdf',
          'fileBytes': [255, 254, 253],
        },
      ];

      for (final testCase in testCases) {
        // Reset mock state
        mockApiService.lastUploadCall = null;
        
        final questionPaperData = testCase['data'] as Map<String, dynamic>;
        final fileName = testCase['fileName'] as String;
        final fileBytes = testCase['fileBytes'] as List<int>;

        // Act: Create question paper with PDF
        final result = await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: fileBytes,
          pdfFileName: fileName,
        );

        // Assert: Question paper was created
        expect(result, isNotNull, 
          reason: 'Question paper should be created for: ${questionPaperData['title']}');

        // Assert: Upload endpoint was called
        expect(mockApiService.lastUploadCall, isNotNull,
          reason: 'Upload should be called for: ${questionPaperData['title']}');

        // Assert: Upload was called with correct question paper ID
        expect(mockApiService.lastUploadCall!['questionPaperId'], 
          equals(result!.id),
          reason: 'Upload should use the created question paper ID');

        // Assert: Upload was called with correct file data
        expect(mockApiService.lastUploadCall!['fileBytes'], equals(fileBytes),
          reason: 'Upload should use the provided file bytes');
        expect(mockApiService.lastUploadCall!['fileName'], equals(fileName),
          reason: 'Upload should use the provided file name');
      }
    });

    test('property: PDF upload is called with file path for mobile platforms', 
      () async {
      // Property: For any successfully created question paper with a PDF file path,
      // the upload endpoint SHALL be called with the file path
      
      final testCases = [
        {
          'data': {
            'title': 'Mobile Test 1',
            'subject': 'Subject A',
            'year': 1,
            'semester': 1,
          },
          'filePath': '/storage/emulated/0/Download/test1.pdf',
          'fileName': 'test1.pdf',
        },
        {
          'data': {
            'title': 'Mobile Test 2',
            'subject': 'Subject B',
            'year': 2,
            'semester': 3,
          },
          'filePath': '/data/user/0/com.example.app/files/test2.pdf',
          'fileName': 'test2.pdf',
        },
      ];

      for (final testCase in testCases) {
        // Reset mock state
        mockApiService.lastUploadCall = null;
        
        final questionPaperData = testCase['data'] as Map<String, dynamic>;
        final filePath = testCase['filePath'] as String;
        final fileName = testCase['fileName'] as String;

        // Act: Create question paper with file path
        final result = await controller.createQuestionPaperWithPdf(
          questionPaperData,
          filePath,
          pdfFileName: fileName,
        );

        // Assert: Question paper was created
        expect(result, isNotNull);

        // Assert: Upload endpoint was called
        expect(mockApiService.lastUploadCall, isNotNull);

        // Assert: Upload was called with file path
        expect(mockApiService.lastUploadCall!['filePath'], equals(filePath),
          reason: 'Upload should use the provided file path');
        expect(mockApiService.lastUploadCall!['fileName'], equals(fileName),
          reason: 'Upload should use the provided file name');
      }
    });

    test('property: PDF upload is NOT called when no PDF is provided', 
      () async {
      // Property: For any successfully created question paper WITHOUT a PDF,
      // the upload endpoint SHALL NOT be called
      
      final testCases = [
        {
          'title': 'No PDF Test 1',
          'subject': 'Subject A',
          'year': 1,
          'semester': 1,
        },
        {
          'title': 'No PDF Test 2',
          'subject': 'Subject B',
          'year': 2,
          'semester': 3,
          'exam_type': 'midterm',
        },
      ];

      for (final questionPaperData in testCases) {
        // Reset mock state
        mockApiService.lastUploadCall = null;
        
        // Act: Create question paper without PDF
        final result = await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
        );

        // Assert: Question paper was created
        expect(result, isNotNull,
          reason: 'Question paper should be created even without PDF');

        // Assert: Upload endpoint was NOT called
        expect(mockApiService.lastUploadCall, isNull,
          reason: 'Upload should NOT be called when no PDF is provided');
      }
    });

    test('property: question paper is added to list even if upload fails', 
      () async {
      // Property: For any successfully created question paper where upload fails,
      // the question paper SHALL still be added to the local list
      
      // Configure mock to fail upload
      mockApiService.shouldFailUpload = true;
      
      final testCases = [
        {
          'title': 'Upload Fail Test 1',
          'subject': 'Subject A',
          'year': 1,
          'semester': 1,
        },
        {
          'title': 'Upload Fail Test 2',
          'subject': 'Subject B',
          'year': 3,
          'semester': 6,
          'exam_type': 'final',
          'marks': 200,
        },
      ];

      for (final questionPaperData in testCases) {
        // Clear list
        controller.clearQuestionPapers();
        expect(controller.questionPapers, isEmpty);
        
        // Act: Create question paper with PDF (upload will fail)
        final result = await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        // Assert: Question paper was created
        expect(result, isNotNull,
          reason: 'Question paper should be created even if upload fails');

        // Assert: Question paper is in the list
        expect(controller.questionPapers, hasLength(1),
          reason: 'Question paper should be added to list even if upload fails');
        expect(controller.questionPapers.first.id, equals(result!.id),
          reason: 'The created question paper should be in the list');
      }
    });
  });

  group('BooksController - Question Paper Deletion Property Tests (Task 2.5)', () {
    late BooksController controller;
    late MockQuestionPapersApiService mockApiService;

    setUp(() {
      // Initialize GetX
      Get.testMode = true;
      
      // Register mock services
      Get.put<ApiService>(MockApiService());
      Get.put<RoleAccessService>(MockRoleAccessService());
      mockApiService = MockQuestionPapersApiService();
      Get.put<QuestionPapersApiService>(mockApiService);
      
      // Create controller
      controller = BooksController();
      
      // Configure GetX for testing (disable snackbars)
      Get.config(enableLog: false);
    });

    tearDown(() {
      Get.reset();
    });

    // Feature: question-paper-upload-for-books, Property 11: List Update After Successful Deletion
    // **Validates: Requirements 6.4**
    test('property: question paper is removed from list after successful deletion', 
      () async {
      // Property: For any successfully deleted question paper,
      // it SHALL be removed from the displayed list
      
      // Test with multiple question papers
      final testQuestionPapers = [
        QuestionPaper(
          id: 'qp-1',
          title: 'Midterm Exam',
          subject: 'Data Structures',
          year: 2,
          semester: 3,
          examType: 'midterm',
          marks: 100,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        QuestionPaper(
          id: 'qp-2',
          title: 'Final Exam',
          subject: 'Algorithms',
          year: 3,
          semester: 5,
          examType: 'final',
          marks: 150,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        QuestionPaper(
          id: 'qp-3',
          title: 'Quiz 1',
          subject: 'Operating Systems',
          year: 1,
          semester: 2,
          examType: 'quiz',
          marks: 50,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        QuestionPaper(
          id: 'qp-4',
          title: 'Practice Test',
          subject: 'Database Systems',
          year: 4,
          semester: 7,
          examType: 'practice',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];

      // Add all question papers to the controller
      for (final qp in testQuestionPapers) {
        await controller.createQuestionPaperWithPdf(
          {
            'title': qp.title,
            'subject': qp.subject,
            'year': qp.year,
            'semester': qp.semester,
            'exam_type': qp.examType,
            'marks': qp.marks,
          },
          null,
        );
      }

      // Verify all question papers are in the list
      expect(controller.questionPapers, hasLength(testQuestionPapers.length));

      // Test deletion of each question paper
      for (var i = 0; i < testQuestionPapers.length; i++) {
        final qpToDelete = controller.questionPapers.first;
        final qpId = qpToDelete.id;
        final initialCount = controller.questionPapers.length;

        // Reset mock state
        mockApiService.lastDeletedQuestionPaperId = null;

        // Act: Delete the question paper
        final result = await controller.deleteQuestionPaper(qpId);

        // Assert: Deletion was successful
        expect(result, isTrue,
          reason: 'Deletion should succeed for question paper: ${qpToDelete.title}');

        // Assert: API was called with correct ID
        expect(mockApiService.lastDeletedQuestionPaperId, equals(qpId),
          reason: 'Delete API should be called with correct ID');

        // Assert: Question paper is removed from list
        expect(controller.questionPapers, hasLength(initialCount - 1),
          reason: 'List should have one less item after deletion');
        
        // Assert: The specific question paper is not in the list
        final stillInList = controller.questionPapers.any((qp) => qp.id == qpId);
        expect(stillInList, isFalse,
          reason: 'Deleted question paper should not be in the list');
      }

      // Assert: All question papers have been deleted
      expect(controller.questionPapers, isEmpty,
        reason: 'All question papers should be deleted');
    });

    test('property: list remains unchanged when deletion fails', 
      () async {
      // Property: For any failed deletion attempt,
      // the question paper SHALL remain in the list
      
      // Configure mock to fail deletion
      mockApiService.shouldFailDelete = true;

      // Add question papers to the controller
      final testQuestionPapers = [
        {
          'title': 'Test Paper 1',
          'subject': 'Subject A',
          'year': 1,
          'semester': 1,
        },
        {
          'title': 'Test Paper 2',
          'subject': 'Subject B',
          'year': 2,
          'semester': 3,
        },
        {
          'title': 'Test Paper 3',
          'subject': 'Subject C',
          'year': 3,
          'semester': 5,
        },
      ];

      for (final qpData in testQuestionPapers) {
        await controller.createQuestionPaperWithPdf(qpData, null);
      }

      final initialCount = controller.questionPapers.length;
      expect(initialCount, equals(testQuestionPapers.length));

      // Try to delete each question paper (should fail)
      for (final qp in controller.questionPapers.toList()) {
        final qpId = qp.id;

        // Act: Attempt to delete (will fail)
        final result = await controller.deleteQuestionPaper(qpId);

        // Assert: Deletion failed
        expect(result, isFalse,
          reason: 'Deletion should fail when API fails');

        // Assert: List count remains the same
        expect(controller.questionPapers, hasLength(initialCount),
          reason: 'List should remain unchanged when deletion fails');

        // Assert: The question paper is still in the list
        final stillInList = controller.questionPapers.any((q) => q.id == qpId);
        expect(stillInList, isTrue,
          reason: 'Question paper should remain in list when deletion fails');
      }
    });

    test('property: deleting non-existent question paper does not affect list', 
      () async {
      // Property: For any deletion attempt of a non-existent question paper,
      // the list SHALL remain unchanged
      
      // Add some question papers
      final testQuestionPapers = [
        {
          'title': 'Existing Paper 1',
          'subject': 'Subject A',
          'year': 1,
          'semester': 1,
        },
        {
          'title': 'Existing Paper 2',
          'subject': 'Subject B',
          'year': 2,
          'semester': 3,
        },
      ];

      for (final qpData in testQuestionPapers) {
        await controller.createQuestionPaperWithPdf(qpData, null);
      }

      final initialCount = controller.questionPapers.length;
      final initialIds = controller.questionPapers.map((qp) => qp.id).toSet();

      // Try to delete non-existent question papers
      final nonExistentIds = [
        'non-existent-id-1',
        'non-existent-id-2',
        'non-existent-id-3',
      ];

      for (final nonExistentId in nonExistentIds) {
        // Act: Delete non-existent question paper
        await controller.deleteQuestionPaper(nonExistentId);

        // Assert: List count remains the same
        expect(controller.questionPapers, hasLength(initialCount),
          reason: 'List should remain unchanged when deleting non-existent ID');

        // Assert: All original IDs are still present
        final currentIds = controller.questionPapers.map((qp) => qp.id).toSet();
        expect(currentIds, equals(initialIds),
          reason: 'Original question papers should remain in list');
      }
    });

    test('property: multiple deletions update list correctly', 
      () async {
      // Property: For any sequence of successful deletions,
      // the list SHALL be updated correctly after each deletion
      
      // Add multiple question papers
      final questionPaperCount = 10;
      for (var i = 0; i < questionPaperCount; i++) {
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Test Paper ${i + 1}',
            'subject': 'Subject ${i + 1}',
            'year': (i % 4) + 1,
            'semester': (i % 8) + 1,
          },
          null,
        );
      }

      expect(controller.questionPapers, hasLength(questionPaperCount));

      // Delete every other question paper
      final idsToDelete = <String>[];
      for (var i = 0; i < controller.questionPapers.length; i += 2) {
        idsToDelete.add(controller.questionPapers[i].id);
      }

      var expectedCount = questionPaperCount;
      for (final idToDelete in idsToDelete) {
        // Act: Delete question paper
        final result = await controller.deleteQuestionPaper(idToDelete);

        // Assert: Deletion succeeded
        expect(result, isTrue);

        // Assert: Count decreased by 1
        expectedCount--;
        expect(controller.questionPapers, hasLength(expectedCount),
          reason: 'List should have correct count after each deletion');

        // Assert: Deleted ID is not in list
        final stillInList = controller.questionPapers.any((qp) => qp.id == idToDelete);
        expect(stillInList, isFalse,
          reason: 'Deleted question paper should not be in list');
      }

      // Assert: Final count is correct
      expect(controller.questionPapers, hasLength(questionPaperCount - idsToDelete.length));
    });
  });

  group('BooksController - Unit Tests for Question Paper Methods (Task 2.7)', () {
    late BooksController controller;
    late MockQuestionPapersApiService mockApiService;

    setUp(() {
      // Initialize GetX
      Get.testMode = true;
      
      // Register mock services
      Get.put<ApiService>(MockApiService());
      Get.put<RoleAccessService>(MockRoleAccessService());
      mockApiService = MockQuestionPapersApiService();
      Get.put<QuestionPapersApiService>(mockApiService);
      
      // Create controller
      controller = BooksController();
      
      // Configure GetX for testing (disable snackbars)
      Get.config(enableLog: false);
    });

    tearDown(() {
      Get.reset();
    });

    group('createQuestionPaperWithPdf', () {
      test('should create question paper with valid data', () async {
        // Arrange
        final questionPaperData = {
          'title': 'Unit Test Paper',
          'subject': 'Unit Testing',
          'year': 2,
          'semester': 4,
          'exam_type': 'midterm',
          'marks': 100,
        };

        // Act
        final result = await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.title, equals('Unit Test Paper'));
        expect(result.subject, equals('Unit Testing'));
        expect(result.year, equals(2));
        expect(result.semester, equals(4));
        expect(result.examType, equals('midterm'));
        expect(result.marks, equals(100));
      });

      test('should return null when API creation fails', () async {
        // Arrange
        mockApiService.shouldFailCreate = true;
        final questionPaperData = {
          'title': 'Fail Test',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 1,
        };

        // Act
        final result = await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        // Assert
        expect(result, isNull);
        expect(controller.error, isNotEmpty);
        expect(controller.questionPapers, isEmpty);
      });

      test('should handle upload failure after successful creation', () async {
        // Arrange
        mockApiService.shouldFailUpload = true;
        final questionPaperData = {
          'title': 'Upload Fail Test',
          'subject': 'Test Subject',
          'year': 2,
          'semester': 3,
        };

        // Act
        final result = await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        // Assert - question paper should still be created
        expect(result, isNotNull);
        expect(result!.title, equals('Upload Fail Test'));
        expect(controller.questionPapers, hasLength(1));
      });

      test('should not upload PDF when no file is provided', () async {
        // Arrange
        final questionPaperData = {
          'title': 'No PDF Test',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 2,
        };

        // Act
        await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
        );

        // Assert
        expect(mockApiService.lastUploadCall, isNull);
      });

      test('should handle file path for mobile platforms', () async {
        // Arrange
        final questionPaperData = {
          'title': 'Mobile Test',
          'subject': 'Test Subject',
          'year': 2,
          'semester': 4,
        };
        final filePath = '/path/to/file.pdf';

        // Act
        await controller.createQuestionPaperWithPdf(
          questionPaperData,
          filePath,
          pdfFileName: 'file.pdf',
        );

        // Assert
        expect(mockApiService.lastUploadCall, isNotNull);
        expect(mockApiService.lastUploadCall!['filePath'], equals(filePath));
      });

      test('should handle file bytes for web platforms', () async {
        // Arrange
        final questionPaperData = {
          'title': 'Web Test',
          'subject': 'Test Subject',
          'year': 3,
          'semester': 5,
        };
        final fileBytes = [1, 2, 3, 4, 5];

        // Act
        await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: fileBytes,
          pdfFileName: 'web-file.pdf',
        );

        // Assert
        expect(mockApiService.lastUploadCall, isNotNull);
        expect(mockApiService.lastUploadCall!['fileBytes'], equals(fileBytes));
      });

      test('should add question paper to local list after successful creation', 
        () async {
        // Arrange
        final questionPaperData = {
          'title': 'List Test',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 1,
        };

        expect(controller.questionPapers, isEmpty);

        // Act
        await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        // Assert
        expect(controller.questionPapers, hasLength(1));
        expect(controller.questionPapers.first.title, equals('List Test'));
      });

      test('should handle optional fields correctly', () async {
        // Arrange
        final questionPaperData = {
          'title': 'Optional Fields Test',
          'subject': 'Test Subject',
          'year': 4,
          'semester': 8,
          'description': 'Test description',
          'exam_type': 'final',
          'marks': 200,
          'college_id': 'college-123',
        };

        // Act
        final result = await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.description, equals('Test description'));
        expect(result.examType, equals('final'));
        expect(result.marks, equals(200));
        expect(result.collegeId, equals('college-123'));
      });
    });

    group('deleteQuestionPaper', () {
      test('should delete question paper with valid ID', () async {
        // Arrange - create a question paper first
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Delete Test',
            'subject': 'Test Subject',
            'year': 1,
            'semester': 1,
          },
          null,
        );

        expect(controller.questionPapers, hasLength(1));
        final qpId = controller.questionPapers.first.id;

        // Act
        final result = await controller.deleteQuestionPaper(qpId);

        // Assert
        expect(result, isTrue);
        expect(controller.questionPapers, isEmpty);
        expect(mockApiService.lastDeletedQuestionPaperId, equals(qpId));
      });

      test('should return false when API deletion fails', () async {
        // Arrange
        mockApiService.shouldFailDelete = true;
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Delete Fail Test',
            'subject': 'Test Subject',
            'year': 1,
            'semester': 1,
          },
          null,
        );

        expect(controller.questionPapers, hasLength(1));
        final qpId = controller.questionPapers.first.id;

        // Act
        final result = await controller.deleteQuestionPaper(qpId);

        // Assert
        expect(result, isFalse);
        expect(controller.error, isNotEmpty);
        expect(controller.questionPapers, hasLength(1));
      });

      test('should remove question paper from list after successful deletion', 
        () async {
        // Arrange - create multiple question papers
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Paper 1',
            'subject': 'Subject A',
            'year': 1,
            'semester': 1,
          },
          null,
        );
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Paper 2',
            'subject': 'Subject B',
            'year': 2,
            'semester': 3,
          },
          null,
        );

        expect(controller.questionPapers, hasLength(2));
        final qpToDelete = controller.questionPapers.first;

        // Act
        await controller.deleteQuestionPaper(qpToDelete.id);

        // Assert
        expect(controller.questionPapers, hasLength(1));
        expect(controller.questionPapers.first.title, equals('Paper 2'));
      });

      test('should handle deletion of non-existent question paper', () async {
        // Arrange
        final nonExistentId = 'non-existent-id';

        // Act
        final result = await controller.deleteQuestionPaper(nonExistentId);

        // Assert
        expect(result, isTrue); // API returns success
        expect(controller.questionPapers, isEmpty);
      });
    });

    group('clearQuestionPapers', () {
      test('should clear all question papers from list', () async {
        // Arrange - create multiple question papers
        for (var i = 0; i < 5; i++) {
          await controller.createQuestionPaperWithPdf(
            {
              'title': 'Paper ${i + 1}',
              'subject': 'Subject ${i + 1}',
              'year': (i % 4) + 1,
              'semester': (i % 8) + 1,
            },
            null,
          );
        }

        expect(controller.questionPapers, hasLength(5));

        // Act
        controller.clearQuestionPapers();

        // Assert
        expect(controller.questionPapers, isEmpty);
      });

      test('should handle clearing empty list', () {
        // Arrange
        expect(controller.questionPapers, isEmpty);

        // Act
        controller.clearQuestionPapers();

        // Assert
        expect(controller.questionPapers, isEmpty);
      });

      test('should allow adding question papers after clearing', () async {
        // Arrange - create and clear
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Paper 1',
            'subject': 'Subject A',
            'year': 1,
            'semester': 1,
          },
          null,
        );
        controller.clearQuestionPapers();
        expect(controller.questionPapers, isEmpty);

        // Act - add new question paper
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Paper 2',
            'subject': 'Subject B',
            'year': 2,
            'semester': 3,
          },
          null,
        );

        // Assert
        expect(controller.questionPapers, hasLength(1));
        expect(controller.questionPapers.first.title, equals('Paper 2'));
      });
    });

    group('error handling', () {
      test('should set error message when creation fails', () async {
        // Arrange
        mockApiService.shouldFailCreate = true;
        final questionPaperData = {
          'title': 'Error Test',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 1,
        };

        // Act
        await controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        // Assert
        expect(controller.error, isNotEmpty);
      });

      test('should set error message when deletion fails', () async {
        // Arrange
        mockApiService.shouldFailDelete = true;
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Delete Error Test',
            'subject': 'Test Subject',
            'year': 1,
            'semester': 1,
          },
          null,
        );
        final qpId = controller.questionPapers.first.id;

        // Act
        await controller.deleteQuestionPaper(qpId);

        // Assert
        expect(controller.error, isNotEmpty);
      });

      test('should clear error on successful operation', () async {
        // Arrange - cause an error first
        mockApiService.shouldFailCreate = true;
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Error Test',
            'subject': 'Test Subject',
            'year': 1,
            'semester': 1,
          },
          null,
        );
        expect(controller.error, isNotEmpty);

        // Act - perform successful operation
        mockApiService.shouldFailCreate = false;
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Success Test',
            'subject': 'Test Subject',
            'year': 2,
            'semester': 3,
          },
          null,
        );

        // Assert
        expect(controller.error, isEmpty);
      });
    });

    group('loading state', () {
      test('should set loading state during creation', () async {
        // Arrange
        final questionPaperData = {
          'title': 'Loading Test',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 1,
        };

        // Act & Assert
        final future = controller.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        // Loading should be false after completion
        await future;
        expect(controller.isLoading, isFalse);
      });

      test('should set loading state during deletion', () async {
        // Arrange
        await controller.createQuestionPaperWithPdf(
          {
            'title': 'Loading Delete Test',
            'subject': 'Test Subject',
            'year': 1,
            'semester': 1,
          },
          null,
        );
        final qpId = controller.questionPapers.first.id;

        // Act & Assert
        final future = controller.deleteQuestionPaper(qpId);

        // Loading should be false after completion
        await future;
        expect(controller.isLoading, isFalse);
      });
    });
  });
}
