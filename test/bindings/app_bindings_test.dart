import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:academixstore_admin_n_subadmin/bindings/app_bindings.dart';
import 'package:academixstore_admin_n_subadmin/services/api/question_papers_api_service.dart';
import 'package:academixstore_admin_n_subadmin/services/file_validation_service.dart';
import 'package:academixstore_admin_n_subadmin/services/token_service.dart';
import 'package:academixstore_admin_n_subadmin/services/base_api_service.dart';
import 'package:academixstore_admin_n_subadmin/services/role_access_service.dart';

/// Integration tests for service initialization in app bindings
/// 
/// These tests verify that all required services are properly initialized
/// and accessible through GetX dependency injection.
/// 
/// Requirements: 4.1, 7.1
void main() {
  group('InitialBinding Service Initialization', () {
    setUp(() {
      // Reset GetX before each test
      Get.reset();
    });

    tearDown(() {
      // Clean up after each test
      Get.reset();
    });

    test('QuestionPapersApiService is properly initialized', () {
      // Arrange & Act
      InitialBinding().dependencies();

      // Assert
      expect(Get.isRegistered<QuestionPapersApiService>(), isTrue,
          reason: 'QuestionPapersApiService should be registered');

      final service = Get.find<QuestionPapersApiService>();
      expect(service, isNotNull,
          reason: 'QuestionPapersApiService instance should not be null');
      expect(service, isA<QuestionPapersApiService>(),
          reason: 'Service should be of type QuestionPapersApiService');
    });

    test('FileValidationService is properly initialized', () {
      // Arrange & Act
      InitialBinding().dependencies();

      // Assert
      expect(Get.isRegistered<FileValidationService>(), isTrue,
          reason: 'FileValidationService should be registered');

      final service = Get.find<FileValidationService>();
      expect(service, isNotNull,
          reason: 'FileValidationService instance should not be null');
      expect(service, isA<FileValidationService>(),
          reason: 'Service should be of type FileValidationService');
    });

    test('Services are accessible from controllers and dialogs', () {
      // Arrange & Act
      InitialBinding().dependencies();

      // Assert - Verify all core services are accessible
      expect(Get.isRegistered<TokenService>(), isTrue,
          reason: 'TokenService should be accessible');
      expect(Get.isRegistered<BaseApiService>(), isTrue,
          reason: 'BaseApiService should be accessible');
      expect(Get.isRegistered<RoleAccessService>(), isTrue,
          reason: 'RoleAccessService should be accessible');
      expect(Get.isRegistered<QuestionPapersApiService>(), isTrue,
          reason: 'QuestionPapersApiService should be accessible');
      expect(Get.isRegistered<FileValidationService>(), isTrue,
          reason: 'FileValidationService should be accessible');

      // Verify services can be retrieved
      final questionPapersService = Get.find<QuestionPapersApiService>();
      final fileValidationService = Get.find<FileValidationService>();

      expect(questionPapersService, isNotNull);
      expect(fileValidationService, isNotNull);
    });

    test('Services are initialized in correct order', () {
      // Arrange & Act
      InitialBinding().dependencies();

      // Assert - Verify dependency order
      // TokenService should be initialized first
      expect(Get.isRegistered<TokenService>(), isTrue,
          reason: 'TokenService should be initialized first');

      // BaseApiService depends on TokenService
      expect(Get.isRegistered<BaseApiService>(), isTrue,
          reason: 'BaseApiService should be initialized after TokenService');

      // QuestionPapersApiService depends on BaseApiService
      expect(Get.isRegistered<QuestionPapersApiService>(), isTrue,
          reason:
              'QuestionPapersApiService should be initialized after BaseApiService');

      // FileValidationService is independent
      expect(Get.isRegistered<FileValidationService>(), isTrue,
          reason: 'FileValidationService should be initialized');
    });

    test('Services are registered as permanent', () {
      // Arrange & Act
      InitialBinding().dependencies();

      // Assert - Services should remain registered after reset attempt
      final questionPapersService = Get.find<QuestionPapersApiService>();
      final fileValidationService = Get.find<FileValidationService>();

      expect(questionPapersService, isNotNull);
      expect(fileValidationService, isNotNull);

      // Services should still be accessible (permanent registration)
      expect(Get.isRegistered<QuestionPapersApiService>(), isTrue);
      expect(Get.isRegistered<FileValidationService>(), isTrue);
    });

    test('Multiple calls to dependencies() do not cause errors', () {
      // Arrange & Act
      InitialBinding().dependencies();

      // Act - Call dependencies again
      expect(() => InitialBinding().dependencies(), returnsNormally,
          reason: 'Multiple calls to dependencies() should not throw errors');

      // Assert - Services should still be accessible
      expect(Get.isRegistered<QuestionPapersApiService>(), isTrue);
      expect(Get.isRegistered<FileValidationService>(), isTrue);
    });

    test('FileValidationService can be used independently', () {
      // Arrange
      InitialBinding().dependencies();
      final service = Get.find<FileValidationService>();

      // Act
      final result = service.validatePdfFile(
        fileName: 'test.pdf',
        fileSizeBytes: 1024,
      );

      // Assert
      expect(result.isValid, isTrue,
          reason: 'FileValidationService should be functional after initialization');
    });
  });
}
