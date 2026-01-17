import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'token_service.dart';

/// Base API service that handles JWT authentication and common HTTP operations
/// Automatically injects JWT tokens and handles token expiry scenarios
class BaseApiService extends GetxService {
  late final Dio _dio;
  final TokenService _tokenService = Get.find<TokenService>();

  // API configuration
  static const String baseUrl =
      'https://academixstore-backend.onrender.com/api/'; // Deployed backend URL
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  @override
  void onInit() {
    super.onInit();
    _initializeDio();
  }

  /// Initialize Dio instance with configuration and interceptors
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        sendTimeout: Duration(milliseconds: sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Add logging interceptor (only in debug mode)
    if (Get.isLogEnable) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) => Get.log(object.toString()),
        ),
      );
    }
  }

  /// Request interceptor - Automatically adds JWT token to headers
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Get token from secure storage
      final token = await _tokenService.getToken();

      if (token != null) {
        // Add Authorization header with Bearer token
        options.headers['Authorization'] = 'Bearer $token';
        Get.log('JWT token added to request headers', isError: false);
      } else {
        Get.log(
          'No valid token found, proceeding without authentication',
          isError: false,
        );
      }

      // Continue with the request
      handler.next(options);
    } catch (e) {
      Get.log('Error in request interceptor: $e', isError: true);
      handler.next(options); // Continue even if token retrieval fails
    }
  }

  /// Response interceptor - Handle successful responses
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    Get.log(
      'API Response: ${response.statusCode} - ${response.requestOptions.path}',
      isError: false,
    );
    Get.log('Response data: ${response.data}', isError: false);
    handler.next(response);
  }

  /// Error interceptor - Handle API errors and token expiry
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    Get.log(
      'API Error: ${error.response?.statusCode} - ${error.message}',
      isError: true,
    );

    // Handle 401 Unauthorized - Token expired or invalid
    if (error.response?.statusCode == 401) {
      await _handleUnauthorized(error, handler);
      return;
    }

    // Handle other common HTTP errors
    switch (error.response?.statusCode) {
      case 403:
        _handleForbidden();
        break;
      case 404:
        _handleNotFound();
        break;
      case 500:
        _handleServerError();
        break;
      case 503:
        _handleServiceUnavailable();
        break;
      default:
        _handleGenericError(error);
    }

    handler.next(error);
  }

  /// Handle 401 Unauthorized errors (token expiry/invalid)
  Future<void> _handleUnauthorized(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    Get.log(
      'Unauthorized access detected - token may be expired',
      isError: true,
    );

    try {
      // Clear expired token
      await _tokenService.deleteToken();

      // Show user-friendly message
      Get.snackbar(
        'Session Expired',
        'Your session has expired. Please sign in again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );

      // Navigate to sign-in screen
      Get.offAllNamed('/signin');
    } catch (e) {
      Get.log('Error handling unauthorized: $e', isError: true);
    }

    handler.next(error);
  }

  /// Handle 403 Forbidden errors
  void _handleForbidden() {
    Get.snackbar(
      'Access Denied',
      'You don\'t have permission to access this resource.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  /// Handle 404 Not Found errors
  void _handleNotFound() {
    Get.snackbar(
      'Resource Not Found',
      'The requested resource could not be found.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  /// Handle 500 Internal Server Error
  void _handleServerError() {
    Get.snackbar(
      'Server Error',
      'Something went wrong on our end. Please try again later.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  /// Handle 503 Service Unavailable
  void _handleServiceUnavailable() {
    Get.snackbar(
      'Service Unavailable',
      'The service is temporarily unavailable. Please try again later.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  /// Handle generic errors
  void _handleGenericError(DioException error) {
    String message = 'An unexpected error occurred.';

    if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Server response timeout. Please try again.';
    } else if (error.type == DioExceptionType.sendTimeout) {
      message = 'Request timeout. Please try again.';
    } else if (error.type == DioExceptionType.connectionError) {
      message =
          'Unable to connect to server. Please check your internet connection.';
    }

    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  // === Public API Methods ===

  /// Perform GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      Get.log('GET request failed for $path: $e', isError: true);
      rethrow;
    }
  }

  /// Perform POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      Get.log('POST request failed for $path: $e', isError: true);
      rethrow;
    }
  }

  /// Perform PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      Get.log('PUT request failed for $path: $e', isError: true);
      rethrow;
    }
  }

  /// Perform PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      Get.log('PATCH request failed for $path: $e', isError: true);
      rethrow;
    }
  }

  /// Perform DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      Get.log('DELETE request failed for $path: $e', isError: true);
      rethrow;
    }
  }

  /// Upload file using multipart form data
  /// Supports both file path (mobile/desktop) and bytes (web)
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath,
    String fileKey, {
    Map<String, dynamic>? additionalData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      MultipartFile multipartFile;
      
      if (fileBytes != null && fileName != null) {
        // Web platform: use bytes
        Get.log('📱 Creating multipart file from bytes: $fileName (${fileBytes.length} bytes)', isError: false);
        multipartFile = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        );
      } else if (filePath.isNotEmpty) {
        // Mobile/Desktop: use file path
        Get.log('💻 Creating multipart file from path: $filePath', isError: false);
        multipartFile = await MultipartFile.fromFile(filePath);
      } else {
        throw Exception('Either fileBytes with fileName or filePath must be provided');
      }

      final formData = FormData.fromMap({
        fileKey: multipartFile,
        if (additionalData != null) ...additionalData,
      });

      Get.log('📤 Uploading file to: $path with key: $fileKey', isError: false);

      return await _dio.post<T>(
        path,
        data: formData,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } catch (e) {
      Get.log('File upload failed for $path: $e', isError: true);
      rethrow;
    }
  }

  /// Download file
  Future<Response> downloadFile(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      Get.log('File download failed for $path: $e', isError: true);
      rethrow;
    }
  }

  /// Check if user has valid authentication
  Future<bool> isAuthenticated() async {
    return await _tokenService.hasToken();
  }

  /// Get current user ID from token
  Future<String?> getCurrentUserId() async {
    return await _tokenService.getUserId();
  }

  /// Get current user role from token
  Future<String?> getCurrentUserRole() async {
    return await _tokenService.getUserRole();
  }
}
