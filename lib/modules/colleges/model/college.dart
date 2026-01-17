/// College model representing a college/university entity
/// Matches the API response structure from the backend
class College {
  final String id;
  final String name;
  final String code;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const College({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    this.logoUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create College from JSON
  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String,
      website: json['website'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert College to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'logo_url': logoUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of College with updated fields
  College copyWith({
    String? id,
    String? name,
    String? code,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return College(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get status display text
  String get statusText => isActive ? 'Active' : 'Inactive';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is College && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'College(id: $id, name: $name, code: $code, isActive: $isActive)';
  }
}

/// College statistics model
class CollegeStats {
  final College college;
  final int totalStudents;
  final int totalAdmins;
  final int totalBooks;
  final int totalUsers;
  final List<CategoryCount> booksByCategory;
  final List<dynamic> recentUsers;
  final List<dynamic> recentBooks;

  const CollegeStats({
    required this.college,
    required this.totalStudents,
    required this.totalAdmins,
    required this.totalBooks,
    required this.totalUsers,
    required this.booksByCategory,
    required this.recentUsers,
    required this.recentBooks,
  });

  factory CollegeStats.fromJson(Map<String, dynamic> json) {
    return CollegeStats(
      college: College.fromJson(json['college'] as Map<String, dynamic>),
      totalStudents: (json['stats']?['totalStudents'] ?? 0) as int,
      totalAdmins: (json['stats']?['totalAdmins'] ?? 0) as int,
      totalBooks: (json['stats']?['totalBooks'] ?? 0) as int,
      totalUsers: (json['stats']?['totalUsers'] ?? 0) as int,
      booksByCategory: (json['booksByCategory'] as List<dynamic>?)
              ?.map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentUsers: (json['recentUsers'] as List<dynamic>?) ?? [],
      recentBooks: (json['recentBooks'] as List<dynamic>?) ?? [],
    );
  }
}

/// Category count model for statistics
class CategoryCount {
  final String category;
  final int count;

  const CategoryCount({
    required this.category,
    required this.count,
  });

  factory CategoryCount.fromJson(Map<String, dynamic> json) {
    return CategoryCount(
      category: json['category'] as String,
      count: json['count'] as int,
    );
  }
}

/// College filters for search and pagination
class CollegeFilters {
  final String? search;
  final String? status;

  const CollegeFilters({
    this.search,
    this.status,
  });

  /// Convert filters to query parameters
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }

    return params;
  }

  /// Create a copy with updated filters
  CollegeFilters copyWith({
    String? search,
    String? status,
  }) {
    return CollegeFilters(
      search: search ?? this.search,
      status: status ?? this.status,
    );
  }

  /// Check if any filters are applied
  bool get hasFilters => search != null || status != null;

  /// Clear all filters
  CollegeFilters clear() {
    return const CollegeFilters();
  }
}
