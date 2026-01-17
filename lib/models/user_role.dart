/// User role enumeration defining different access levels in the system
/// Each role has specific permissions and module access rights
enum UserRole {
  /// Super Admin - Full access to all modules and functionalities
  superAdmin('super_admin', 'Super Admin', 100),

  /// College Admin - Limited access to books and students modules only
  collegeAdmin('college_admin', 'College Admin', 50),

  /// Teacher - Future role for teaching staff (placeholder for extensibility)
  teacher('teacher', 'Teacher', 30),

  /// Staff - Future role for support staff (placeholder for extensibility)
  staff('staff', 'Staff', 20),

  /// Guest - Read-only access (placeholder for extensibility)
  guest('guest', 'Guest', 10);

  const UserRole(this.value, this.displayName, this.priority);

  /// The string value stored in JWT token
  final String value;

  /// Human-readable display name
  final String displayName;

  /// Priority level for role hierarchy (higher = more permissions)
  final int priority;

  /// Check if this role has higher or equal priority than another role
  bool hasHigherOrEqualPriorityThan(UserRole other) {
    return priority >= other.priority;
  }

  /// Check if this role has higher priority than another role
  bool hasHigherPriorityThan(UserRole other) {
    return priority > other.priority;
  }

  /// Create UserRole from string value (used when parsing JWT token)
  static UserRole? fromString(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      return UserRole.values.firstWhere(
        (role) => role.value == value.toLowerCase(),
      );
    } catch (e) {
      return null; // Return null for invalid role values
    }
  }

  /// Get all roles with lower priority than this role
  List<UserRole> getSubordinateRoles() {
    return UserRole.values.where((role) => role.priority < priority).toList();
  }

  /// Check if this is an admin-level role
  bool get isAdmin =>
      this == UserRole.superAdmin || this == UserRole.collegeAdmin;

  /// Check if this role can manage other users
  bool get canManageUsers => this == UserRole.superAdmin;

  /// Check if this role can access system settings
  bool get canAccessSystemSettings => this == UserRole.superAdmin;

  @override
  String toString() => value;
}

/// Access modules enumeration defining different functional areas
/// Each module represents a distinct feature set in the application
enum AccessModule {
  /// Dashboard - Overview and analytics
  dashboard('dashboard', 'Dashboard', 'Dashboard and analytics overview'),

  /// Users - User management functionality
  users('users', 'Users', 'User account management and administration'),

  /// Students - Student management functionality
  students('students', 'Students', 'Student records and academic management'),

  /// Colleges - College/Institution management
  colleges('colleges', 'Colleges', 'Educational institution management'),

  /// Books - Book inventory and management
  books('books', 'Books', 'Book catalog and inventory management'),

  /// Auth Logs - Authentication and security logs
  authLogs(
    'auth_logs',
    'Auth Logs',
    'Authentication logs and security monitoring',
  ),

  /// Reports - Reporting and analytics (future extension)
  reports('reports', 'Reports', 'Advanced reporting and analytics'),

  /// Settings - System configuration (future extension)
  settings('settings', 'Settings', 'System configuration and preferences');

  const AccessModule(this.value, this.displayName, this.description);

  /// The string identifier for the module
  final String value;

  /// Human-readable display name
  final String displayName;

  /// Detailed description of module functionality
  final String description;

  /// Create AccessModule from string value
  static AccessModule? fromString(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      return AccessModule.values.firstWhere(
        (module) => module.value == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get route path for this module
  String get routePath => '/$value';

  /// Check if this module requires admin privileges
  bool get requiresAdminAccess {
    return this == AccessModule.users ||
        this == AccessModule.colleges ||
        this == AccessModule.authLogs ||
        this == AccessModule.settings;
  }

  /// Check if this module is available for college admins
  bool get availableForCollegeAdmin {
    return this == AccessModule.dashboard ||
        this == AccessModule.students ||
        this == AccessModule.books;
  }

  @override
  String toString() => value;
}

/// Role permission configuration class
/// Defines which modules each role can access
class RolePermissions {
  static const Map<UserRole, List<AccessModule>> _permissions = {
    UserRole.superAdmin: [
      AccessModule.dashboard,
      AccessModule.users,
      AccessModule.students,
      AccessModule.colleges,
      AccessModule.books,
      AccessModule.authLogs,
      AccessModule.reports,
      AccessModule.settings,
    ],

    UserRole.collegeAdmin: [
      AccessModule.dashboard,
      AccessModule.students,
      AccessModule.books,
    ],

    UserRole.teacher: [AccessModule.dashboard, AccessModule.students],

    UserRole.staff: [AccessModule.dashboard],

    UserRole.guest: [AccessModule.dashboard],
  };

  /// Get all modules accessible by a specific role
  static List<AccessModule> getModulesForRole(UserRole role) {
    return _permissions[role] ?? [];
  }

  /// Check if a role has access to a specific module
  static bool hasModuleAccess(UserRole role, AccessModule module) {
    return _permissions[role]?.contains(module) ?? false;
  }

  /// Get all roles that can access a specific module
  static List<UserRole> getRolesForModule(AccessModule module) {
    return _permissions.entries
        .where((entry) => entry.value.contains(module))
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if a role can perform CRUD operations on a module
  static bool canModify(UserRole role, AccessModule module) {
    // Only super admin can modify users, colleges, and system settings
    if (module == AccessModule.users ||
        module == AccessModule.colleges ||
        module == AccessModule.settings) {
      return role == UserRole.superAdmin;
    }

    // College admin can modify students and books
    if (module == AccessModule.students || module == AccessModule.books) {
      return role == UserRole.superAdmin || role == UserRole.collegeAdmin;
    }

    // Dashboard and reports are read-only for most roles
    return false;
  }

  /// Get navigation menu items based on role
  static List<AccessModule> getNavigationModules(UserRole role) {
    return getModulesForRole(role)
        .where(
          (module) => module != AccessModule.settings,
        ) // Settings not in main nav
        .toList();
  }
}
