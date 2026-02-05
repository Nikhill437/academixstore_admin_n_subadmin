import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common_widgets/common_data_table.dart';
import '../../../common_widgets/shared_sidebar.dart';
import '../controller/books_controller.dart';
import '../../../models/book.dart';
import '../../auth/controller/auth_controller.dart';
import 'add_edit_book_dialog.dart';

/// Books table view displaying book inventory with role-based access control
/// Provides comprehensive book management interface for authorized users
class BooksTableView extends StatelessWidget {
  const BooksTableView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation
          SharedSidebar(
            selectedIndex: 4, // Books index
            onItemSelected: (index) {
              // Handle navigation based on index
              switch (index) {
                case 0:
                  Get.offNamed('/dashboard');
                  break;
                case 1:
                  Get.offNamed('/users');
                  break;
                case 2:
                  Get.offNamed('/students');
                  break;
                case 3:
                  Get.offNamed('/colleges');
                  break;
                case 4:
                  // Already on books page
                  break;
              }
            },
            onLogout: () => authController.logout(),
          ),

          // Main content area
          Expanded(
            child: Container(
              color: Colors.white, // White background
              child: Obx(() {
                final controller = Get.find<BooksController>();
                return Column(
                  children: [
                    // Header section
                    _buildHeader(controller),

                    // Filters section
                    _buildFiltersSection(controller),

                    // Data table section
                    Expanded(child: _buildDataTableSection(controller)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Build header with title and action buttons
  Widget _buildHeader(BooksController controller) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Get.theme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Books Management',
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage book inventory, stock levels, and book information',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              // Refresh button
              IconButton(
                onPressed: controller.hasError ? null : controller.refreshBooks,
                icon: Icon(Icons.refresh, color: Get.theme.colorScheme.primary),
                tooltip: 'Refresh books',
              ),

              const SizedBox(width: 8),

              // Add book button (if user has permission)
              if (controller.canCreateBooks)
                ElevatedButton.icon(
                  onPressed: () => _showAddBookDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Get.theme.colorScheme.primary,
                    foregroundColor: Get.theme.colorScheme.onPrimary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build filters section
  Widget _buildFiltersSection(BooksController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          // Search field
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search books by title, author, or ISBN...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: controller.searchBooks,
            ),
          ),

          const SizedBox(width: 16),

          // Category filter
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<BookCategory>(
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              initialValue: controller.filters.category,
              items: [
                const DropdownMenuItem<BookCategory>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...BookCategory.values.map(
                  (category) => DropdownMenuItem<BookCategory>(
                    value: category,
                    child: Text(category.displayName),
                  ),
                ),
              ],
              onChanged: controller.filterByCategory,
            ),
          ),

          const SizedBox(width: 16),

          // Status filter
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<bool>(
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              initialValue: controller.filters.isActive,
              items: const [
                DropdownMenuItem<bool>(value: null, child: Text('All')),
                DropdownMenuItem<bool>(value: true, child: Text('Active')),
                DropdownMenuItem<bool>(value: false, child: Text('Inactive')),
              ],
              onChanged: (value) {
                final newFilters = controller.filters.copyWith(isActive: value);
                controller.applyFilters(newFilters);
              },
            ),
          ),

          const SizedBox(width: 16),

          // Clear filters button
          if (controller.filters.hasFilters)
            TextButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  /// Build data table section
  Widget _buildDataTableSection(BooksController controller) {
    // Show error state
    if (controller.hasError) {
      return _buildErrorState(controller);
    }

    // Show loading state
    if (controller.isLoading && !controller.hasBooks) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show empty state
    if (!controller.hasBooks && !controller.isLoading) {
      return _buildEmptyState(controller);
    }

    // Show data table
    return CommonDataTable<Book>(
      title: 'Books',
      data: controller.books,
      columns: _buildColumns(controller),
      rowBuilder: (books) => _buildDataRows(books, controller),
      showSearch: false, // We have custom search
      showPagination: true,
      itemsPerPage: BooksController.itemsPerPage,
      onAdd: controller.canCreateBooks ? () => _showAddBookDialog() : null,
    );
  }

  /// Build table columns
  List<DataColumn> _buildColumns(BooksController controller) {
    return [
      const DataColumn(label: Text('Book'), tooltip: 'Book name and author'),
      const DataColumn(label: Text('Category'), tooltip: 'Book category'),
      const DataColumn(label: Text('Subject'), tooltip: 'Book subject'),
      const DataColumn(
        label: Text('Year/Sem'),
        tooltip: 'Academic year and semester',
      ),
      const DataColumn(
        label: Text('Rating'),
        tooltip: 'Book rating',
        numeric: true,
      ),
      const DataColumn(
        label: Text('Downloads'),
        tooltip: 'Download count',
        numeric: true,
      ),
      const DataColumn(
        label: Text('Status'),
        tooltip: 'Book status',
      ),
      const DataColumn(label: Text('Actions'), tooltip: 'Available actions'),
    ];
  }

  /// Build data rows for the table
  List<DataRow> _buildDataRows(List<Book> books, BooksController controller) {
    return books.map((book) {
      return DataRow(
        cells: [
          // Book name and author
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'by ${book.authorname ?? 'Unknown Author'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Category
          DataCell(
            Chip(
              label: Text(book.category ?? 'Uncategorized', style: const TextStyle(fontSize: 12)),
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: Get.theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),

          // Subject
          DataCell(
            Text(book.subject ?? 'N/A'),
          ),

          // Year and Semester
          DataCell(
            Text(
              book.yearSemester,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // Rating
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  book.formattedRate,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Downloads
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download, size: 16),
                const SizedBox(width: 4),
                Text(
                  book.downloadCount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Status
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: book.isActive
                    ? Get.theme.colorScheme.primaryContainer
                    : Get.theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                book.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: book.isActive
                      ? Get.theme.colorScheme.onPrimaryContainer
                      : Get.theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),

          // Actions
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View/Edit button
                IconButton(
                  onPressed: () => _showBookDetails(book),
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View details',
                  iconSize: 18,
                ),

                // Edit button (if user has permission)
                if (controller.canUpdateBooks)
                  IconButton(
                    onPressed: () => _showEditBookDialog(book),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit book',
                    iconSize: 18,
                  ),

                // Delete button (if user has permission)
                if (controller.canDeleteBooks)
                  IconButton(
                    onPressed: () => _showDeleteConfirmationDialog(book),
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete book',
                    iconSize: 18,
                    color: Get.theme.colorScheme.error,
                  ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Build error state
  Widget _buildErrorState(BooksController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Get.theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Books',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Get.theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.error,
            style: Get.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              controller.clearError();
              controller.refreshBooks();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BooksController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Get.theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            controller.filters.hasFilters
                ? 'No Books Found'
                : 'No Books Available',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Get.theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.filters.hasFilters
                ? 'Try adjusting your search criteria'
                : 'Start by adding some books to the inventory',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (controller.filters.hasFilters)
            TextButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            )
          else if (controller.canCreateBooks)
            ElevatedButton.icon(
              onPressed: () => _showAddBookDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Book'),
            ),
        ],
      ),
    );
  }

  /// Show add book dialog
  void _showAddBookDialog({Book? book}) {
    Get.dialog(
      AddEditBookDialog(book: book),
      barrierDismissible: false,
    );
  }

  /// Show book details dialog
  void _showBookDetails(Book book) {
    Get.dialog(
      AlertDialog(
        title: Text(book.name),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Author', book.authorname ?? 'Unknown'),
              _buildDetailRow('Category', book.category ?? 'Uncategorized'),
              if (book.subject != null)
                _buildDetailRow('Subject', book.subject!),
              _buildDetailRow('Year/Semester', book.yearSemester),
              _buildDetailRow('Rating', book.formattedRate),
              _buildDetailRow('Downloads', book.downloadCount.toString()),
              if (book.isbn != null)
                _buildDetailRow('ISBN', book.isbn!),
              if (book.publisher != null)
                _buildDetailRow('Publisher', book.publisher!),
              if (book.publicationYear != null)
                _buildDetailRow('Publication Year', book.publicationYear.toString()),
              if (book.language != null)
                _buildDetailRow('Language', book.language!),
              if (book.pages != null)
                _buildDetailRow('Pages', book.pages.toString()),
              if (book.description != null && book.description!.isNotEmpty)
                _buildDetailRow('Description', book.description!),
              if (book.college != null)
                _buildDetailRow('College', '${book.college!.name} (${book.college!.code})'),
              if (book.creator != null)
                _buildDetailRow('Created By', book.creator!.fullName),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  /// Build detail row for book details dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Show edit book dialog
  void _showEditBookDialog(Book book) {
    Get.dialog(
      AddEditBookDialog(book: book),
      barrierDismissible: false,
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmationDialog(Book book) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${book.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<BooksController>().deleteBook(book.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
