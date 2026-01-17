import 'package:get/get.dart';
import '../../../models/book.dart';
import '../../../services/api_service.dart';
import '../../../services/role_access_service.dart';

/// Books controller managing book inventory and operations
/// Integrates with the centralized ApiService for all API operations
class BooksController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final RoleAccessService _roleAccessService = Get.find<RoleAccessService>();

  // Observable variables for reactive UI updates
  final RxList<Book> _books = <Book>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxString _error = ''.obs;
  final Rx<BookFilters> _filters = const BookFilters().obs;
  final RxInt _currentPage = 1.obs;
  final RxInt _totalItems = 0.obs;
  final RxInt _totalPages = 0.obs;
  final RxBool _hasMore = false.obs;

  // Getters for UI access
  List<Book> get books => _books.toList();
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  String get error => _error.value;
  BookFilters get filters => _filters.value;
  int get currentPage => _currentPage.value;
  int get totalItems => _totalItems.value;
  int get totalPages => _totalPages.value;
  bool get hasMore => _hasMore.value;
  bool get hasBooks => _books.isNotEmpty;
  bool get hasError => _error.value.isNotEmpty;

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
    loadBooks();
  }

  /// Initialize the controller
  void _initializeController() {
    Get.log('BooksController initialized', isError: false);
  }

  /// Load books with current filters and pagination
  Future<void> loadBooks({bool refresh = false}) async {
    if (refresh) {
      _currentPage.value = 1;
      _books.clear();
      _error.value = '';
    }

    if (_isLoading.value) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      Get.log('📚 Fetching books from API...', isError: false);

      // Make API call using ApiService
      final response = await _apiService.getBooks(
        category: _filters.value.category?.value,
      );

      Get.log('📥 API Response received: ${response.data}', isError: false);

      if (response.data['success'] == true) {
        // Parse response
        final data = response.data['data'];
        Get.log('📦 Data object: $data', isError: false);
        
        final booksData = (data['books'] ?? data) as List<dynamic>;
        Get.log('📚 Books array length: ${booksData.length}', isError: false);
        
        final newBooks = <Book>[];
        for (var i = 0; i < booksData.length; i++) {
          try {
            final bookJson = booksData[i] as Map<String, dynamic>;
            Get.log('📖 Parsing book $i: ${bookJson['name']}', isError: false);
            final book = Book.fromJson(bookJson);
            newBooks.add(book);
            Get.log('✅ Book $i parsed successfully', isError: false);
          } catch (e, stackTrace) {
            Get.log('❌ Error parsing book $i: $e', isError: true);
            Get.log('Stack trace: $stackTrace', isError: true);
            Get.log('Book JSON: ${booksData[i]}', isError: true);
          }
        }

        Get.log('✅ Total books parsed: ${newBooks.length}', isError: false);

        // Update state
        if (refresh || _currentPage.value == 1) {
          _books.value = newBooks;
        } else {
          _books.addAll(newBooks);
        }

        Get.log('📊 Books in state: ${_books.length}', isError: false);

        _totalItems.value = data['total'] as int? ?? newBooks.length;
        _totalPages.value = data['total_pages'] as int? ?? 1;
        _hasMore.value = _currentPage.value < _totalPages.value;

        Get.log(
          'Loaded ${newBooks.length} books (page ${_currentPage.value})',
          isError: false,
        );
      } else {
        _error.value = response.data['message'] ?? 'Failed to load books';
        Get.log('❌ API returned success=false: ${_error.value}', isError: true);
      }
    } catch (e, stackTrace) {
      _error.value = _handleError(e);
      Get.log('❌ Error loading books: $e', isError: true);
      Get.log('Stack trace: $stackTrace', isError: true);
    } finally {
      _isLoading.value = false;
      Get.log('🏁 Loading complete. Books count: ${_books.length}', isError: false);
    }
  }

  /// Load more books for pagination
  Future<void> loadMoreBooks() async {
    if (_isLoadingMore.value || !_hasMore.value) return;

    try {
      _isLoadingMore.value = true;
      _currentPage.value++;
      await loadBooks();
    } catch (e) {
      _currentPage.value--; // Revert page increment on error
      rethrow;
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refresh books list
  Future<void> refreshBooks() async {
    await loadBooks(refresh: true);
  }

  /// Apply search and filters
  Future<void> applyFilters(BookFilters newFilters) async {
    _filters.value = newFilters;
    await loadBooks(refresh: true);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _filters.value = const BookFilters();
    await loadBooks(refresh: true);
  }

  /// Search books by query
  Future<void> searchBooks(String query) async {
    final newFilters = _filters.value.copyWith(
      search: query.trim().isEmpty ? null : query,
    );
    await applyFilters(newFilters);
  }

  /// Filter by category
  Future<void> filterByCategory(BookCategory? category) async {
    final newFilters = _filters.value.copyWith(category: category);
    await applyFilters(newFilters);
  }

  /// Create a new book (requires modify permission)
  /// Returns the created book ID if successful, null otherwise
  Future<String?> createBook(Map<String, dynamic> bookData) async {
    if (!_roleAccessService.canModify('books')) {
      _showAccessDeniedError('create books');
      return null;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      Get.log('Creating book with data: $bookData', isError: false);
      final response = await _apiService.createBook(bookData);

      Get.log('Create book response: ${response.data}', isError: false);

      if (response.data['success'] == true) {
        final bookDataResponse = response.data['data'];
        
        // Extract book ID from response
        final bookId = bookDataResponse['id'] ?? bookDataResponse['book']?['id'];
        
        Get.log('Book created with ID: $bookId', isError: false);

        // Try to parse as Book if possible
        try {
          final newBook = Book.fromJson(
            bookDataResponse is Map<String, dynamic> 
              ? bookDataResponse 
              : bookDataResponse['book'] as Map<String, dynamic>,
          );

          // Add to the beginning of the list
          _books.insert(0, newBook);
          _totalItems.value++;

          Get.snackbar(
            'Success',
            'Book "${newBook.name}" created successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );

          Get.log('Book created: ${newBook.name}', isError: false);
        } catch (e) {
          Get.log('Could not parse book, but creation succeeded: $e', isError: false);
          Get.snackbar(
            'Success',
            'Book created successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );
        }

        return bookId as String?;
      } else {
        _error.value = response.data['message'] ?? 'Failed to create book';
        return null;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error creating book: $e', isError: true);
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update an existing book
  Future<bool> updateBook(String bookId, Map<String, dynamic> bookData) async {
    if (!_roleAccessService.canModify('books')) {
      _showAccessDeniedError('modify books');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.updateBook(bookId, bookData);

      if (response.data['success'] == true) {
        final updatedBook = Book.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );

        // Update the book in the list
        final index = _books.indexWhere((book) => book.id == bookId);
        if (index != -1) {
          _books[index] = updatedBook;
        }

        Get.snackbar(
          'Success',
          'Book "${updatedBook.name}" updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        Get.log('Book updated: ${updatedBook.name}', isError: false);
        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to update book';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error updating book: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete a book
  Future<bool> deleteBook(String bookId) async {
    if (!_roleAccessService.canModify('books')) {
      _showAccessDeniedError('delete books');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.deleteBook(bookId);

      if (response.data['success'] == true) {
        // Remove from the list
        final removedBook = _books.firstWhereOrNull(
          (book) => book.id == bookId,
        );
        _books.removeWhere((book) => book.id == bookId);
        _totalItems.value--;

        Get.snackbar(
          'Success',
          'Book "${removedBook?.name ?? 'Unknown'}" deleted successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        Get.log('Book deleted: ${removedBook?.name}', isError: false);
        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to delete book';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error deleting book: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get book by ID
  Book? getBookById(String bookId) {
    try {
      return _books.firstWhere((book) => book.id == bookId);
    } catch (e) {
      return null;
    }
  }

  /// Update book stock
  Future<bool> updateBookStock(String bookId, int newStock) async {
    if (!_roleAccessService.canModify('books')) {
      _showAccessDeniedError('modify book stock');
      return false;
    }

    return await updateBook(bookId, {'stock': newStock});
  }

  /// Toggle book active status
  Future<bool> toggleBookStatus(String bookId) async {
    if (!_roleAccessService.canModify('books')) {
      _showAccessDeniedError('modify book status');
      return false;
    }

    final book = getBookById(bookId);
    if (book == null) return false;

    return await updateBook(bookId, {'is_active': !book.isActive});
  }

  /// Upload book PDF
  Future<bool> uploadBookPdf(
    String bookId,
    String? filePath, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    if (!_roleAccessService.canModify('books')) {
      _showAccessDeniedError('upload book PDF');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      Get.log('📤 Uploading PDF for book: $bookId', isError: false);
      if (filePath != null) {
        Get.log('📁 File path: $filePath', isError: false);
      } else {
        Get.log('📁 File bytes: ${fileBytes?.length} bytes, name: $fileName', isError: false);
      }

      final response = await _apiService.uploadBookPdf(
        bookId,
        filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      Get.log('📥 Upload response: ${response.data}', isError: false);
      Get.log('📊 Status code: ${response.statusCode}', isError: false);

      if (response.data['success'] == true) {
        Get.snackbar(
          'Success',
          'Book PDF uploaded successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        Get.log('✅ PDF upload successful', isError: false);
        
        // Reload books to get updated data
        await loadBooks(refresh: true);
        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to upload PDF';
        Get.log('❌ PDF upload failed: ${_error.value}', isError: true);
        
        Get.snackbar(
          'Upload Failed',
          _error.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('❌ Error uploading book PDF: $e', isError: true);
      
      Get.snackbar(
        'Upload Error',
        'Failed to upload PDF: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Upload book cover image
  Future<bool> uploadBookCover(
    String bookId,
    String? filePath, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    if (!_roleAccessService.canModify('books')) {
      _showAccessDeniedError('upload book cover');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.uploadBookCover(
        bookId,
        filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      if (response.data['success'] == true) {
        Get.snackbar(
          'Success',
          'Book cover uploaded successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        // Reload books to get updated data
        await loadBooks(refresh: true);
        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to upload cover';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error uploading book cover: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Log book access (view or download)
  Future<void> logBookAccess(String bookId, String accessType) async {
    try {
      await _apiService.logBookAccess(bookId, accessType);
      Get.log('Book access logged: $bookId - $accessType', isError: false);
    } catch (e) {
      Get.log('Error logging book access: $e', isError: true);
    }
  }

  /// Search books
  Future<void> searchBooksByQuery(String query) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.searchBooks(query);

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final booksData = (data['books'] ?? data) as List<dynamic>;
        final searchResults = booksData
            .map((json) => Book.fromJson(json as Map<String, dynamic>))
            .toList();

        _books.value = searchResults;
        Get.log('Found ${searchResults.length} books', isError: false);
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error searching books: $e', isError: true);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get books by category
  List<Book> getBooksByCategory(BookCategory category) {
    return _books.where((book) => book.category == category.value).toList();
  }

  /// Get books by year
  List<Book> getBooksByYear(int year) {
    return _books.where((book) => book.year == year).toList();
  }

  /// Get books by semester
  List<Book> getBooksBySemester(int semester) {
    return _books.where((book) => book.semester == semester).toList();
  }

  /// Get books statistics
  Map<String, int> getBooksStatistics() {
    return {
      'total': _books.length,
      'active': _books.where((book) => book.isActive).length,
      'inactive': _books.where((book) => !book.isActive).length,
      'totalDownloads': _books.fold(0, (sum, book) => sum + book.downloadCount),
    };
  }

  /// Check if user can perform CRUD operations
  bool get canCreateBooks => _roleAccessService.canModify('books');
  bool get canUpdateBooks => _roleAccessService.canModify('books');
  bool get canDeleteBooks => _roleAccessService.canModify('books');

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

  /// Handle and format errors
  String _handleError(dynamic error) {
    if (error is UnauthorizedAccessException) {
      return error.message;
    }

    // Handle common API errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return 'Network error. Please check your connection and try again.';
    }

    if (error.toString().contains('404')) {
      return 'Books service not found. Please contact support.';
    }

    if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Clear error state
  void clearError() {
    _error.value = '';
  }

  @override
  void onClose() {
    // Clean up resources
    Get.log('BooksController disposed', isError: false);
    super.onClose();
  }
}
