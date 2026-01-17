import 'package:get/get.dart';
import '../controller/books_controller.dart';

/// Books module binding for dependency injection
/// Manages the lifecycle of books-related controllers and services
class BooksBinding extends Bindings {
  @override
  void dependencies() {
    Get.log('Loading books module dependencies...', isError: false);

    // Books controller (lazy-loaded for performance)
    Get.lazyPut<BooksController>(
      () => BooksController(),
      fenix: true, // Recreate if disposed
    );

    Get.log('Books module dependencies loaded successfully', isError: false);
  }
}
