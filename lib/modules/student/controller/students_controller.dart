import 'package:get/get.dart';
import '../model/student.dart';
import '../../../services/api_service.dart';
import '../../../services/role_access_service.dart';

/// Students controller managing student operations
/// Students are users with role='student' in the system
class StudentsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final RoleAccessService _roleAccessService = Get.find<RoleAccessService>();

  // Observable variables
  final RxList<Student> _students = <Student>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxInt _currentPage = 1.obs;
  final RxInt _totalItems = 0.obs;
  final RxInt _totalPages = 0.obs;
  final Rx<StudentFilters> _filters = const StudentFilters().obs;

  // Getters
  List<Student> get students => _students.toList();
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  int get currentPage => _currentPage.value;
  int get totalItems => _totalItems.value;
  int get totalPages => _totalPages.value;
  StudentFilters get filters => _filters.value;
  bool get hasStudents => _students.isNotEmpty;
  bool get hasError => _error.value.isNotEmpty;
  RoleAccessService get roleAccessService => _roleAccessService;

  static const int itemsPerPage = 20;

  @override
  void onInit() {
    super.onInit();
    Get.log('StudentsController initialized', isError: false);
  }

  @override
  void onReady() {
    super.onReady();
    loadStudents();
  }

  /// Load students (users with role='student')
  Future<void> loadStudents({bool refresh = false}) async {
    if (refresh) {
      _currentPage.value = 1;
      _students.clear();
      _error.value = '';
    }

    if (_isLoading.value) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      // Get users with role='student'
      final response = await _apiService.getAllUsers(
        page: _currentPage.value,
        limit: itemsPerPage,
        role: 'student',
        search: _filters.value.search,
        collegeId: _filters.value.collegeId,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final usersData = (data['users'] ?? data) as List<dynamic>;
        final newStudents = usersData
            .map((json) => Student.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh || _currentPage.value == 1) {
          _students.value = newStudents;
        } else {
          _students.addAll(newStudents);
        }

        final pagination = data['pagination'] as Map<String, dynamic>?;
        _totalItems.value = pagination?['total'] as int? ?? newStudents.length;
        _totalPages.value =
            pagination?['totalPages'] as int? ?? _currentPage.value;

        Get.log(
          'Loaded ${newStudents.length} students (page ${_currentPage.value})',
          isError: false,
        );
      } else {
        _error.value = response.data['message'] ?? 'Failed to load students';
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error loading students: $e', isError: true);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get student by ID
  Future<Student?> getStudent(String studentId) async {
    try {
      final response = await _apiService.getUserById(studentId);
      if (response.data['success'] == true) {
        return Student.fromJson(response.data['data']);
      }
    } catch (e) {
      Get.log('Error getting student: $e', isError: true);
    }
    return null;
  }

  /// Register new student
  Future<bool> registerStudent(Map<String, dynamic> studentData) async {
    if (!_roleAccessService.canModify('students')) {
      _showAccessDeniedError('register students');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      // Ensure role is set to 'student'
      studentData['role'] = 'student';

      final response = await _apiService.registerUser(studentData);

      if (response.data['success'] == true) {
        final newStudent = Student.fromJson(
          response.data['data']['user'] as Map<String, dynamic>,
        );
        _students.insert(0, newStudent);
        _totalItems.value++;

        Get.snackbar(
          'Success',
          'Student "${newStudent.fullName}" registered successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to register student';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error registering student: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update student
  Future<bool> updateStudent(
    String studentId,
    Map<String, dynamic> studentData,
  ) async {
    if (!_roleAccessService.canModify('students')) {
      _showAccessDeniedError('update students');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.updateUser(studentId, studentData);

      if (response.data['success'] == true) {
        final updatedStudent = Student.fromJson(response.data['data']);
        final index = _students.indexWhere((s) => s.id == studentId);

        if (index != -1) {
          _students[index] = updatedStudent;
        }

        Get.snackbar(
          'Success',
          'Student "${updatedStudent.fullName}" updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to update student';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error updating student: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Activate student
  Future<bool> activateStudent(String studentId) async {
    if (!_roleAccessService.canModify('students')) {
      _showAccessDeniedError('activate students');
      return false;
    }

    try {
      final response = await _apiService.activateUser(studentId);

      if (response.data['success'] == true) {
        final index = _students.indexWhere((s) => s.id == studentId);
        if (index != -1) {
          _students[index] = _students[index].copyWith(isActive: true);
        }

        Get.snackbar(
          'Success',
          'Student activated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      }
      return false;
    } catch (e) {
      Get.log('Error activating student: $e', isError: true);
      return false;
    }
  }

  /// Deactivate student
  Future<bool> deactivateStudent(String studentId) async {
    if (!_roleAccessService.canModify('students')) {
      _showAccessDeniedError('deactivate students');
      return false;
    }

    try {
      final response = await _apiService.deactivateUser(studentId);

      if (response.data['success'] == true) {
        final index = _students.indexWhere((s) => s.id == studentId);
        if (index != -1) {
          _students[index] = _students[index].copyWith(isActive: false);
        }

        Get.snackbar(
          'Success',
          'Student deactivated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      }
      return false;
    } catch (e) {
      Get.log('Error deactivating student: $e', isError: true);
      return false;
    }
  }

  /// Change student password
  Future<bool> changeStudentPassword(
    String studentId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _apiService.changePassword(
        studentId,
        currentPassword,
        newPassword,
      );

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
      Get.log('Error changing student password: $e', isError: true);
      return false;
    }
  }

  /// Get student's books
  Future<List<dynamic>> getStudentBooks() async {
    try {
      final response = await _apiService.getMyBooks();
      if (response.data['success'] == true) {
        final data = response.data['data'];
        return (data['books'] ?? data) as List<dynamic>;
      }
    } catch (e) {
      Get.log('Error getting student books: $e', isError: true);
    }
    return [];
  }

  /// Apply filters
  Future<void> applyFilters(StudentFilters newFilters) async {
    _filters.value = newFilters;
    await loadStudents(refresh: true);
  }

  /// Search students
  Future<void> searchStudents(String query) async {
    _filters.value = _filters.value.copyWith(search: query);
    await loadStudents(refresh: true);
  }

  /// Filter by college
  Future<void> filterByCollege(String? collegeId) async {
    _filters.value = _filters.value.copyWith(collegeId: collegeId);
    await loadStudents(refresh: true);
  }

  /// Refresh students list
  Future<void> refreshStudents() async {
    await loadStudents(refresh: true);
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
      return 'Students service not found. Please contact support.';
    }

    if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  @override
  void onClose() {
    Get.log('StudentsController disposed', isError: false);
    super.onClose();
  }
}


