import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../base_api_service.dart';

/// College Management Controller Service
/// Handles all college management API calls
/// Based on API Documentation: College Management Routes
class CollegeController extends GetxService {
  final BaseApiService _baseService = Get.find<BaseApiService>();

  // ===========================================
  // COLLEGE MANAGEMENT ENDPOINTS
  // ===========================================

  /// Get all colleges with optional filtering and pagination
  /// GET /api/colleges
  ///
  /// Query Parameters:
  /// - [page]: Page number (optional, default: 1)
  /// - [limit]: Items per page (optional, default: 10)
  /// - [search]: Search in name, code, address (optional)
  /// - [status]: Filter by status - 'active' or 'inactive' (optional)
  ///
  /// Returns: Paginated list of colleges
  Future<Response> getAllColleges({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null) queryParams['search'] = search;
      if (status != null) queryParams['status'] = status;

      final response = await _baseService.get(
        'api/colleges',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Get all colleges failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get college by ID
  /// GET /api/colleges/:id
  ///
  /// [collegeId]: College ID
  /// Returns: College details
  Future<Response> getCollegeById(String collegeId) async {
    try {
      final response = await _baseService.get('api/colleges/$collegeId');
      return response;
    } on DioException catch (e) {
      Get.log('Get college by ID failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Create a new college
  /// POST /api/colleges
  /// Requires: super_admin
  ///
  /// [collegeData]: College data
  /// - name (required): College name (2-255 characters)
  /// - code (required): College code (2-20 characters, uppercase, unique)
  /// - address (required): College address
  /// - phone (required): Contact phone number
  /// - email (required): Contact email (valid format, unique)
  /// - website (optional): College website URL
  ///
  /// Returns: Created college data
  Future<Response> createCollege(Map<String, dynamic> collegeData) async {
    try {
      final response = await _baseService.post(
        'api/colleges',
        data: collegeData,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Create college failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Update college
  /// PUT /api/colleges/:id
  /// Requires: super_admin or college_admin (own college)
  ///
  /// [collegeId]: College ID
  /// [updateData]: Updated college data (same fields as create, all optional)
  ///
  /// Returns: Updated college data
  Future<Response> updateCollege(
    String collegeId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _baseService.put(
        'api/colleges/$collegeId',
        data: updateData,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Update college failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get college statistics
  /// GET /api/colleges/:id/stats
  /// Requires: super_admin or college_admin
  ///
  /// [collegeId]: College ID
  ///
  /// Returns: College statistics including:
  /// - Total students, admins, books, users
  /// - Books by category breakdown
  /// - Recent users and books
  Future<Response> getCollegeStats(String collegeId) async {
    try {
      final response = await _baseService.get('api/colleges/$collegeId/stats');
      return response;
    } on DioException catch (e) {
      Get.log('Get college stats failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get college users
  /// GET /api/colleges/:id/users
  /// Requires: super_admin or college_admin
  ///
  /// [collegeId]: College ID
  /// [page]: Page number (optional, default: 1)
  /// [limit]: Items per page (optional, default: 20)
  /// [role]: Filter by role (optional)
  ///
  /// Returns: Paginated list of college users
  Future<Response> getCollegeUsers(
    String collegeId, {
    int page = 1,
    int limit = 20,
    String? role,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (role != null) queryParams['role'] = role;

      final response = await _baseService.get(
        'api/colleges/$collegeId/users',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Get college users failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get college books
  /// GET /api/colleges/:id/books
  ///
  /// [collegeId]: College ID
  /// [page]: Page number (optional, default: 1)
  /// [limit]: Items per page (optional, default: 20)
  /// [category]: Filter by category (optional)
  ///
  /// Returns: Paginated list of college books
  Future<Response> getCollegeBooks(
    String collegeId, {
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (category != null) queryParams['category'] = category;

      final response = await _baseService.get(
        'api/colleges/$collegeId/books',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Get college books failed: ${e.message}', isError: true);
      rethrow;
    }
  }
}
