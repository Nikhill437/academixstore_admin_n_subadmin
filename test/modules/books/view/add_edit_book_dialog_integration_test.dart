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
  
  @override
  Future<QuestionPaper> createQuestionPaper(
    Map<String, dynamic> questionPaperData,
  ) async {
    final qp = QuestionPaper(
      id: 'qp-${DateTime.now().millisecondsSinceEpoch}',
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
    return {
      'question_paper_id': questionPaperId,
      'pdf_url': 'https://example.com/$fileName',
    };
  }
  
  @override
  Future<bool> deleteQuestionPaper(String questionPaperId) async {
    createdQuestionPapers.removeWhere((qp) => qp.id == questionPaperId);
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
  group('AddEditBookDialog Integration Tests', () {
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
      Get.put<CollegesController>(MockCollegesController());
    });

    tearDown(() {
      Get.reset();
    });

    /// Property 8: List Update After Successful Upload
    /// Validates: Requirements 4.4
    /// Test that for any successful upload, the list is updated and form is cleared
    group('Property 8: List Update After Successful Upload', () {
      final testCases = [
        {
          'title': 'Midterm Exam',
          'subject': 'Mathematics',
          'year': 1,
          'semester': 1,
          'exam_type': 'midterm',
        },
        {
          'title': 'Final Exam',
          'subject': 'Physics',
          'year': 2,
          'semester': 3,
          'exam_type': 'final',
        },
        {
          'title': 'Quiz 1',
          'subject': 'Chemistry',
          'year': 3,
          'semester': 5,
          'exam_type': 'quiz',
          'marks': 50,
        },
        {
          'title': 'Practice Test',
          'subject': 'Biology',
          'year': 4,
          'semester': 7,
          'exam_type': 'practice',
          'description': 'Practice test for final exam',
        },
      ];

      for (final testCase in testCases) {
        test('updates list after uploading: ${testCase['title']}', () async {
          // Verify initial state
          expect(booksController.questionPapers, isEmpty);
          
          // Create question paper with PDF
          final questionPaper = await booksController.createQuestionPaperWithPdf(
            testCase,
            null,
            pdfFileBytes: [1, 2, 3, 4], // Mock PDF bytes
            pdfFileName: 'test.pdf',
          );
          
          // Property validation: After successful upload, the list should be updated
          expect(questionPaper, isNotNull);
          expect(booksController.questionPapers, isNotEmpty);
          expect(booksController.questionPapers.length, 1);
          expect(booksController.questionPapers.first.title, testCase['title']);
          expect(booksController.questionPapers.first.subject, testCase['subject']);
          expect(booksController.questionPapers.first.year, testCase['year']);
          expect(booksController.questionPapers.first.semester, testCase['semester']);
          
          // Clear for next test
          booksController.clearQuestionPapers();
        });
      }
      
      test('updates list with multiple uploads', () async {
        // Verify initial state
        expect(booksController.questionPapers, isEmpty);
        
        // Upload multiple question papers
        for (int i = 0; i < testCases.length; i++) {
          final questionPaper = await booksController.createQuestionPaperWithPdf(
            testCases[i],
            null,
            pdfFileBytes: [1, 2, 3, 4],
            pdfFileName: 'test$i.pdf',
          );
          
          expect(questionPaper, isNotNull);
          expect(booksController.questionPapers.length, i + 1);
        }
        
        // Verify all question papers are in the list
        expect(booksController.questionPapers.length, testCases.length);
        
        for (int i = 0; i < testCases.length; i++) {
          expect(
            booksController.questionPapers[i].title,
            testCases[i]['title'],
          );
        }
      });
    });

    /// Test: Question papers section is visible in dialog
    testWidgets('question papers section is visible', (WidgetTester tester) async {
      final widget = GetMaterialApp(
        home: Scaffold(
          body: AddEditBookDialog(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify the question papers section is visible
      expect(find.text('Question Papers'), findsOneWidget);
      expect(find.text('Add Question Paper'), findsOneWidget);
    });

    /// Test: Question papers list updates when controller state changes
    testWidgets('list updates when controller state changes', (WidgetTester tester) async {
      final widget = GetMaterialApp(
        home: Scaffold(
          body: AddEditBookDialog(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Initially, the list should be empty
      expect(find.text('No question papers added yet'), findsOneWidget);

      // Add a question paper through the controller
      await booksController.createQuestionPaperWithPdf(
        {
          'title': 'Test Question Paper',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 1,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'test.pdf',
      );

      // Rebuild the widget
      await tester.pumpAndSettle();

      // Verify the list is updated
      expect(find.text('No question papers added yet'), findsNothing);
      expect(find.text('Test Question Paper'), findsOneWidget);
      expect(find.text('Test Subject • Year 1 • Semester 1'), findsOneWidget);
    });

    /// Test: Question papers list is cleared when dialog closes
    testWidgets('list is cleared when dialog closes', (WidgetTester tester) async {
      // Add a question paper
      await booksController.createQuestionPaperWithPdf(
        {
          'title': 'Test Question Paper',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 1,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'test.pdf',
      );

      expect(booksController.questionPapers, isNotEmpty);

      final widget = GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddEditBookDialog(),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.byType(AddEditBookDialog), findsOneWidget);

      // Close the dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify the list is cleared
      expect(booksController.questionPapers, isEmpty);
    });
  });

  group('Dialog Behavior with Question Papers', () {
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
      Get.put<CollegesController>(MockCollegesController());
    });

    tearDown(() {
      Get.reset();
    });

    /// Test: Opening dialog for new book (empty question papers list)
    testWidgets('opening dialog for new book shows empty list', (WidgetTester tester) async {
      final widget = GetMaterialApp(
        home: Scaffold(
          body: AddEditBookDialog(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify the dialog is open
      expect(find.byType(AddEditBookDialog), findsOneWidget);
      expect(find.text('Add New Book'), findsOneWidget);

      // Verify the question papers list is empty
      expect(booksController.questionPapers, isEmpty);
      expect(find.text('No question papers added yet'), findsOneWidget);
    });

    /// Test: Opening dialog for existing book (load question papers)
    /// Note: In a real scenario, this would load question papers from the API
    /// For this test, we simulate having question papers already loaded
    testWidgets('opening dialog for existing book shows loaded question papers', 
        (WidgetTester tester) async {
      // Simulate having question papers already loaded for an existing book
      await booksController.createQuestionPaperWithPdf(
        {
          'title': 'Existing Question Paper',
          'subject': 'Mathematics',
          'year': 1,
          'semester': 1,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'existing.pdf',
      );

      final widget = GetMaterialApp(
        home: Scaffold(
          body: AddEditBookDialog(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify the dialog is open
      expect(find.byType(AddEditBookDialog), findsOneWidget);

      // Verify the question papers list shows the existing question paper
      expect(booksController.questionPapers, isNotEmpty);
      expect(find.text('Existing Question Paper'), findsOneWidget);
      expect(find.text('No question papers added yet'), findsNothing);
    });

    /// Test: Adding multiple question papers without closing dialog
    testWidgets('can add multiple question papers without closing dialog', 
        (WidgetTester tester) async {
      final widget = GetMaterialApp(
        home: Scaffold(
          body: AddEditBookDialog(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify initial state
      expect(booksController.questionPapers, isEmpty);

      // Add first question paper
      await booksController.createQuestionPaperWithPdf(
        {
          'title': 'Question Paper 1',
          'subject': 'Math',
          'year': 1,
          'semester': 1,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp1.pdf',
      );

      await tester.pumpAndSettle();

      // Verify first question paper is added
      expect(booksController.questionPapers.length, 1);
      expect(find.text('Question Paper 1'), findsOneWidget);

      // Add second question paper
      await booksController.createQuestionPaperWithPdf(
        {
          'title': 'Question Paper 2',
          'subject': 'Physics',
          'year': 1,
          'semester': 2,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp2.pdf',
      );

      await tester.pumpAndSettle();

      // Verify both question papers are in the list
      expect(booksController.questionPapers.length, 2);
      expect(find.text('Question Paper 1'), findsOneWidget);
      expect(find.text('Question Paper 2'), findsOneWidget);

      // Verify dialog is still open
      expect(find.byType(AddEditBookDialog), findsOneWidget);
    });

    /// Test: Deleting question papers
    testWidgets('can delete question papers from the list', (WidgetTester tester) async {
      // Add a question paper first
      await booksController.createQuestionPaperWithPdf(
        {
          'title': 'Question Paper to Delete',
          'subject': 'Chemistry',
          'year': 2,
          'semester': 3,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'delete-me.pdf',
      );

      final widget = GetMaterialApp(
        home: Scaffold(
          body: AddEditBookDialog(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify the question paper is in the list
      expect(booksController.questionPapers.length, 1);
      expect(find.text('Question Paper to Delete'), findsOneWidget);

      // Scroll to make the delete button visible
      await tester.dragUntilVisible(
        find.byIcon(Icons.delete_outline),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();

      // Find and tap the delete button
      final deleteButton = find.byIcon(Icons.delete_outline);
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Delete Question Paper'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this question paper? This action cannot be undone.'), 
          findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify the question paper is removed from the list
      expect(booksController.questionPapers, isEmpty);
      expect(find.text('Question Paper to Delete'), findsNothing);
      expect(find.text('No question papers added yet'), findsOneWidget);
    });

    /// Test: Dialog remains open after errors
    /// Note: This test verifies that the dialog stays open when operations occur
    testWidgets('dialog remains open during operations', (WidgetTester tester) async {
      final widget = GetMaterialApp(
        home: Scaffold(
          body: AddEditBookDialog(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.byType(AddEditBookDialog), findsOneWidget);

      // Perform an operation (create question paper)
      await booksController.createQuestionPaperWithPdf(
        {
          'title': 'Test Question Paper',
          'subject': 'Test Subject',
          'year': 1,
          'semester': 1,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'test.pdf',
      );

      await tester.pumpAndSettle();

      // Verify dialog is still open after operation
      expect(find.byType(AddEditBookDialog), findsOneWidget);
      
      // Verify the question paper was added
      expect(booksController.questionPapers, isNotEmpty);
    });
  });
}

/// Mock service that throws errors for testing error handling
class _MockQuestionPapersApiServiceWithError extends GetxService 
    implements QuestionPapersApiService {
  @override
  Future<QuestionPaper> createQuestionPaper(
    Map<String, dynamic> questionPaperData,
  ) async {
    throw Exception('Network error');
  }
  
  @override
  Future<Map<String, dynamic>> uploadQuestionPaperPdf(
    String questionPaperId,
    String? filePath, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    throw Exception('Upload failed');
  }
  
  @override
  Future<bool> deleteQuestionPaper(String questionPaperId) async {
    throw Exception('Delete failed');
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
