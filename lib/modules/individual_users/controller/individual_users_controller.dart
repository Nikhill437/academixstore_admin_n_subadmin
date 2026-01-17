import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../services/role_access_service.dart';

/// Individual Users controller managing individual user operations
/// Individual users are users with role='user' (not associated with any college)
class IndividualUsersController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final RoleAccessService _roleAccessService = Get.find<RoleAccessService>();

  // Observable variables
  final RxList<Map<String, dynamic>> _individualUsers =
      <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxInt _currentPage = 1.obs;
  final RxInt _totalItems = 0.obs;
  final RxInt _totalPages = 0.obs;
  final RxString _searchQuery = ''.obs;

  // Getters
  List<Map<String, dynamic>> get individualUsers => _individualUsers.toList();
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  int get currentPage => _currentPage.value;
  int get totalItems => _totalItems.value;
  int get totalPages => _totalPages.value;
  String get searchQuery => _searchQuery.value;
  bool get hasUsers => _individualUsers.isNotEmpty;
  bool get hasError => _error.value.isNotEmpty;

  static const int itemsPerPage = 10;

  @override
  void onInit() {
    super.onInit();
    Get.log('IndividualUsersController initialized', isError: false);
  }

  @override
  void onReady() {
    super.onReady();
    loadIndividualUsers();
  }

  /// Load individual users (super_admin only)
  Future<void> loadIndividualUsers({bool refresh = false}) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('view individual users');
      return;
    }

    if (refresh) {
      _currentPage.value = 1;
      _individualUsers.clear();
      _error.value = '';
    }

    if (_isLoading.value) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.getAllIndividualUsers(
        page: _currentPage.value,
        limit: itemsPerPage,
        search: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final usersData = (data['users'] ?? data) as List<dynamic>;
        final newUsers = usersData
            .map((json) => json as Map<String, dynamic>)
            .toList();

        if (refresh || _currentPage.value == 1) {
          _individualUsers.value = newUsers;
        } else {
          _individualUsers.addAll(newUsers);
        }

        final pagination = data['pagination'] as Map<String, dynamic>?;
        _totalItems.value = pagination?['total'] as int? ?? newUsers.length;
        _totalPages.value =
            pagination?['totalPages'] as int? ?? _currentPage.value;

        Get.log(
          'Loaded ${newUsers.length} individual users (page ${_currentPage.value})',
          isError: false,
        );
      } else {
        _error.value =
            response.data['message'] ?? 'Failed to load individual users';
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error loading individual users: $e', isError: true);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get individual user by ID
  Future<Map<String, dynamic>?> getIndividualUser(String userId) async {
    try {
      final response = await _apiService.getIndividualUserById(userId);
      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      Get.log('Error getting individual user: $e', isError: true);
    }
    return null;
  }

  /// Create individual user (super_admin only)
  Future<bool> createIndividualUser(Map<String, dynamic> userData) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('create individual users');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.createIndividualUser(userData);

      if (response.data['success'] == true) {
        final newUser = response.data['data'] as Map<String, dynamic>;
        _individualUsers.insert(0, newUser);
        _totalItems.value++;

        Get.snackbar(
          'Success',
          'Individual user "${newUser['full_name']}" created successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _error.value =
            response.data['message'] ?? 'Failed to create individual user';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error creating individual user: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update individual user
  Future<bool> updateIndividualUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('update individual users');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response =
          await _apiService.updateIndividualUser(userId, userData);

      if (response.data['success'] == true) {
        final updatedUser = response.data['data'] as Map<String, dynamic>;
        final index = _individualUsers.indexWhere((u) => u['id'] == userId);

        if (index != -1) {
          _individualUsers[index] = updatedUser;
        }

        Get.snackbar(
          'Success',
          'Individual user "${updatedUser['full_name']}" updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _error.value =
            response.data['message'] ?? 'Failed to update individual user';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error updating individual user: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Change individual user password
  Future<bool> changeIndividualUserPassword(
    String userId,
    String newPassword,
  ) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('change individual user passwords');
      return false;
    }

    try {
      final response =
          await _apiService.changeIndividualUserPassword(userId, newPassword);

      if (response.data['success'] == true) {
        Get.snackbar(
          'Success',
          'Password changed successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
        return true;
      }
      return false;
    } catch (e) {
      Get.log('Error changing individual user password: $e', isError: true);
      return false;
    }
  }

  /// Activate individual user
  Future<bool> activateIndividualUser(String userId) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('activate individual users');
      return false;
    }

    try {
      final response = await _apiService.activateIndividualUser(userId);

      if (response.data['success'] == true) {
        final index = _individualUsers.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _individualUsers[index]['is_active'] = true;
          _individualUsers.refresh();
        }

        Get.snackbar(
          'Success',
          'Individual user activated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      }
      return false;
    } catch (e) {
      Get.log('Error activating individual user: $e', isError: true);
      return false;
    }
  }

  /// Deactivate individual user
  Future<bool> deactivateIndividualUser(String userId) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('deactivate individual users');
      return false;
    }

    try {
      final response = await _apiService.deactivateIndividualUser(userId);

      if (response.data['success'] == true) {
        final index = _individualUsers.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _individualUsers[index]['is_active'] = false;
          _individualUsers.refresh();
        }

        Get.snackbar(
          'Success',
          'Individual user deactivated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      }
      return false;
    } catch (e) {
      Get.log('Error deactivating individual user: $e', isError: true);
      return false;
    }
  }

  /// Delete individual user
  Future<bool> deleteIndividualUser(String userId) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('delete individual users');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.deleteIndividualUser(userId);

      if (response.data['success'] == true) {
        _individualUsers.removeWhere((u) => u['id'] == userId);
        _totalItems.value--;

        Get.snackbar(
          'Success',
          'Individual user deleted successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _error.value =
            response.data['message'] ?? 'Failed to delete individual user';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error deleting individual user: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Search individual users
  Future<void> searchIndividualUsers(String query) async {
    _searchQuery.value = query;
    await loadIndividualUsers(refresh: true);
  }

  /// Refresh individual users list
  Future<void> refreshIndividualUsers() async {
    await loadIndividualUsers(refresh: true);
  }

  /// Clear error
  void clearError() {
    _error.value = '';
  }

  /// Show access denied error
  void _showAccessDeniedError(String action) {
    Get.snackbar(
      'Access Denied',
      'You don\'t have permission to $action. Super admin access required.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 5),
    );
  }

  /// Handle errors
  String _handleError(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return 'Network error. Please check your connection and try again.';
    }

    if (error.toString().contains('404')) {
      return 'Individual users service not found. Please contact support.';
    }

    if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  @override
  void onClose() {
    Get.log('IndividualUsersController disposed', isError: false);
    super.onClose();
  }
}
