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
  final Map<String, String> uploadedPdfs = {};
  int _idCounter = 0;
  
  @override
  Future<QuestionPaper> createQuestionPaper(
    Map<String, dynamic> questionPaperData,
  ) async {
    // Generate unique ID using counter to avoid collisions
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
  group('Task 11.1: Complete Workflow - Create Book with Question Papers', () {
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
      // Clear all data before resetting
      booksController.clearQuestionPapers();
      mockQpApiService.createdQuestionPapers.clear();
      mockQpApiService.uploadedPdfs.clear();
      Get.reset();
    });

    /// Test: Complete workflow - Open dialog, fill book form, add multiple question papers with PDFs
    testWidgets('complete workflow: create book with multiple question papers', 
        (WidgetTester tester) async {
      final widget = GetMaterialApp(
        home: Scaffold(
          body: AddEditBookDialog(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Step 1: Verify dialog is open
      expect(find.byType(AddEditBookDialog), findsOneWidget);
      expect(find.text('Add New Book'), findsOneWidget);

      // Step 2: Verify question papers section is visible
      expect(find.text('Question Papers'), findsOneWidget);
      expect(find.text('Add Question Paper'), findsOneWidget);
      expect(find.text('No question papers added yet'), findsOneWidget);

      // Step 3: Add first question paper
      final qp1Data = {
        'title': 'Midterm Exam - Data Structures',
        'subject': 'Data Structures',
        'year': 2,
        'semester': 3,
        'description': 'Covers arrays, linked lists, stacks, queues',
        'exam_type': 'midterm',
        'marks': 100,
      };

      final qp1 = await booksController.createQuestionPaperWithPdf(
        qp1Data,
        null,
        pdfFileBytes: List.generate(1000, (i) => i % 256), // Mock PDF bytes
        pdfFileName: 'midterm-ds.pdf',
      );

      await tester.pumpAndSettle();

      // Verify first question paper is added
      expect(qp1, isNotNull);
      expect(booksController.questionPapers.length, 1);
      expect(find.text('Midterm Exam - Data Structures'), findsOneWidget);
      expect(mockQpApiService.createdQuestionPapers.length, 1);
      expect(mockQpApiService.uploadedPdfs.length, 1);

      // Step 4: Add second question paper
      final qp2Data = {
        'title': 'Final Exam - Algorithms',
        'subject': 'Algorithms',
        'year': 2,
        'semester': 4,
        'description': 'Covers sorting, searching, graph algorithms',
        'exam_type': 'final',
        'marks': 150,
      };

      final qp2 = await booksController.createQuestionPaperWithPdf(
        qp2Data,
        null,
        pdfFileBytes: List.generate(2000, (i) => i % 256),
        pdfFileName: 'final-algo.pdf',
      );

      await tester.pumpAndSettle();

      // Verify second question paper is added
      expect(qp2, isNotNull);
      expect(booksController.questionPapers.length, 2);
      expect(find.text('Final Exam - Algorithms'), findsOneWidget);
      expect(mockQpApiService.createdQuestionPapers.length, 2);
      expect(mockQpApiService.uploadedPdfs.length, 2);

      // Step 5: Add third question paper
      final qp3Data = {
        'title': 'Quiz 1 - Database Systems',
        'subject': 'Database Systems',
        'year': 3,
        'semester': 5,
        'exam_type': 'quiz',
        'marks': 50,
      };

      final qp3 = await booksController.createQuestionPaperWithPdf(
        qp3Data,
        null,
        pdfFileBytes: List.generate(500, (i) => i % 256),
        pdfFileName: 'quiz-db.pdf',
      );

      await tester.pumpAndSettle();

      // Verify third question paper is added
      expect(qp3, isNotNull);
      expect(booksController.questionPapers.length, 3);
      expect(find.text('Quiz 1 - Database Systems'), findsOneWidget);
      expect(mockQpApiService.createdQuestionPapers.length, 3);
      expect(mockQpApiService.uploadedPdfs.length, 3);

      // Step 6: Verify all data is persisted
      // Verify all question papers are in the controller's list
      expect(booksController.questionPapers.length, 3);
      
      // Verify all question papers have correct data
      final qps = booksController.questionPapers;
      expect(qps[0].title, 'Midterm Exam - Data Structures');
      expect(qps[0].subject, 'Data Structures');
      expect(qps[0].year, 2);
      expect(qps[0].semester, 3);
      expect(qps[0].examType, 'midterm');
      expect(qps[0].marks, 100);
      
      expect(qps[1].title, 'Final Exam - Algorithms');
      expect(qps[1].subject, 'Algorithms');
      expect(qps[1].year, 2);
      expect(qps[1].semester, 4);
      expect(qps[1].examType, 'final');
      expect(qps[1].marks, 150);
      
      expect(qps[2].title, 'Quiz 1 - Database Systems');
      expect(qps[2].subject, 'Database Systems');
      expect(qps[2].year, 3);
      expect(qps[2].semester, 5);
      expect(qps[2].examType, 'quiz');
      expect(qps[2].marks, 50);

      // Verify all PDFs are uploaded
      expect(mockQpApiService.uploadedPdfs[qps[0].id], 'midterm-ds.pdf');
      expect(mockQpApiService.uploadedPdfs[qps[1].id], 'final-algo.pdf');
      expect(mockQpApiService.uploadedPdfs[qps[2].id], 'quiz-db.pdf');

      // Step 7: Verify dialog is still open (not closed after adding question papers)
      expect(find.byType(AddEditBookDialog), findsOneWidget);
    });

    /// Test: Verify all question papers are displayed in the UI
    testWidgets('all question papers are displayed in the UI', 
        (WidgetTester tester) async {
      final widget = GetMaterialApp(
        home: Scaffold(
          body: AddEditBookDialog(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Add multiple question papers after widget is built
      final questionPapers = [
        {
          'title': 'QP 1',
          'subject': 'Math',
          'year': 1,
          'semester': 1,
          'exam_type': 'midterm',
        },
        {
          'title': 'QP 2',
          'subject': 'Physics',
          'year': 1,
          'semester': 2,
          'exam_type': 'final',
        },
        {
          'title': 'QP 3',
          'subject': 'Chemistry',
          'year': 2,
          'semester': 3,
          'exam_type': 'quiz',
        },
      ];

      for (int i = 0; i < questionPapers.length; i++) {
        await booksController.createQuestionPaperWithPdf(
          questionPapers[i],
          null,
          pdfFileBytes: [1, 2, 3, 4],
          pdfFileName: 'qp$i.pdf',
        );
        await tester.pumpAndSettle();
      }

      // Verify all question papers are displayed
      expect(find.text('QP 1'), findsOneWidget);
      expect(find.text('QP 2'), findsOneWidget);
      expect(find.text('QP 3'), findsOneWidget);

      // Verify subject, year, semester are displayed (correct format from UI)
      expect(find.textContaining('Math • Year 1 • Semester 1'), findsOneWidget);
      expect(find.textContaining('Physics • Year 1 • Semester 2'), findsOneWidget);
      expect(find.textContaining('Chemistry • Year 2 • Semester 3'), findsOneWidget);
    });

    /// Test: Verify data persistence across operations
    test('data persists across multiple operations', () async {
      // Verify initial state
      expect(booksController.questionPapers, isEmpty);

      // Add first question paper
      final qp1 = await booksController.createQuestionPaperWithPdf(
        {
          'title': 'QP 1',
          'subject': 'Math',
          'year': 1,
          'semester': 1,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp1.pdf',
      );

      // Verify first question paper is added
      expect(qp1, isNotNull);
      expect(booksController.questionPapers.length, 1);

      // Add second question paper
      final qp2 = await booksController.createQuestionPaperWithPdf(
        {
          'title': 'QP 2',
          'subject': 'Physics',
          'year': 1,
          'semester': 2,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp2.pdf',
      );

      // Verify both question papers are persisted
      expect(qp2, isNotNull);
      expect(booksController.questionPapers.length, 2);

      // Add third question paper
      final qp3 = await booksController.createQuestionPaperWithPdf(
        {
          'title': 'QP 3',
          'subject': 'Chemistry',
          'year': 2,
          'semester': 3,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp3.pdf',
      );

      // Verify all three question papers are persisted
      expect(qp3, isNotNull);
      expect(booksController.questionPapers.length, 3);

      // Verify all question papers have correct data
      final qps = booksController.questionPapers;
      expect(qps[0].title, 'QP 1');
      expect(qps[1].title, 'QP 2');
      expect(qps[2].title, 'QP 3');
    });
  });

  group('Task 11.3: Complete Workflow - Edit Book with Question Papers', () {
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

    /// Test: Open dialog for existing book, add new question papers
    testWidgets('edit book: add new question papers to existing book', 
        (WidgetTester tester) async {
      // Get fresh controller reference
      final controller = Get.find<BooksController>();
      
      // Step 1: Simulate existing book with question papers
      final existingQp1 = await controller.createQuestionPaperWithPdf(
        {
          'title': 'Existing QP 1',
          'subject': 'Mathematics',
          'year': 1,
          'semester': 1,
          'exam_type': 'midterm',
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'existing1.pdf',
      );

      final existingQp2 = await controller.createQuestionPaperWithPdf(
        {
          'title': 'Existing QP 2',
          'subject': 'Physics',
          'year': 1,
          'semester': 2,
          'exam_type': 'final',
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'existing2.pdf',
      );

      expect(existingQp1, isNotNull);
      expect(existingQp2, isNotNull);
      expect(controller.questionPapers.length, 2);

      // Step 2: Open dialog (simulating edit mode)
      final widget = GetMaterialApp(
        home: Scaffold(
          body: AddEditBookDialog(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Step 3: Verify existing question papers are displayed
      expect(find.text('Existing QP 1'), findsOneWidget);
      expect(find.text('Existing QP 2'), findsOneWidget);

      // Step 4: Add new question papers
      final newQp1 = await controller.createQuestionPaperWithPdf(
        {
          'title': 'New QP 1',
          'subject': 'Chemistry',
          'year': 2,
          'semester': 3,
          'exam_type': 'quiz',
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'new1.pdf',
      );

      await tester.pumpAndSettle();

      expect(newQp1, isNotNull);
      expect(controller.questionPapers.length, 3);

      final newQp2 = await controller.createQuestionPaperWithPdf(
        {
          'title': 'New QP 2',
          'subject': 'Biology',
          'year': 2,
          'semester': 4,
          'exam_type': 'practice',
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'new2.pdf',
      );

      await tester.pumpAndSettle();

      expect(newQp2, isNotNull);
      expect(controller.questionPapers.length, 4);

      // Step 5: Verify all question papers (existing + new) are displayed
      expect(find.text('Existing QP 1'), findsOneWidget);
      expect(find.text('Existing QP 2'), findsOneWidget);
      expect(find.text('New QP 1'), findsOneWidget);
      expect(find.text('New QP 2'), findsOneWidget);

      // Step 6: Verify changes are persisted
      final qps = controller.questionPapers;
      expect(qps.length, 4);
      expect(qps[0].title, 'Existing QP 1');
      expect(qps[1].title, 'Existing QP 2');
      expect(qps[2].title, 'New QP 1');
      expect(qps[3].title, 'New QP 2');
    });

    /// Test: Open dialog for existing book, delete existing question papers
    test('edit book: delete existing question papers', () async {
      // Get fresh controller reference
      final controller = Get.find<BooksController>();
      
      // Step 1: Create existing question papers
      final qp1 = await controller.createQuestionPaperWithPdf(
        {
          'title': 'QP to Keep',
          'subject': 'Mathematics',
          'year': 1,
          'semester': 1,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'keep.pdf',
      );

      final qp2 = await controller.createQuestionPaperWithPdf(
        {
          'title': 'QP to Delete',
          'subject': 'Physics',
          'year': 1,
          'semester': 2,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'delete.pdf',
      );

      expect(qp1, isNotNull);
      expect(qp2, isNotNull);
      expect(controller.questionPapers.length, 2);

      // Step 2: Delete one question paper
      final deleteSuccess = await controller.deleteQuestionPaper(qp2!.id);
      expect(deleteSuccess, isTrue);

      // Step 3: Verify the deleted question paper is removed
      expect(controller.questionPapers.length, 1);
      expect(controller.questionPapers.first.title, 'QP to Keep');
      expect(controller.questionPapers.any((qp) => qp.id == qp2.id), isFalse);
    });

    /// Test: Complete workflow - add and delete in same session
    test('edit book: add new and delete existing question papers', () async {
      // Get fresh controller reference
      final controller = Get.find<BooksController>();
      
      // Step 1: Create existing question papers
      final existingQp1 = await controller.createQuestionPaperWithPdf(
        {
          'title': 'Existing QP 1',
          'subject': 'Math',
          'year': 1,
          'semester': 1,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'existing1.pdf',
      );

      final existingQp2 = await controller.createQuestionPaperWithPdf(
        {
          'title': 'Existing QP 2',
          'subject': 'Physics',
          'year': 1,
          'semester': 2,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'existing2.pdf',
      );

      expect(existingQp1, isNotNull);
      expect(existingQp2, isNotNull);
      expect(controller.questionPapers.length, 2);

      // Step 2: Delete one existing question paper
      await controller.deleteQuestionPaper(existingQp2!.id);
      expect(controller.questionPapers.length, 1);

      // Step 3: Add new question papers
      final newQp1 = await controller.createQuestionPaperWithPdf(
        {
          'title': 'New QP 1',
          'subject': 'Chemistry',
          'year': 2,
          'semester': 3,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'new1.pdf',
      );

      expect(newQp1, isNotNull);
      expect(controller.questionPapers.length, 2);

      final newQp2 = await controller.createQuestionPaperWithPdf(
        {
          'title': 'New QP 2',
          'subject': 'Biology',
          'year': 2,
          'semester': 4,
        },
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'new2.pdf',
      );

      expect(newQp2, isNotNull);
      expect(controller.questionPapers.length, 3);

      // Step 4: Verify final state
      final qps = controller.questionPapers;
      expect(qps.length, 3);
      expect(qps[0].title, 'Existing QP 1');
      expect(qps[1].title, 'New QP 1');
      expect(qps[2].title, 'New QP 2');
      expect(qps.any((qp) => qp.id == existingQp2.id), isFalse);
    });

    /// Test: Verify data persistence after multiple edit operations
    test('data persists correctly after multiple edit operations', () async {
      // Get fresh controller reference
      final controller = Get.find<BooksController>();
      
      // Initial state: 3 question papers
      final qp1 = await controller.createQuestionPaperWithPdf(
        {'title': 'QP 1', 'subject': 'Math', 'year': 1, 'semester': 1},
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp1.pdf',
      );

      final qp2 = await controller.createQuestionPaperWithPdf(
        {'title': 'QP 2', 'subject': 'Physics', 'year': 1, 'semester': 2},
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp2.pdf',
      );

      final qp3 = await controller.createQuestionPaperWithPdf(
        {'title': 'QP 3', 'subject': 'Chemistry', 'year': 2, 'semester': 3},
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp3.pdf',
      );

      expect(controller.questionPapers.length, 3);

      // Edit operation 1: Delete QP 2
      await controller.deleteQuestionPaper(qp2!.id);
      expect(controller.questionPapers.length, 2);
      expect(controller.questionPapers.any((qp) => qp.id == qp2.id), isFalse);

      // Edit operation 2: Add new QP
      final qp4 = await controller.createQuestionPaperWithPdf(
        {'title': 'QP 4', 'subject': 'Biology', 'year': 2, 'semester': 4},
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp4.pdf',
      );

      expect(controller.questionPapers.length, 3);

      // Edit operation 3: Delete QP 1
      await controller.deleteQuestionPaper(qp1!.id);
      expect(controller.questionPapers.length, 2);

      // Edit operation 4: Add two more QPs
      final qp5 = await controller.createQuestionPaperWithPdf(
        {'title': 'QP 5', 'subject': 'English', 'year': 3, 'semester': 5},
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp5.pdf',
      );

      final qp6 = await controller.createQuestionPaperWithPdf(
        {'title': 'QP 6', 'subject': 'History', 'year': 3, 'semester': 6},
        null,
        pdfFileBytes: [1, 2, 3, 4],
        pdfFileName: 'qp6.pdf',
      );

      // Final verification
      expect(controller.questionPapers.length, 4);
      
      // Verify correct QPs remain
      final titles = controller.questionPapers.map((qp) => qp.title).toList();
      expect(titles, containsAll(['QP 3', 'QP 4', 'QP 5', 'QP 6']));
      expect(titles, isNot(contains('QP 1')));
      expect(titles, isNot(contains('QP 2')));
    });
  });
}
