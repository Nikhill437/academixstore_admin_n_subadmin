import 'package:get/get.dart' hide Response;
import 'base_api_service.dart';

/// Dashboard API service that extends BaseApiService
/// Example implementation showing how to use the base service for specific API endpoints
class DashboardApiService extends GetxService {
  final BaseApiService _baseApi = Get.find<BaseApiService>();

  // === Dashboard Statistics ===

  /// Get dashboard statistics and overview data
  /// Returns dashboard metrics like user count, sales, etc.
  Future<DashboardStats?> getDashboardStats() async {
    try {
      Get.log('Fetching dashboard statistics', isError: false);

      final response = await _baseApi.get('/dashboard/stats');

      if (response.statusCode == 200 && response.data != null) {
        return DashboardStats.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      Get.log('Error fetching dashboard stats: $e', isError: true);
      return null;
    }
  }

  /// Get recent activities for dashboard
  Future<List<DashboardActivity>> getRecentActivities({
    int limit = 10,
    int page = 1,
  }) async {
    try {
      Get.log('Fetching recent activities', isError: false);

      final response = await _baseApi.get(
        '/dashboard/activities',
        queryParameters: {'limit': limit, 'page': page},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final activities = data['activities'] as List?;

        if (activities != null) {
          return activities
              .map(
                (activity) => DashboardActivity.fromJson(
                  activity as Map<String, dynamic>,
                ),
              )
              .toList();
        }
      }

      return [];
    } catch (e) {
      Get.log('Error fetching recent activities: $e', isError: true);
      return [];
    }
  }

  // === User Management ===

  /// Get paginated list of users
  Future<UserListResponse?> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? status,
  }) async {
    try {
      Get.log('Fetching users list', isError: false);

      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _baseApi.get(
        '/users',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return UserListResponse.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      Get.log('Error fetching users: $e', isError: true);
      return null;
    }
  }

  /// Get user details by ID
  Future<UserDetail?> getUserById(String userId) async {
    try {
      Get.log('Fetching user details for ID: $userId', isError: false);

      final response = await _baseApi.get('/users/$userId');

      if (response.statusCode == 200 && response.data != null) {
        return UserDetail.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      Get.log('Error fetching user details: $e', isError: true);
      return null;
    }
  }

  /// Update user status (activate/deactivate)
  Future<bool> updateUserStatus(String userId, String status) async {
    try {
      Get.log(
        'Updating user status for ID: $userId to $status',
        isError: false,
      );

      final response = await _baseApi.patch(
        '/users/$userId/status',
        data: {'status': status},
      );

      return response.statusCode == 200;
    } catch (e) {
      Get.log('Error updating user status: $e', isError: true);
      return false;
    }
  }

  // === Student Management ===

  /// Get paginated list of students
  Future<StudentListResponse?> getStudents({
    int page = 1,
    int limit = 20,
    String? search,
    String? collegeId,
    String? status,
  }) async {
    try {
      Get.log('Fetching students list', isError: false);

      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (collegeId != null && collegeId.isNotEmpty) {
        queryParams['college_id'] = collegeId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _baseApi.get(
        '/students',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return StudentListResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      Get.log('Error fetching students: $e', isError: true);
      return null;
    }
  }

  // === College Management ===

  /// Get list of colleges
  Future<List<College>> getColleges() async {
    try {
      Get.log('Fetching colleges list', isError: false);

      final response = await _baseApi.get('/colleges');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final colleges = data['colleges'] as List?;

        if (colleges != null) {
          return colleges
              .map(
                (college) => College.fromJson(college as Map<String, dynamic>),
              )
              .toList();
        }
      }

      return [];
    } catch (e) {
      Get.log('Error fetching colleges: $e', isError: true);
      return [];
    }
  }

  // === Authentication Logs ===

  /// Get authentication logs
  Future<AuthLogListResponse?> getAuthLogs({
    int page = 1,
    int limit = 20,
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Get.log('Fetching auth logs', isError: false);

      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (userId != null && userId.isNotEmpty) {
        queryParams['user_id'] = userId;
      }
      if (action != null && action.isNotEmpty) {
        queryParams['action'] = action;
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _baseApi.get(
        '/auth/logs',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return AuthLogListResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      Get.log('Error fetching auth logs: $e', isError: true);
      return null;
    }
  }

  // === File Upload Example ===

  /// Upload profile image
  Future<bool> uploadProfileImage(String filePath) async {
    try {
      Get.log('Uploading profile image', isError: false);

      final response = await _baseApi.uploadFile(
        '/user/profile/image',
        filePath,
        'image',
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          Get.log('Upload progress: $progress%', isError: false);
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      Get.log('Error uploading profile image: $e', isError: true);
      return false;
    }
  }

  // === Export Data Example ===

  /// Export users data as CSV
  Future<bool> exportUsersCSV(String savePath) async {
    try {
      Get.log('Exporting users CSV', isError: false);

      final response = await _baseApi.downloadFile(
        '/export/users/csv',
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(1);
            Get.log('Download progress: $progress%', isError: false);
          }
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      Get.log('Error exporting users CSV: $e', isError: true);
      return false;
    }
  }
}

// === Data Models ===

/// Dashboard statistics model
class DashboardStats {
  final int totalUsers;
  final int totalStudents;
  final int totalColleges;
  final int activeUsers;
  final double totalRevenue;
  final List<ChartData> userGrowthChart;
  final List<ChartData> revenueChart;

  DashboardStats({
    required this.totalUsers,
    required this.totalStudents,
    required this.totalColleges,
    required this.activeUsers,
    required this.totalRevenue,
    required this.userGrowthChart,
    required this.revenueChart,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['total_users'] ?? 0,
      totalStudents: json['total_students'] ?? 0,
      totalColleges: json['total_colleges'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      userGrowthChart:
          (json['user_growth_chart'] as List?)
              ?.map((item) => ChartData.fromJson(item))
              .toList() ??
          [],
      revenueChart:
          (json['revenue_chart'] as List?)
              ?.map((item) => ChartData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// Chart data model
class ChartData {
  final String label;
  final double value;
  final DateTime date;

  ChartData({required this.label, required this.value, required this.date});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
}

/// Dashboard activity model
class DashboardActivity {
  final String id;
  final String action;
  final String description;
  final String userId;
  final String userName;
  final DateTime timestamp;

  DashboardActivity({
    required this.id,
    required this.action,
    required this.description,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      id: json['id'] ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// User list response model
class UserListResponse {
  final List<UserSummary> users;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  UserListResponse({
    required this.users,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    return UserListResponse(
      users:
          (json['users'] as List?)
              ?.map((user) => UserSummary.fromJson(user))
              .toList() ??
          [],
      totalCount: json['total_count'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

/// User summary model
class UserSummary {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;

  UserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// User detail model
class UserDetail {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? phone;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      phone: json['phone'],
      profileImage: json['profile_image'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Student list response model
class StudentListResponse {
  final List<StudentSummary> students;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  StudentListResponse({
    required this.students,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory StudentListResponse.fromJson(Map<String, dynamic> json) {
    return StudentListResponse(
      students:
          (json['students'] as List?)
              ?.map((student) => StudentSummary.fromJson(student))
              .toList() ??
          [],
      totalCount: json['total_count'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

/// Student summary model
class StudentSummary {
  final String id;
  final String name;
  final String email;
  final String collegeId;
  final String collegeName;
  final String status;
  final DateTime enrolledAt;

  StudentSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.collegeId,
    required this.collegeName,
    required this.status,
    required this.enrolledAt,
  });

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    return StudentSummary(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      collegeId: json['college_id'] ?? '',
      collegeName: json['college_name'] ?? '',
      status: json['status'] ?? '',
      enrolledAt: DateTime.parse(json['enrolled_at']),
    );
  }
}

/// College model
class College {
  final String id;
  final String name;
  final String code;
  final String address;
  final String status;

  College({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.status,
  });

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

/// Auth log list response model
class AuthLogListResponse {
  final List<AuthLog> logs;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  AuthLogListResponse({
    required this.logs,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory AuthLogListResponse.fromJson(Map<String, dynamic> json) {
    return AuthLogListResponse(
      logs:
          (json['logs'] as List?)
              ?.map((log) => AuthLog.fromJson(log))
              .toList() ??
          [],
      totalCount: json['total_count'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

/// Auth log model
class AuthLog {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String ipAddress;
  final String userAgent;
  final DateTime timestamp;

  AuthLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.ipAddress,
    required this.userAgent,
    required this.timestamp,
  });

  factory AuthLog.fromJson(Map<String, dynamic> json) {
    return AuthLog(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      action: json['action'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      userAgent: json['user_agent'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
