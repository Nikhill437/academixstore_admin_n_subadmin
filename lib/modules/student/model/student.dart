/// Student model representing a student user in the system
/// Students are users with role='student' and are associated with a college
class Student {
  final String id;
  final String email;
  final String fullName;
  final String role; // Always 'student'
  final String? collegeId;
  final String? studentId;
  final String? mobile;
  final String? profileImageUrl;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final College? college;
  final String? year;
  const Student({
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
    this.year,
  });

  /// Create Student from JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
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
      year: json['year'],
      college: json['college'] != null
          ? College.fromJson(json['college'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert Student to JSON
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
      'year': year,
      if (college != null) 'college': college!.toJson(),
    };
  }

  /// Create a copy of Student with updated fields
  Student copyWith({
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
    String? year,
  }) {
    return Student(
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
      year: year ?? this.year,
    );
  }

  /// Get status display text
  String get statusText => isActive ? 'Active' : 'Inactive';

  /// Get verification status text
  String get verificationText => isVerified ? 'Verified' : 'Not Verified';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Student(id: $id, fullName: $fullName, studentId: $studentId, college: ${college?.name})';
  }
}

/// College model for student's college information
class College {
  final String id;
  final String name;
  final String code;

  const College({required this.id, required this.name, required this.code});

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }
}

/// Student filters for search and pagination
class StudentFilters {
  final String? search;
  final String? collegeId;
  final String? status;

  const StudentFilters({this.search, this.collegeId, this.status});

  /// Convert filters to query parameters
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (collegeId != null && collegeId!.isNotEmpty) {
      params['collegeId'] = collegeId;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }

    return params;
  }

  /// Create a copy with updated filters
  StudentFilters copyWith({String? search, String? collegeId, String? status}) {
    return StudentFilters(
      search: search ?? this.search,
      collegeId: collegeId ?? this.collegeId,
      status: status ?? this.status,
    );
  }

  /// Check if any filters are applied
  bool get hasFilters => search != null || collegeId != null || status != null;

  /// Clear all filters
  StudentFilters clear() {
    return const StudentFilters();
  }
}
