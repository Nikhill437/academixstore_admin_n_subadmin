import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../base_api_service.dart';

/// User Management Controller Service
/// Handles all user management API calls
/// Based on API Documentation: User Management Routes
class UserController extends GetxService {
  final BaseApiService _baseService = Get.find<BaseApiService>();

  // ===========================================
  // USER MANAGEMENT ENDPOINTS
  // ===========================================

  /// Get all users with optional filtering and pagination
  /// GET /api/users
  /// Requires: super_admin or college_admin
  ///
  /// Query Parameters:
  /// - [page]: Page number (default: 1)
  /// - [limit]: Items per page (default: 10)
  /// - [role]: Filter by role (optional)
  /// - [collegeId]: Filter by college (optional)
  /// - [search]: Search in full_name or email (optional)
  ///
  /// Returns: Paginated list of users with pagination info
  Future<Response> getAllUsers({
    int page = 1,
    int limit = 10,
    String? role,
    String? collegeId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (role != null) queryParams['role'] = role;
      if (collegeId != null) queryParams['collegeId'] = collegeId;
      if (search != null) queryParams['search'] = search;

      final response = await _baseService.get(
        'api/users',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Get all users failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get user by ID
  /// GET /api/users/:id
  /// Requires: Authentication (own profile or admin)
  ///
  /// [userId]: User ID
  /// Returns: User details with college information
  Future<Response> getUserById(String userId) async {
    try {
      final response = await _baseService.get('api/users/$userId');
      return response;
    } on DioException catch (e) {
      Get.log('Get user by ID failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Update user profile
  /// PUT /api/users/:id
  /// Requires: Authentication (own profile or admin)
  ///
  /// [userId]: User ID
  /// [updateData]: Updated user data
  /// - full_name (optional): User full name
  /// - email (optional): User email
  /// - mobile (optional): Phone number
  /// - profile_image_url (optional): Profile image URL
  ///
  /// Returns: Updated user data
  Future<Response> updateUser(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _baseService.put(
        'api/users/$userId',
        data: updateData,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Update user failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Change user password
  /// PUT /api/users/:id/password
  /// Requires: Authentication
  ///
  /// [userId]: User ID
  /// [currentPassword]: Current password
  /// [newPassword]: New password
  ///
  /// Returns: Success message
  Future<Response> changePassword(
    String userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _baseService.put(
        'api/users/$userId/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return response;
    } on DioException catch (e) {
      Get.log('Change password failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Deactivate user
  /// PUT /api/users/:id/deactivate
  /// Requires: super_admin or college_admin
  ///
  /// [userId]: User ID
  /// Returns: Success message
  Future<Response> deactivateUser(String userId) async {
    try {
      final response = await _baseService.put('api/users/$userId/deactivate');
      return response;
    } on DioException catch (e) {
      Get.log('Deactivate user failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Activate user
  /// PUT /api/users/:id/activate
  /// Requires: super_admin or college_admin
  ///
  /// [userId]: User ID
  /// Returns: Success message
  Future<Response> activateUser(String userId) async {
    try {
      final response = await _baseService.put('api/users/$userId/activate');
      return response;
    } on DioException catch (e) {
      Get.log('Activate user failed: ${e.message}', isError: true);
      rethrow;
    }
  }
}
