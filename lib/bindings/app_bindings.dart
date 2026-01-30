import 'package:academixstore_admin_n_subadmin/modules/books/controller/books_controller.dart';
import 'package:academixstore_admin_n_subadmin/modules/colleges/controller/colleges_controller.dart';
import 'package:get/get.dart';
import '../services/token_service.dart';
import '../services/base_api_service.dart';
import '../services/role_access_service.dart';
import '../services/dashboard_api_service.dart';
import '../services/api/books_api_service.dart';
import '../services/api/question_papers_api_service.dart';
import '../services/file_validation_service.dart';
import '../modules/auth/controller/auth_controller.dart'; // Updated import path

/// Initial bindings that are loaded when the app starts
/// Sets up all core services and controllers that should be available throughout the app
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.log('Initializing app dependencies...', isError: false);

    // === Core Services ===
    // These services are instantiated immediately and persist throughout the app lifecycle

    // Token service for JWT management - highest priority
    Get.put<TokenService>(
      TokenService(),
      permanent: true, // Keeps service alive throughout app lifecycle
    );

    // Base API service - depends on TokenService
    Get.put<BaseApiService>(BaseApiService(), permanent: true);

    // Role access service - depends on TokenService and BaseApiService
    Get.put<RoleAccessService>(RoleAccessService(), permanent: true);

    // Dashboard API service - extends base API service
    Get.put<DashboardApiService>(DashboardApiService(), permanent: true);

    // Books API service - manages book-related operations
    Get.put<BooksApiService>(BooksApiService(), permanent: true);

    // Question Papers API service - manages question paper operations
    Get.put<QuestionPapersApiService>(
      QuestionPapersApiService(),
      permanent: true,
    );

    // File Validation service - validates file uploads
    Get.put<FileValidationService>(
      FileValidationService(),
      permanent: true,
    );

    // === Core Controllers ===
    // Authentication controller - manages app-wide auth state
    Get.put<AuthController>(AuthController(), permanent: true);

    Get.log('App dependencies initialized successfully', isError: false);

    Get.put(BooksController());
    Get.put(CollegesController());
  }
}

/// Lazy bindings for dashboard-related features
/// These are loaded only when needed to improve app startup performance
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.log('Loading dashboard dependencies...', isError: false);

    // Dashboard controller (lazy-loaded)
    Get.lazyPut<DashboardController>(
      () => DashboardController(),
      fenix: true, // Recreate if disposed
    );
    Get.lazyPut<AuthController>(() => AuthController());
    Get.log('Dashboard dependencies loaded', isError: false);
  }
}

/// Lazy bindings for user management features
class UserManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.log('Loading user management dependencies...', isError: false);

    // User management controller (lazy-loaded)
    Get.lazyPut<UserManagementController>(
      () => UserManagementController(),
      fenix: true,
    );

    Get.log('User management dependencies loaded', isError: false);
  }
}

/// Lazy bindings for student management features
class StudentManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.log('Loading student management dependencies...', isError: false);

    // Student management controller (lazy-loaded)
    Get.lazyPut<StudentManagementController>(
      () => StudentManagementController(),
      fenix: true,
    );

    Get.log('Student management dependencies loaded', isError: false);
  }
}

/// Lazy bindings for college management features
class CollegeManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.log('Loading college management dependencies...', isError: false);

    // College management controller (lazy-loaded)
    Get.lazyPut<CollegeManagementController>(
      () => CollegeManagementController(),
      fenix: true,
    );

    Get.log('College management dependencies loaded', isError: false);
  }
}

/// Lazy bindings for auth logs features
class AuthLogsBinding extends Bindings {
  @override
  void dependencies() {
    Get.log('Loading auth logs dependencies...', isError: false);

    // Auth logs controller (lazy-loaded)
    Get.lazyPut<AuthLogsController>(() => AuthLogsController(), fenix: true);

    Get.log('Auth logs dependencies loaded', isError: false);
  }
}

// === Example Controllers ===
// These are example controllers that would be implemented in your modules

/// Dashboard controller for managing dashboard state
class DashboardController extends GetxController {
  final DashboardApiService _apiService = Get.find<DashboardApiService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observable state
  final RxBool isLoading = false.obs;
  final Rx<DashboardStats?> stats = Rx<DashboardStats?>(null);
  final RxList<DashboardActivity> recentActivities = <DashboardActivity>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Load dashboard data
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;

      // Check authentication first
      if (!await _authController.checkAuthenticationAndRedirect()) {
        return;
      }

      // Load dashboard stats and activities in parallel
      final results = await Future.wait([
        _apiService.getDashboardStats(),
        _apiService.getRecentActivities(limit: 10),
      ]);

      stats.value = results[0] as DashboardStats?;
      recentActivities.value = results[1] as List<DashboardActivity>;

      Get.log('Dashboard data loaded successfully', isError: false);
    } catch (e) {
      Get.log('Error loading dashboard data: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh dashboard data
  Future<void> refreshData() async {
    await loadDashboardData();
  }
}

/// User management controller
class UserManagementController extends GetxController {
  final DashboardApiService _apiService = Get.find<DashboardApiService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxList<UserSummary> users = <UserSummary>[].obs;
  final RxInt totalCount = 0.obs;
  final RxInt currentPage = 1.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  /// Load users with pagination
  Future<void> loadUsers({int page = 1}) async {
    try {
      isLoading.value = true;

      if (!await _authController.checkAuthenticationAndRedirect()) {
        return;
      }

      final response = await _apiService.getUsers(
        page: page,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      if (response != null) {
        users.value = response.users;
        totalCount.value = response.totalCount;
        currentPage.value = response.currentPage;
      }
    } catch (e) {
      Get.log('Error loading users: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// Search users
  Future<void> searchUsers(String query) async {
    searchQuery.value = query;
    await loadUsers(page: 1);
  }

  /// Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      final success = await _apiService.updateUserStatus(userId, status);
      if (success) {
        await loadUsers(page: currentPage.value); // Refresh current page
      }
    } catch (e) {
      Get.log('Error updating user status: $e', isError: true);
    }
  }
}

/// Student management controller
class StudentManagementController extends GetxController {
  final DashboardApiService _apiService = Get.find<DashboardApiService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxList<StudentSummary> students = <StudentSummary>[].obs;
  final RxList<College> colleges = <College>[].obs;
  final RxInt totalCount = 0.obs;
  final RxInt currentPage = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  /// Load initial data (students and colleges)
  Future<void> loadInitialData() async {
    await Future.wait([loadStudents(), loadColleges()]);
  }

  /// Load students with pagination
  Future<void> loadStudents({int page = 1}) async {
    try {
      isLoading.value = true;

      if (!await _authController.checkAuthenticationAndRedirect()) {
        return;
      }

      final response = await _apiService.getStudents(page: page);

      if (response != null) {
        students.value = response.students;
        totalCount.value = response.totalCount;
        currentPage.value = response.currentPage;
      }
    } catch (e) {
      Get.log('Error loading students: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// Load colleges list
  Future<void> loadColleges() async {
    try {
      colleges.value = await _apiService.getColleges();
    } catch (e) {
      Get.log('Error loading colleges: $e', isError: true);
    }
  }
}

/// College management controller
class CollegeManagementController extends GetxController {
  final DashboardApiService _apiService = Get.find<DashboardApiService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxList<College> colleges = <College>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadColleges();
  }

  /// Load colleges
  Future<void> loadColleges() async {
    try {
      isLoading.value = true;

      if (!await _authController.checkAuthenticationAndRedirect()) {
        return;
      }

      colleges.value = await _apiService.getColleges();
    } catch (e) {
      Get.log('Error loading colleges: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}

/// Auth logs controller
class AuthLogsController extends GetxController {
  final DashboardApiService _apiService = Get.find<DashboardApiService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxList<AuthLog> logs = <AuthLog>[].obs;
  final RxInt totalCount = 0.obs;
  final RxInt currentPage = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadAuthLogs();
  }

  /// Load auth logs with pagination
  Future<void> loadAuthLogs({int page = 1}) async {
    try {
      isLoading.value = true;

      if (!await _authController.checkAuthenticationAndRedirect()) {
        return;
      }

      final response = await _apiService.getAuthLogs(page: page);

      if (response != null) {
        logs.value = response.logs;
        totalCount.value = response.totalCount;
        currentPage.value = response.currentPage;
      }
    } catch (e) {
      Get.log('Error loading auth logs: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
