import 'package:get/get.dart';
import '../models/user_role.dart';
import 'token_service.dart';
import 'base_api_service.dart';

/// Production-grade Role-based Access Control Service
/// Manages user permissions, module access, and route authorization
/// Integrates with JWT token service to extract and validate user roles
class RoleAccessService extends GetxService {
  final TokenService _tokenService = Get.find<TokenService>();

  // Reactive variables for current user state
  final Rx<UserRole?> _currentRole = Rx<UserRole?>(null);
  final RxList<AccessModule> _accessibleModules = <AccessModule>[].obs;
  final RxBool _isInitialized = false.obs;

  // Getters for reactive access to user state
  UserRole? get currentRole => _currentRole.value;
  List<AccessModule> get accessibleModules => _accessibleModules.toList();
  bool get isInitialized => _isInitialized.value;
  bool get hasRole => _currentRole.value != null;

  /// Cache for permission checks to improve performance
  final Map<String, bool> _permissionCache = {};

  @override
  void onInit() {
    super.onInit();
    _initializeRoleService();
  }

  /// Initialize the role service and load current user role
  Future<void> _initializeRoleService() async {
    try {
      Get.log('Initializing RoleAccessService...', isError: false);

      // Load current role from token
      await _loadCurrentRole();

      _isInitialized.value = true;
      Get.log('RoleAccessService initialized successfully', isError: false);
    } catch (e) {
      Get.log('Error initializing RoleAccessService: $e', isError: true);
      _isInitialized.value =
          true; // Still mark as initialized to prevent blocking
    }
  }

  /// Load and set the current user role from JWT token
  Future<void> _loadCurrentRole() async {
    try {
      // Get current token
      final token = await _tokenService.getToken();
      if (token == null) {
        _clearRoleData();
        return;
      }

      // Decode token to extract role
      final decodedToken = _tokenService.decodeToken(token);
      if (decodedToken == null) {
        _clearRoleData();
        return;
      }

      // Extract role from token payload
      final roleString = decodedToken['role'] as String?;
      final role = UserRole.fromString(roleString);

      if (role != null) {
        await _setCurrentRole(role);
        Get.log('User role loaded: ${role.displayName}', isError: false);
      } else {
        Get.log('Invalid role in token: $roleString', isError: true);
        _clearRoleData();
      }
    } catch (e) {
      Get.log('Error loading current role: $e', isError: true);
      _clearRoleData();
    }
  }

  /// Set the current user role and update accessible modules
  Future<void> _setCurrentRole(UserRole role) async {
    _currentRole.value = role;
    _accessibleModules.value = RolePermissions.getModulesForRole(role);
    _clearPermissionCache();

    Get.log(
      'Role set to ${role.displayName} with ${_accessibleModules.length} accessible modules',
      isError: false,
    );
  }

  /// Clear role data (used during logout or when token is invalid)
  void _clearRoleData() {
    _currentRole.value = null;
    _accessibleModules.clear();
    _clearPermissionCache();
    Get.log('Role data cleared', isError: false);
  }

  /// Clear permission cache when role changes
  void _clearPermissionCache() {
    _permissionCache.clear();
  }

  // === Public API Methods ===

  /// Check if current user has access to a specific module
  ///
  /// [moduleName] - Name of the module to check (e.g., 'users', 'students')
  /// Returns true if user has access, false otherwise
  bool hasAccess(String moduleName) {
    if (!hasRole) {
      Get.log('No role assigned, denying access to $moduleName', isError: true);
      return false;
    }

    // Check cache first for performance
    final cacheKey = '${currentRole!.value}_$moduleName';
    if (_permissionCache.containsKey(cacheKey)) {
      return _permissionCache[cacheKey]!;
    }

    // Parse module and check access
    final module = AccessModule.fromString(moduleName);
    if (module == null) {
      Get.log('Invalid module name: $moduleName', isError: true);
      _permissionCache[cacheKey] = false;
      return false;
    }

    final hasAccess = RolePermissions.hasModuleAccess(currentRole!, module);

    // Cache the result
    _permissionCache[cacheKey] = hasAccess;

    Get.log(
      'Access check: ${currentRole!.displayName} -> $moduleName = $hasAccess',
      isError: !hasAccess,
    );

    return hasAccess;
  }

  /// Check if current user can modify a specific module
  ///
  /// [moduleName] - Name of the module to check modification rights
  /// Returns true if user can modify, false otherwise
  bool canModify(String moduleName) {
    if (!hasRole) return false;

    final module = AccessModule.fromString(moduleName);
    if (module == null) return false;

    return RolePermissions.canModify(currentRole!, module);
  }

  /// Check if current user has access to a specific route
  ///
  /// [routePath] - The route path to check (e.g., '/users', '/students')
  /// Returns true if user can access the route, false otherwise
  bool canAccessRoute(String routePath) {
    if (!hasRole) return false;

    // Remove leading slash and extract module name
    final moduleName = routePath.startsWith('/')
        ? routePath.substring(1)
        : routePath;

    return hasAccess(moduleName);
  }

  /// Get navigation menu items for current user role
  /// Returns list of modules that should appear in navigation
  List<AccessModule> getNavigationModules() {
    if (!hasRole) return [];
    return RolePermissions.getNavigationModules(currentRole!);
  }

  /// Check if current user is an admin (super admin or college admin)
  bool get isAdmin => hasRole && currentRole!.isAdmin;

  /// Check if current user is a super admin
  bool get isSuperAdmin => hasRole && currentRole == UserRole.superAdmin;

  /// Check if current user is a college admin
  bool get isCollegeAdmin => hasRole && currentRole == UserRole.collegeAdmin;

  /// Check if current user can manage other users
  bool get canManageUsers => hasRole && currentRole!.canManageUsers;

  /// Check if current user can access system settings
  bool get canAccessSystemSettings =>
      hasRole && currentRole!.canAccessSystemSettings;

  /// Get user-friendly error message for access denial
  String getAccessDeniedMessage(String moduleName) {
    if (!hasRole) {
      return 'You must be signed in to access this feature.';
    }

    final module = AccessModule.fromString(moduleName);
    if (module == null) {
      return 'The requested feature is not available.';
    }

    return 'Your ${currentRole!.displayName} role does not have access to ${module.displayName}.';
  }

  /// Refresh current user role (useful after token refresh)
  Future<void> refreshRole() async {
    Get.log('Refreshing user role...', isError: false);
    await _loadCurrentRole();
  }

  /// Clear role data (used during logout)
  Future<void> clearRole() async {
    Get.log('Clearing role data...', isError: false);
    _clearRoleData();
  }

  /// Handle user logout - clear all role data
  Future<void> logout() async {
    try {
      Get.log('Logging out and clearing role data...', isError: false);

      // Clear token data
      await _tokenService.deleteToken();

      // Clear role data
      _clearRoleData();

      // Navigate to sign-in screen
      Get.offAllNamed('/signin');

      // Show logout message
      Get.snackbar(
        'Signed Out',
        'You have been successfully signed out.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.log('Error during logout: $e', isError: true);
    }
  }

  /// Set role manually (useful for testing or role switching)
  ///
  /// [role] - The role to set
  /// [persistToToken] - Whether to update the stored token (default: false)
  Future<void> setRole(UserRole role, {bool persistToToken = false}) async {
    await _setCurrentRole(role);

    if (persistToToken) {
      // This would require updating the stored token
      // Implementation depends on your backend token structure
      Get.log('Warning: persistToToken not implemented', isError: true);
    }
  }

  /// Validate access with exception throwing for protected operations
  ///
  /// [moduleName] - Module to check access for
  /// Throws [UnauthorizedAccessException] if access is denied
  void validateAccess(String moduleName) {
    if (!hasAccess(moduleName)) {
      throw UnauthorizedAccessException(getAccessDeniedMessage(moduleName));
    }
  }

  /// Get detailed permission info for current user
  Map<String, dynamic> getPermissionInfo() {
    if (!hasRole) {
      return {
        'hasRole': false,
        'role': null,
        'accessibleModules': [],
        'isAdmin': false,
        'canManageUsers': false,
      };
    }

    return {
      'hasRole': true,
      'role': {
        'value': currentRole!.value,
        'displayName': currentRole!.displayName,
        'priority': currentRole!.priority,
      },
      'accessibleModules': _accessibleModules
          .map(
            (m) => {
              'value': m.value,
              'displayName': m.displayName,
              'description': m.description,
            },
          )
          .toList(),
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'isCollegeAdmin': isCollegeAdmin,
      'canManageUsers': canManageUsers,
      'canAccessSystemSettings': canAccessSystemSettings,
    };
  }

  /// Example API calls that automatically include JWT and check permissions

  /// Fetch students with automatic role-based access control
  Future<Map<String, dynamic>> fetchStudents({
    int? page,
    int? limit,
    String? search,
  }) async {
    // Validate access first
    validateAccess('students');

    try {
      final baseApi = Get.find<BaseApiService>();

      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await baseApi.get(
        '/students',
        queryParameters: queryParams,
      );

      Get.log('Students fetched successfully', isError: false);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      Get.log('Error fetching students: $e', isError: true);
      rethrow;
    }
  }

  /// Fetch books with automatic role-based access control
  Future<Map<String, dynamic>> fetchBooks({
    int? page,
    int? limit,
    String? search,
    String? category,
  }) async {
    // Validate access first
    validateAccess('books');

    try {
      final baseApi = Get.find<BaseApiService>();

      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category.isNotEmpty)
        queryParams['category'] = category;

      final response = await baseApi.get(
        '/books',
        queryParameters: queryParams,
      );

      Get.log('Books fetched successfully', isError: false);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      Get.log('Error fetching books: $e', isError: true);
      rethrow;
    }
  }

  /// Fetch users (Super Admin only)
  Future<Map<String, dynamic>> fetchUsers({
    int? page,
    int? limit,
    String? search,
    String? role,
  }) async {
    // Validate access first
    validateAccess('users');

    try {
      final baseApi = Get.find<BaseApiService>();

      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (role != null && role.isNotEmpty) queryParams['role'] = role;

      final response = await baseApi.get(
        '/users',
        queryParameters: queryParams,
      );

      Get.log('Users fetched successfully', isError: false);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      Get.log('Error fetching users: $e', isError: true);
      rethrow;
    }
  }

  /// Fetch colleges (Super Admin only)
  Future<Map<String, dynamic>> fetchColleges({
    int? page,
    int? limit,
    String? search,
  }) async {
    // Validate access first
    validateAccess('colleges');

    try {
      final baseApi = Get.find<BaseApiService>();

      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await baseApi.get(
        '/colleges',
        queryParameters: queryParams,
      );

      Get.log('Colleges fetched successfully', isError: false);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      Get.log('Error fetching colleges: $e', isError: true);
      rethrow;
    }
  }
}

/// Custom exception for unauthorized access attempts
class UnauthorizedAccessException implements Exception {
  final String message;

  const UnauthorizedAccessException(this.message);

  @override
  String toString() => 'UnauthorizedAccessException: $message';
}

/// Extension to add convenience methods to BaseApiService
extension BaseApiServiceExtensions on BaseApiService {
  /// Import the BaseApiService to access this extension
  static BaseApiService get instance => Get.find<BaseApiService>();
}
