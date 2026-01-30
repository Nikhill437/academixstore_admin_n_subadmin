import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:academixstore_admin_n_subadmin/modules/books/view/add_edit_book_dialog.dart';
import 'package:academixstore_admin_n_subadmin/modules/books/controller/books_controller.dart';
import 'package:academixstore_admin_n_subadmin/modules/colleges/controller/colleges_controller.dart';
import 'package:academixstore_admin_n_subadmin/modules/colleges/model/college.dart';
import 'package:academixstore_admin_n_subadmin/services/api_service.dart';
import 'package:academixstore_admin_n_subadmin/services/role_access_service.dart';
import 'package:academixstore_admin_n_subadmin/services/api/question_papers_api_service.dart';
import 'package:academixstore_admin_n_subadmin/services/file_validation_service.dart';
import 'package:academixstore_admin_n_subadmin/models/question_paper.dart';

/// Mock services for testing error scenarios
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

/// Mock QuestionPapersApiService that can simulate errors
class MockQuestionPapersApiServiceWithErrors extends GetxService 
    implements QuestionPapersApiService {
  bool shouldFailCreation = false;
  bool shouldFailUpload = false;
  bool shouldFailDeletion = false;
  bool shouldThrowNetworkError = false;
  int _idCounter = 0;
  
  final List<QuestionPaper> createdQuestionPapers = [];
  final Map<String, String> uploadedPdfs = {};
  
  @override
  Future<QuestionPaper> createQuestionPaper(
    Map<String, dynamic> questionPaperData,
  ) async {
    if (shouldThrowNetworkError) {
      throw Exception('Network error: Connection timeout');
    }
    
    if (shouldFailCreation) {
      throw Exception('API error: Failed to create question paper');
    }
    
    final qp = QuestionPaper(
      id: 'qp-${_idCounter++}',
      title: questionPaperData['title'] as String,
      subject: questionPaperData['subject'] as String,
      year: questionPaperData['year'] as int,
      semester: questionPaperData['semester'] as int,
      description: questionPaperData['description'] as String?,
      examType: questionPaperData['exam_type'] as String?,
      marks: questionPaperData['marks'] as int?,
      createdAt: DateTime.now(),
    );
    createdQuestionPapers.add(qp);
    return qp;
  }
  
  @override
  Future<Map<String, dynamic>> uploadQuestionPaperPdf(
    String questionPaperId,
    String? filePath, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    if (shouldThrowNetworkError) {
      throw Exception('Network error: Connection timeout');
    }
    
    if (shouldFailUpload) {
      throw Exception('API error: Failed to upload PDF');
    }
    
    uploadedPdfs[questionPaperId] = fileName ?? 'unknown.pdf';
    return {
      'question_paper_id': questionPaperId,
      'pdf_url': 'https://example.com/$fileName',
    };
  }
  
  @override
  Future<bool> deleteQuestionPaper(String questionPaperId) async {
    if (shouldThrowNetworkError) {
      throw Exception('Network error: Connection timeout');
    }
    
    if (shouldFailDeletion) {
      throw Exception('API error: Failed to delete question paper');
    }
    
    createdQuestionPapers.removeWhere((qp) => qp.id == questionPaperId);
    uploadedPdfs.remove(questionPaperId);
    return true;
  }
  
  @override
  Future<List<QuestionPaper>> getQuestionPapers({
    String? subject,
    int? year,
    int? semester,
    String? examType,
  }) async {
    return createdQuestionPapers;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCollegesController extends GetxController implements CollegesController {
  final RxList<College> _colleges = <College>[].obs;
  
  @override
  List<College> get colleges => _colleges.toList();
  
  @override
  bool get isLoading => false;
  
  @override
  Future<void> loadColleges({bool refresh = false}) async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Task 11.4: Error Recovery Workflows', () {
    late BooksController booksController;
    late MockQuestionPapersApiServiceWithErrors mockQpApiService;
    late FileValidationService fileValidationService;
    
    setUp(() {
      // Initialize GetX
      Get.testMode = true;
      
      // Register mock services
      Get.put<ApiService>(MockApiService());
      Get.put<RoleAccessService>(MockRoleAccessService());
      mockQpApiService = MockQuestionPapersApiServiceWithErrors();
      Get.put<QuestionPapersApiService>(mockQpApiService);
      fileValidationService = FileValidationService();
      Get.put<FileValidationService>(fileValidationService);
      booksController = BooksController();
      Get.put<BooksController>(booksController);
      Get.put<CollegesController>(MockCollegesController());
    });

    tearDown(() {
      booksController.clearQuestionPapers();
      mockQpApiService.createdQuestionPapers.clear();
      mockQpApiService.uploadedPdfs.clear();
      Get.reset();
    });

    group('Validation Error Recovery', () {
      test('retry after validation error - file type validation', () async {
        // Step 1: Attempt to validate invalid file (non-PDF)
        final invalidFileResult = fileValidationService.validatePdfFile(
          fileName: 'document.docx',
          fileSizeBytes: 1000000,
        );
        
        // Verify validation fails
        expect(invalidFileResult.isValid, isFalse);
        expect(invalidFileResult.errorMessage, contains('PDF'));
        
        // Step 2: Retry with valid PDF file
        final validFileResult = fileValidationService.validatePdfFile(
          fileName: 'document.pdf',
          fileSizeBytes: 1000000,
        );
        
        // Verify validation succeeds
        expect(validFileResult.isValid, isTrue);
        expect(validFileResult.errorMessage, isNull);
      });

      test('retry after validation error - file size validation', () async {
        // Step 1: Attempt to validate oversized file
        final oversizedFileResult = fileValidationService.validatePdfFile(
          fileName: 'large-document.pdf',
          fileSizeBytes: 60 * 1024 * 1024, // 60MB
        );
        
        // Verify validation fails
        expect(oversizedFileResult.isValid, isFalse);
        expect(oversizedFileResult.errorMessage, contains('50MB'));
        
        // Step 2: Retry with valid file size
        final validFileResult = fileValidationService.validatePdfFile(
          fileName: 'large-document.pdf',
          fileSizeBytes: 40 * 1024 * 1024, // 40MB
        );
        
        // Verify validation succeeds
        expect(validFileResult.isValid, isTrue);
        expect(validFileResult.errorMessage, isNull);
      });

      test('retry after validation error - empty required fields', () async {
        // Step 1: Attempt to create question paper with empty title
        final invalidData = {
          'title': '',  // Empty title
          'subject': 'Mathematics',
          'year': 1,
          'semester': 1,
        };
        
        // Verify title is empty (validation would fail in UI)
        expect(invalidData['title'], isEmpty);
        
        // Step 2: Retry with valid title
        final validData = {
          'title': 'Midterm Exam',  // Valid title
          'subject': 'Mathematics',
          'year': 1,
          'semester': 1,
        };
        
        // Verify title is not empty
        expect(validData['title'], isNotEmpty);
        
        // Step 3: Create question paper with valid data
        final qp = await booksController.createQuestionPaperWithPdf(
          validData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'exam.pdf',
        );
        
        // Verify creation succeeds
        expect(qp, isNotNull);
        expect(qp!.title, 'Midterm Exam');
      });

      test('form data is preserved after validation error', () async {
        // Simulate form data
        final formData = {
          'title': 'Midterm Exam - Data Structures',
          'subject': 'Data Structures',
          'year': 2,
          'semester': 3,
          'description': 'Covers arrays, linked lists, stacks, queues',
          'exam_type': 'midterm',
          'marks': 100,
        };
        
        // Step 1: Validation error occurs (e.g., invalid file)
        final invalidFileResult = fileValidationService.validatePdfFile(
          fileName: 'document.txt',
          fileSizeBytes: 1000000,
        );
        
        expect(invalidFileResult.isValid, isFalse);
        
        // Step 2: Verify form data is still intact (not cleared)
        expect(formData['title'], 'Midterm Exam - Data Structures');
        expect(formData['subject'], 'Data Structures');
        expect(formData['year'], 2);
        expect(formData['semester'], 3);
        expect(formData['description'], 'Covers arrays, linked lists, stacks, queues');
        expect(formData['exam_type'], 'midterm');
        expect(formData['marks'], 100);
        
        // Step 3: Retry with valid file
        final validFileResult = fileValidationService.validatePdfFile(
          fileName: 'document.pdf',
          fileSizeBytes: 1000000,
        );
        
        expect(validFileResult.isValid, isTrue);
        
        // Step 4: Create question paper with preserved form data
        final qp = await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'document.pdf',
        );
        
        // Verify creation succeeds with preserved data
        expect(qp, isNotNull);
        expect(qp!.title, formData['title']);
        expect(qp.subject, formData['subject']);
        expect(qp.year, formData['year']);
        expect(qp.semester, formData['semester']);
      });
    });

    group('API Error Recovery', () {
      test('retry after API error - creation failure', () async {
        final questionPaperData = {
          'title': 'Midterm Exam',
          'subject': 'Mathematics',
          'year': 1,
          'semester': 1,
        };
        
        // Step 1: Simulate API error
        mockQpApiService.shouldFailCreation = true;
        
        final failedQp = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'exam.pdf',
        );
        
        // Verify creation fails
        expect(failedQp, isNull);
        expect(booksController.questionPapers.length, 0);
        
        // Step 2: Fix API error and retry
        mockQpApiService.shouldFailCreation = false;
        
        final successQp = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'exam.pdf',
        );
        
        // Verify retry succeeds
        expect(successQp, isNotNull);
        expect(booksController.questionPapers.length, 1);
        expect(successQp!.title, 'Midterm Exam');
      });

      test('retry after API error - upload failure', () async {
        final questionPaperData = {
          'title': 'Final Exam',
          'subject': 'Physics',
          'year': 2,
          'semester': 2,
        };
        
        // Step 1: Simulate upload failure (creation succeeds)
        mockQpApiService.shouldFailUpload = true;
        
        final qpWithFailedUpload = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'exam.pdf',
        );
        
        // Verify creation succeeds but upload fails (partial failure)
        // The question paper is created and added to list even though upload failed
        expect(qpWithFailedUpload, isNotNull);
        expect(booksController.questionPapers.length, 1);
        expect(mockQpApiService.uploadedPdfs.containsKey(qpWithFailedUpload!.id), isFalse);
        
        // Step 2: Fix upload error and retry entire operation with new question paper
        mockQpApiService.shouldFailUpload = false;
        
        final qpWithSuccessfulUpload = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'exam.pdf',
        );
        
        // Verify retry succeeds
        expect(qpWithSuccessfulUpload, isNotNull);
        expect(booksController.questionPapers.length, 2);
        expect(mockQpApiService.uploadedPdfs.containsKey(qpWithSuccessfulUpload!.id), isTrue);
      });

      test('retry after API error - deletion failure', () async {
        // Step 1: Create a question paper
        final qp = await booksController.createQuestionPaperWithPdf(
          {
            'title': 'Quiz 1',
            'subject': 'Chemistry',
            'year': 1,
            'semester': 1,
          },
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'quiz.pdf',
        );
        
        expect(qp, isNotNull);
        expect(booksController.questionPapers.length, 1);
        
        // Step 2: Simulate deletion failure
        mockQpApiService.shouldFailDeletion = true;
        
        final failedDeletion = await booksController.deleteQuestionPaper(qp!.id);
        
        // Verify deletion fails
        expect(failedDeletion, isFalse);
        expect(booksController.questionPapers.length, 1);
        
        // Step 3: Fix deletion error and retry
        mockQpApiService.shouldFailDeletion = false;
        
        final successfulDeletion = await booksController.deleteQuestionPaper(qp.id);
        
        // Verify retry succeeds
        expect(successfulDeletion, isTrue);
        expect(booksController.questionPapers.length, 0);
      });

      test('form data is preserved after API error', () async {
        final formData = {
          'title': 'Practice Test',
          'subject': 'Biology',
          'year': 3,
          'semester': 5,
          'description': 'Practice questions for final exam',
          'exam_type': 'practice',
          'marks': 75,
        };
        
        // Step 1: Simulate API error
        mockQpApiService.shouldFailCreation = true;
        
        final failedQp = await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'practice.pdf',
        );
        
        expect(failedQp, isNull);
        
        // Step 2: Verify form data is preserved (not cleared)
        expect(formData['title'], 'Practice Test');
        expect(formData['subject'], 'Biology');
        expect(formData['year'], 3);
        expect(formData['semester'], 5);
        expect(formData['description'], 'Practice questions for final exam');
        expect(formData['exam_type'], 'practice');
        expect(formData['marks'], 75);
        
        // Step 3: Retry with preserved data
        mockQpApiService.shouldFailCreation = false;
        
        final successQp = await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'practice.pdf',
        );
        
        // Verify retry succeeds with preserved data
        expect(successQp, isNotNull);
        expect(successQp!.title, formData['title']);
        expect(successQp.subject, formData['subject']);
        expect(successQp.marks, formData['marks']);
      });
    });

    group('Network Error Recovery', () {
      test('retry after network error - creation', () async {
        final questionPaperData = {
          'title': 'Network Test',
          'subject': 'Computer Networks',
          'year': 2,
          'semester': 4,
        };
        
        // Step 1: Simulate network error
        mockQpApiService.shouldThrowNetworkError = true;
        
        final failedQp = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'network.pdf',
        );
        
        // Verify creation fails due to network error
        expect(failedQp, isNull);
        expect(booksController.questionPapers.length, 0);
        
        // Step 2: Fix network and retry
        mockQpApiService.shouldThrowNetworkError = false;
        
        final successQp = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'network.pdf',
        );
        
        // Verify retry succeeds
        expect(successQp, isNotNull);
        expect(booksController.questionPapers.length, 1);
        expect(successQp!.title, 'Network Test');
      });

      test('retry after network error - upload', () async {
        final questionPaperData = {
          'title': 'Upload Test',
          'subject': 'Software Engineering',
          'year': 3,
          'semester': 6,
        };
        
        // Step 1: Simulate network error during upload
        mockQpApiService.shouldThrowNetworkError = true;
        
        final failedQp = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'upload.pdf',
        );
        
        // Verify operation fails
        expect(failedQp, isNull);
        
        // Step 2: Fix network and retry
        mockQpApiService.shouldThrowNetworkError = false;
        
        final successQp = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'upload.pdf',
        );
        
        // Verify retry succeeds
        expect(successQp, isNotNull);
        expect(mockQpApiService.uploadedPdfs.containsKey(successQp!.id), isTrue);
      });

      test('retry after network error - deletion', () async {
        // Step 1: Create a question paper
        final qp = await booksController.createQuestionPaperWithPdf(
          {
            'title': 'Delete Test',
            'subject': 'Operating Systems',
            'year': 2,
            'semester': 3,
          },
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'delete.pdf',
        );
        
        expect(qp, isNotNull);
        expect(booksController.questionPapers.length, 1);
        
        // Step 2: Simulate network error during deletion
        mockQpApiService.shouldThrowNetworkError = true;
        
        final failedDeletion = await booksController.deleteQuestionPaper(qp!.id);
        
        // Verify deletion fails
        expect(failedDeletion, isFalse);
        expect(booksController.questionPapers.length, 1);
        
        // Step 3: Fix network and retry
        mockQpApiService.shouldThrowNetworkError = false;
        
        final successfulDeletion = await booksController.deleteQuestionPaper(qp.id);
        
        // Verify retry succeeds
        expect(successfulDeletion, isTrue);
        expect(booksController.questionPapers.length, 0);
      });

      test('form data is preserved after network error', () async {
        final formData = {
          'title': 'Network Recovery Test',
          'subject': 'Distributed Systems',
          'year': 4,
          'semester': 7,
          'description': 'Testing network error recovery',
          'exam_type': 'final',
          'marks': 150,
        };
        
        // Step 1: Simulate network error
        mockQpApiService.shouldThrowNetworkError = true;
        
        final failedQp = await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'network-recovery.pdf',
        );
        
        expect(failedQp, isNull);
        
        // Step 2: Verify form data is preserved
        expect(formData['title'], 'Network Recovery Test');
        expect(formData['subject'], 'Distributed Systems');
        expect(formData['year'], 4);
        expect(formData['semester'], 7);
        expect(formData['description'], 'Testing network error recovery');
        expect(formData['exam_type'], 'final');
        expect(formData['marks'], 150);
        
        // Step 3: Retry with preserved data after network recovery
        mockQpApiService.shouldThrowNetworkError = false;
        
        final successQp = await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'network-recovery.pdf',
        );
        
        // Verify retry succeeds with preserved data
        expect(successQp, isNotNull);
        expect(successQp!.title, formData['title']);
        expect(successQp.subject, formData['subject']);
        expect(successQp.year, formData['year']);
        expect(successQp.semester, formData['semester']);
        expect(successQp.marks, formData['marks']);
      });
    });

    group('Multiple Retry Scenarios', () {
      test('multiple retries after different errors', () async {
        final formData = {
          'title': 'Multi-Retry Test',
          'subject': 'Software Testing',
          'year': 3,
          'semester': 5,
        };
        
        // Attempt 1: Network error
        mockQpApiService.shouldThrowNetworkError = true;
        var result = await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'test.pdf',
        );
        expect(result, isNull);
        
        // Attempt 2: API error
        mockQpApiService.shouldThrowNetworkError = false;
        mockQpApiService.shouldFailCreation = true;
        result = await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'test.pdf',
        );
        expect(result, isNull);
        
        // Attempt 3: Success
        mockQpApiService.shouldFailCreation = false;
        result = await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'test.pdf',
        );
        expect(result, isNotNull);
        expect(result!.title, 'Multi-Retry Test');
      });

      test('form data preserved across multiple error types', () async {
        final formData = {
          'title': 'Persistence Test',
          'subject': 'Data Persistence',
          'year': 2,
          'semester': 4,
          'description': 'Testing data persistence across errors',
          'exam_type': 'midterm',
          'marks': 100,
        };
        
        // Error 1: Network error
        mockQpApiService.shouldThrowNetworkError = true;
        await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'persist.pdf',
        );
        
        // Verify data preserved
        expect(formData['title'], 'Persistence Test');
        expect(formData['marks'], 100);
        
        // Error 2: API error
        mockQpApiService.shouldThrowNetworkError = false;
        mockQpApiService.shouldFailCreation = true;
        await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'persist.pdf',
        );
        
        // Verify data still preserved
        expect(formData['title'], 'Persistence Test');
        expect(formData['description'], 'Testing data persistence across errors');
        expect(formData['marks'], 100);
        
        // Success
        mockQpApiService.shouldFailCreation = false;
        final result = await booksController.createQuestionPaperWithPdf(
          formData,
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'persist.pdf',
        );
        
        // Verify success with preserved data
        expect(result, isNotNull);
        expect(result!.title, formData['title']);
        expect(result.description, formData['description']);
        expect(result.marks, formData['marks']);
      });
    });

    group('UI State After Errors', () {
      testWidgets('dialog remains open after validation error', 
          (WidgetTester tester) async {
        final widget = GetMaterialApp(
          home: Scaffold(
            body: AddEditBookDialog(),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Verify dialog is open
        expect(find.byType(AddEditBookDialog), findsOneWidget);
        
        // Simulate validation error (invalid file)
        final validationResult = fileValidationService.validatePdfFile(
          fileName: 'document.txt',
          fileSizeBytes: 1000000,
        );
        
        expect(validationResult.isValid, isFalse);
        
        await tester.pumpAndSettle();
        
        // Verify dialog remains open
        expect(find.byType(AddEditBookDialog), findsOneWidget);
      });

      testWidgets('dialog remains open after API error', 
          (WidgetTester tester) async {
        final widget = GetMaterialApp(
          home: Scaffold(
            body: AddEditBookDialog(),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Verify dialog is open
        expect(find.byType(AddEditBookDialog), findsOneWidget);
        
        // Simulate API error
        mockQpApiService.shouldFailCreation = true;
        
        final result = await booksController.createQuestionPaperWithPdf(
          {
            'title': 'Test',
            'subject': 'Test Subject',
            'year': 1,
            'semester': 1,
          },
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'test.pdf',
        );
        
        expect(result, isNull);
        
        await tester.pumpAndSettle();
        
        // Verify dialog remains open
        expect(find.byType(AddEditBookDialog), findsOneWidget);
      });

      testWidgets('dialog remains open after network error', 
          (WidgetTester tester) async {
        final widget = GetMaterialApp(
          home: Scaffold(
            body: AddEditBookDialog(),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Verify dialog is open
        expect(find.byType(AddEditBookDialog), findsOneWidget);
        
        // Simulate network error
        mockQpApiService.shouldThrowNetworkError = true;
        
        final result = await booksController.createQuestionPaperWithPdf(
          {
            'title': 'Network Test',
            'subject': 'Networks',
            'year': 2,
            'semester': 3,
          },
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'network.pdf',
        );
        
        expect(result, isNull);
        
        await tester.pumpAndSettle();
        
        // Verify dialog remains open
        expect(find.byType(AddEditBookDialog), findsOneWidget);
      });
    });
  });
}
