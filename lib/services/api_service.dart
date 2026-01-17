import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'base_api_service.dart';

/// Comprehensive API service that integrates all backend endpoints
/// Handles authentication, user management, book management, colleges, and system settings
class ApiService extends GetxService {
  final BaseApiService _baseService = Get.find<BaseApiService>();

  // ===========================================
  // AUTHENTICATION ENDPOINTS
  // ===========================================

  /// Register a new user
  /// POST /api/auth/register
  ///
  /// [userData] - User registration data including email, password, full_name, role, etc.
  /// Returns: User data with JWT token
  Future<Response> registerUser(Map<String, dynamic> userData) async {
    try {
      final response = await _baseService.post(
        'auth/register',
        data: userData,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to register user');
    }
  }

  /// Login user with email and password
  /// POST /api/auth/login
  ///
  /// [email] - User email address
  /// [password] - User password
  /// Returns: User data with JWT token
  Future<Response> loginUser(String email, String password) async {
    try {
      final response = await _baseService.post(
        'auth/login',
        data: {'email': email, 'password': password},
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Login failed');
    }
  }

  /// Get current user profile
  /// GET /api/auth/me
  /// Requires: Authentication
  ///
  /// Returns: Current user profile data
  Future<Response> getCurrentUser() async {
    try {
      final response = await _baseService.get('auth/me');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get user profile');
    }
  }

  /// Refresh JWT token
  /// POST /api/auth/refresh
  /// Requires: Authentication
  ///
  /// Returns: New JWT token
  Future<Response> refreshToken() async {
    try {
      final response = await _baseService.post('auth/refresh');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to refresh token');
    }
  }

  /// Logout user
  /// POST /api/auth/logout
  /// Requires: Authentication
  ///
  /// Returns: Success message
  Future<Response> logoutUser() async {
    try {
      final response = await _baseService.post('auth/logout');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Logout failed');
    }
  }

  // ===========================================
  // USER MANAGEMENT ENDPOINTS
  // ===========================================

  /// Get all users with optional filtering and pagination
  /// GET /api/users
  /// Requires: super_admin or college_admin
  ///
  /// [page] - Page number (default: 1)
  /// [limit] - Items per page (default: 10)
  /// [role] - Filter by role (optional)
  /// [collegeId] - Filter by college (optional)
  /// [search] - Search in full_name or email (optional)
  /// Returns: Paginated list of users
  Future<Response> getAllUsers({
    int page = 1,
    int limit = 10,
    String? role,
    String? collegeId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (role != null) queryParams['role'] = role;
      if (collegeId != null) queryParams['collegeId'] = collegeId;
      if (search != null) queryParams['search'] = search;

      final response = await _baseService.get(
        'users',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get users');
    }
  }

  /// Get user by ID
  /// GET /api/users/:id
  /// Requires: Authentication (own profile or admin)
  ///
  /// [userId] - User ID
  /// Returns: User details
  Future<Response> getUserById(String userId) async {
    try {
      final response = await _baseService.get('users/$userId');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get user');
    }
  }

  /// Update user profile
  /// PUT /api/users/:id
  /// Requires: Authentication (own profile or admin)
  ///
  /// [userId] - User ID
  /// [updateData] - Updated user data
  /// Returns: Updated user data
  Future<Response> updateUser(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _baseService.put(
        'users/$userId',
        data: updateData,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update user');
    }
  }

  /// Change user password
  /// PUT /api/users/:id/password
  /// Requires: Authentication
  ///
  /// [userId] - User ID
  /// [currentPassword] - Current password
  /// [newPassword] - New password
  /// Returns: Success message
  Future<Response> changePassword(
    String userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _baseService.put(
        'users/$userId/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to change password');
    }
  }

  /// Deactivate user
  /// PUT /api/users/:id/deactivate
  /// Requires: super_admin or college_admin
  ///
  /// [userId] - User ID
  /// Returns: Success message
  Future<Response> deactivateUser(String userId) async {
    try {
      final response = await _baseService.put('users/$userId/deactivate');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to deactivate user');
    }
  }

  /// Activate user
  /// PUT /api/users/:id/activate
  /// Requires: super_admin or college_admin
  ///
  /// [userId] - User ID
  /// Returns: Success message
  Future<Response> activateUser(String userId) async {
    try {
      final response = await _baseService.put('users/$userId/activate');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to activate user');
    }
  }

  // ===========================================
  // BOOK MANAGEMENT ENDPOINTS
  // ===========================================

  /// Get books with optional filtering
  /// GET /api/books
  /// Requires: Authentication
  ///
  /// [category] - Filter by category (optional)
  /// [year] - Filter by academic year (optional)
  /// [semester] - Filter by semester (optional)
  /// Returns: List of books
  Future<Response> getBooks({
    String? category,
    int? year,
    int? semester,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (category != null) queryParams['category'] = category;
      if (year != null) queryParams['year'] = year;
      if (semester != null) queryParams['semester'] = semester;

      final response = await _baseService.get(
        'books',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get books');
    }
  }

  /// Get single book by ID
  /// GET /api/books/:bookId
  /// Requires: Authentication
  ///
  /// [bookId] - Book ID
  /// Returns: Book details
  Future<Response> getBookById(String bookId) async {
    try {
      final response = await _baseService.get('books/$bookId');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get book');
    }
  }

  /// Create new book
  /// POST /api/books
  /// Requires: super_admin or college_admin
  ///
  /// [bookData] - Book metadata
  /// Returns: Created book data
  Future<Response> createBook(Map<String, dynamic> bookData) async {
    try {
      final response = await _baseService.post('books', data: bookData);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to create book');
    }
  }

  /// Update book
  /// PUT /api/books/:bookId
  /// Requires: super_admin or college_admin
  ///
  /// [bookId] - Book ID
  /// [updateData] - Updated book data
  /// Returns: Updated book data
  Future<Response> updateBook(
    String bookId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _baseService.put(
        'books/$bookId',
        data: updateData,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update book');
    }
  }

  /// Delete book
  /// DELETE /api/books/:bookId
  /// Requires: super_admin or college_admin
  ///
  /// [bookId] - Book ID
  /// Returns: Success message
  Future<Response> deleteBook(String bookId) async {
    try {
      final response = await _baseService.delete('books/$bookId');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to delete book');
    }
  }

  /// Upload book PDF file
  /// POST /api/books/:bookId/upload-pdf
  /// Requires: super_admin or college_admin
  ///
  /// [bookId] - Book ID
  /// [filePath] - PDF file path (mobile/desktop) or null (web)
  /// [fileBytes] - PDF file bytes (web) or null (mobile/desktop)
  /// [fileName] - File name (required for web)
  /// Returns: Upload success with PDF URLs
  Future<Response> uploadBookPdf(
    String bookId,
    String? filePath, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      final response = await _baseService.uploadFile(
        'books/$bookId/upload-pdf',
        filePath ?? '',
        'book',
        fileBytes: fileBytes,
        fileName: fileName,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to upload book PDF');
    }
  }

  /// Upload book cover image
  /// POST /api/books/:bookId/upload-cover
  /// Requires: super_admin or college_admin
  ///
  /// [bookId] - Book ID
  /// [filePath] - Image file path (mobile/desktop) or null (web)
  /// [fileBytes] - Image file bytes (web) or null (mobile/desktop)
  /// [fileName] - File name (required for web)
  /// Returns: Upload success with cover image URL
  Future<Response> uploadBookCover(
    String bookId,
    String? filePath, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      final response = await _baseService.uploadFile(
        'books/$bookId/upload-cover',
        filePath ?? '',
        'cover',
        fileBytes: fileBytes,
        fileName: fileName,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to upload book cover');
    }
  }

  /// Log book access (view or download)
  /// POST /api/books/:bookId/access
  /// Requires: Authentication
  ///
  /// [bookId] - Book ID
  /// [accessType] - Type of access ('view' or 'download')
  /// Returns: Success message
  Future<Response> logBookAccess(String bookId, String accessType) async {
    try {
      final response = await _baseService.post(
        'books/$bookId/access',
        data: {'access_type': accessType},
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to log book access');
    }
  }

  /// Search books
  /// GET /api/books/search/:query
  /// Requires: Authentication
  ///
  /// [query] - Search query
  /// Returns: List of matching books
  Future<Response> searchBooks(String query) async {
    try {
      final response = await _baseService.get('books/search/$query');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to search books');
    }
  }

  /// Get books by category
  /// GET /api/books/category/:category
  /// Requires: Authentication
  ///
  /// [category] - Book category
  /// Returns: List of books in category
  Future<Response> getBooksByCategory(String category) async {
    try {
      final response = await _baseService.get('books/category/$category');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get books by category');
    }
  }

  /// Get books by year
  /// GET /api/books/year/:year
  /// Requires: super_admin or college_admin
  ///
  /// [year] - Academic year
  /// Returns: List of books for the year
  Future<Response> getBooksByYear(int year) async {
    try {
      final response = await _baseService.get('books/year/$year');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get books by year');
    }
  }

  /// Get books by semester
  /// GET /api/books/semester/:semester
  /// Requires: super_admin or college_admin
  ///
  /// [semester] - Semester number
  /// Returns: List of books for the semester
  Future<Response> getBooksBySemester(int semester) async {
    try {
      final response = await _baseService.get('books/semester/$semester');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get books by semester');
    }
  }

  /// Get books by year and semester
  /// GET /api/books/year/:year/semester/:semester
  /// Requires: super_admin or college_admin
  ///
  /// [year] - Academic year
  /// [semester] - Semester number
  /// Returns: List of books for the year and semester
  Future<Response> getBooksByYearAndSemester(int year, int semester) async {
    try {
      final response = await _baseService.get(
        'books/year/$year/semester/$semester',
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get books by year and semester');
    }
  }

  /// Get student's books (for current student)
  /// GET /api/books/my-books
  /// Requires: student role
  ///
  /// Returns: List of books available to the student
  Future<Response> getMyBooks() async {
    try {
      final response = await _baseService.get('books/my-books');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get student books');
    }
  }

  /// Get user's books (for individual users)
  /// GET /api/books/user-books
  /// Requires: user role
  ///
  /// Returns: List of all books accessible to user
  Future<Response> getUserBooks() async {
    try {
      final response = await _baseService.get('books/user-books');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get user books');
    }
  }

  // ===========================================
  // COLLEGE MANAGEMENT ENDPOINTS
  // ===========================================

  /// Get all colleges with optional filtering and pagination
  /// GET /api/colleges
  ///
  /// [page] - Page number (optional)
  /// [limit] - Items per page (optional)
  /// [search] - Search query (optional)
  /// [status] - Filter by status (optional)
  /// Returns: Paginated list of colleges
  Future<Response> getAllColleges({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null) queryParams['search'] = search;
      if (status != null) queryParams['status'] = status;

      final response = await _baseService.get(
        'colleges',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get colleges');
    }
  }

  /// Get college by ID
  /// GET /api/colleges/:id
  ///
  /// [collegeId] - College ID
  /// Returns: College details
  Future<Response> getCollegeById(String collegeId) async {
    try {
      final response = await _baseService.get('colleges/$collegeId');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get college');
    }
  }

  /// Create new college
  /// POST /api/colleges
  /// Requires: super_admin
  ///
  /// [collegeData] - College data
  /// Returns: Created college data
  Future<Response> createCollege(Map<String, dynamic> collegeData) async {
    try {
      final response = await _baseService.post(
        'colleges',
        data: collegeData,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to create college');
    }
  }

  /// Update college
  /// PUT /api/colleges/:id
  /// Requires: super_admin or college_admin (own college)
  ///
  /// [collegeId] - College ID
  /// [updateData] - Updated college data
  /// Returns: Updated college data
  Future<Response> updateCollege(
    String collegeId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _baseService.put(
        'colleges/$collegeId',
        data: updateData,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update college');
    }
  }

  /// Get college statistics
  /// GET /api/colleges/:id/stats
  /// Requires: super_admin or college_admin
  ///
  /// [collegeId] - College ID
  /// Returns: College statistics including users, books, etc.
  Future<Response> getCollegeStats(String collegeId) async {
    try {
      final response = await _baseService.get('colleges/$collegeId/stats');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get college statistics');
    }
  }

  /// Get college users
  /// GET /api/colleges/:id/users
  /// Requires: super_admin or college_admin
  ///
  /// [collegeId] - College ID
  /// [page] - Page number (optional)
  /// [limit] - Items per page (optional)
  /// [role] - Filter by role (optional)
  /// Returns: Paginated list of college users
  Future<Response> getCollegeUsers(
    String collegeId, {
    int page = 1,
    int limit = 20,
    String? role,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (role != null) queryParams['role'] = role;

      final response = await _baseService.get(
        'colleges/$collegeId/users',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get college users');
    }
  }

  /// Get college books
  /// GET /api/colleges/:id/books
  ///
  /// [collegeId] - College ID
  /// [page] - Page number (optional)
  /// [limit] - Items per page (optional)
  /// [category] - Filter by category (optional)
  /// Returns: Paginated list of college books
  Future<Response> getCollegeBooks(
    String collegeId, {
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (category != null) queryParams['category'] = category;

      final response = await _baseService.get(
        'colleges/$collegeId/books',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get college books');
    }
  }

  // ===========================================
  // INDIVIDUAL USERS MANAGEMENT ENDPOINTS
  // ===========================================

  /// Get all individual users
  /// GET /api/individual-users
  /// Requires: super_admin
  ///
  /// [page] - Page number (optional)
  /// [limit] - Items per page (optional)
  /// [search] - Search query (optional)
  /// Returns: Paginated list of individual users
  Future<Response> getAllIndividualUsers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null) queryParams['search'] = search;

      final response = await _baseService.get(
        'individual-users',
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get individual users');
    }
  }

  /// Get individual user by ID
  /// GET /api/individual-users/:id
  /// Requires: super_admin
  ///
  /// [userId] - User ID
  /// Returns: Individual user details
  Future<Response> getIndividualUserById(String userId) async {
    try {
      final response = await _baseService.get('individual-users/$userId');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get individual user');
    }
  }

  /// Create individual user
  /// POST /api/individual-users
  /// Requires: super_admin
  ///
  /// [userData] - Individual user data
  /// Returns: Created user data
  Future<Response> createIndividualUser(Map<String, dynamic> userData) async {
    try {
      final response = await _baseService.post(
        'individual-users',
        data: userData,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to create individual user');
    }
  }

  /// Update individual user
  /// PUT /api/individual-users/:id
  /// Requires: super_admin
  ///
  /// [userId] - User ID
  /// [updateData] - Updated user data
  /// Returns: Updated user data
  Future<Response> updateIndividualUser(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _baseService.put(
        'individual-users/$userId',
        data: updateData,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update individual user');
    }
  }

  /// Change individual user password
  /// PUT /api/individual-users/:id/password
  /// Requires: super_admin
  ///
  /// [userId] - User ID
  /// [newPassword] - New password
  /// Returns: Success message
  Future<Response> changeIndividualUserPassword(
    String userId,
    String newPassword,
  ) async {
    try {
      final response = await _baseService.put(
        'individual-users/$userId/password',
        data: {'newPassword': newPassword},
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to change individual user password');
    }
  }

  /// Deactivate individual user
  /// PUT /api/individual-users/:id/deactivate
  /// Requires: super_admin
  ///
  /// [userId] - User ID
  /// Returns: Success message
  Future<Response> deactivateIndividualUser(String userId) async {
    try {
      final response = await _baseService.put(
        'individual-users/$userId/deactivate',
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to deactivate individual user');
    }
  }

  /// Activate individual user
  /// PUT /api/individual-users/:id/activate
  /// Requires: super_admin
  ///
  /// [userId] - User ID
  /// Returns: Success message
  Future<Response> activateIndividualUser(String userId) async {
    try {
      final response = await _baseService.put(
        'individual-users/$userId/activate',
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to activate individual user');
    }
  }

  /// Delete individual user
  /// DELETE /api/individual-users/:id
  /// Requires: super_admin
  ///
  /// [userId] - User ID
  /// Returns: Success message
  Future<Response> deleteIndividualUser(String userId) async {
    try {
      final response = await _baseService.delete(
        'individual-users/$userId',
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to delete individual user');
    }
  }

  // ===========================================
  // SYSTEM SETTINGS ENDPOINTS
  // ===========================================

  /// Get all system settings
  /// GET /api/system-settings
  /// Requires: super_admin
  ///
  /// Returns: List of all system settings
  Future<Response> getAllSystemSettings() async {
    try {
      final response = await _baseService.get('system-settings');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get system settings');
    }
  }

  /// Get public system settings
  /// GET /api/system-settings/public
  /// No authentication required
  ///
  /// Returns: List of public system settings
  Future<Response> getPublicSystemSettings() async {
    try {
      final response = await _baseService.get('system-settings/public');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get public system settings');
    }
  }

  /// Get setting by key
  /// GET /api/system-settings/:key
  /// Requires: super_admin
  ///
  /// [key] - Setting key
  /// Returns: Setting details
  Future<Response> getSystemSettingByKey(String key) async {
    try {
      final response = await _baseService.get('system-settings/$key');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get system setting');
    }
  }

  /// Create or update system setting
  /// PUT /api/system-settings/:key
  /// Requires: super_admin
  ///
  /// [key] - Setting key
  /// [value] - Setting value
  /// [description] - Setting description (optional)
  /// [isPublic] - Whether setting is public (optional)
  /// Returns: Updated setting data
  Future<Response> updateSystemSetting(
    String key,
    String value, {
    String? description,
    bool? isPublic,
  }) async {
    try {
      final data = <String, dynamic>{'value': value};

      if (description != null) data['description'] = description;
      if (isPublic != null) data['is_public'] = isPublic;

      final response = await _baseService.put(
        'system-settings/$key',
        data: data,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update system setting');
    }
  }

  /// Delete system setting
  /// DELETE /api/system-settings/:key
  /// Requires: super_admin
  ///
  /// [key] - Setting key
  /// Returns: Success message
  Future<Response> deleteSystemSetting(String key) async {
    try {
      final response = await _baseService.delete('system-settings/$key');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to delete system setting');
    }
  }

  /// Bulk update system settings
  /// POST /api/system-settings/bulk-update
  /// Requires: super_admin
  ///
  /// [settings] - List of settings to update
  /// Returns: Updated settings
  Future<Response> bulkUpdateSystemSettings(
    List<Map<String, dynamic>> settings,
  ) async {
    try {
      final response = await _baseService.post(
        'system-settings/bulk-update',
        data: {'settings': settings},
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to bulk update system settings');
    }
  }

  /// Get setting history
  /// GET /api/system-settings/:key/history
  /// Requires: super_admin
  ///
  /// [key] - Setting key
  /// Returns: Setting change history
  Future<Response> getSystemSettingHistory(String key) async {
    try {
      final response = await _baseService.get(
        'system-settings/$key/history',
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get system setting history');
    }
  }

  // ===========================================
  // HEALTH & UTILITY ENDPOINTS
  // ===========================================

  /// Health check endpoint
  /// GET /health
  /// No authentication required
  ///
  /// Returns: API health status
  Future<Response> healthCheck() async {
    try {
      final response = await _baseService.get('/health');
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Health check failed');
    }
  }

  // ===========================================
  // ERROR HANDLING
  // ===========================================

  /// Handle Dio errors with custom error messages
  ///
  /// [error] - DioException to handle
  /// [defaultMessage] - Default error message
  /// Returns: Formatted error message
  String _handleDioError(DioException error, String defaultMessage) {
    String message = defaultMessage;

    if (error.response?.data != null) {
      // Try to extract error message from response
      final responseData = error.response!.data;
      if (responseData is Map<String, dynamic>) {
        message = responseData['message'] ?? defaultMessage;
      }
    }

    // Add status code to error message
    if (error.response?.statusCode != null) {
      message = '[${error.response!.statusCode}] $message';
    }

    Get.log('API Error: $message', isError: true);
    return message;
  }
}
