import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../services/token_service.dart';
import '../../../services/role_access_service.dart';

/// Controller to handle authentication logic and state management
class AuthController extends GetxController {
  final ApiService _apiService = Get.put(ApiService());
  final TokenService _tokenService = Get.find<TokenService>();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthenticationStatus();
    _checkBackendHealth();
  }

  /// Check backend health on startup
  Future<void> _checkBackendHealth() async {
    try {
      Get.log('Checking backend health...', isError: false);
      final response = await _apiService.healthCheck().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          Get.log(
            'Backend health check timed out - server may be sleeping',
            isError: true,
          );
          throw Exception('Health check timeout');
        },
      );
      Get.log('Backend is healthy: ${response.data}', isError: false);
    } catch (e) {
      Get.log('Backend health check failed (this is OK): $e', isError: false);
      // Don't block the app, just log the issue
      // The /health endpoint might not exist, which is fine
    }
  }

  /// Check if user is already authenticated
  Future<void> checkAuthenticationStatus() async {
    try {
      final hasToken = await _tokenService.hasToken();
      
      if (!hasToken) {
        isAuthenticated.value = false;
        return;
      }

      // Check if token is valid (not expired)
      final token = await _tokenService.getToken();
      if (token != null && _tokenService.isTokenValid(token)) {
        isAuthenticated.value = true;
        
        // Optionally verify token with API in background
        // Don't await to avoid blocking the UI
        verifyCurrentToken().catchError((e) {
          Get.log('Background token verification failed: $e', isError: false);
        });
      } else {
        // Token expired or invalid
        await _tokenService.deleteToken();
        isAuthenticated.value = false;
      }
    } catch (e) {
      Get.log('Authentication check failed: $e', isError: false);
      isAuthenticated.value = false;
    }
  }

  /// Verify current token with API
  Future<void> verifyCurrentToken() async {
    try {
      final response = await _apiService.getCurrentUser();
      if (response.data['success'] == true) {
        isAuthenticated.value = true;
      } else {
        // Invalid token, clear it
        await _tokenService.deleteToken();
        isAuthenticated.value = false;
      }
    } catch (e) {
      Get.log('Token verification failed: $e', isError: false);
      // Don't logout on verification failure - could be network issue
      // Just log the error and keep the local token
    }
  }

  /// Login user with email and password
  Future<bool> login({
    required String email,
    required String password,
    String? collegeId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      Get.log('Starting login request for: $email', isError: false);

      // Make API login request with timeout (60 seconds for Render free tier)
      final response = await _apiService.loginUser(email, password).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          Get.log('Login request timed out after 60 seconds', isError: true);
          throw Exception(
            'Login request timed out. The server may be sleeping. Please try again.',
          );
        },
      );

      Get.log('✅ Response received from API', isError: false);
      Get.log('📊 Response status code: ${response.statusCode}', isError: false);
      Get.log('📦 Response data type: ${response.data.runtimeType}', isError: false);
      Get.log('📄 Response data: ${response.data}', isError: false);
      
      // Additional debugging
      if (response.data != null) {
        Get.log('🔍 Response data keys: ${(response.data as Map?)?.keys}', isError: false);
      }

      // Check if response.data is null or not a Map
      if (response.data == null) {
        throw Exception('Response data is null');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Response data is not a Map: ${response.data}');
      }

      // Check for success field
      final success = response.data['success'];
      Get.log('✅ Success field value: $success', isError: false);

      if (success == true) {
        Get.log('🎉 Login successful, extracting user data...', isError: false);
        
        final data = response.data['data'];
        Get.log('📦 Data field: $data', isError: false);
        
        if (data == null) {
          throw Exception('Response data field is null');
        }
        
        final userData = data['user'];
        final token = data['token'];
        
        Get.log('👤 User data: $userData', isError: false);
        Get.log('🔑 Token: ${token?.substring(0, 20)}...', isError: false);
        
        if (userData == null || token == null) {
          throw Exception('User data or token is null');
        }
        
        final userRole = userData['role'];
        final userId = userData['id'];
        
        Get.log('🆔 User ID: $userId', isError: false);
        Get.log('👔 Role: $userRole', isError: false);

        // Validate role-based access
        if (collegeId?.isNotEmpty == true) {
          // College ID provided - ensure user is college_admin
          if (userRole != 'college_admin') {
            throw Exception(
              'College ID provided but user is not a college admin',
            );
          }
          // Verify college ID matches user's college
          if (userData['college_id'] != collegeId) {
            throw Exception(
              'College ID does not match user\'s assigned college',
            );
          }
        } else {
          // No College ID - ensure user is super_admin
          if (userRole != 'super_admin') {
            throw Exception(
              'Super admin access required. Please provide College ID for college admin access.',
            );
          }
        }

        // Save token and user data
        Get.log('💾 Saving token to storage...', isError: false);
        final saveSuccess = await _tokenService.saveToken(
          token: token,
          userId: userId,
          userRole: userRole,
        );

        Get.log('💾 Token save result: $saveSuccess', isError: false);

        if (saveSuccess) {
          isAuthenticated.value = true;
          Get.log('✅ Authentication state set to true', isError: false);
          Get.log('✅ isAuthenticated.value = ${isAuthenticated.value}', isError: false);

          // Refresh role access service to load the new role
          try {
            final roleAccessService = Get.find<RoleAccessService>();
            await roleAccessService.refreshRole();
            Get.log('✅ Role refreshed in RoleAccessService', isError: false);
          } catch (e) {
            Get.log('⚠️ Error refreshing role: $e', isError: true);
          }

          // Show success message
          _showSuccessMessage(userRole, userData, collegeId);

          Get.log('🎊 Login completed successfully, returning true', isError: false);
          return true;
        } else {
          throw Exception('Failed to save authentication data');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } catch (e, stackTrace) {
      Get.log('Login error: $e', isError: true);
      Get.log('Stack trace: $stackTrace', isError: true);
      _handleLoginError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout user - clears all stored data and navigates to signin
  Future<void> logout() async {
    try {
      isLoading.value = true;

      Get.log('🚪 Starting logout process...', isError: false);

      // Call API logout endpoint
      try {
        await _apiService.logoutUser();
        Get.log('✅ API logout successful', isError: false);
      } catch (e) {
        // Continue with local logout even if API call fails
        Get.log('⚠️ API logout failed (continuing with local logout): $e', isError: false);
      }

      // Clear local token and data
      await _tokenService.deleteToken();
      Get.log('✅ Token deleted from storage', isError: false);

      // Clear authentication state
      isAuthenticated.value = false;
      errorMessage.value = '';
      Get.log('✅ Authentication state cleared', isError: false);

      // Clear role access service
      try {
        final roleAccessService = Get.find<RoleAccessService>();
        await roleAccessService.clearRole();
        Get.log('✅ Role access service cleared', isError: false);
      } catch (e) {
        Get.log('⚠️ Error clearing role access service: $e', isError: false);
      }

      // Delete all GetX controllers to clear cached data
      try {
        Get.deleteAll(force: true);
        Get.log('✅ All GetX controllers deleted', isError: false);
      } catch (e) {
        Get.log('⚠️ Error deleting controllers: $e', isError: false);
      }

      // Navigate to signin screen and clear navigation stack
      Get.offAllNamed('/signin');
      Get.log('✅ Navigated to signin screen', isError: false);

      // Show success message
      Get.snackbar(
        'Logged Out',
        'You have been successfully logged out',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 2),
      );

      Get.log('🎉 Logout completed successfully', isError: false);
    } catch (e) {
      Get.log('❌ Logout error: $e', isError: true);
      
      // Even if there's an error, try to navigate to signin
      try {
        Get.offAllNamed('/signin');
      } catch (navError) {
        Get.log('❌ Navigation error: $navError', isError: true);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current user information
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _apiService.getCurrentUser();
      if (response.data['success'] == true) {
        return response.data['data']['user'];
      }
      return null;
    } catch (e) {
      Get.log('Get current user error: $e', isError: true);
      return null;
    }
  }

  /// Refresh authentication token
  Future<bool> refreshToken() async {
    try {
      final response = await _apiService.refreshToken();
      if (response.data['success'] == true) {
        final newToken = response.data['data']['token'];
        final userId = await _tokenService.getUserId();
        final userRole = await _tokenService.getUserRole();

        if (userId != null && userRole != null) {
          await _tokenService.saveToken(
            token: newToken,
            userId: userId,
            userRole: userRole,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      Get.log('Token refresh error: $e', isError: true);
      return false;
    }
  }

  /// Checks if user is authenticated and redirects to signin if not
  /// Returns true if authenticated, false if not
  Future<bool> checkAuthenticationAndRedirect() async {
    if (!isAuthenticated.value) {
      Get.offAllNamed('/signin');
      return false;
    }

    // Check if token is about to expire
    final token = await _tokenService.getToken();
    if (token != null && await _tokenService.willExpireSoon()) {
      final refreshed = await refreshToken();
      if (!refreshed) {
        return false; // User will be logged out by refreshToken method
      }
    }

    return true;
  }

  /// Handle login errors and show appropriate messages
  void _handleLoginError(dynamic error) {
    String message = 'Please check your credentials and try again.';

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      switch (statusCode) {
        case 401:
          message = 'Invalid email or password.';
          break;
        case 403:
          message = 'Access denied. Please check your permissions.';
          break;
        case 429:
          message = 'Too many login attempts. Please try again later.';
          break;
        case 500:
          message = 'Server error. Please try again later.';
          break;
        default:
          if (error.response?.data != null &&
              error.response!.data is Map<String, dynamic>) {
            message = error.response!.data['message'] ?? message;
          }
      }
    } else if (error.toString().contains('College ID')) {
      message = error.toString().replaceAll('Exception: ', '');
    } else if (error.toString().contains('Super admin access required')) {
      message =
          'Super admin access required. Please provide College ID for college admin access.';
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      message = 'Network error. Please check your internet connection.';
    }

    errorMessage.value = message;

    Get.snackbar(
      'Sign In Failed',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 5),
    );
  }

  /// Show success message after login
  void _showSuccessMessage(
    String userRole,
    Map<String, dynamic> userData,
    String? collegeId,
  ) {
    final collegeName = userData['college']?['name'] ?? collegeId;

    Get.snackbar(
      'Welcome!',
      userRole == 'super_admin'
          ? 'Signed in as Super Admin'
          : 'Signed in as College Admin for $collegeName',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.primaryColor.withValues(alpha: 0.9),
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 3),
    );
  }

  /// Check if user has specific role
  Future<bool> hasRole(String role) async {
    try {
      final userRole = await _tokenService.getUserRole();
      return userRole == role;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is super admin
  Future<bool> isSuperAdmin() async {
    return await hasRole('super_admin');
  }

  /// Check if user is college admin
  Future<bool> isCollegeAdmin() async {
    return await hasRole('college_admin');
  }
}
