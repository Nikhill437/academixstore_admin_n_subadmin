import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../base_api_service.dart';

/// Book Management Controller Service
/// Handles all book management API calls
/// Based on API Documentation: Book Management Routes
class BookController extends GetxService {
  final BaseApiService _baseService = Get.find<BaseApiService>();

  // ===========================================
  // BOOK MANAGEMENT ENDPOINTS
  // ===========================================

  /// Get books with optional filters
  /// GET /api/books
  /// Requires: Authentication
  ///
  /// Query Parameters:
  /// - [category]: Filter by category (optional)
  /// - [year]: Filter by academic year (optional)
  /// - [semester]: Filter by semester (optional)
  ///
  /// Returns: List of books with PDF URLs
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
        'api/books',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Get books failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get single book by ID
  /// GET /api/books/:bookId
  /// Requires: Authentication
  ///
  /// [bookId]: Book ID
  /// Returns: Complete book details
  Future<Response> getBookById(String bookId) async {
    try {
      final response = await _baseService.get('api/books/$bookId');
      return response;
    } on DioException catch (e) {
      Get.log('Get book by ID failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Create a new book
  /// POST /api/books
  /// Requires: super_admin or college_admin
  ///
  /// [bookData]: Book data
  /// - name (required): Book name
  /// - authorname (required): Author name
  /// - description (optional): Book description
  /// - isbn (optional): ISBN number
  /// - publisher (optional): Publisher name
  /// - publication_year (optional): Publication year
  /// - category (required): Book category
  /// - subject (required): Subject
  /// - language (required): Language
  /// - year (required): Academic year (2020-2030)
  /// - semester (required): Semester (1-8)
  /// - pages (optional): Number of pages
  ///
  /// Returns: Created book data
  Future<Response> createBook(Map<String, dynamic> bookData) async {
    try {
      final response = await _baseService.post(
        'api/books',
        data: bookData,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Create book failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Update book
  /// PUT /api/books/:bookId
  /// Requires: super_admin or college_admin
  ///
  /// [bookId]: Book ID
  /// [updateData]: Updated book data (same fields as create, all optional)
  ///
  /// Returns: Updated book data
  Future<Response> updateBook(
    String bookId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _baseService.put(
        'api/books/$bookId',
        data: updateData,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Update book failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Delete book
  /// DELETE /api/books/:bookId
  /// Requires: super_admin or college_admin
  ///
  /// [bookId]: Book ID
  /// Returns: Success message
  Future<Response> deleteBook(String bookId) async {
    try {
      final response = await _baseService.delete('api/books/$bookId');
      return response;
    } on DioException catch (e) {
      Get.log('Delete book failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Upload book PDF
  /// POST /api/books/:bookId/upload-pdf
  /// Requires: super_admin or college_admin
  /// Content-Type: multipart/form-data
  ///
  /// [bookId]: Book ID
  /// [filePath]: Path to PDF file
  ///
  /// File Requirements:
  /// - Type: PDF files only (application/pdf)
  /// - Size: Maximum 100MB
  ///
  /// Returns: PDF URL and signed URL
  Future<Response> uploadBookPdf(
    String bookId,
    String filePath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final response = await _baseService.uploadFile(
        'api/books/$bookId/upload-pdf',
        filePath,
        'book',
        onSendProgress: onProgress != null
            ? (int sent, int total) {
                onProgress(sent, total);
              }
            : null,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Upload book PDF failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Upload book cover image
  /// POST /api/books/:bookId/upload-cover
  /// Requires: super_admin or college_admin
  /// Content-Type: multipart/form-data
  ///
  /// [bookId]: Book ID
  /// [filePath]: Path to image file
  ///
  /// File Requirements:
  /// - Types: JPEG, PNG, WebP, GIF
  /// - Size: Maximum 5MB
  ///
  /// Returns: Cover image URL
  Future<Response> uploadBookCover(
    String bookId,
    String filePath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final response = await _baseService.uploadFile(
        'api/books/$bookId/upload-cover',
        filePath,
        'cover',
        onSendProgress: onProgress != null
            ? (int sent, int total) {
                onProgress(sent, total);
              }
            : null,
      );
      return response;
    } on DioException catch (e) {
      Get.log('Upload book cover failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Log book access (view or download)
  /// POST /api/books/:bookId/access
  /// Requires: Authentication
  ///
  /// [bookId]: Book ID
  /// [accessType]: 'view' or 'download'
  ///
  /// Returns: Success message
  Future<Response> logBookAccess(String bookId, String accessType) async {
    try {
      final response = await _baseService.post(
        'api/books/$bookId/access',
        data: {'access_type': accessType},
      );
      return response;
    } on DioException catch (e) {
      Get.log('Log book access failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Search books by query
  /// GET /api/books/search/:query
  /// Requires: Authentication
  ///
  /// [query]: Search query string
  /// Returns: List of matching books
  Future<Response> searchBooks(String query) async {
    try {
      final response = await _baseService.get('api/books/search/$query');
      return response;
    } on DioException catch (e) {
      Get.log('Search books failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get books by category
  /// GET /api/books/category/:category
  /// Requires: Authentication
  ///
  /// [category]: Category name
  /// Returns: List of books in category
  Future<Response> getBooksByCategory(String category) async {
    try {
      final response = await _baseService.get('api/books/category/$category');
      return response;
    } on DioException catch (e) {
      Get.log('Get books by category failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get books by year
  /// GET /api/books/year/:year
  /// Requires: super_admin or college_admin
  ///
  /// [year]: Academic year
  /// Returns: List of books for the year
  Future<Response> getBooksByYear(int year) async {
    try {
      final response = await _baseService.get('api/books/year/$year');
      return response;
    } on DioException catch (e) {
      Get.log('Get books by year failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get books by semester
  /// GET /api/books/semester/:semester
  /// Requires: super_admin or college_admin
  ///
  /// [semester]: Semester number (1-8)
  /// Returns: List of books for the semester
  Future<Response> getBooksBySemester(int semester) async {
    try {
      final response = await _baseService.get('api/books/semester/$semester');
      return response;
    } on DioException catch (e) {
      Get.log('Get books by semester failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get books by year and semester
  /// GET /api/books/year/:year/semester/:semester
  /// Requires: super_admin or college_admin
  ///
  /// [year]: Academic year
  /// [semester]: Semester number (1-8)
  /// Returns: List of books for year and semester
  Future<Response> getBooksByYearAndSemester(int year, int semester) async {
    try {
      final response = await _baseService.get(
        'api/books/year/$year/semester/$semester',
      );
      return response;
    } on DioException catch (e) {
      Get.log('Get books by year and semester failed: ${e.message}',
          isError: true);
      rethrow;
    }
  }

  /// Get student's books (books from their college)
  /// GET /api/books/my-books
  /// Requires: student role
  ///
  /// Returns: List of books from student's college
  Future<Response> getMyBooks() async {
    try {
      final response = await _baseService.get('api/books/my-books');
      return response;
    } on DioException catch (e) {
      Get.log('Get my books failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  /// Get user's books (all books from all colleges)
  /// GET /api/books/user-books
  /// Requires: user role
  ///
  /// Returns: List of all books from all colleges
  Future<Response> getUserBooks() async {
    try {
      final response = await _baseService.get('api/books/user-books');
      return response;
    } on DioException catch (e) {
      Get.log('Get user books failed: ${e.message}', isError: true);
      rethrow;
    }
  }
}
