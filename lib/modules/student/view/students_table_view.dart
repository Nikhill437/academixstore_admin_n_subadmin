import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/students_controller.dart';
import '../model/student.dart';
import '../../../common_widgets/common_data_table.dart';
import '../../../common_widgets/shared_sidebar.dart';
import 'add_edit_student_dialog.dart';

/// Students table view displaying student management interface
class StudentsTableView extends StatelessWidget {
  const StudentsTableView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StudentsController());
    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation
          SharedSidebar(
            selectedIndex: 2, // Students index
            onItemSelected: (index) {
              switch (index) {
                case 0:
                  Get.offNamed('/dashboard');
                  break;
                case 1:
                  Get.offNamed('/users');
                  break;
                case 2:
                  // Already on students page
                  break;
                case 3:
                  Get.offNamed('/colleges');
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

  Widget _buildHeader(StudentsController controller) {
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
                  'Students Management',
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage students, view profiles, and monitor activities',
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
                    : controller.refreshStudents,
                icon: Icon(Icons.refresh, color: Get.theme.colorScheme.primary),
                tooltip: 'Refresh students',
              ),
              const SizedBox(width: 8),
              if (controller.roleAccessService.canModify('students'))
                ElevatedButton.icon(
                  onPressed: () => _showAddStudentDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
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

  Widget _buildFiltersSection(StudentsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students by name, email, or student ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: controller.searchStudents,
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
              onPressed: () => controller.applyFilters(const StudentFilters()),
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _buildDataTableSection(StudentsController controller) {
    if (controller.hasError) {
      return _buildErrorState(controller);
    }

    if (controller.isLoading && !controller.hasStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!controller.hasStudents && !controller.isLoading) {
      return _buildEmptyState(controller);
    }

    return CommonDataTable<Student>(
      title: 'Students',
      data: controller.students,
      columns: _buildColumns(),
      rowBuilder: (students) => _buildDataRows(students, controller),
      showSearch: false,
      showPagination: true,
      itemsPerPage: StudentsController.itemsPerPage,
      onAdd: controller.roleAccessService.canModify('students')
          ? () => _showAddStudentDialog()
          : null,
    );
  }

  List<DataColumn> _buildColumns() {
    return const [
      DataColumn(label: Text('Student'), tooltip: 'Student name and ID'),
      DataColumn(label: Text('Email'), tooltip: 'Student email'),
      DataColumn(label: Text('College'), tooltip: 'Associated college'),
      DataColumn(label: Text('Mobile'), tooltip: 'Contact number'),
      DataColumn(label: Text('Status'), tooltip: 'Account status'),
      DataColumn(label: Text('Verified'), tooltip: 'Verification status'),
      DataColumn(label: Text('Actions'), tooltip: 'Available actions'),
    ];
  }

  List<DataRow> _buildDataRows(
    List<Student> students,
    StudentsController controller,
  ) {
    return students.map((student) {
      return DataRow(
        cells: [
          // Student name and ID
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                if (student.studentId != null)
                  Text(
                    student.studentId!,
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

          // Email
          DataCell(Text(student.email, overflow: TextOverflow.ellipsis)),

          // College
          DataCell(
            Text(
              student.college?.name ?? 'N/A',
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Mobile
          DataCell(
            Text(student.mobile ?? 'N/A', overflow: TextOverflow.ellipsis),
          ),

          // Status
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: student.isActive
                    ? Get.theme.colorScheme.primaryContainer
                    : Get.theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                student.statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: student.isActive
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
                  student.isVerified ? Icons.verified : Icons.pending,
                  size: 16,
                  color: student.isVerified ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  student.verificationText,
                  style: TextStyle(
                    fontSize: 12,
                    color: student.isVerified ? Colors.green : Colors.orange,
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
                  onPressed: () => _showStudentDetails(student),
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View details',
                  iconSize: 18,
                ),
                if (controller.roleAccessService.canModify('students'))
                  IconButton(
                    onPressed: () => _showEditStudentDialog(student),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit student',
                    iconSize: 18,
                  ),
                if (controller.roleAccessService.canModify('students'))
                  IconButton(
                    onPressed: () => student.isActive
                        ? _showDeactivateDialog(student, controller)
                        : controller.activateStudent(student.id),
                    icon: Icon(
                      student.isActive ? Icons.block : Icons.check_circle,
                    ),
                    tooltip: student.isActive ? 'Deactivate' : 'Activate',
                    iconSize: 18,
                    color: student.isActive
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

  Widget _buildErrorState(StudentsController controller) {
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
            'Error Loading Students',
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
              controller.refreshStudents();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(StudentsController controller) {
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
                ? 'No Students Found'
                : 'No Students Available',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Get.theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.filters.hasFilters
                ? 'Try adjusting your search criteria'
                : 'Start by adding some students to the system',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (controller.filters.hasFilters)
            TextButton.icon(
              onPressed: () => controller.applyFilters(const StudentFilters()),
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            )
          else if (controller.roleAccessService.canModify('students'))
            ElevatedButton.icon(
              onPressed: () => _showAddStudentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Student'),
            ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    Get.dialog(const AddEditStudentDialog(), barrierDismissible: false);
  }

  void _showEditStudentDialog(Student student) {
    Get.dialog(
      AddEditStudentDialog(student: student),
      barrierDismissible: false,
    );
  }

  void _showStudentDetails(Student student) {
    Get.dialog(
      AlertDialog(
        title: Text(student.fullName),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (student.studentId != null)
                _buildDetailRow('Student ID', student.studentId!),
              _buildDetailRow('Email', student.email),
              if (student.mobile != null)
                _buildDetailRow('Mobile', student.mobile!),
              if (student.college != null)
                _buildDetailRow(
                  'College',
                  '${student.college!.name} (${student.college!.code})',
                ),
              _buildDetailRow('Status', student.statusText),
              _buildDetailRow('Verified', student.verificationText),
              _buildDetailRow(
                'Registered',
                '${student.createdAt.day}/${student.createdAt.month}/${student.createdAt.year}',
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

  void _showDeactivateDialog(Student student, StudentsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Deactivate Student'),
        content: Text(
          'Are you sure you want to deactivate ${student.fullName}? They will not be able to access the system.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deactivateStudent(student.id);
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
