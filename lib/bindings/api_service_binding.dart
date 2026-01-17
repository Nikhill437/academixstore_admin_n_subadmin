import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/base_api_service.dart';
import '../services/token_service.dart';
import '../modules/auth/controller/auth_controller.dart';
import '../modules/books/controller/books_controller.dart';
import '../modules/users/controller/users_controller.dart';

/// Binding class to register API-related services with GetX dependency injection
/// This ensures proper initialization order and availability of services
class ApiServiceBinding extends Bindings {
  @override
  void dependencies() {
    // Register TokenService first (required by BaseApiService)
    Get.lazyPut<TokenService>(() => TokenService(), fenix: true);

    // Register BaseApiService (required by ApiService)
    Get.lazyPut<BaseApiService>(() => BaseApiService(), fenix: true);

    // Register the main ApiService
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);

    // Register AuthController (depends on ApiService and TokenService)
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);

    // Register BooksController (depends on ApiService)
    Get.lazyPut<BooksController>(() => BooksController(), fenix: true);

    // Register UsersController (depends on ApiService)
    Get.lazyPut<UsersController>(() => UsersController(), fenix: true);
  }
}

/// Alternative manual registration method
/// Call this in your main.dart or app initialization if not using bindings
class ApiServiceInitializer {
  static Future<void> initialize() async {
    // Register services in correct order
    Get.put<TokenService>(TokenService(), permanent: true);
    Get.put<BaseApiService>(BaseApiService(), permanent: true);
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);

    // Initialize services
    Get.find<BaseApiService>().onInit();
  }
}
