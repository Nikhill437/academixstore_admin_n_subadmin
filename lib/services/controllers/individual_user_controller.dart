import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../base_api_service.dart';

/// Individual Users Management Controller Service
/// Handles all individual user (user role) management API calls
/// Based on API Documentation: Individual Users Management Routes
class IndividualUserController extends GetxService {
  final BaseApiService _baseService = Get.find<BaseApiService>();

  // ===========================================
  // INDIVIDUAL USERS MANAGEMENT ENDPOINTS
  // ===========================================

  /// Get all individual users with pagination
  /// GET /api/individual-users
  /// Requires: super_admin
  ///
  /// Query Parameters:
  /// - [page]: Page number (optional, default: 1)
  /// - [limit]: Items per page (optional, default: 10)
  /// - [search]: Search in full_name or email (optional)
  ///
  /// Returns: Paginated list of individual users
  Future<Response> getAllIndividualUsers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null) queryParams['search'] = search;

      final response = await _baseService.get(
        'api/individual-users',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Get all individual users failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get individual user by ID
  /// GET /api/individual-users/:id
  /// Requires: super_admin
  ///
  /// [userId]: User ID
  /// Returns: Individual user details
  Future<Response> getIndividualUserById(String userId) async {
    try {
      final response =
          await _baseService.get('api/individual-users/$userId');
      return response;
    } on DioException catch (e) {
      Get.log('Get individual user by ID failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Create a new individual user
  /// POST /api/individual-users
  /// Requires: super_admin
  ///
  /// [userData]: User data
  /// - email (required): User email
  /// - password (required): User password (minimum 6 characters)
  /// - full_name (required): User full name (2-255 characters)
  /// - mobile (optional): Phone number
  /// - profile_image_url (optional): Profile image URL
  ///
  /// Returns: Created individual user data
  Future<Response> createIndividualUser(Map<String, dynamic> userData) async {
    try {
      final response = await _baseService.post(
        'api/individual-users',
        data: userData,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Create individual user failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Update individual user
  /// PUT /api/individual-users/:id
  /// Requires: super_admin
  ///
  /// [userId]: User ID
  /// [updateData]: Updated user data (same fields as create, all optional)
  ///
  /// Returns: Updated individual user data
  Future<Response> updateIndividualUser(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _baseService.put(
        'api/individual-users/$userId',
        data: updateData,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Update individual user failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Change individual user password
  /// PUT /api/individual-users/:id/password
  /// Requires: super_admin
  ///
  /// [userId]: User ID
  /// [newPassword]: New password
  ///
  /// Returns: Success message
  Future<Response> changeIndividualUserPassword(
    String userId,
    String newPassword,
  ) async {
    try {
      final response = await _baseService.put(
        'api/individual-users/$userId/password',
        data: {'newPassword': newPassword},
      );
      return response;
    } on DioException catch (e) {
      Get.log('Change individual user password failed: ${e.message}',
          isError: true);
      rethrow;
    }
  }

  /// Deactivate individual user
  /// PUT /api/individual-users/:id/deactivate
  /// Requires: super_admin
  ///
  /// [userId]: User ID
  /// Returns: Success message
  Future<Response> deactivateIndividualUser(String userId) async {
    try {
      final response = await _baseService.put(
        'api/individual-users/$userId/deactivate',
      );
      return response;
    } on DioException catch (e) {
      Get.log('Deactivate individual user failed: ${e.message}',
          isError: true);
      rethrow;
    }
  }

  /// Activate individual user
  /// PUT /api/individual-users/:id/activate
  /// Requires: super_admin
  ///
  /// [userId]: User ID
  /// Returns: Success message
  Future<Response> activateIndividualUser(String userId) async {
    try {
      final response = await _baseService.put(
        'api/individual-users/$userId/activate',
      );
      return response;
    } on DioException catch (e) {
      Get.log('Activate individual user failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Delete individual user
  /// DELETE /api/individual-users/:id
  /// Requires: super_admin
  ///
  /// [userId]: User ID
  /// Returns: Success message
  Future<Response> deleteIndividualUser(String userId) async {
    try {
      final response =
          await _baseService.delete('api/individual-users/$userId');
      return response;
    } on DioException catch (e) {
      Get.log('Delete individual user failed: ${e.message}', isError: true);
      rethrow;
    }
  }
}
