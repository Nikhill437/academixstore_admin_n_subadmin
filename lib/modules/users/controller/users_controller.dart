import 'package:get/get.dart';
import '../model/user.dart';
import '../../../services/api_service.dart';
import '../../../services/role_access_service.dart';

/// Users controller managing user operations
/// Integrates with the centralized ApiService for all API operations
class UsersController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final RoleAccessService _roleAccessService = Get.find<RoleAccessService>();

  // Observable variables for reactive UI updates
  final RxList<User> _users = <User>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserFilters> _filters = const UserFilters().obs;
  final RxInt _currentPage = 1.obs;
  final RxInt _totalItems = 0.obs;
  final RxInt _totalPages = 0.obs;
  final RxBool _hasMore = false.obs;

  // Getters for UI access
  List<User> get users => _users.toList();
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  String get error => _error.value;
  UserFilters get filters => _filters.value;
  int get currentPage => _currentPage.value;
  int get totalItems => _totalItems.value;
  int get totalPages => _totalPages.value;
  bool get hasMore => _hasMore.value;
  bool get hasUsers => _users.isNotEmpty;
  bool get hasError => _error.value.isNotEmpty;
  RoleAccessService get roleAccessService => _roleAccessService;

  // Configuration
  static const int itemsPerPage = 20;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  @override
  void onReady() {
    super.onReady();
    loadUsers();
  }

  /// Initialize the controller
  void _initializeController() {
    Get.log('UsersController initialized', isError: false);
  }

  /// Load users with current filters and pagination
  // Future<void> loadUsers({bool refresh = false}) async {
  //   if (refresh) {
  //     _currentPage.value = 1;
  //     _users.clear();
  //     _error.value = '';
  //   }

  //   if (_isLoading.value) return;

  //   try {
  //     _isLoading.value = true;
  //     _error.value = '';

  //     // Make API call using ApiService
  //     final response = await _apiService.getAllUsers(
  //       page: _currentPage.value,
  //       limit: itemsPerPage,
  //       search: _filters.value.search,
  //       role: _filters.value.role,
  //       collegeId: _filters.value.collegeId,
  //     );

  //     if (response.data['success'] == true) {
  //       // Parse response
  //       final data = response.data['data'];
  //       final usersData = (data['users'] ?? data) as List<dynamic>;
  //       final newUsers = usersData
  //           .map((json) => User.fromJson(json as Map<String, dynamic>))
  //           .toList();

  //       // Update state
  //       if (refresh || _currentPage.value == 1) {
  //         _users.value = newUsers;
  //       } else {
  //         _users.addAll(newUsers);
  //       }

  //       _totalItems.value = data['total'] as int? ?? newUsers.length;
  //       _totalPages.value = data['total_pages'] as int? ?? 1;
  //       _hasMore.value = _currentPage.value < _totalPages.value;

  //       Get.log(
  //         'Loaded ${newUsers.length} users (page ${_currentPage.value})',
  //         isError: false,
  //       );
  //     } else {
  //       _error.value = response.data['message'] ?? 'Failed to load users';
  //     }
  //   } catch (e) {
  //     _error.value = _handleError(e);
  //     Get.log('Error loading users: $e', isError: true);
  //   } finally {
  //     _isLoading.value = false;
  //   }
  // }
  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      _currentPage.value = 1;
      _users.clear();
      _error.value = '';
    }

    if (_isLoading.value) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.getAllUsers(
        page: _currentPage.value,
        limit: itemsPerPage,
        search: _filters.value.search,
        role: _filters.value.role,
        collegeId: _filters.value.collegeId,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final List usersData = data['users'] ?? [];

        final newUsers = usersData
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();

        if (refresh || _currentPage.value == 1) {
          _users.value = newUsers;
        } else {
          _users.addAll(newUsers);
        }

        final pagination = data['pagination'];

        _totalItems.value = pagination['total'] ?? newUsers.length;
        _totalPages.value = pagination['totalPages'] ?? 1;
        _hasMore.value = _currentPage.value < _totalPages.value;

        Get.log('Loaded ${newUsers.length} users');
      } else {
        _error.value = response.data['message'] ?? 'Failed to load users';
      }
    } catch (e) {
      _error.value = _handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load more users for pagination
  Future<void> loadMoreUsers() async {
    if (_isLoadingMore.value || !_hasMore.value) return;

    try {
      _isLoadingMore.value = true;
      _currentPage.value++;
      await loadUsers();
    } catch (e) {
      _currentPage.value--; // Revert page increment on error
      rethrow;
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refresh users list
  Future<void> refreshUsers() async {
    await loadUsers(refresh: true);
  }

  /// Apply search and filters
  Future<void> applyFilters(UserFilters newFilters) async {
    _filters.value = newFilters;
    await loadUsers(refresh: true);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _filters.value = const UserFilters();
    await loadUsers(refresh: true);
  }

  /// Search users by name, email, or phone
  Future<void> searchUsers(String query) async {
    _filters.value = _filters.value.copyWith(search: query);
    await loadUsers(refresh: true);
  }

  /// Filter users by role
  Future<void> filterByRole(String role) async {
    _filters.value = _filters.value.copyWith(role: role);
    await loadUsers(refresh: true);
  }

  /// Get a single user by ID
  Future<User?> getUser(String userId) async {
    try {
      final response = await _apiService.getUserById(userId);
      if (response.data['success'] == true) {
        return User.fromJson(response.data['data']);
      }
    } catch (e) {
      Get.log('Error getting user: $e', isError: true);
    }
    return null;
  }

  /// Update an existing user
  Future<bool> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.updateUser(userId, userData);

      if (response.data['success'] == true) {
        final updatedUser = User.fromJson(response.data['data']);
        final index = _users.indexWhere((user) => user.id == userId);

        if (index != -1) {
          _users[index] = updatedUser;
        }

        Get.snackbar(
          'Success',
          'User "${updatedUser.fullName}" updated successfully',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        Get.log('User updated: ${updatedUser.fullName}');
        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to update user';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error updating user: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Activate a user
  Future<bool> activateUser(String userId) async {
    try {
      final response = await _apiService.activateUser(userId);

      if (response.data['success'] == true) {
        final index = _users.indexWhere((user) => user.id == userId);
        if (index != -1) {
          final updatedUser = _users[index].copyWith(isActive: true);
          _users[index] = updatedUser;
        }

        Get.snackbar(
          'Success',
          'User activated successfully',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      }
      return false;
    } catch (e) {
      Get.log('Error activating user: $e', isError: true);
      return false;
    }
  }

  /// Deactivate a user
  Future<bool> deactivateUser(String userId) async {
    try {
      final response = await _apiService.deactivateUser(userId);

      if (response.data['success'] == true) {
        final index = _users.indexWhere((user) => user.id == userId);
        if (index != -1) {
          final updatedUser = _users[index].copyWith(isActive: false);
          _users[index] = updatedUser;
        }

        Get.snackbar(
          'Success',
          'User deactivated successfully',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      }
      return false;
    } catch (e) {
      Get.log('Error deactivating user: $e', isError: true);
      return false;
    }
  }

  /// Change user password
  Future<bool> changeUserPassword(
    String userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _apiService.changePassword(
        userId,
        currentPassword,
        newPassword,
      );

      if (response.data['success'] == true) {
        Get.snackbar(
          'Success',
          'Password changed successfully',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
        return true;
      }
      return false;
    } catch (e) {
      Get.log('Error changing user password: $e', isError: true);
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _error.value = '';
  }

  /// Handle API errors
  String _handleError(dynamic error) {
    if (error is Map<String, dynamic>) {
      return error['message'] ?? 'An error occurred';
    }
    return error.toString();
  }

  /// Utility getters for UI state
  bool get isEmpty => !hasUsers && !isLoading;
  bool get hasData => hasUsers && !isLoading;
}
