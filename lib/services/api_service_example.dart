// Example usage of the ApiService
// This file demonstrates how to use the comprehensive API service

import 'package:get/get.dart';
import '../services/api_service.dart';

class ApiServiceExample {
  final ApiService _apiService = Get.find<ApiService>();

  // ===========================================
  // AUTHENTICATION EXAMPLES
  // ===========================================

  /// Example: User registration
  Future<void> registerUserExample() async {
    try {
      final response = await _apiService.registerUser({
        'email': 'student@example.com',
        'password': 'password123',
        'full_name': 'John Doe',
        'role': 'student',
        'college_id': 'uuid-college-id',
        'student_id': 'STU2024001',
        'mobile': '+91-9999999999',
      });

      if (response.data['success'] == true) {
        final user = response.data['data']['user'];
        final token = response.data['data']['token'];
        print('User registered: ${user['full_name']}');
        print('Token: $token');
      }
    } catch (e) {
      print('Registration failed: $e');
    }
  }

  /// Example: User login
  Future<void> loginUserExample() async {
    try {
      final response = await _apiService.loginUser(
        'user@example.com',
        'password123',
      );

      if (response.data['success'] == true) {
        final user = response.data['data']['user'];
        final token = response.data['data']['token'];
        print('Login successful: ${user['full_name']}');
        // Store token for future requests
      }
    } catch (e) {
      print('Login failed: $e');
    }
  }

  /// Example: Get current user profile
  Future<void> getCurrentUserExample() async {
    try {
      final response = await _apiService.getCurrentUser();

      if (response.data['success'] == true) {
        final user = response.data['data']['user'];
        print('Current user: ${user['full_name']}');
        print('Role: ${user['role']}');
        if (user['college'] != null) {
          print('College: ${user['college']['name']}');
        }
      }
    } catch (e) {
      print('Failed to get user profile: $e');
    }
  }

  // ===========================================
  // BOOK MANAGEMENT EXAMPLES
  // ===========================================

  /// Example: Get books with filters
  Future<void> getBooksExample() async {
    try {
      final response = await _apiService.getBooks(
        category: 'Computer Science',
        year: 2024,
        semester: 3,
      );

      if (response.data['success'] == true) {
        final books = response.data['data']['books'] as List;
        print('Found ${books.length} books');

        for (final book in books) {
          print('Book: ${book['name']} by ${book['authorname']}');
          print('  Category: ${book['category']}');
          print('  Year: ${book['year']}, Semester: ${book['semester']}');
          print('  Rating: ${book['rate']}/5.0');
          print('  Downloads: ${book['download_count']}');
        }
      }
    } catch (e) {
      print('Failed to get books: $e');
    }
  }

  /// Example: Create a new book
  Future<void> createBookExample() async {
    try {
      final response = await _apiService.createBook({
        'name': 'Data Structures and Algorithms',
        'description': 'Comprehensive guide to DSA',
        'authorname': 'Thomas H. Cormen',
        'isbn': '978-0262033848',
        'publisher': 'MIT Press',
        'publication_year': 2009,
        'category': 'Computer Science',
        'subject': 'Programming',
        'language': 'English',
        'year': 2024,
        'semester': 3,
        'pages': 1312,
      });

      if (response.data['success'] == true) {
        final book = response.data['data']['book'];
        print('Book created: ${book['name']}');
        print('Book ID: ${book['id']}');
      }
    } catch (e) {
      print('Failed to create book: $e');
    }
  }

  /// Example: Upload book PDF
  Future<void> uploadBookPdfExample(String bookId, String pdfFilePath) async {
    try {
      final response = await _apiService.uploadBookPdf(bookId, pdfFilePath);

      if (response.data['success'] == true) {
        final data = response.data['data'];
        print('PDF uploaded successfully');
        print('PDF URL: ${data['pdf_url']}');
        print('Signed URL: ${data['signed_url']}');
      }
    } catch (e) {
      print('Failed to upload PDF: $e');
    }
  }

  /// Example: Search books
  Future<void> searchBooksExample() async {
    try {
      final response = await _apiService.searchBooks('algorithms');

      if (response.data['success'] == true) {
        final books = response.data['data']['books'] as List;
        print('Search results: ${books.length} books found');

        for (final book in books) {
          print('${book['name']} - ${book['authorname']}');
        }
      }
    } catch (e) {
      print('Search failed: $e');
    }
  }

  /// Example: Log book access
  Future<void> logBookAccessExample(String bookId) async {
    try {
      await _apiService.logBookAccess(bookId, 'view');
      print('Book access logged successfully');
    } catch (e) {
      print('Failed to log book access: $e');
    }
  }

  // ===========================================
  // USER MANAGEMENT EXAMPLES
  // ===========================================

  /// Example: Get all users with pagination and filters
  Future<void> getAllUsersExample() async {
    try {
      final response = await _apiService.getAllUsers(
        page: 1,
        limit: 20,
        role: 'student',
        search: 'john',
      );

      if (response.data['success'] == true) {
        final users = response.data['data']['users'] as List;
        final pagination = response.data['data']['pagination'];

        print('Users: ${users.length}/${pagination['total']}');
        print('Page: ${pagination['page']}/${pagination['totalPages']}');

        for (final user in users) {
          print('${user['full_name']} (${user['email']}) - ${user['role']}');
        }
      }
    } catch (e) {
      print('Failed to get users: $e');
    }
  }

  /// Example: Update user profile
  Future<void> updateUserExample(String userId) async {
    try {
      final response = await _apiService.updateUser(userId, {
        'full_name': 'John Doe Updated',
        'mobile': '+91-9999999998',
      });

      if (response.data['success'] == true) {
        print('User updated successfully');
      }
    } catch (e) {
      print('Failed to update user: $e');
    }
  }

  /// Example: Change password
  Future<void> changePasswordExample(String userId) async {
    try {
      final response = await _apiService.changePassword(
        userId,
        'old_password',
        'new_password123',
      );

      if (response.data['success'] == true) {
        print('Password changed successfully');
      }
    } catch (e) {
      print('Failed to change password: $e');
    }
  }

  // ===========================================
  // COLLEGE MANAGEMENT EXAMPLES
  // ===========================================

  /// Example: Get all colleges
  Future<void> getAllCollegesExample() async {
    try {
      final response = await _apiService.getAllColleges(
        page: 1,
        limit: 10,
        search: 'technical',
        status: 'active',
      );

      if (response.data['success'] == true) {
        final colleges = response.data['data']['colleges'] as List;
        print('Colleges found: ${colleges.length}');

        for (final college in colleges) {
          print('${college['name']} (${college['code']})');
          print('  Address: ${college['address']}');
          print('  Website: ${college['website']}');
        }
      }
    } catch (e) {
      print('Failed to get colleges: $e');
    }
  }

  /// Example: Get college statistics
  Future<void> getCollegeStatsExample(String collegeId) async {
    try {
      final response = await _apiService.getCollegeStats(collegeId);

      if (response.data['success'] == true) {
        final stats = response.data['data']['stats'];
        print('College Statistics:');
        print('  Total Students: ${stats['totalStudents']}');
        print('  Total Admins: ${stats['totalAdmins']}');
        print('  Total Books: ${stats['totalBooks']}');
        print('  Total Users: ${stats['totalUsers']}');

        final booksByCategory = stats['booksByCategory'] as List;
        print('Books by Category:');
        for (final category in booksByCategory) {
          print('  ${category['category']}: ${category['count']} books');
        }
      }
    } catch (e) {
      print('Failed to get college stats: $e');
    }
  }

  /// Example: Create a new college
  Future<void> createCollegeExample() async {
    try {
      final response = await _apiService.createCollege({
        'name': 'Delhi Technical University',
        'code': 'DTU001',
        'address': 'Bawana Road, Delhi-110042',
        'phone': '+91-11-27871023',
        'email': 'admin@dtu.ac.in',
        'website': 'http://dtu.ac.in',
      });

      if (response.data['success'] == true) {
        final college = response.data['data']['college'];
        print('College created: ${college['name']}');
      }
    } catch (e) {
      print('Failed to create college: $e');
    }
  }

  // ===========================================
  // SYSTEM SETTINGS EXAMPLES
  // ===========================================

  /// Example: Get public system settings
  Future<void> getPublicSettingsExample() async {
    try {
      final response = await _apiService.getPublicSystemSettings();

      if (response.data['success'] == true) {
        final settings = response.data['data']['settings'] as List;
        print('Public Settings:');

        for (final setting in settings) {
          print('${setting['key']}: ${setting['value']}');
          if (setting['description'] != null) {
            print('  Description: ${setting['description']}');
          }
        }
      }
    } catch (e) {
      print('Failed to get public settings: $e');
    }
  }

  /// Example: Update system setting
  Future<void> updateSystemSettingExample() async {
    try {
      final response = await _apiService.updateSystemSetting(
        'app_name',
        'Educational Book Management System',
        description: 'Application name displayed in UI',
        isPublic: true,
      );

      if (response.data['success'] == true) {
        print('System setting updated successfully');
      }
    } catch (e) {
      print('Failed to update system setting: $e');
    }
  }

  /// Example: Bulk update system settings
  Future<void> bulkUpdateSettingsExample() async {
    try {
      final response = await _apiService.bulkUpdateSystemSettings([
        {
          'key': 'app_name',
          'value': 'AcademixStore',
          'description': 'Application name',
          'is_public': true,
        },
        {
          'key': 'maintenance_mode',
          'value': 'false',
          'description': 'Enable/disable maintenance mode',
          'is_public': false,
        },
      ]);

      if (response.data['success'] == true) {
        print('Bulk settings update completed');
      }
    } catch (e) {
      print('Failed to bulk update settings: $e');
    }
  }

  // ===========================================
  // UTILITY EXAMPLES
  // ===========================================

  /// Example: Health check
  Future<void> healthCheckExample() async {
    try {
      final response = await _apiService.healthCheck();

      if (response.data['success'] == true) {
        print('API Health: ${response.data['message']}');
        print('Version: ${response.data['version']}');
        print('Timestamp: ${response.data['timestamp']}');
      }
    } catch (e) {
      print('Health check failed: $e');
    }
  }

  // ===========================================
  // COMPLETE WORKFLOW EXAMPLES
  // ===========================================

  /// Example: Complete book upload workflow
  Future<void> completeBookUploadWorkflow() async {
    try {
      // Step 1: Create book record
      print('Step 1: Creating book record...');
      final createResponse = await _apiService.createBook({
        'name': 'Advanced Flutter Development',
        'authorname': 'Jane Smith',
        'category': 'Computer Science',
        'subject': 'Mobile Development',
        'year': 2024,
        'semester': 5,
        'pages': 450,
      });

      if (createResponse.data['success'] != true) {
        throw Exception('Failed to create book');
      }

      final bookId = createResponse.data['data']['book']['id'];
      print('Book created with ID: $bookId');

      // Step 2: Upload PDF file
      print('Step 2: Uploading PDF...');
      final pdfResponse = await _apiService.uploadBookPdf(
        bookId,
        '/path/to/book.pdf', // Replace with actual file path
      );

      if (pdfResponse.data['success'] == true) {
        print('PDF uploaded successfully');
      }

      // Step 3: Upload cover image
      print('Step 3: Uploading cover image...');
      final coverResponse = await _apiService.uploadBookCover(
        bookId,
        '/path/to/cover.jpg', // Replace with actual file path
      );

      if (coverResponse.data['success'] == true) {
        print('Cover uploaded successfully');
      }

      print('Book upload workflow completed successfully!');
    } catch (e) {
      print('Book upload workflow failed: $e');
    }
  }

  /// Example: Complete user management workflow
  Future<void> completeUserManagementWorkflow() async {
    try {
      // Step 1: Get all students
      print('Step 1: Getting all students...');
      final usersResponse = await _apiService.getAllUsers(
        role: 'student',
        limit: 50,
      );

      if (usersResponse.data['success'] == true) {
        final users = usersResponse.data['data']['users'] as List;
        print('Found ${users.length} students');

        // Step 2: Update a specific user
        if (users.isNotEmpty) {
          final userId = users.first['id'];
          print('Step 2: Updating user $userId...');

          await _apiService.updateUser(userId, {'mobile': '+91-9999999999'});
          print('User updated successfully');
        }
      }

      // Step 3: Get updated user profile
      print('Step 3: Getting updated user profile...');
      final profileResponse = await _apiService.getCurrentUser();

      if (profileResponse.data['success'] == true) {
        final user = profileResponse.data['data']['user'];
        print('Updated profile: ${user['full_name']}');
      }

      print('User management workflow completed!');
    } catch (e) {
      print('User management workflow failed: $e');
    }
  }
}
