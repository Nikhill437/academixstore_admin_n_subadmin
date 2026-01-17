import 'package:academixstore_admin_n_subadmin/modules/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/app_bindings.dart';
import 'services/role_access_service.dart';
import 'modules/dashboard/view/dashboard.dart';
import 'modules/users/view/users_table_view.dart';
import 'modules/student/view/students_table_view.dart';
import 'modules/colleges/view/colleges_table_view.dart';
import 'modules/books/view/books_table_view.dart';
import 'modules/books/binding/books_binding.dart';
import 'modules/auth/view/auth_logs_table_view.dart';
import 'modules/auth/view/signin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcademixStoreAdminApp());
}

class AcademixStoreAdminApp extends StatelessWidget {
  const AcademixStoreAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AcademixStore Admin',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      home: const AuthCheckScreen(), // Check authentication first
      debugShowCheckedModeBanner: false,
      enableLog: true, // Enable GetX logging
      getPages: [
        // Authentication routes
        GetPage(
          name: '/signin',
          page: () => const SignInScreen(),
          transition: Transition.fadeIn,
        ),

        // Main dashboard route
        GetPage(
          name: '/dashboard',
          page: () => const DashboardScreen(),
          binding: DashboardBinding(),
          middlewares: [AuthMiddleware(), RoleAccessMiddleware('dashboard')],
          transition: Transition.fadeIn,
        ),

        // User management routes
        GetPage(
          name: '/users',
          page: () => const UsersTableView(),
          binding: UserManagementBinding(),
          middlewares: [AuthMiddleware(), RoleAccessMiddleware('users')],
          transition: Transition.fadeIn,
        ),

        // Student management routes
        GetPage(
          name: '/students',
          page: () => const StudentsTableView(),
          binding: StudentManagementBinding(),
          middlewares: [AuthMiddleware(), RoleAccessMiddleware('students')],
          transition: Transition.fadeIn,
        ),

        // College management routes
        GetPage(
          name: '/colleges',
          page: () => const CollegesTableView(),
          binding: CollegeManagementBinding(),
          middlewares: [AuthMiddleware(), RoleAccessMiddleware('colleges')],
          transition: Transition.fadeIn,
        ),

        // Books management routes
        GetPage(
          name: '/books',
          page: () => const BooksTableView(),
          binding: BooksBinding(),
          middlewares: [AuthMiddleware(), RoleAccessMiddleware('books')],
          transition: Transition.fadeIn,
        ),

        // Auth logs routes
        GetPage(
          name: '/auth-logs',
          page: () => const AuthLogsTableView(),
          binding: AuthLogsBinding(),
          middlewares: [AuthMiddleware(), RoleAccessMiddleware('auth_logs')],
          transition: Transition.fadeIn,
        ),
      ],
    );
  }
}

/// Authentication check screen that determines initial route
/// Checks if user has valid token and routes to dashboard or sign-in accordingly
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait a brief moment for services to initialize
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final authController = Get.find<AuthController>();

      // Wait for authentication check to complete
      await authController.checkAuthenticationStatus();

      // Navigate based on authentication status
      if (authController.isAuthenticated.value) {
        Get.log('User authenticated, navigating to dashboard', isError: false);
        Get.offAllNamed('/dashboard');
      } else {
        Get.log(
          'User not authenticated, navigating to sign-in',
          isError: false,
        );
        Get.offAllNamed('/signin');
      }
    } catch (e) {
      Get.log('Error checking authentication: $e', isError: true);
      // On error, navigate to sign-in for safety
      Get.offAllNamed('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading...', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to dashboard by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed('/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Authentication guard widget that checks authentication state
/// Automatically redirects to sign-in screen if user is not authenticated
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      init: Get.find<AuthController>(),
      builder: (authController) {
        // Show loading while checking authentication
        if (authController.isLoading.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Redirect to sign-in if not authenticated
        if (!authController.isAuthenticated.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/signin');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show the child widget if authenticated
        return child;
      },
    );
  }
}

/// Authentication middleware for protected routes
/// Checks authentication before allowing access to routes
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    Get.log('🔒 AuthMiddleware: Checking route: $route', isError: false);

    final authController = Get.find<AuthController>();
    Get.log(
      '🔒 AuthMiddleware: isAuthenticated = ${authController.isAuthenticated.value}',
      isError: false,
    );

    // Allow access to sign-in route
    if (route == '/signin') {
      Get.log('🔒 AuthMiddleware: Allowing access to signin', isError: false);
      return null;
    }

    // Check if user is authenticated
    if (!authController.isAuthenticated.value) {
      Get.log(
        '🔒 AuthMiddleware: User not authenticated, redirecting to sign-in',
        isError: true,
      );
      return const RouteSettings(name: '/signin');
    }

    // Allow access to protected route
    Get.log(
      '🔒 AuthMiddleware: User authenticated, allowing access to $route',
      isError: false,
    );
    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    Get.log('Accessing route: ${page?.name}', isError: false);
    return super.onPageCalled(page);
  }
}

/// Role-based access middleware for module-specific route protection
/// Checks if user has access to specific modules based on their role
class RoleAccessMiddleware extends GetMiddleware {
  final String moduleName;

  RoleAccessMiddleware(this.moduleName);

  @override
  RouteSettings? redirect(String? route) {
    try {
      final roleAccessService = Get.find<RoleAccessService>();

      // Check if user has access to this module
      if (!roleAccessService.hasAccess(moduleName)) {
        Get.log(
          'Access denied to module $moduleName for user role: ${roleAccessService.currentRole?.displayName}',
          isError: true,
        );

        // Show access denied message
        Get.snackbar(
          'Access Denied',
          roleAccessService.getAccessDeniedMessage(moduleName),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 5),
        );

        // Redirect to dashboard or first accessible module
        final accessibleModules = roleAccessService.getNavigationModules();
        if (accessibleModules.isNotEmpty) {
          return RouteSettings(name: accessibleModules.first.routePath);
        }

        return const RouteSettings(name: '/dashboard');
      }

      // Allow access to the route
      return null;
    } catch (e) {
      Get.log('Error in RoleAccessMiddleware: $e', isError: true);
      // On error, redirect to dashboard for safety
      return const RouteSettings(name: '/dashboard');
    }
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    Get.log(
      'Role-based access check passed for module: $moduleName',
      isError: false,
    );
    return super.onPageCalled(page);
  }
}
