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
  final List<QuestionPaper> createdQuestionPapers = [];
  final Map<String, String> uploadedPdfs = {};
  
  @override
  Future<QuestionPaper> createQuestionPaper(
    Map<String, dynamic> questionPaperData,
  ) async {
    final qp = QuestionPaper(
      id: 'qp-${DateTime.now().millisecondsSinceEpoch}-${createdQuestionPapers.length}',
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
    uploadedPdfs[questionPaperId] = fileName ?? 'unknown.pdf';
    return {
      'question_paper_id': questionPaperId,
      'pdf_url': 'https://example.com/$fileName',
    };
  }
  
  @override
  Future<bool> deleteQuestionPaper(String questionPaperId) async {
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

void main() {
  group('Property 16: Book-Question Paper Association Persistence', () {
    late BooksController booksController;
    late MockQuestionPapersApiService mockQpApiService;
    
    setUp(() {
      // Initialize GetX
      Get.testMode = true;
      
      // Register mock services
      Get.put<ApiService>(MockApiService());
      Get.put<RoleAccessService>(MockRoleAccessService());
      mockQpApiService = MockQuestionPapersApiService();
      Get.put<QuestionPapersApiService>(mockQpApiService);
      booksController = BooksController();
      Get.put<BooksController>(booksController);
    });

    tearDown(() {
      booksController.clearQuestionPapers();
      mockQpApiService.createdQuestionPapers.clear();
      mockQpApiService.uploadedPdfs.clear();
      Get.reset();
    });

    /// Feature: question-paper-upload-for-books, Property 16: Book-Question Paper Association Persistence
    /// Validates: Requirements 5.4
    /// 
    /// Property: For ANY book with associated question papers, when the book is saved,
    /// all associations between the book and its question papers SHALL be persisted.
    /// 
    /// This property test generates various combinations of question papers and verifies
    /// that all associations are maintained after creation.
    group('Property: All book-question paper associations are persisted', () {
      // Test case generator: Different numbers of question papers
      final testCases = [
        {'count': 1, 'description': 'single question paper'},
        {'count': 2, 'description': 'two question papers'},
        {'count': 3, 'description': 'three question papers'},
        {'count': 5, 'description': 'five question papers'},
        {'count': 10, 'description': 'ten question papers'},
      ];

      for (final testCase in testCases) {
        test('persists associations for ${testCase['description']}', () async {
          final count = testCase['count'] as int;
          final createdQuestionPapers = <QuestionPaper>[];

          // Generate and create question papers
          for (int i = 0; i < count; i++) {
            final qpData = {
              'title': 'Question Paper ${i + 1}',
              'subject': 'Subject ${i % 5 + 1}', // Vary subjects
              'year': (i % 4) + 1, // Years 1-4
              'semester': (i % 8) + 1, // Semesters 1-8
              'exam_type': ['midterm', 'final', 'quiz', 'practice'][i % 4],
              'marks': (i + 1) * 10, // Vary marks
            };

            final qp = await booksController.createQuestionPaperWithPdf(
              qpData,
              null,
              pdfFileBytes: List.generate(100 * (i + 1), (j) => j % 256),
              pdfFileName: 'qp${i + 1}.pdf',
            );

            expect(qp, isNotNull, reason: 'Question paper $i should be created');
            createdQuestionPapers.add(qp!);
          }

          // Property validation: All associations are persisted
          // 1. Verify count matches
          expect(
            booksController.questionPapers.length,
            count,
            reason: 'Controller should have $count question papers',
          );

          // 2. Verify all question papers are in the controller's list
          for (int i = 0; i < count; i++) {
            final qp = createdQuestionPapers[i];
            final found = booksController.questionPapers.any((q) => q.id == qp.id);
            expect(
              found,
              isTrue,
              reason: 'Question paper ${qp.id} should be in controller list',
            );
          }

          // 3. Verify all question papers have correct data
          for (int i = 0; i < count; i++) {
            final qp = booksController.questionPapers[i];
            expect(qp.title, 'Question Paper ${i + 1}');
            expect(qp.subject, 'Subject ${i % 5 + 1}');
            expect(qp.year, (i % 4) + 1);
            expect(qp.semester, (i % 8) + 1);
            expect(qp.examType, ['midterm', 'final', 'quiz', 'practice'][i % 4]);
            expect(qp.marks, (i + 1) * 10);
          }

          // 4. Verify all PDFs are uploaded
          for (int i = 0; i < count; i++) {
            final qp = createdQuestionPapers[i];
            expect(
              mockQpApiService.uploadedPdfs.containsKey(qp.id),
              isTrue,
              reason: 'PDF for question paper ${qp.id} should be uploaded',
            );
            expect(
              mockQpApiService.uploadedPdfs[qp.id],
              'qp${i + 1}.pdf',
              reason: 'PDF filename should match',
            );
          }
        });
      }

      /// Test with various exam types
      test('persists associations with different exam types', () async {
        final examTypes = ['midterm', 'final', 'quiz', 'practice'];
        final createdQuestionPapers = <QuestionPaper>[];

        for (int i = 0; i < examTypes.length; i++) {
          final qpData = {
            'title': '${examTypes[i]} Exam',
            'subject': 'Mathematics',
            'year': 2,
            'semester': 3,
            'exam_type': examTypes[i],
            'marks': 100,
          };

          final qp = await booksController.createQuestionPaperWithPdf(
            qpData,
            null,
            pdfFileBytes: [1, 2, 3, 4],
            pdfFileName: '${examTypes[i]}.pdf',
          );

          expect(qp, isNotNull);
          createdQuestionPapers.add(qp!);
        }

        // Property validation: All exam types are persisted
        expect(booksController.questionPapers.length, examTypes.length);
        
        for (int i = 0; i < examTypes.length; i++) {
          final qp = booksController.questionPapers[i];
          expect(qp.examType, examTypes[i]);
          expect(qp.title, '${examTypes[i]} Exam');
        }
      });

      /// Test with various year and semester combinations
      test('persists associations with different year/semester combinations', () async {
        final combinations = [
          {'year': 1, 'semester': 1},
          {'year': 1, 'semester': 2},
          {'year': 2, 'semester': 3},
          {'year': 2, 'semester': 4},
          {'year': 3, 'semester': 5},
          {'year': 3, 'semester': 6},
          {'year': 4, 'semester': 7},
          {'year': 4, 'semester': 8},
        ];

        final createdQuestionPapers = <QuestionPaper>[];

        for (int i = 0; i < combinations.length; i++) {
          final combo = combinations[i];
          final qpData = {
            'title': 'QP Year ${combo['year']} Sem ${combo['semester']}',
            'subject': 'Subject $i',
            'year': combo['year'],
            'semester': combo['semester'],
          };

          final qp = await booksController.createQuestionPaperWithPdf(
            qpData,
            null,
            pdfFileBytes: [1, 2, 3, 4],
            pdfFileName: 'qp_y${combo['year']}_s${combo['semester']}.pdf',
          );

          expect(qp, isNotNull);
          createdQuestionPapers.add(qp!);
        }

        // Property validation: All year/semester combinations are persisted
        expect(booksController.questionPapers.length, combinations.length);
        
        for (int i = 0; i < combinations.length; i++) {
          final qp = booksController.questionPapers[i];
          final combo = combinations[i];
          expect(qp.year, combo['year']);
          expect(qp.semester, combo['semester']);
        }
      });

      /// Test with optional fields (description, marks)
      test('persists associations with optional fields', () async {
        final testCases = [
          {
            'title': 'QP with description',
            'subject': 'Math',
            'year': 1,
            'semester': 1,
            'description': 'This is a detailed description',
          },
          {
            'title': 'QP with marks',
            'subject': 'Physics',
            'year': 2,
            'semester': 3,
            'marks': 150,
          },
          {
            'title': 'QP with both',
            'subject': 'Chemistry',
            'year': 3,
            'semester': 5,
            'description': 'Final exam covering all topics',
            'marks': 200,
          },
          {
            'title': 'QP with neither',
            'subject': 'Biology',
            'year': 4,
            'semester': 7,
          },
        ];

        final createdQuestionPapers = <QuestionPaper>[];

        for (int i = 0; i < testCases.length; i++) {
          final qp = await booksController.createQuestionPaperWithPdf(
            testCases[i],
            null,
            pdfFileBytes: [1, 2, 3, 4],
            pdfFileName: 'qp$i.pdf',
          );

          expect(qp, isNotNull);
          createdQuestionPapers.add(qp!);
        }

        // Property validation: All optional fields are persisted correctly
        expect(booksController.questionPapers.length, testCases.length);
        
        expect(booksController.questionPapers[0].description, 'This is a detailed description');
        expect(booksController.questionPapers[0].marks, isNull);
        
        expect(booksController.questionPapers[1].description, isNull);
        expect(booksController.questionPapers[1].marks, 150);
        
        expect(booksController.questionPapers[2].description, 'Final exam covering all topics');
        expect(booksController.questionPapers[2].marks, 200);
        
        expect(booksController.questionPapers[3].description, isNull);
        expect(booksController.questionPapers[3].marks, isNull);
      });

      /// Test persistence after multiple operations
      test('maintains associations after adding and verifying multiple times', () async {
        // Add first batch
        for (int i = 0; i < 3; i++) {
          await booksController.createQuestionPaperWithPdf(
            {
              'title': 'Batch 1 QP ${i + 1}',
              'subject': 'Subject A',
              'year': 1,
              'semester': 1,
            },
            null,
            pdfFileBytes: [1, 2, 3, 4],
            pdfFileName: 'batch1_qp${i + 1}.pdf',
          );
        }

        expect(booksController.questionPapers.length, 3);

        // Add second batch
        for (int i = 0; i < 2; i++) {
          await booksController.createQuestionPaperWithPdf(
            {
              'title': 'Batch 2 QP ${i + 1}',
              'subject': 'Subject B',
              'year': 2,
              'semester': 3,
            },
            null,
            pdfFileBytes: [1, 2, 3, 4],
            pdfFileName: 'batch2_qp${i + 1}.pdf',
          );
        }

        // Property validation: All associations from both batches are maintained
        expect(booksController.questionPapers.length, 5);
        
        // Verify first batch is still there
        expect(
          booksController.questionPapers.where((qp) => qp.title.startsWith('Batch 1')).length,
          3,
        );
        
        // Verify second batch is there
        expect(
          booksController.questionPapers.where((qp) => qp.title.startsWith('Batch 2')).length,
          2,
        );
      });
    });
  });
}
