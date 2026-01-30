import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:academixstore_admin_n_subadmin/modules/books/controller/books_controller.dart';
import 'package:academixstore_admin_n_subadmin/modules/colleges/controller/colleges_controller.dart';
import 'package:academixstore_admin_n_subadmin/modules/colleges/model/college.dart';
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
      'question_paper_id': questionPaperId,
      'file_path': filePath,
      'file_bytes': fileBytes,
      'file_name': fileName,
    };
    
    return {
      'question_paper_id': questionPaperId,
      'pdf_url': 'https://example.com/test.pdf',
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
  Future<List<QuestionPaper>> getQuestionPapers({
    String? subject,
    int? year,
    int? semester,
    String? examType,
  }) async {
    return [];
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
  group('Question Paper Dialog Methods - Unit Tests', () {
    late BooksController booksController;
    late MockQuestionPapersApiService mockQpApiService;

    setUp(() {
      Get.testMode = true;
      
      Get.put<ApiService>(MockApiService());
      Get.put<RoleAccessService>(MockRoleAccessService());
      mockQpApiService = MockQuestionPapersApiService();
      Get.put<QuestionPapersApiService>(mockQpApiService);
      booksController = BooksController();
      Get.put<BooksController>(booksController);
      Get.put<CollegesController>(MockCollegesController());
    });

    tearDown(() {
      Get.reset();
    });

    group('_saveQuestionPaper', () {
      test('creates question paper with valid data', () async {
        final questionPaperData = {
          'title': 'Midterm Exam',
          'subject': 'Mathematics',
          'year': 2,
          'semester': 3,
          'description': 'Test description',
          'exam_type': 'midterm',
          'marks': 100,
        };

        final result = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        expect(result, isNotNull);
        expect(result!.title, equals('Midterm Exam'));
        expect(result.subject, equals('Mathematics'));
        expect(result.year, equals(2));
        expect(result.semester, equals(3));
        expect(mockQpApiService.lastCreatedQuestionPaper, isNotNull);
        expect(mockQpApiService.lastUploadCall, isNotNull);
      });

      test('handles API failure gracefully', () async {
        mockQpApiService.shouldFailCreate = true;

        final questionPaperData = {
          'title': 'Test',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 1,
        };

        final result = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        expect(result, isNull);
      });

      test('handles upload failure after creation', () async {
        mockQpApiService.shouldFailUpload = true;

        final questionPaperData = {
          'title': 'Test',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 1,
        };

        final result = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        // Question paper is created but upload fails
        // The controller should handle this gracefully
        expect(mockQpApiService.lastCreatedQuestionPaper, isNotNull);
      });
    });

    group('_deleteQuestionPaper', () {
      test('deletes question paper with valid ID', () async {
        // First create a question paper
        final questionPaperData = {
          'title': 'Test',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 1,
        };

        final created = await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        expect(created, isNotNull);
        expect(booksController.questionPapers.length, equals(1));

        // Now delete it
        final success = await booksController.deleteQuestionPaper(created!.id);

        expect(success, isTrue);
        expect(mockQpApiService.lastDeletedQuestionPaperId, equals(created.id));
        expect(booksController.questionPapers.length, equals(0));
      });

      test('handles API failure during deletion', () async {
        mockQpApiService.shouldFailDelete = true;

        final success = await booksController.deleteQuestionPaper('test-id');

        expect(success, isFalse);
      });
    });

    group('File validation', () {
      test('validates PDF file type correctly', () {
        // This test validates the file validation logic
        // The actual validation is done by FileValidationService
        // which is tested separately
        
        final validPdfNames = [
          'document.pdf',
          'test.PDF',
          'file.with.dots.pdf',
        ];

        for (final name in validPdfNames) {
          expect(
            name.toLowerCase().endsWith('.pdf'),
            isTrue,
            reason: '$name should be recognized as a PDF',
          );
        }

        final invalidNames = [
          'document.doc',
          'test.txt',
          'file.jpg',
        ];

        for (final name in invalidNames) {
          expect(
            name.toLowerCase().endsWith('.pdf'),
            isFalse,
            reason: '$name should not be recognized as a PDF',
          );
        }
      });
    });

    group('Form state management', () {
      test('question papers list is initially empty', () {
        expect(booksController.questionPapers, isEmpty);
      });

      test('question papers list updates after creation', () async {
        final questionPaperData = {
          'title': 'Test 1',
          'subject': 'Subject 1',
          'year': 1,
          'semester': 1,
        };

        await booksController.createQuestionPaperWithPdf(
          questionPaperData,
          null,
          pdfFileBytes: [1, 2, 3],
          pdfFileName: 'test.pdf',
        );

        expect(booksController.questionPapers.length, equals(1));
        expect(booksController.questionPapers.first.title, equals('Test 1'));
      });

      test('can add multiple question papers', () async {
        for (int i = 1; i <= 3; i++) {
          final questionPaperData = {
            'title': 'Test $i',
            'subject': 'Subject $i',
            'year': 1,
            'semester': i,
          };

          await booksController.createQuestionPaperWithPdf(
            questionPaperData,
            null,
            pdfFileBytes: [1, 2, 3],
            pdfFileName: 'test$i.pdf',
          );
        }

        expect(booksController.questionPapers.length, equals(3));
      });

      test('clearQuestionPapers removes all question papers', () async {
        // Add some question papers
        for (int i = 1; i <= 2; i++) {
          final questionPaperData = {
            'title': 'Test $i',
            'subject': 'Subject $i',
            'year': 1,
            'semester': i,
          };

          await booksController.createQuestionPaperWithPdf(
            questionPaperData,
            null,
            pdfFileBytes: [1, 2, 3],
            pdfFileName: 'test$i.pdf',
          );
        }

        expect(booksController.questionPapers.length, equals(2));

        // Clear the list
        booksController.clearQuestionPapers();

        expect(booksController.questionPapers, isEmpty);
      });
    });
  });
}
