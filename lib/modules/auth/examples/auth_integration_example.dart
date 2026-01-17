// Example usage of the integrated authentication system
// This demonstrates how to use the AuthController with ApiService

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import the auth controller
import '../controller/auth_controller.dart';

/// Example usage of the integrated authentication system
class AuthenticationExample {
  // ===========================================
  // BASIC AUTHENTICATION EXAMPLES
  // ===========================================

  /// Example: Login with email and password
  Future<void> loginExample() async {
    final authController = Get.find<AuthController>();

    // For Super Admin (no college ID)
    final success = await authController.login(
      email: 'admin@university.com',
      password: 'securePassword123',
    );

    if (success) {
      print('Super Admin login successful!');
      // User will be automatically redirected to dashboard
    } else {
      print('Login failed. Check console for error details.');
    }
  }

  /// Example: Login as College Admin
  Future<void> loginCollegeAdminExample() async {
    final authController = Get.find<AuthController>();

    // For College Admin (with college ID)
    final success = await authController.login(
      email: 'admin@college.edu',
      password: 'collegePassword123',
      collegeId: 'COLLEGE_001',
    );

    if (success) {
      print('College Admin login successful!');
    }
  }

  /// Example: Check authentication status
  Future<void> checkAuthStatusExample() async {
    final authController = Get.find<AuthController>();

    // Check if user is authenticated
    if (authController.isAuthenticated.value) {
      print('User is authenticated');

      // Check specific roles
      final isSuperAdmin = await authController.isSuperAdmin();
      final isCollegeAdmin = await authController.isCollegeAdmin();

      if (isSuperAdmin) {
        print('User is Super Admin');
      } else if (isCollegeAdmin) {
        print('User is College Admin');
      }
    } else {
      print('User is not authenticated');
    }
  }

  /// Example: Get current user information
  Future<void> getCurrentUserExample() async {
    final authController = Get.find<AuthController>();

    final user = await authController.getCurrentUser();
    if (user != null) {
      print('Current User:');
      print('  Name: ${user['full_name']}');
      print('  Email: ${user['email']}');
      print('  Role: ${user['role']}');

      if (user['college'] != null) {
        print('  College: ${user['college']['name']}');
      }
    }
  }

  /// Example: Logout user
  Future<void> logoutExample() async {
    final authController = Get.find<AuthController>();
    await authController.logout();
    print('User logged out successfully');
  }

  // ===========================================
  // REACTIVE UI EXAMPLES
  // ===========================================

  /// Example: Reactive login button widget
  Widget buildReactiveLoginButton() {
    final authController = Get.find<AuthController>();

    return Obx(
      () => ElevatedButton(
        onPressed: authController.isLoading.value
            ? null
            : () async {
                await authController.login(
                  email: 'user@example.com',
                  password: 'password123',
                );
              },
        child: authController.isLoading.value
            ? const CircularProgressIndicator()
            : const Text('Login'),
      ),
    );
  }

  /// Example: Reactive error message widget
  Widget buildErrorMessage() {
    final authController = Get.find<AuthController>();

    return Obx(
      () => authController.errorMessage.value.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                authController.errorMessage.value,
                style: TextStyle(color: Colors.red.shade700),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Example: Reactive authentication status widget
  Widget buildAuthStatus() {
    final authController = Get.find<AuthController>();

    return Obx(
      () => authController.isAuthenticated.value
          ? const Icon(Icons.verified_user, color: Colors.green)
          : const Icon(Icons.error, color: Colors.red),
    );
  }

  // ===========================================
  // ERROR HANDLING EXAMPLES
  // ===========================================

  /// Example: Comprehensive error handling
  Future<void> loginWithErrorHandling() async {
    final authController = Get.find<AuthController>();

    try {
      final success = await authController.login(
        email: 'user@example.com',
        password: 'password123',
      );

      if (success) {
        // Success - user is automatically redirected
        Get.snackbar(
          'Success',
          'Welcome back!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Handle specific error cases
        final errorMessage = authController.errorMessage.value;

        if (errorMessage.contains('Invalid email')) {
          // Handle invalid email
          _showEmailError();
        } else if (errorMessage.contains('College ID')) {
          // Handle college ID mismatch
          _showCollegeIdError();
        } else {
          // Handle general error
          _showGeneralError(errorMessage);
        }
      }
    } catch (e) {
      // Handle unexpected errors
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showEmailError() {
    Get.dialog(
      AlertDialog(
        title: const Text('Invalid Email'),
        content: const Text('Please check your email address and try again.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showCollegeIdError() {
    Get.dialog(
      AlertDialog(
        title: const Text('College ID Mismatch'),
        content: const Text(
          'The provided College ID does not match your account.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showGeneralError(String message) {
    Get.snackbar(
      'Login Failed',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  // ===========================================
  // TESTING EXAMPLES
  // ===========================================

  /// Example: How to test authentication
  Future<void> testAuthentication() async {
    print('=== Testing Authentication System ===');

    final authController = Get.find<AuthController>();

    // Test 1: Check initial state
    print('Initial auth state: ${authController.isAuthenticated.value}');

    // Test 2: Test invalid login
    print('\nTesting invalid login...');
    await authController.login(
      email: 'invalid@email.com',
      password: 'wrongpassword',
    );
    print('Expected failure: ${authController.errorMessage.value}');

    // Test 3: Test valid super admin login
    print('\nTesting super admin login...');
    final superAdminSuccess = await authController.login(
      email: 'admin@university.com',
      password: 'correctPassword123',
    );
    print('Super admin login success: $superAdminSuccess');

    if (superAdminSuccess) {
      // Test 4: Check user role
      final isSuperAdmin = await authController.isSuperAdmin();
      print('Is super admin: $isSuperAdmin');

      // Test 5: Get user info
      final user = await authController.getCurrentUser();
      print('User info: ${user?['full_name']} (${user?['role']})');

      // Test 6: Test logout
      print('\nTesting logout...');
      await authController.logout();
      print('Auth state after logout: ${authController.isAuthenticated.value}');
    }

    print('=== Authentication Test Complete ===');
  }
}

// ===========================================
// MIDDLEWARE CLASSES
// ===========================================

/// Example: Route middleware to check authentication
class AuthMiddleware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    final authController = Get.find<AuthController>();

    // Check if user is authenticated
    if (!authController.isAuthenticated.value) {
      // Redirect to login if not authenticated
      return GetPage(name: '/signin', page: () => AuthExampleScreen());
    }

    return page;
  }
}

/// Example: Role-based route protection
class SuperAdminMiddleware extends GetMiddleware {
  @override
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route) async {
    final authController = Get.find<AuthController>();

    // Check if user is super admin
    final isSuperAdmin = await authController.isSuperAdmin();
    if (!isSuperAdmin) {
      // Redirect to unauthorized page
      return GetNavConfig.fromRoute('/unauthorized');
    }

    return null; // Allow access
  }
}

/// Example widget showing complete authentication flow
class AuthExampleScreen extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController collegeIdController = TextEditingController();

  AuthExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Example'),
        actions: [
          // Auth status indicator
          Obx(
            () => authController.isAuthenticated.value
                ? IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => authController.logout(),
                  )
                : const Icon(Icons.login),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current auth status
            Obx(
              () => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authentication Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Authenticated: ${authController.isAuthenticated.value}',
                      ),
                      Text('Loading: ${authController.isLoading.value}'),
                      if (authController.errorMessage.value.isNotEmpty)
                        Text(
                          'Error: ${authController.errorMessage.value}',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Login form
            if (!authController.isAuthenticated.value) ...[
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: collegeIdController,
                decoration: const InputDecoration(
                  labelText: 'College ID (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Login button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : () async {
                            await authController.login(
                              email: emailController.text,
                              password: passwordController.text,
                              collegeId: collegeIdController.text.isNotEmpty
                                  ? collegeIdController.text
                                  : null,
                            );
                          },
                    child: authController.isLoading.value
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
                  ),
                ),
              ),
            ] else ...[
              // User info when authenticated
              const Text(
                'Successfully authenticated!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => authController.logout(),
                child: const Text('Logout'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
