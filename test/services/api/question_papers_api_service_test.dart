import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:academixstore_admin_n_subadmin/services/api/question_papers_api_service.dart';
import 'package:academixstore_admin_n_subadmin/services/base_api_service.dart';
import 'package:academixstore_admin_n_subadmin/services/role_access_service.dart';
import 'package:academixstore_admin_n_subadmin/services/token_service.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:math';

void main() {
  group('QuestionPapersApiService', () {
    late QuestionPapersApiService service;

    setUp(() {
      // Initialize GetX for testing
      Get.testMode = true;

      // Register required dependencies
      Get.put<TokenService>(TokenService());
      Get.put<BaseApiService>(BaseApiService());
      Get.put<RoleAccessService>(RoleAccessService());

      // Create service instance
      service = QuestionPapersApiService();
    });

    tearDown(() {
      // Clean up GetX
      Get.reset();
    });

    test('service initializes correctly', () {
      expect(service, isNotNull);
      expect(service, isA<QuestionPapersApiService>());
    });

    test('service can be registered in GetX', () {
      Get.put<QuestionPapersApiService>(service);
      final retrievedService = Get.find<QuestionPapersApiService>();
      expect(retrievedService, equals(service));
    });

    test('service extends GetxService', () {
      expect(service, isA<GetxService>());
    });
  });

  // Property-Based Tests
  group('QuestionPapersApiService - Property Tests', () {
    late MockBaseApiService mockBaseApiService;
    late MockRoleAccessService mockRoleAccessService;

    setUp(() {
      // Initialize GetX for testing
      Get.testMode = true;

      // Register mock dependencies
      Get.put<TokenService>(TokenService());
      mockBaseApiService = MockBaseApiService();
      mockRoleAccessService = MockRoleAccessService();
      Get.put<BaseApiService>(mockBaseApiService);
      Get.put<RoleAccessService>(mockRoleAccessService);
    });

    tearDown(() {
      // Clean up GetX
      Get.reset();
    });

    // Feature: question-paper-upload-for-books, Property 6: Question Paper Creation API Call
    // **Validates: Requirements 4.1**
    test('property: for any valid question paper data, createQuestionPaper calls POST /question-papers', () async {
      // Run property test with 100 iterations
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Create service instance for this iteration
        final service = QuestionPapersApiService();
        
        // Generate random valid question paper data
        final questionPaperData = _generateRandomQuestionPaperData();
        
        // Mock role access to allow modification
        mockRoleAccessService.setCanModify('question_papers', true);
        
        // Mock API response
        final mockResponse = _createMockResponse(questionPaperData);
        mockBaseApiService.setPostResponse('/question-papers', mockResponse);
        
        // Call the method
        try {
          await service.createQuestionPaper(questionPaperData);
          
          // Verify the correct endpoint was called
          expect(
            mockBaseApiService.wasPostCalled('/question-papers'),
            isTrue,
            reason: 'POST /question-papers should be called for iteration $i with data: $questionPaperData',
          );
          
          // Verify the data was passed correctly
          expect(
            mockBaseApiService.getLastPostData('/question-papers'),
            equals(questionPaperData),
            reason: 'Question paper data should match for iteration $i',
          );
        } catch (e) {
          // If there's an error, it should not be due to incorrect endpoint
          fail('Unexpected error in iteration $i: $e');
        }
        
        // Reset mock for next iteration
        mockBaseApiService.reset();
      }
    });
  });

  // Unit Tests
  group('QuestionPapersApiService - Unit Tests', () {
    late MockBaseApiService mockBaseApiService;
    late MockRoleAccessService mockRoleAccessService;
    late QuestionPapersApiService service;

    setUp(() {
      // Initialize GetX for testing
      Get.testMode = true;

      // Register mock dependencies
      Get.put<TokenService>(TokenService());
      mockBaseApiService = MockBaseApiService();
      mockRoleAccessService = MockRoleAccessService();
      Get.put<BaseApiService>(mockBaseApiService);
      Get.put<RoleAccessService>(mockRoleAccessService);

      // Create service instance
      service = QuestionPapersApiService();
    });

    tearDown(() {
      // Clean up GetX
      Get.reset();
    });

    group('createQuestionPaper', () {
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

        mockRoleAccessService.setCanModify('question_papers', true);
        final mockResponse = _createMockResponse(questionPaperData);
        mockBaseApiService.setPostResponse('/question-papers', mockResponse);

        // Act
        final result = await service.createQuestionPaper(questionPaperData);

        // Assert
        expect(result, isNotNull);
        expect(result.title, equals('Midterm Exam - Data Structures'));
        expect(result.subject, equals('Data Structures'));
        expect(result.year, equals(2));
        expect(result.semester, equals(3));
        expect(mockBaseApiService.wasPostCalled('/question-papers'), isTrue);
      });

      test('should throw UnauthorizedAccessException when user lacks permission', () async {
        // Arrange
        final questionPaperData = {
          'title': 'Test Paper',
          'subject': 'Math',
          'year': 1,
          'semester': 1,
        };

        mockRoleAccessService.setCanModify('question_papers', false);

        // Act & Assert
        expect(
          () => service.createQuestionPaper(questionPaperData),
          throwsA(isA<UnauthorizedAccessException>()),
        );
      });

      test('should handle API errors gracefully', () async {
        // Arrange
        final questionPaperData = {
          'title': 'Test Paper',
          'subject': 'Math',
          'year': 1,
          'semester': 1,
        };

        mockRoleAccessService.setCanModify('question_papers', true);
        mockBaseApiService.setPostError('/question-papers', 
          dio.DioException(
            requestOptions: dio.RequestOptions(path: '/question-papers'),
            type: dio.DioExceptionType.connectionError,
            message: 'Network error',
          ),
        );

        // Act & Assert
        expect(
          () => service.createQuestionPaper(questionPaperData),
          throwsA(isA<dio.DioException>()),
        );
      });
    });

    group('uploadQuestionPaperPdf', () {
      test('should upload PDF with file bytes (web platform)', () async {
        // Arrange
        final questionPaperId = '550e8400-e29b-41d4-a716-446655440000';
        final fileBytes = List<int>.generate(1000, (i) => i % 256);
        final fileName = 'test-paper.pdf';

        mockRoleAccessService.setCanModify('question_papers', true);
        final mockResponse = _createMockUploadResponse(questionPaperId);
        mockBaseApiService.setPostResponse(
          '/question-papers/$questionPaperId/upload-pdf',
          mockResponse,
        );

        // Act
        final result = await service.uploadQuestionPaperPdf(
          questionPaperId,
          null,
          fileBytes: fileBytes,
          fileName: fileName,
        );

        // Assert
        expect(result, isNotNull);
        expect(result['question_paper_id'], equals(questionPaperId));
        expect(mockBaseApiService.wasUploadFileCalled(
          '/question-papers/$questionPaperId/upload-pdf'
        ), isTrue);
      });

      test('should upload PDF with file path (mobile/desktop platform)', () async {
        // Arrange
        final questionPaperId = '550e8400-e29b-41d4-a716-446655440000';
        final filePath = '/path/to/test-paper.pdf';

        mockRoleAccessService.setCanModify('question_papers', true);
        final mockResponse = _createMockUploadResponse(questionPaperId);
        mockBaseApiService.setPostResponse(
          '/question-papers/$questionPaperId/upload-pdf',
          mockResponse,
        );

        // Act
        final result = await service.uploadQuestionPaperPdf(
          questionPaperId,
          filePath,
        );

        // Assert
        expect(result, isNotNull);
        expect(result['question_paper_id'], equals(questionPaperId));
        expect(mockBaseApiService.wasUploadFileCalled(
          '/question-papers/$questionPaperId/upload-pdf'
        ), isTrue);
      });

      test('should throw UnauthorizedAccessException when user lacks permission', () async {
        // Arrange
        final questionPaperId = '550e8400-e29b-41d4-a716-446655440000';
        final filePath = '/path/to/test-paper.pdf';

        mockRoleAccessService.setCanModify('question_papers', false);

        // Act & Assert
        expect(
          () => service.uploadQuestionPaperPdf(questionPaperId, filePath),
          throwsA(isA<UnauthorizedAccessException>()),
        );
      });

      test('should handle upload errors gracefully', () async {
        // Arrange
        final questionPaperId = '550e8400-e29b-41d4-a716-446655440000';
        final filePath = '/path/to/test-paper.pdf';

        mockRoleAccessService.setCanModify('question_papers', true);
        mockBaseApiService.setUploadFileError(
          '/question-papers/$questionPaperId/upload-pdf',
          dio.DioException(
            requestOptions: dio.RequestOptions(path: '/question-papers/$questionPaperId/upload-pdf'),
            type: dio.DioExceptionType.sendTimeout,
            message: 'Upload timeout',
          ),
        );

        // Act & Assert
        expect(
          () => service.uploadQuestionPaperPdf(questionPaperId, filePath),
          throwsA(isA<dio.DioException>()),
        );
      });
    });

    group('deleteQuestionPaper', () {
      test('should delete question paper with valid ID', () async {
        // Arrange
        final questionPaperId = '550e8400-e29b-41d4-a716-446655440000';

        mockRoleAccessService.setCanModify('question_papers', true);
        final mockResponse = dio.Response(
          requestOptions: dio.RequestOptions(path: '/question-papers/$questionPaperId'),
          data: {
            'success': true,
            'message': 'Question paper deleted successfully',
          },
          statusCode: 200,
        );
        mockBaseApiService.setDeleteResponse(
          '/question-papers/$questionPaperId',
          mockResponse,
        );

        // Act
        final result = await service.deleteQuestionPaper(questionPaperId);

        // Assert
        expect(result, isTrue);
        expect(mockBaseApiService.wasDeleteCalled('/question-papers/$questionPaperId'), isTrue);
      });

      test('should throw UnauthorizedAccessException when user lacks permission', () async {
        // Arrange
        final questionPaperId = '550e8400-e29b-41d4-a716-446655440000';

        mockRoleAccessService.setCanModify('question_papers', false);

        // Act & Assert
        expect(
          () => service.deleteQuestionPaper(questionPaperId),
          throwsA(isA<UnauthorizedAccessException>()),
        );
      });

      test('should handle delete errors gracefully', () async {
        // Arrange
        final questionPaperId = '550e8400-e29b-41d4-a716-446655440000';

        mockRoleAccessService.setCanModify('question_papers', true);
        mockBaseApiService.setDeleteError(
          '/question-papers/$questionPaperId',
          dio.DioException(
            requestOptions: dio.RequestOptions(path: '/question-papers/$questionPaperId'),
            type: dio.DioExceptionType.badResponse,
            response: dio.Response(
              requestOptions: dio.RequestOptions(path: '/question-papers/$questionPaperId'),
              statusCode: 404,
              data: {'message': 'Question paper not found'},
            ),
          ),
        );

        // Act & Assert
        expect(
          () => service.deleteQuestionPaper(questionPaperId),
          throwsA(isA<dio.DioException>()),
        );
      });
    });

    group('getQuestionPapers', () {
      test('should get question papers without filters', () async {
        // Arrange
        mockRoleAccessService.setValidateAccess('question_papers', false);
        final mockResponse = _createMockGetResponse([
          {
            'id': '1',
            'title': 'Paper 1',
            'subject': 'Math',
            'year': 1,
            'semester': 1,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': '2',
            'title': 'Paper 2',
            'subject': 'Physics',
            'year': 2,
            'semester': 3,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);
        mockBaseApiService.setGetResponse('/question-papers', mockResponse);

        // Act
        final result = await service.getQuestionPapers();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
        expect(result[0].title, equals('Paper 1'));
        expect(result[1].title, equals('Paper 2'));
        expect(mockBaseApiService.wasGetCalled('/question-papers'), isTrue);
      });

      test('should get question papers with subject filter', () async {
        // Arrange
        mockRoleAccessService.setValidateAccess('question_papers', false);
        final mockResponse = _createMockGetResponse([
          {
            'id': '1',
            'title': 'Math Paper',
            'subject': 'Math',
            'year': 1,
            'semester': 1,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);
        mockBaseApiService.setGetResponse('/question-papers', mockResponse);

        // Act
        final result = await service.getQuestionPapers(subject: 'Math');

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(1));
        expect(result[0].subject, equals('Math'));
        expect(mockBaseApiService.wasGetCalled('/question-papers'), isTrue);
        expect(mockBaseApiService.getLastQueryParams('/question-papers'), 
          containsPair('subject', 'Math'));
      });

      test('should get question papers with multiple filters', () async {
        // Arrange
        mockRoleAccessService.setValidateAccess('question_papers', false);
        final mockResponse = _createMockGetResponse([
          {
            'id': '1',
            'title': 'Midterm Math',
            'subject': 'Math',
            'year': 2,
            'semester': 3,
            'exam_type': 'midterm',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);
        mockBaseApiService.setGetResponse('/question-papers', mockResponse);

        // Act
        final result = await service.getQuestionPapers(
          subject: 'Math',
          year: 2,
          semester: 3,
          examType: 'midterm',
        );

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(1));
        expect(result[0].subject, equals('Math'));
        expect(result[0].year, equals(2));
        expect(result[0].semester, equals(3));
        expect(result[0].examType, equals('midterm'));
        
        final queryParams = mockBaseApiService.getLastQueryParams('/question-papers');
        expect(queryParams, containsPair('subject', 'Math'));
        expect(queryParams, containsPair('year', 2));
        expect(queryParams, containsPair('semester', 3));
        expect(queryParams, containsPair('exam_type', 'midterm'));
      });

      test('should throw UnauthorizedAccessException when user lacks permission', () async {
        // Arrange
        mockRoleAccessService.setValidateAccess('question_papers', true);

        // Act & Assert
        expect(
          () => service.getQuestionPapers(),
          throwsA(isA<UnauthorizedAccessException>()),
        );
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        mockRoleAccessService.setValidateAccess('question_papers', false);
        mockBaseApiService.setGetError(
          '/question-papers',
          dio.DioException(
            requestOptions: dio.RequestOptions(path: '/question-papers'),
            type: dio.DioExceptionType.connectionTimeout,
            message: 'Connection timeout',
          ),
        );

        // Act & Assert
        expect(
          () => service.getQuestionPapers(),
          throwsA(isA<dio.DioException>()),
        );
      });
    });
  });
}

// Helper function to generate random valid question paper data
Map<String, dynamic> _generateRandomQuestionPaperData() {
  final random = Random();
  
  // Generate random strings
  String randomString(int minLength, int maxLength) {
    final length = minLength + random.nextInt(maxLength - minLength + 1);
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  // Generate random exam type
  String randomExamType() {
    const examTypes = ['midterm', 'final', 'quiz', 'practice'];
    return examTypes[random.nextInt(examTypes.length)];
  }
  
  // Generate random UUID
  String randomUuid() {
    return '${random.nextInt(100000000)}-${random.nextInt(10000)}-${random.nextInt(10000)}-${random.nextInt(10000)}-${random.nextInt(100000000)}';
  }
  
  // Build question paper data with required fields
  final data = <String, dynamic>{
    'title': randomString(1, 500),
    'subject': randomString(1, 100),
    'year': 1 + random.nextInt(4), // 1-4
    'semester': 1 + random.nextInt(8), // 1-8
  };
  
  // Add optional fields randomly
  if (random.nextBool()) {
    data['description'] = randomString(10, 200);
  }
  
  if (random.nextBool()) {
    data['exam_type'] = randomExamType();
  }
  
  if (random.nextBool()) {
    data['marks'] = random.nextInt(201); // 0-200
  }
  
  if (random.nextBool()) {
    data['college_id'] = randomUuid();
  }
  
  return data;
}

// Helper function to create mock response
dio.Response _createMockResponse(Map<String, dynamic> questionPaperData) {
  final responseData = {
    'success': true,
    'message': 'Question paper created successfully',
    'data': {
      'question_paper': {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        ...questionPaperData,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      }
    }
  };
  
  return dio.Response(
    requestOptions: dio.RequestOptions(path: '/question-papers'),
    data: responseData,
    statusCode: 201,
  );
}

// Helper function to create mock upload response
dio.Response _createMockUploadResponse(String questionPaperId) {
  final responseData = {
    'success': true,
    'message': 'Question paper PDF uploaded successfully',
    'data': {
      'question_paper_id': questionPaperId,
      'pdf_url': 'https://bucket.s3.amazonaws.com/question-papers/pdfs/$questionPaperId/file.pdf',
      'signed_url': 'https://bucket.s3.amazonaws.com/...?X-Amz-Expires=3600',
      'original_name': 'test-paper.pdf',
    }
  };
  
  return dio.Response(
    requestOptions: dio.RequestOptions(path: '/question-papers/$questionPaperId/upload-pdf'),
    data: responseData,
    statusCode: 200,
  );
}

// Helper function to create mock get response
dio.Response _createMockGetResponse(List<Map<String, dynamic>> questionPapers) {
  final responseData = {
    'success': true,
    'message': 'Question papers fetched successfully',
    'data': {
      'question_papers': questionPapers,
    }
  };
  
  return dio.Response(
    requestOptions: dio.RequestOptions(path: '/question-papers'),
    data: responseData,
    statusCode: 200,
  );
}

// Mock BaseApiService for testing
class MockBaseApiService extends BaseApiService {
  final Map<String, bool> _postCalls = {};
  final Map<String, Map<String, dynamic>> _postData = {};
  final Map<String, dio.Response> _postResponses = {};
  final Map<String, dio.DioException> _postErrors = {};
  
  final Map<String, bool> _getCalls = {};
  final Map<String, Map<String, dynamic>> _getQueryParams = {};
  final Map<String, dio.Response> _getResponses = {};
  final Map<String, dio.DioException> _getErrors = {};
  
  final Map<String, bool> _deleteCalls = {};
  final Map<String, dio.Response> _deleteResponses = {};
  final Map<String, dio.DioException> _deleteErrors = {};
  
  final Map<String, bool> _uploadFileCalls = {};
  final Map<String, dio.DioException> _uploadFileErrors = {};
  
  void setPostResponse(String endpoint, dio.Response response) {
    _postResponses[endpoint] = response;
  }
  
  void setPostError(String endpoint, dio.DioException error) {
    _postErrors[endpoint] = error;
  }
  
  void setGetResponse(String endpoint, dio.Response response) {
    _getResponses[endpoint] = response;
  }
  
  void setGetError(String endpoint, dio.DioException error) {
    _getErrors[endpoint] = error;
  }
  
  void setDeleteResponse(String endpoint, dio.Response response) {
    _deleteResponses[endpoint] = response;
  }
  
  void setDeleteError(String endpoint, dio.DioException error) {
    _deleteErrors[endpoint] = error;
  }
  
  void setUploadFileError(String endpoint, dio.DioException error) {
    _uploadFileErrors[endpoint] = error;
  }
  
  bool wasPostCalled(String endpoint) {
    return _postCalls[endpoint] ?? false;
  }
  
  bool wasGetCalled(String endpoint) {
    return _getCalls[endpoint] ?? false;
  }
  
  bool wasDeleteCalled(String endpoint) {
    return _deleteCalls[endpoint] ?? false;
  }
  
  bool wasUploadFileCalled(String endpoint) {
    return _uploadFileCalls[endpoint] ?? false;
  }
  
  Map<String, dynamic>? getLastPostData(String endpoint) {
    return _postData[endpoint];
  }
  
  Map<String, dynamic>? getLastQueryParams(String endpoint) {
    return _getQueryParams[endpoint];
  }
  
  void reset() {
    _postCalls.clear();
    _postData.clear();
    _getCalls.clear();
    _getQueryParams.clear();
    _deleteCalls.clear();
    _uploadFileCalls.clear();
  }
  
  @override
  Future<dio.Response<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
    dio.CancelToken? cancelToken,
  }) async {
    _postCalls[endpoint] = true;
    if (data != null && data is Map<String, dynamic>) {
      _postData[endpoint] = data;
    }
    
    if (_postErrors.containsKey(endpoint)) {
      throw _postErrors[endpoint]!;
    }
    
    if (_postResponses.containsKey(endpoint)) {
      return _postResponses[endpoint]! as dio.Response<T>;
    }
    
    // Return default response
    return dio.Response<T>(
      requestOptions: dio.RequestOptions(path: endpoint),
      data: {
        'success': true,
        'data': {
          'question_paper': {
            'id': '550e8400-e29b-41d4-a716-446655440000',
            if (data is Map<String, dynamic>) ...data,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          }
        }
      } as T,
      statusCode: 201,
    );
  }
  
  @override
  Future<dio.Response<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
    dio.CancelToken? cancelToken,
  }) async {
    _getCalls[endpoint] = true;
    if (queryParameters != null) {
      _getQueryParams[endpoint] = queryParameters;
    }
    
    if (_getErrors.containsKey(endpoint)) {
      throw _getErrors[endpoint]!;
    }
    
    if (_getResponses.containsKey(endpoint)) {
      return _getResponses[endpoint]! as dio.Response<T>;
    }
    
    // Return default response
    return dio.Response<T>(
      requestOptions: dio.RequestOptions(path: endpoint),
      data: {
        'success': true,
        'data': {
          'question_papers': [],
        }
      } as T,
      statusCode: 200,
    );
  }
  
  @override
  Future<dio.Response<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
    dio.CancelToken? cancelToken,
  }) async {
    _deleteCalls[endpoint] = true;
    
    if (_deleteErrors.containsKey(endpoint)) {
      throw _deleteErrors[endpoint]!;
    }
    
    if (_deleteResponses.containsKey(endpoint)) {
      return _deleteResponses[endpoint]! as dio.Response<T>;
    }
    
    // Return default response
    return dio.Response<T>(
      requestOptions: dio.RequestOptions(path: endpoint),
      data: {
        'success': true,
        'message': 'Question paper deleted successfully',
      } as T,
      statusCode: 200,
    );
  }
  
  @override
  Future<dio.Response<T>> uploadFile<T>(
    String path,
    String filePath,
    String fileKey, {
    Map<String, dynamic>? additionalData,
    dio.Options? options,
    dio.CancelToken? cancelToken,
    dio.ProgressCallback? onSendProgress,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    _uploadFileCalls[path] = true;
    
    if (_uploadFileErrors.containsKey(path)) {
      throw _uploadFileErrors[path]!;
    }
    
    if (_postResponses.containsKey(path)) {
      return _postResponses[path]! as dio.Response<T>;
    }
    
    // Return default response
    return dio.Response<T>(
      requestOptions: dio.RequestOptions(path: path),
      data: {
        'success': true,
        'message': 'File uploaded successfully',
        'data': {
          'question_paper_id': '550e8400-e29b-41d4-a716-446655440000',
          'pdf_url': 'https://bucket.s3.amazonaws.com/file.pdf',
        }
      } as T,
      statusCode: 200,
    );
  }
}

// Mock RoleAccessService for testing
class MockRoleAccessService extends RoleAccessService {
  final Map<String, bool> _canModifyMap = {};
  final Map<String, bool> _validateAccessMap = {};
  
  void setCanModify(String resource, bool value) {
    _canModifyMap[resource] = value;
  }
  
  void setValidateAccess(String resource, bool shouldThrow) {
    _validateAccessMap[resource] = shouldThrow;
  }
  
  @override
  bool canModify(String resource) {
    return _canModifyMap[resource] ?? false;
  }
  
  @override
  void validateAccess(String resource) {
    if (_validateAccessMap[resource] == true) {
      throw UnauthorizedAccessException('Access denied for $resource');
    }
  }
  
  @override
  String getAccessDeniedMessage(String resource) {
    return 'Access denied for $resource';
  }
}
