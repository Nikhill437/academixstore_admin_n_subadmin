import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../services/role_access_service.dart';

/// System Settings controller managing system configuration
/// Only accessible by super_admin
class SystemSettingsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final RoleAccessService _roleAccessService = Get.find<RoleAccessService>();

  // Observable variables
  final RxList<Map<String, dynamic>> _settings = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _publicSettings =
      <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  // Getters
  List<Map<String, dynamic>> get settings => _settings.toList();
  List<Map<String, dynamic>> get publicSettings => _publicSettings.toList();
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get hasSettings => _settings.isNotEmpty;
  bool get hasError => _error.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    Get.log('SystemSettingsController initialized', isError: false);
  }

  @override
  void onReady() {
    super.onReady();
    loadAllSettings();
  }

  /// Load all system settings (super_admin only)
  Future<void> loadAllSettings({bool refresh = false}) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('view system settings');
      return;
    }

    if (refresh) {
      _settings.clear();
      _error.value = '';
    }

    if (_isLoading.value) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.getAllSystemSettings();

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final settingsData = (data['settings'] ?? data) as List<dynamic>;
        _settings.value = settingsData
            .map((json) => json as Map<String, dynamic>)
            .toList();

        Get.log('Loaded ${_settings.length} system settings', isError: false);
      } else {
        _error.value =
            response.data['message'] ?? 'Failed to load system settings';
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error loading system settings: $e', isError: true);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load public system settings (no authentication required)
  Future<void> loadPublicSettings() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.getPublicSystemSettings();

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final settingsData = (data['settings'] ?? data) as List<dynamic>;
        _publicSettings.value = settingsData
            .map((json) => json as Map<String, dynamic>)
            .toList();

        Get.log(
          'Loaded ${_publicSettings.length} public system settings',
          isError: false,
        );
      } else {
        _error.value =
            response.data['message'] ?? 'Failed to load public settings';
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error loading public settings: $e', isError: true);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get setting by key
  Future<Map<String, dynamic>?> getSettingByKey(String key) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('view system settings');
      return null;
    }

    try {
      final response = await _apiService.getSystemSettingByKey(key);
      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      Get.log('Error getting setting by key: $e', isError: true);
    }
    return null;
  }

  /// Create or update system setting
  Future<bool> updateSetting(
    String key,
    String value, {
    String? description,
    bool? isPublic,
  }) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('update system settings');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.updateSystemSetting(
        key,
        value,
        description: description,
        isPublic: isPublic,
      );

      if (response.data['success'] == true) {
        final updatedSetting = response.data['data'] as Map<String, dynamic>;
        final index = _settings.indexWhere((s) => s['key'] == key);

        if (index != -1) {
          _settings[index] = updatedSetting;
        } else {
          _settings.add(updatedSetting);
        }

        Get.snackbar(
          'Success',
          'Setting "$key" updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to update setting';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error updating setting: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete system setting
  Future<bool> deleteSetting(String key) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('delete system settings');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.deleteSystemSetting(key);

      if (response.data['success'] == true) {
        _settings.removeWhere((s) => s['key'] == key);

        Get.snackbar(
          'Success',
          'Setting "$key" deleted successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _error.value = response.data['message'] ?? 'Failed to delete setting';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error deleting setting: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Bulk update system settings
  Future<bool> bulkUpdateSettings(
    List<Map<String, dynamic>> settingsToUpdate,
  ) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('bulk update system settings');
      return false;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final response =
          await _apiService.bulkUpdateSystemSettings(settingsToUpdate);

      if (response.data['success'] == true) {
        // Reload all settings after bulk update
        await loadAllSettings(refresh: true);

        Get.snackbar(
          'Success',
          '${settingsToUpdate.length} settings updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _error.value =
            response.data['message'] ?? 'Failed to bulk update settings';
        return false;
      }
    } catch (e) {
      _error.value = _handleError(e);
      Get.log('Error bulk updating settings: $e', isError: true);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get setting history
  Future<List<Map<String, dynamic>>> getSettingHistory(String key) async {
    if (!_roleAccessService.isSuperAdmin) {
      _showAccessDeniedError('view setting history');
      return [];
    }

    try {
      final response = await _apiService.getSystemSettingHistory(key);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final historyData = (data['history'] ?? data) as List<dynamic>;
        return historyData.map((json) => json as Map<String, dynamic>).toList();
      }
    } catch (e) {
      Get.log('Error getting setting history: $e', isError: true);
    }
    return [];
  }

  /// Get setting value by key (helper method)
  String? getSettingValue(String key) {
    try {
      final setting = _settings.firstWhere((s) => s['key'] == key);
      return setting['value'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get public setting value by key (helper method)
  String? getPublicSettingValue(String key) {
    try {
      final setting = _publicSettings.firstWhere((s) => s['key'] == key);
      return setting['value'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Check if setting exists
  bool hasSetting(String key) {
    return _settings.any((s) => s['key'] == key);
  }

  /// Refresh settings
  Future<void> refreshSettings() async {
    await loadAllSettings(refresh: true);
  }

  /// Clear error
  void clearError() {
    _error.value = '';
  }

  /// Show access denied error
  void _showAccessDeniedError(String action) {
    Get.snackbar(
      'Access Denied',
      'You don\'t have permission to $action. Super admin access required.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 5),
    );
  }

  /// Handle errors
  String _handleError(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return 'Network error. Please check your connection and try again.';
    }

    if (error.toString().contains('404')) {
      return 'System settings service not found. Please contact support.';
    }

    if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  @override
  void onClose() {
    Get.log('SystemSettingsController disposed', isError: false);
    super.onClose();
  }
}
