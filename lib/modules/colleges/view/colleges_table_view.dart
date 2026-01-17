import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/colleges_controller.dart';
import '../model/college.dart';
import '../../../common_widgets/common_data_table.dart';
import '../../../common_widgets/shared_sidebar.dart';
import 'add_edit_college_dialog.dart';

/// Colleges table view displaying college management interface
class CollegesTableView extends StatelessWidget {
  const CollegesTableView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CollegesController());

    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation
          SharedSidebar(
            selectedIndex: 3, // Colleges index
            onItemSelected: (index) {
              switch (index) {
                case 0:
                  Get.offNamed('/dashboard');
                  break;
                case 1:
                  Get.offNamed('/users');
                  break;
                case 2:
                  Get.offNamed('/students');
                  break;
                case 3:
                  // Already on colleges page
                  break;
                case 4:
                  Get.offNamed('/books');
                  break;
              }
            },
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

  Widget _buildHeader(CollegesController controller) {
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
                  'Colleges Management',
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage colleges, view statistics, and monitor activities',
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
                onPressed: controller.hasError
                    ? null
                    : controller.refreshColleges,
                icon: Icon(Icons.refresh, color: Get.theme.colorScheme.primary),
                tooltip: 'Refresh colleges',
              ),
              const SizedBox(width: 8),
              if (controller.roleAccessService.canModify('colleges'))
                ElevatedButton.icon(
                  onPressed: () => _showAddCollegeDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add College'),
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

  Widget _buildFiltersSection(CollegesController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search colleges by name, code, or address...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: controller.searchColleges,
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
              initialValue: controller.filters.status,
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
              onPressed: () => controller.applyFilters(const CollegeFilters()),
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _buildDataTableSection(CollegesController controller) {
    if (controller.hasError) {
      return _buildErrorState(controller);
    }

    if (controller.isLoading && !controller.hasColleges) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!controller.hasColleges && !controller.isLoading) {
      return _buildEmptyState(controller);
    }

    return CommonDataTable<College>(
      title: 'Colleges',
      data: controller.colleges,
      columns: _buildColumns(),
      rowBuilder: (colleges) => _buildDataRows(colleges, controller),
      showSearch: false,
      showPagination: true,
      itemsPerPage: CollegesController.itemsPerPage,
      onAdd: controller.roleAccessService.canModify('colleges')
          ? () => _showAddCollegeDialog()
          : null,
    );
  }

  List<DataColumn> _buildColumns() {
    return const [
      DataColumn(label: Text('College'), tooltip: 'College name and code'),
      DataColumn(label: Text('Contact'), tooltip: 'Email and phone'),
      DataColumn(label: Text('Address'), tooltip: 'College address'),
      DataColumn(label: Text('Website'), tooltip: 'College website'),
      DataColumn(label: Text('Status'), tooltip: 'College status'),
      DataColumn(label: Text('Actions'), tooltip: 'Available actions'),
    ];
  }

  List<DataRow> _buildDataRows(
    List<College> colleges,
    CollegesController controller,
  ) {
    return colleges.map((college) {
      return DataRow(
        cells: [
          // College name and code
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  college.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  college.code,
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

          // Contact
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  college.email,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  college.phone,
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

          // Address
          DataCell(
            Text(college.address, overflow: TextOverflow.ellipsis, maxLines: 2),
          ),

          // Website
          DataCell(
            Text(
              college.website,
              style: TextStyle(
                color: Get.theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: college.isActive
                    ? Get.theme.colorScheme.primaryContainer
                    : Get.theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                college.statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: college.isActive
                      ? Get.theme.colorScheme.onPrimaryContainer
                      : Get.theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),

          // Actions
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showCollegeDetails(college, controller),
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View details',
                  iconSize: 18,
                ),
                if (controller.roleAccessService.canModify('colleges'))
                  IconButton(
                    onPressed: () => _showEditCollegeDialog(college),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit college',
                    iconSize: 18,
                  ),
                IconButton(
                  onPressed: () => _showCollegeStats(college, controller),
                  icon: const Icon(Icons.analytics),
                  tooltip: 'View statistics',
                  iconSize: 18,
                  color: Get.theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildErrorState(CollegesController controller) {
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
            'Error Loading Colleges',
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
              controller.refreshColleges();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(CollegesController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Get.theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            controller.filters.hasFilters
                ? 'No Colleges Found'
                : 'No Colleges Available',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Get.theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.filters.hasFilters
                ? 'Try adjusting your search criteria'
                : 'Start by adding some colleges to the system',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (controller.filters.hasFilters)
            TextButton.icon(
              onPressed: () => controller.applyFilters(const CollegeFilters()),
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            )
          else if (controller.roleAccessService.canModify('colleges'))
            ElevatedButton.icon(
              onPressed: () => _showAddCollegeDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First College'),
            ),
        ],
      ),
    );
  }

  void _showAddCollegeDialog() {
    Get.dialog(const AddEditCollegeDialog(), barrierDismissible: false);
  }

  void _showEditCollegeDialog(College college) {
    Get.dialog(
      AddEditCollegeDialog(college: college),
      barrierDismissible: false,
    );
  }

  void _showCollegeDetails(College college, CollegesController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(college.name),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Code', college.code),
              _buildDetailRow('Email', college.email),
              _buildDetailRow('Phone', college.phone),
              _buildDetailRow('Address', college.address),
              _buildDetailRow('Website', college.website),
              _buildDetailRow('Status', college.statusText),
              _buildDetailRow(
                'Created',
                '${college.createdAt.day}/${college.createdAt.month}/${college.createdAt.year}',
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

  void _showCollegeStats(College college, CollegesController controller) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final stats = await controller.getCollegeStats(college.id);
    Get.back(); // Close loading dialog

    if (stats != null) {
      Get.dialog(
        AlertDialog(
          title: Text('${college.name} - Statistics'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard(
                  'Total Students',
                  stats['stats']?['totalStudents']?.toString() ?? '0',
                ),
                _buildStatCard(
                  'Total Admins',
                  stats['stats']?['totalAdmins']?.toString() ?? '0',
                ),
                _buildStatCard(
                  'Total Books',
                  stats['stats']?['totalBooks']?.toString() ?? '0',
                ),
                _buildStatCard(
                  'Total Users',
                  stats['stats']?['totalUsers']?.toString() ?? '0',
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

  Widget _buildStatCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
