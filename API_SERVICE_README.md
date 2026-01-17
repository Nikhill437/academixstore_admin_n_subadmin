# ApiService - Comprehensive Dart API Integration

This is a complete Dart API service implementation using the Dio package that integrates all endpoints from your backend API documentation. The service provides a clean, type-safe, and production-ready interface for your Flutter application.

## 📁 Files Created

- `lib/services/api_service.dart` - Main API service with all endpoint methods
- `lib/services/api_service_example.dart` - Usage examples and workflow demonstrations
- `lib/bindings/api_service_binding.dart` - GetX binding for dependency injection

## 🚀 Quick Setup

### 1. Install Dependencies

Make sure your `pubspec.yaml` includes:

```yaml
dependencies:
  dio: ^5.4.0
  get: ^4.6.6
  shared_preferences: ^2.2.2
  jwt_decoder: ^2.0.1
```

### 2. Initialize Services

#### Option A: Using GetX Bindings (Recommended)

```dart
// In your main.dart
import 'package:get/get.dart';
import 'bindings/api_service_binding.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Your App',
      initialBinding: ApiServiceBinding(),
      home: HomeScreen(),
    );
  }
}
```

#### Option B: Manual Initialization

```dart
// In your main.dart
import 'bindings/api_service_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API services
  await ApiServiceInitializer.initialize();
  
  runApp(MyApp());
}
```

### 3. Configure Base URL

Update the base URL in `lib/services/base_api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:3000'; // Your API base URL
```

## 🔧 Usage Examples

### Authentication

```dart
import 'package:get/get.dart';
import 'services/api_service.dart';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Login
  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.loginUser(email, password);
      
      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final user = response.data['data']['user'];
        
        // Store token and user data
        print('Login successful: ${user['full_name']}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Login failed: $e');
    }
  }

  // Register
  Future<void> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.registerUser(userData);
      
      if (response.data['success'] == true) {
        Get.snackbar('Success', 'Registration successful');
      }
    } catch (e) {
      Get.snackbar('Error', 'Registration failed: $e');
    }
  }
}
```

### Book Management

```dart
class BookController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Get books with filters
  Future<void> getBooks({String? category, int? year, int? semester}) async {
    try {
      final response = await _apiService.getBooks(
        category: category,
        year: year,
        semester: semester,
      );
      
      if (response.data['success'] == true) {
        final books = response.data['data']['books'] as List;
        // Update UI with books
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load books: $e');
    }
  }

  // Create book
  Future<void> createBook(Map<String, dynamic> bookData) async {
    try {
      final response = await _apiService.createBook(bookData);
      
      if (response.data['success'] == true) {
        Get.snackbar('Success', 'Book created successfully');
        // Refresh book list
        getBooks();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create book: $e');
    }
  }

  // Upload book PDF
  Future<void> uploadBookPdf(String bookId, String filePath) async {
    try {
      final response = await _apiService.uploadBookPdf(bookId, filePath);
      
      if (response.data['success'] == true) {
        Get.snackbar('Success', 'PDF uploaded successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload PDF: $e');
    }
  }
}
```

### User Management

```dart
class UserController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Get all users with pagination
  Future<void> getAllUsers({int page = 1, int limit = 20, String? role}) async {
    try {
      final response = await _apiService.getAllUsers(
        page: page,
        limit: limit,
        role: role,
      );
      
      if (response.data['success'] == true) {
        final users = response.data['data']['users'] as List;
        final pagination = response.data['data']['pagination'];
        
        // Update UI with users and pagination info
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load users: $e');
    }
  }

  // Update user
  Future<void> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      final response = await _apiService.updateUser(userId, updateData);
      
      if (response.data['success'] == true) {
        Get.snackbar('Success', 'User updated successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update user: $e');
    }
  }
}
```

## 📋 Available API Methods

### Authentication
- `registerUser(userData)` - Register new user
- `loginUser(email, password)` - User login
- `getCurrentUser()` - Get current user profile
- `refreshToken()` - Refresh JWT token
- `logoutUser()` - User logout

### User Management
- `getAllUsers()` - Get all users with filters
- `getUserById(userId)` - Get user by ID
- `updateUser(userId, data)` - Update user profile
- `changePassword(userId, currentPassword, newPassword)` - Change password
- `activateUser(userId)` / `deactivateUser(userId)` - Activate/deactivate user

### Book Management
- `getBooks()` - Get books with filters
- `getBookById(bookId)` - Get single book
- `createBook(bookData)` - Create new book
- `updateBook(bookId, data)` - Update book
- `deleteBook(bookId)` - Delete book
- `uploadBookPdf(bookId, filePath)` - Upload book PDF
- `uploadBookCover(bookId, filePath)` - Upload book cover
- `searchBooks(query)` - Search books
- `getBooksByCategory(category)` - Get books by category
- `getBooksByYear(year)` - Get books by year
- `getBooksBySemester(semester)` - Get books by semester
- `getMyBooks()` - Get student's books
- `getUserBooks()` - Get user's books
- `logBookAccess(bookId, accessType)` - Log book access

### College Management
- `getAllColleges()` - Get all colleges
- `getCollegeById(collegeId)` - Get college by ID
- `createCollege(collegeData)` - Create new college
- `updateCollege(collegeId, data)` - Update college
- `getCollegeStats(collegeId)` - Get college statistics
- `getCollegeUsers(collegeId)` - Get college users
- `getCollegeBooks(collegeId)` - Get college books

### Individual Users Management
- `getAllIndividualUsers()` - Get all individual users
- `getIndividualUserById(userId)` - Get individual user by ID
- `createIndividualUser(userData)` - Create individual user
- `updateIndividualUser(userId, data)` - Update individual user
- `changeIndividualUserPassword(userId, newPassword)` - Change password
- `activateIndividualUser(userId)` / `deactivateIndividualUser(userId)` - Activate/deactivate
- `deleteIndividualUser(userId)` - Delete individual user

### System Settings
- `getAllSystemSettings()` - Get all system settings
- `getPublicSystemSettings()` - Get public system settings
- `getSystemSettingByKey(key)` - Get setting by key
- `updateSystemSetting(key, value)` - Update system setting
- `deleteSystemSetting(key)` - Delete system setting
- `bulkUpdateSystemSettings(settings)` - Bulk update settings
- `getSystemSettingHistory(key)` - Get setting history

### Utility
- `healthCheck()` - API health check

## 🔐 Authentication & Security

The service automatically handles:
- **JWT Token Management**: Tokens are automatically added to request headers
- **Token Expiry**: Automatic token refresh and user logout on expiry
- **Secure Storage**: Tokens stored securely using SharedPreferences
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Request/Response Logging**: Debug logging for development

## 🛠️ Error Handling

All methods include comprehensive error handling:

```dart
try {
  final response = await _apiService.someMethod();
  // Handle success
} catch (e) {
  // Error message includes status codes and server messages
  print('API Error: $e');
}
```

Error messages are formatted as: `[StatusCode] ErrorMessage`

## 📊 Response Format

All API responses follow this structure:

```dart
{
  "success": true/false,
  "message": "Response message",
  "data": { /* Response data */ }
}
```

Paginated responses include:

```dart
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "total": 100,
      "page": 1,
      "limit": 20,
      "totalPages": 5
    }
  }
}
```

## 🚀 File Upload Support

The service supports file uploads for:
- **Book PDFs**: Up to 100MB
- **Book Covers**: Up to 5MB (JPEG, PNG, WebP, GIF)

```dart
// Upload book PDF
await _apiService.uploadBookPdf(bookId, '/path/to/file.pdf');

// Upload book cover
await _apiService.uploadBookCover(bookId, '/path/to/cover.jpg');
```

## 🔧 Configuration

### Base URL
Update in `base_api_service.dart`:
```dart
static const String baseUrl = 'https://your-api-domain.com/api';
```

### Timeouts
Configure in `base_api_service.dart`:
```dart
static const int connectTimeout = 30000; // 30 seconds
static const int receiveTimeout = 30000; // 30 seconds
static const int sendTimeout = 30000; // 30 seconds
```

## 📝 Role-Based Access Control

The service respects the API's role-based permissions:

- **super_admin**: Full system access
- **college_admin**: Access to their college's data
- **student**: View access to their college's books
- **user**: View access to all books from all colleges

Methods are documented with required permission levels.

## 🧪 Testing

See `api_service_example.dart` for comprehensive usage examples and workflow demonstrations.

## 🤝 Contributing

When adding new endpoints:

1. Add the method to `ApiService` class
2. Include comprehensive documentation
3. Add error handling
4. Update this README
5. Add usage examples

## 📄 License

This implementation is part of your Educational Book Management System project.