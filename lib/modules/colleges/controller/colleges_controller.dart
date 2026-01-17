import 'package:get/get.dart';
import '../model/college.dart';
import '../../../services/api_service.dart';
import '../../../services/role_access_service.dart';

/// Colleges controller managing college operations
/// Integrates with the centralized ApiService for all API operations
class CollegesController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final RoleAccessService _roleAccessService = Get.find<RoleAccessService>();

  // Observable variables
  final RxList<College> _colleges = <College>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxInt _currentPage = 1.obs;
  final RxInt _totalItems = 0.obs;
  final RxInt _totalPages = 0.obs;
  final Rx<CollegeFilters> _filters = const CollegeFilters().obs;

  // Getters
  List<College> get colleges => _colleges.toList();
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  int get currentPage => _currentPage.value;
  int get totalItems => _totalItems.value;
  int get totalPages => _totalPages.value;
  CollegeFilters get filters => _filters.value;
  bool get hasColleges => _colleges.isNotEmpty;
  bool get hasError => _error.value.isNotEmpty;
  RoleAccessService get roleAccessService => _roleAccessService;

  static const int itemsPerPage = 10;

  @override
  void onInit() {
    super.onInit();
    Get.log('CollegesController initialized', isError: false);
  }

  @override
  void onReady() {
    super.onReady();
    loadColleges();
  }

  /// Load colleges with pagination and filters
  Future<void> loadColleges({bool refresh = false}) async {
    if (refresh) {
      _currentPage.value = 1;
      _colleges.clear();
      _error.value = '';
    }

    if (_isLoading.value) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.getAllColleges(
        page: _currentPage.value,
        limit: itemsPerPage,
        search: _filters.value.search,
        status: _filters.value.status,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final collegesData = (data['colleges'] ?? data) as List<dynamic>;
        final newColleges = collegesData
            .map((json) => College.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh || _currentPage.value == 1) {
          _colleges.value = newColleges;
        } else {
          _colleges.addAll(newColleges);
        }

        final pagination = data['pagination'] as Map<String, dynamic>?;
        _totalItems.value = pagination?['total'] as int? ?? newColleges.length;
        _totalPages.value =
            pagination?['totalPages'] as int? ?? _currentPage.value;

        Get.log(
          'Loaded ${newColleges.length} colleges (page ${_currentPage.value})',
          isError: false,
        );
      } else {
        _error.value = response.data['message'] ?? 'Failed to load colleges';
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error loading colleges: $e', isError: true);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get college by ID
  Future<College?> getCollege(String collegeId) async {
    try {
      final response = await _apiService.getCollegeById(collegeId);
      if (response.data['success'] == true) {
        return College.fromJson(response.data['data']);
      }
    } catch (e) {
      Get.log('Error getting college: $e', isError: true);
    }
    return null;
  }

  /// Create new college (super_admin only)
  Future<bool> createCollege(Map<String, dynamic> collegeData) async {
    if (!_roleAccessService.canModify('colleges')) {
      _showAccessDeniedError('create colleges');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.createCollege(collegeData);

      if (response.data['success'] == true) {
        final newCollege = College.fromJson(response.data['data']);
        _colleges.insert(0, newCollege);
        _totalItems.value++;

        Get.snackbar(
          'Success',
          'College "${newCollege.name}" created successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to create college';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error creating college: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update college
  Future<bool> updateCollege(
    String collegeId,
    Map<String, dynamic> collegeData,
  ) async {
    if (!_roleAccessService.canModify('colleges')) {
      _showAccessDeniedError('update colleges');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.updateCollege(collegeId, collegeData);

      if (response.data['success'] == true) {
        final updatedCollege = College.fromJson(response.data['data']);
        final index = _colleges.indexWhere((c) => c.id == collegeId);

        if (index != -1) {
          _colleges[index] = updatedCollege;
        }

        Get.snackbar(
          'Success',
          'College "${updatedCollege.name}" updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to update college';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error updating college: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get college statistics
  Future<Map<String, dynamic>?> getCollegeStats(String collegeId) async {
    try {
      final response = await _apiService.getCollegeStats(collegeId);
      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      Get.log('Error getting college stats: $e', isError: true);
    }
    return null;
  }

  /// Get college users
  Future<List<dynamic>> getCollegeUsers(
    String collegeId, {
    int page = 1,
    int limit = 20,
    String? role,
  }) async {
    try {
      final response = await _apiService.getCollegeUsers(
        collegeId,
        page: page,
        limit: limit,
        role: role,
      );
      if (response.data['success'] == true) {
        final data = response.data['data'];
        return (data['users'] ?? data) as List<dynamic>;
      }
    } catch (e) {
      Get.log('Error getting college users: $e', isError: true);
    }
    return [];
  }

  /// Get college books
  Future<List<dynamic>> getCollegeBooks(
    String collegeId, {
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    try {
      final response = await _apiService.getCollegeBooks(
        collegeId,
        page: page,
        limit: limit,
        category: category,
      );
      if (response.data['success'] == true) {
        final data = response.data['data'];
        return (data['books'] ?? data) as List<dynamic>;
      }
    } catch (e) {
      Get.log('Error getting college books: $e', isError: true);
    }
    return [];
  }

  /// Apply filters
  Future<void> applyFilters(CollegeFilters newFilters) async {
    _filters.value = newFilters;
    await loadColleges(refresh: true);
  }

  /// Search colleges
  Future<void> searchColleges(String query) async {
    _filters.value = _filters.value.copyWith(search: query);
    await loadColleges(refresh: true);
  }

  /// Refresh colleges list
  Future<void> refreshColleges() async {
    await loadColleges(refresh: true);
  }

  /// Clear error
  void clearError() {
    _error.value = '';
  }

  /// Show access denied error
  void _showAccessDeniedError(String action) {
    Get.snackbar(
      'Access Denied',
      'You don\'t have permission to $action.',
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
      return 'Colleges service not found. Please contact support.';
    }

    if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  @override
  void onClose() {
    Get.log('CollegesController disposed', isError: false);
    super.onClose();
  }
}


