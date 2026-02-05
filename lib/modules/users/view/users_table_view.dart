import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/users_controller.dart';
import '../model/user.dart';
import '../../../common_widgets/common_data_table.dart';
import '../../../common_widgets/shared_sidebar.dart';
import '../../auth/controller/auth_controller.dart';
import 'add_edit_user_dialog.dart';

/// Users table view displaying user management interface
class UsersTableView extends StatelessWidget {
  const UsersTableView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller if it's not already initialized
    final controller = Get.put(UsersController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation
          SharedSidebar(
            selectedIndex: 1, // Users index
            onItemSelected: (index) {
              switch (index) {
                case 0:
                  Get.offNamed('/dashboard');
                  break;
                case 1:
                  // Already on users page
                  break;
                case 2:
                  Get.offNamed('/students');
                  break;
                case 3:
                  Get.offNamed('/colleges');
                  break;
                case 4:
                  Get.offNamed('/books');
                  break;
              }
            },
            onLogout: () => authController.logout(),
          ),

          // Main content area
          Expanded(
            child: Container(
              color: Colors.white,
              child: Obx(
                () => Column(
                  children: [
                    _buildHeader(controller),
                    _buildFiltersSection(controller),
                    Expanded(child: _buildDataTableSection(controller)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UsersController controller) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Get.theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Users Management',
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage all system users including admins, students, and individual users',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Get.theme.colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: controller.hasError ? null : controller.refreshUsers,
                icon: Icon(Icons.refresh, color: Get.theme.colorScheme.primary),
                tooltip: 'Refresh users',
              ),
              const SizedBox(width: 8),
              if (controller.roleAccessService.canModify('users'))
                ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Get.theme.colorScheme.primary,
                    foregroundColor: Get.theme.colorScheme.onPrimary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(UsersController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: controller.searchUsers,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              value: controller.filters.role,
              items: const [
                DropdownMenuItem<String>(value: null, child: Text('All Roles')),
                DropdownMenuItem<String>(
                  value: 'super_admin',
                  child: Text('Super Admin'),
                ),
                DropdownMenuItem<String>(
                  value: 'college_admin',
                  child: Text('College Admin'),
                ),
                DropdownMenuItem<String>(
                  value: 'student',
                  child: Text('Student'),
                ),
                DropdownMenuItem<String>(value: 'user', child: Text('User')),
              ],
              onChanged: (value) {
                final newFilters = controller.filters.copyWith(role: value);
                controller.applyFilters(newFilters);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              value: controller.filters.status,
              items: const [
                DropdownMenuItem<String>(value: null, child: Text('All')),
                DropdownMenuItem<String>(
                  value: 'active',
                  child: Text('Active'),
                ),
                DropdownMenuItem<String>(
                  value: 'inactive',
                  child: Text('Inactive'),
                ),
              ],
              onChanged: (value) {
                final newFilters = controller.filters.copyWith(status: value);
                controller.applyFilters(newFilters);
              },
            ),
          ),
          const SizedBox(width: 16),
          if (controller.filters.hasFilters)
            TextButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _buildDataTableSection(UsersController controller) {
    if (controller.hasError) {
      return _buildErrorState(controller);
    }

    if (controller.isLoading && !controller.hasUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!controller.hasUsers && !controller.isLoading) {
      return _buildEmptyState(controller);
    }

    return CommonDataTable<User>(
      title: 'Users',
      data: controller.users,
      columns: _buildColumns(),
      rowBuilder: (users) => _buildDataRows(users, controller),
      showSearch: false,
      showPagination: true,
      itemsPerPage: UsersController.itemsPerPage,
      onAdd: controller.roleAccessService.canModify('users')
          ? () => _showAddUserDialog()
          : null,
    );
  }

  List<DataColumn> _buildColumns() {
    return const [
      DataColumn(label: Text('User'), tooltip: 'User name and email'),
      DataColumn(label: Text('Role'), tooltip: 'User role'),
      DataColumn(label: Text('College'), tooltip: 'Associated college'),
      DataColumn(label: Text('Mobile'), tooltip: 'Contact number'),
      DataColumn(label: Text('Status'), tooltip: 'Account status'),
      DataColumn(label: Text('Verified'), tooltip: 'Verification status'),
      DataColumn(label: Text('Actions'), tooltip: 'Available actions'),
    ];
  }

  List<DataRow> _buildDataRows(List<User> users, UsersController controller) {
    return users.map((user) {
      return DataRow(
        cells: [
          // User name and email
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Get.theme.colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Role
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _getRoleColor(user.role)),
              ),
              child: Text(
                user.roleDisplayText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getRoleColor(user.role),
                ),
              ),
            ),
          ),

          // College
          DataCell(
            Text(
              user.college?.name ??
                  (user.isStudent || user.isCollegeAdmin ? 'N/A' : '-'),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Mobile
          DataCell(Text(user.mobile ?? 'N/A', overflow: TextOverflow.ellipsis)),

          // Status
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isActive
                    ? Get.theme.colorScheme.primaryContainer
                    : Get.theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: user.isActive
                      ? Get.theme.colorScheme.onPrimaryContainer
                      : Get.theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),

          // Verified
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isVerified ? Icons.verified : Icons.pending,
                  size: 16,
                  color: user.isVerified ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  user.verificationText,
                  style: TextStyle(
                    fontSize: 12,
                    color: user.isVerified ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showUserDetails(user),
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View details',
                  iconSize: 18,
                ),
                if (controller.roleAccessService.canModify('users'))
                  IconButton(
                    onPressed: () => _showEditUserDialog(user),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit user',
                    iconSize: 18,
                  ),
                if (controller.roleAccessService.canModify('users'))
                  IconButton(
                    onPressed: () => user.isActive
                        ? _showDeactivateDialog(user, controller)
                        : controller.activateUser(user.id),
                    icon: Icon(
                      user.isActive ? Icons.block : Icons.check_circle,
                    ),
                    tooltip: user.isActive ? 'Deactivate' : 'Activate',
                    iconSize: 18,
                    color: user.isActive
                        ? Get.theme.colorScheme.error
                        : Get.theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'college_admin':
        return Colors.blue;
      case 'student':
        return Colors.green;
      case 'user':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildErrorState(UsersController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Get.theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Users',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Get.theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.error,
            style: Get.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              controller.clearError();
              controller.refreshUsers();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(UsersController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Get.theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            controller.filters.hasFilters
                ? 'No Users Found'
                : 'No Users Available',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Get.theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.filters.hasFilters
                ? 'Try adjusting your search criteria'
                : 'Start by adding some users to the system',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (controller.filters.hasFilters)
            TextButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            )
          else if (controller.roleAccessService.canModify('users'))
            ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First User'),
            ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    Get.dialog(const AddEditUserDialog(), barrierDismissible: false);
  }

  void _showEditUserDialog(User user) {
    Get.dialog(AddEditUserDialog(user: user), barrierDismissible: false);
  }

  void _showUserDetails(User user) {
    Get.dialog(
      AlertDialog(
        title: Text(user.fullName),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Role', user.roleDisplayText),
              if (user.studentId != null)
                _buildDetailRow('Student ID', user.studentId!),
              if (user.mobile != null) _buildDetailRow('Mobile', user.mobile!),
              if (user.college != null)
                _buildDetailRow(
                  'College',
                  '${user.college!.name} (${user.college!.code})',
                ),
              _buildDetailRow('Status', user.statusText),
              _buildDetailRow('Verified', user.verificationText),
              _buildDetailRow(
                'Registered',
                '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showDeactivateDialog(User user, UsersController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Deactivate User'),
        content: Text(
          'Are you sure you want to deactivate ${user.fullName}? They will not be able to access the system.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deactivateUser(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
