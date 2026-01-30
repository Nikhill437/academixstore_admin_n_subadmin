import 'package:get/get.dart' hide Response;
import '../../models/question_paper.dart';
import '../base_api_service.dart';
import '../role_access_service.dart';

/// Question Papers API service providing CRUD operations with role-based access control
/// Handles all question paper-related API interactions with automatic JWT authentication
class QuestionPapersApiService extends GetxService {
  final BaseApiService _baseApiService = Get.find<BaseApiService>();
  final RoleAccessService _roleAccessService = Get.find<RoleAccessService>();

  // API endpoints
  static const String _questionPapersEndpoint = '/question-papers';

  @override
  void onInit() {
    super.onInit();
    Get.log('QuestionPapersApiService initialized', isError: false);
  }

  /// Create a new question paper
  ///
  /// [questionPaperData] - Question paper information to create
  /// Returns the created question paper with ID
  Future<QuestionPaper> createQuestionPaper(
    Map<String, dynamic> questionPaperData,
  ) async {
    // Validate modify access
    if (!_roleAccessService.canModify('question_papers')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('question_papers'),
      );
    }

    try {
      Get.log(
        'Creating question paper: ${questionPaperData['title']}',
        isError: false,
      );

      final response = await _baseApiService.post(
        _questionPapersEndpoint,
        data: questionPaperData,
      );

      final data = response.data as Map<String, dynamic>;
      final questionPaperJson =
          data['data']['question_paper'] as Map<String, dynamic>;

      final questionPaper = QuestionPaper.fromJson(questionPaperJson);

      Get.log('Question paper created: ${questionPaper.id}', isError: false);

      return questionPaper;
    } catch (e) {
      Get.log('Error creating question paper: $e', isError: true);
      rethrow;
    }
  }

  /// Upload PDF for a question paper
  ///
  /// [questionPaperId] - Unique identifier of the question paper
  /// [filePath] - Local path to the PDF file (for mobile/desktop)
  /// [fileBytes] - PDF file bytes (for web platform)
  /// [fileName] - Name of the PDF file
  /// Returns updated question paper with PDF URL
  Future<Map<String, dynamic>> uploadQuestionPaperPdf(
    String questionPaperId,
    String? filePath, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    // Validate modify access
    if (!_roleAccessService.canModify('question_papers')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('question_papers'),
      );
    }

    try {
      Get.log(
        'Uploading PDF for question paper: $questionPaperId',
        isError: false,
      );

      final response = await _baseApiService.uploadFile(
        '$_questionPapersEndpoint/$questionPaperId/upload-pdf',
        filePath ?? '',
        'question_paper',
        fileBytes: fileBytes,
        fileName: fileName,
      );

      final data = response.data as Map<String, dynamic>;

      Get.log('Question paper PDF uploaded successfully', isError: false);

      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      Get.log('Error uploading question paper PDF: $e', isError: true);
      rethrow;
    }
  }

  /// Delete a question paper
  ///
  /// [questionPaperId] - Unique identifier of the question paper to delete
  /// Returns true if deletion was successful
  Future<bool> deleteQuestionPaper(String questionPaperId) async {
    // Validate modify access
    if (!_roleAccessService.canModify('question_papers')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('question_papers'),
      );
    }

    try {
      Get.log('Deleting question paper: $questionPaperId', isError: false);

      await _baseApiService.delete(
        '$_questionPapersEndpoint/$questionPaperId',
      );

      Get.log('Question paper deleted successfully', isError: false);

      return true;
    } catch (e) {
      Get.log('Error deleting question paper: $e', isError: true);
      rethrow;
    }
  }

  /// Get question papers with optional filters
  ///
  /// [subject] - Filter by subject
  /// [year] - Filter by academic year
  /// [semester] - Filter by semester
  /// [examType] - Filter by exam type
  /// Returns list of question papers
  Future<List<QuestionPaper>> getQuestionPapers({
    String? subject,
    int? year,
    int? semester,
    String? examType,
  }) async {
    // Validate access
    _roleAccessService.validateAccess('question_papers');

    try {
      final queryParams = <String, dynamic>{};
      if (subject != null) queryParams['subject'] = subject;
      if (year != null) queryParams['year'] = year;
      if (semester != null) queryParams['semester'] = semester;
      if (examType != null) queryParams['exam_type'] = examType;

      Get.log(
        'Fetching question papers with filters: $queryParams',
        isError: false,
      );

      final response = await _baseApiService.get(
        _questionPapersEndpoint,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final questionPapersData = data['data']['question_papers'] as List;

      final questionPapers = questionPapersData
          .map((json) => QuestionPaper.fromJson(json as Map<String, dynamic>))
          .toList();

      Get.log(
        'Fetched ${questionPapers.length} question papers',
        isError: false,
      );

      return questionPapers;
    } catch (e) {
      Get.log('Error fetching question papers: $e', isError: true);
      rethrow;
    }
  }
}
