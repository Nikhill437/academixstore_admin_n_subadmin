/// User model representing a user in the system
/// Can have roles: super_admin, college_admin, student, or user
class User {
  final String id;
  final String email;
  final String fullName;
  final String role; // super_admin, college_admin, student, user
  final String? collegeId;
  final String? studentId; // Only for students
  final String? mobile;
  final String? profileImageUrl;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final College? college;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.collegeId,
    this.studentId,
    this.mobile,
    this.profileImageUrl,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    this.college,
  });

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      collegeId: json['college_id'] as String?,
      studentId: json['student_id'] as String?,
      mobile: json['mobile'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      college: json['college'] != null
          ? College.fromJson(json['college'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'college_id': collegeId,
      'student_id': studentId,
      'mobile': mobile,
      'profile_image_url': profileImageUrl,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (college != null) 'college': college!.toJson(),
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? collegeId,
    String? studentId,
    String? mobile,
    String? profileImageUrl,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    College? college,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      collegeId: collegeId ?? this.collegeId,
      studentId: studentId ?? this.studentId,
      mobile: mobile ?? this.mobile,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      college: college ?? this.college,
    );
  }

  /// Get status display text
  String get statusText => isActive ? 'Active' : 'Inactive';

  /// Get verification status text
  String get verificationText => isVerified ? 'Verified' : 'Not Verified';

  /// Get role display text
  String get roleDisplayText {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'college_admin':
        return 'College Admin';
      case 'student':
        return 'Student';
      case 'user':
        return 'User';
      default:
        return role;
    }
  }

  /// Check if user is admin
  bool get isAdmin => role == 'super_admin' || role == 'college_admin';

  /// Check if user is super admin
  bool get isSuperAdmin => role == 'super_admin';

  /// Check if user is college admin
  bool get isCollegeAdmin => role == 'college_admin';

  /// Check if user is student
  bool get isStudent => role == 'student';

  /// Check if user is individual user
  bool get isIndividualUser => role == 'user';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, role: $role, email: $email)';
  }
}

/// College model for user's college information
class College {
  final String id;
  final String name;
  final String code;

  const College({
    required this.id,
    required this.name,
    required this.code,
  });

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }
}

/// User filters for search and pagination
class UserFilters {
  final String? search;
  final String? role;
  final String? status;
  final String? collegeId;

  const UserFilters({
    this.search,
    this.role,
    this.status,
    this.collegeId,
  });

  /// Convert filters to query parameters
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (role != null && role!.isNotEmpty) {
      params['role'] = role;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }
    if (collegeId != null && collegeId!.isNotEmpty) {
      params['college_id'] = collegeId;
    }

    return params;
  }

  /// Create a copy with updated filters
  UserFilters copyWith({
    String? search,
    String? role,
    String? status,
    String? collegeId,
  }) {
    return UserFilters(
      search: search ?? this.search,
      role: role ?? this.role,
      status: status ?? this.status,
      collegeId: collegeId ?? this.collegeId,
    );
  }

  /// Check if any filters are applied
  bool get hasFilters {
    return search != null ||
        role != null ||
        status != null ||
        collegeId != null;
  }

  /// Clear all filters
  UserFilters clear() {
    return const UserFilters();
  }
}

/// User role enumeration
enum UserRole {
  superAdmin('super_admin', 'Super Admin'),
  collegeAdmin('college_admin', 'College Admin'),
  student('student', 'Student'),
  user('user', 'User');

  const UserRole(this.value, this.displayName);

  final String value;
  final String displayName;

  static UserRole? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return UserRole.values.firstWhere(
        (role) => role.value == value,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => value;
}
