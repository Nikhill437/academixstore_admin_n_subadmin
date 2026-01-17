import 'package:get/get.dart' hide Response;
import '../../models/book.dart';
import '../base_api_service.dart';
import '../role_access_service.dart';

/// Books API service providing CRUD operations with role-based access control
/// Handles all book-related API interactions with automatic JWT authentication
class BooksApiService extends GetxService {
  final BaseApiService _baseApiService = Get.find<BaseApiService>();
  final RoleAccessService _roleAccessService = Get.find<RoleAccessService>();

  // API endpoints
  static const String _booksEndpoint = '/books';
  static const String _categoriesEndpoint = '/books/categories';
  static const String _statisticsEndpoint = '/books/statistics';

  @override
  void onInit() {
    super.onInit();
    Get.log('BooksApiService initialized', isError: false);
  }

  /// Fetch books with pagination and filters
  ///
  /// [page] - Page number (1-based)
  /// [limit] - Number of items per page
  /// [filters] - Optional filters to apply
  /// Returns paginated books response
  Future<Map<String, dynamic>> fetchBooks({
    int page = 1,
    int limit = 20,
    BookFilters? filters,
  }) async {
    // Validate access
    _roleAccessService.validateAccess('books');

    try {
      // Prepare query parameters
      final queryParams = {
        'page': page,
        'limit': limit,
        if (filters != null) ...filters.toQueryParams(),
      };

      Get.log('Fetching books: page $page, limit $limit', isError: false);

      final response = await _baseApiService.get(
        _booksEndpoint,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      Get.log(
        'Books fetched successfully: ${data['total'] ?? 0} total items',
        isError: false,
      );

      return data;
    } catch (e) {
      Get.log('Error fetching books: $e', isError: true);
      rethrow;
    }
  }

  /// Fetch a single book by ID
  ///
  /// [bookId] - Unique identifier of the book
  /// Returns book data or throws exception
  Future<Book> fetchBookById(String bookId) async {
    // Validate access
    _roleAccessService.validateAccess('books');

    try {
      Get.log('Fetching book by ID: $bookId', isError: false);

      final response = await _baseApiService.get('$_booksEndpoint/$bookId');
      final bookData = response.data as Map<String, dynamic>;

      Get.log(
        'Book fetched successfully: ${bookData['title']}',
        isError: false,
      );

      return Book.fromJson(bookData);
    } catch (e) {
      Get.log('Error fetching book $bookId: $e', isError: true);
      rethrow;
    }
  }

  /// Create a new book
  ///
  /// [bookData] - Book information to create
  /// Returns created book data
  Future<Book> createBook(Map<String, dynamic> bookData) async {
    // Validate modify access
    if (!_roleAccessService.canModify('books')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('books'),
      );
    }

    try {
      Get.log('Creating new book: ${bookData['title']}', isError: false);

      final response = await _baseApiService.post(
        _booksEndpoint,
        data: bookData,
      );

      final createdBook = Book.fromJson(response.data as Map<String, dynamic>);

      Get.log(
        'Book created successfully: ${createdBook.name}',
        isError: false,
      );

      return createdBook;
    } catch (e) {
      Get.log('Error creating book: $e', isError: true);
      rethrow;
    }
  }

  /// Update an existing book
  ///
  /// [bookId] - Unique identifier of the book to update
  /// [bookData] - Updated book information
  /// Returns updated book data
  Future<Book> updateBook(String bookId, Map<String, dynamic> bookData) async {
    // Validate modify access
    if (!_roleAccessService.canModify('books')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('books'),
      );
    }

    try {
      Get.log('Updating book: $bookId', isError: false);

      final response = await _baseApiService.put(
        '$_booksEndpoint/$bookId',
        data: bookData,
      );

      final updatedBook = Book.fromJson(response.data as Map<String, dynamic>);

      Get.log(
        'Book updated successfully: ${updatedBook.name}',
        isError: false,
      );

      return updatedBook;
    } catch (e) {
      Get.log('Error updating book $bookId: $e', isError: true);
      rethrow;
    }
  }

  /// Partially update a book (PATCH operation)
  ///
  /// [bookId] - Unique identifier of the book to update
  /// [updates] - Partial updates to apply
  /// Returns updated book data
  Future<Book> patchBook(String bookId, Map<String, dynamic> updates) async {
    // Validate modify access
    if (!_roleAccessService.canModify('books')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('books'),
      );
    }

    try {
      Get.log('Patching book: $bookId', isError: false);

      final response = await _baseApiService.patch(
        '$_booksEndpoint/$bookId',
        data: updates,
      );

      final updatedBook = Book.fromJson(response.data as Map<String, dynamic>);

      Get.log(
        'Book patched successfully: ${updatedBook.name}',
        isError: false,
      );

      return updatedBook;
    } catch (e) {
      Get.log('Error patching book $bookId: $e', isError: true);
      rethrow;
    }
  }

  /// Delete a book
  ///
  /// [bookId] - Unique identifier of the book to delete
  /// Returns true if deletion was successful
  Future<bool> deleteBook(String bookId) async {
    // Validate modify access
    if (!_roleAccessService.canModify('books')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('books'),
      );
    }

    try {
      Get.log('Deleting book: $bookId', isError: false);

      await _baseApiService.delete('$_booksEndpoint/$bookId');

      Get.log('Book deleted successfully: $bookId', isError: false);

      return true;
    } catch (e) {
      Get.log('Error deleting book $bookId: $e', isError: true);
      rethrow;
    }
  }

  /// Update book stock quantity
  ///
  /// [bookId] - Unique identifier of the book
  /// [newStock] - New stock quantity
  /// Returns updated book data
  Future<Book> updateBookStock(String bookId, int newStock) async {
    return await patchBook(bookId, {'stock': newStock});
  }

  /// Toggle book active status
  ///
  /// [bookId] - Unique identifier of the book
  /// Returns updated book data
  Future<Book> toggleBookStatus(String bookId) async {
    // First fetch current book to get current status
    final currentBook = await fetchBookById(bookId);
    return await patchBook(bookId, {'is_active': !currentBook.isActive});
  }

  /// Bulk update book stock
  ///
  /// [stockUpdates] - Map of book ID to new stock quantity
  /// Returns list of updated books
  Future<List<Book>> bulkUpdateStock(Map<String, int> stockUpdates) async {
    // Validate modify access
    if (!_roleAccessService.canModify('books')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('books'),
      );
    }

    try {
      Get.log(
        'Bulk updating stock for ${stockUpdates.length} books',
        isError: false,
      );

      final response = await _baseApiService.patch(
        '$_booksEndpoint/bulk-stock',
        data: {'updates': stockUpdates},
      );

      final updatedBooksData = response.data as List<dynamic>;
      final updatedBooks = updatedBooksData
          .map((data) => Book.fromJson(data as Map<String, dynamic>))
          .toList();

      Get.log(
        'Bulk stock update completed for ${updatedBooks.length} books',
        isError: false,
      );

      return updatedBooks;
    } catch (e) {
      Get.log('Error in bulk stock update: $e', isError: true);
      rethrow;
    }
  }

  /// Search books by query
  ///
  /// [query] - Search query string
  /// [page] - Page number (1-based)
  /// [limit] - Number of items per page
  /// Returns search results
  Future<Map<String, dynamic>> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    // Validate access
    _roleAccessService.validateAccess('books');

    try {
      Get.log('Searching books: "$query"', isError: false);

      final response = await _baseApiService.get(
        '$_booksEndpoint/search',
        queryParameters: {'q': query, 'page': page, 'limit': limit},
      );

      final data = response.data as Map<String, dynamic>;

      Get.log(
        'Book search completed: ${data['total'] ?? 0} results for "$query"',
        isError: false,
      );

      return data;
    } catch (e) {
      Get.log('Error searching books: $e', isError: true);
      rethrow;
    }
  }

  /// Fetch book categories
  ///
  /// Returns list of available book categories
  Future<List<String>> fetchBookCategories() async {
    // Validate access
    _roleAccessService.validateAccess('books');

    try {
      Get.log('Fetching book categories', isError: false);

      final response = await _baseApiService.get(_categoriesEndpoint);
      final categories = List<String>.from(response.data as List<dynamic>);

      Get.log(
        'Book categories fetched: ${categories.length} categories',
        isError: false,
      );

      return categories;
    } catch (e) {
      Get.log('Error fetching book categories: $e', isError: true);
      rethrow;
    }
  }

  /// Fetch books statistics
  ///
  /// Returns statistical data about books inventory
  Future<Map<String, dynamic>> fetchBooksStatistics() async {
    // Validate access
    _roleAccessService.validateAccess('books');

    try {
      Get.log('Fetching books statistics', isError: false);

      final response = await _baseApiService.get(_statisticsEndpoint);
      final statistics = response.data as Map<String, dynamic>;

      Get.log('Books statistics fetched successfully', isError: false);

      return statistics;
    } catch (e) {
      Get.log('Error fetching books statistics: $e', isError: true);
      rethrow;
    }
  }

  /// Fetch low stock books
  ///
  /// [threshold] - Stock threshold (default: 10)
  /// Returns books with stock below threshold
  Future<List<Book>> fetchLowStockBooks({int threshold = 10}) async {
    // Validate access
    _roleAccessService.validateAccess('books');

    try {
      Get.log(
        'Fetching low stock books (threshold: $threshold)',
        isError: false,
      );

      final response = await _baseApiService.get(
        '$_booksEndpoint/low-stock',
        queryParameters: {'threshold': threshold},
      );

      final booksData = response.data as List<dynamic>;
      final books = booksData
          .map((data) => Book.fromJson(data as Map<String, dynamic>))
          .toList();

      Get.log('Low stock books fetched: ${books.length} books', isError: false);

      return books;
    } catch (e) {
      Get.log('Error fetching low stock books: $e', isError: true);
      rethrow;
    }
  }

  /// Fetch out of stock books
  ///
  /// Returns books with zero stock
  Future<List<Book>> fetchOutOfStockBooks() async {
    // Validate access
    _roleAccessService.validateAccess('books');

    try {
      Get.log('Fetching out of stock books', isError: false);

      final response = await _baseApiService.get(
        '$_booksEndpoint/out-of-stock',
      );

      final booksData = response.data as List<dynamic>;
      final books = booksData
          .map((data) => Book.fromJson(data as Map<String, dynamic>))
          .toList();

      Get.log(
        'Out of stock books fetched: ${books.length} books',
        isError: false,
      );

      return books;
    } catch (e) {
      Get.log('Error fetching out of stock books: $e', isError: true);
      rethrow;
    }
  }

  /// Upload book cover image
  ///
  /// [bookId] - Unique identifier of the book
  /// [imagePath] - Local path to the image file
  /// Returns updated book data with image URL
  Future<Book> uploadBookCover(String bookId, String imagePath) async {
    // Validate modify access
    if (!_roleAccessService.canModify('books')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('books'),
      );
    }

    try {
      Get.log('Uploading book cover for book: $bookId', isError: false);

      final response = await _baseApiService.uploadFile(
        '$_booksEndpoint/$bookId/cover',
        imagePath,
        'cover_image',
      );

      final updatedBook = Book.fromJson(response.data as Map<String, dynamic>);

      Get.log(
        'Book cover uploaded successfully: ${updatedBook.name}',
        isError: false,
      );

      return updatedBook;
    } catch (e) {
      Get.log('Error uploading book cover: $e', isError: true);
      rethrow;
    }
  }

  /// Export books data
  ///
  /// [format] - Export format ('csv', 'excel', 'pdf')
  /// [filters] - Optional filters to apply
  /// Returns download URL or file path
  Future<String> exportBooks({
    String format = 'csv',
    BookFilters? filters,
  }) async {
    // Validate access
    _roleAccessService.validateAccess('books');

    try {
      Get.log('Exporting books in $format format', isError: false);

      final queryParams = {
        'format': format,
        if (filters != null) ...filters.toQueryParams(),
      };

      final response = await _baseApiService.get(
        '$_booksEndpoint/export',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final downloadUrl = data['download_url'] as String;

      Get.log('Books export completed: $downloadUrl', isError: false);

      return downloadUrl;
    } catch (e) {
      Get.log('Error exporting books: $e', isError: true);
      rethrow;
    }
  }

  /// Import books from file
  ///
  /// [filePath] - Path to the import file
  /// [format] - Import format ('csv', 'excel')
  /// Returns import results
  Future<Map<String, dynamic>> importBooks({
    required String filePath,
    String format = 'csv',
  }) async {
    // Validate modify access
    if (!_roleAccessService.canModify('books')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('books'),
      );
    }

    try {
      Get.log(
        'Importing books from $filePath ($format format)',
        isError: false,
      );

      final response = await _baseApiService.uploadFile(
        '$_booksEndpoint/import',
        filePath,
        'import_file',
        additionalData: {'format': format},
      );

      final results = response.data as Map<String, dynamic>;

      Get.log(
        'Books import completed: ${results['imported']} imported, ${results['failed']} failed',
        isError: false,
      );

      return results;
    } catch (e) {
      Get.log('Error importing books: $e', isError: true);
      rethrow;
    }
  }
}
