import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/students_controller.dart';
import '../model/student.dart';
import '../../../services/token_service.dart';
import '../../colleges/controller/colleges_controller.dart';

class AddEditStudentDialog extends StatefulWidget {
  final Student? student;

  const AddEditStudentDialog({super.key, this.student});

  @override
  State<AddEditStudentDialog> createState() => _AddEditStudentDialogState();
}

class _AddEditStudentDialogState extends State<AddEditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final StudentsController _controller = Get.find<StudentsController>();
  final TokenService _tokenService = Get.find<TokenService>();
  final CollegesController _collegesController = Get.find<CollegesController>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _mobileController;
  late final TextEditingController _collegeIdController;
  late final TextEditingController _yearController;
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isPasswordVisible = false; // Add password visibility state

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.student != null;

    _fullNameController = TextEditingController(
      text: widget.student?.fullName ?? '',
    );
    _emailController = TextEditingController(text: widget.student?.email ?? '');
    _passwordController = TextEditingController();
    _studentIdController = TextEditingController(
      text: widget.student?.studentId ?? '',
    );
    _mobileController = TextEditingController(
      text: widget.student?.mobile ?? '',
    );
    _collegeIdController = TextEditingController(
      text: widget.student?.collegeId ?? '',
    );
    _yearController = TextEditingController(text: widget.student?.year ?? '');
    
    // Load colleges if not already loaded
    if (_collegesController.colleges.isEmpty) {
      _collegesController.loadColleges();
    }
    
    // Auto-set college_id for college admins
    _initializeCollegeForUser();
  }
  
  Future<void> _initializeCollegeForUser() async {
    final userRole = await _tokenService.getUserRole();
    final collegeId = await _tokenService.getCollegeId();
    
    if (userRole == 'college_admin' && collegeId != null && !_isEditMode) {
      setState(() {
        _collegeIdController.text = collegeId;
      });
      Get.log('🏫 Auto-set college_id for college admin: $collegeId', isError: false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentIdController.dispose();
    _mobileController.dispose();
    _collegeIdController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final studentData = {
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'student_id': _studentIdController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'college_id': _collegeIdController.text.trim(),
        'year': _yearController.text.trim(),
      };

      // Add password for new students
      if (!_isEditMode && _passwordController.text.isNotEmpty) {
        studentData['password'] = _passwordController.text;
      }

      bool success;
      if (_isEditMode) {
        success = await _controller.updateStudent(
          widget.student!.id,
          studentData,
        );
      } else {
        success = await _controller.registerStudent(studentData);
      }

      if (success) {
        Get.back();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save student: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  _isEditMode ? 'Edit Student' : 'Add New Student',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name *',
                        hint: 'Enter student full name',
                        icon: Icons.person,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email and Student ID
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _emailController,
                              label: 'Email *',
                              hint: 'student@example.com',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (!GetUtils.isEmail(value!)) {
                                  return 'Invalid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _studentIdController,
                              label: 'Student ID *',
                              hint: 'STU2024001',
                              icon: Icons.badge,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Password (only for new students)
                      if (!_isEditMode)
                        _buildPasswordField(),
                      if (!_isEditMode) const SizedBox(height: 16),

                      _buildTextField(
                        controller: _yearController,
                        label: 'Year',
                        hint: "F.Y.M.Sc",
                        icon: Icons.calendar_month,
                      ),

                      SizedBox(height: 10),
                      // Mobile and College ID
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _mobileController,
                              label: 'Mobile',
                              hint: '+91-9999999999',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FutureBuilder<String?>(
                              future: _tokenService.getUserRole(),
                              builder: (context, roleSnapshot) {
                                if (!roleSnapshot.hasData) {
                                  return const CircularProgressIndicator();
                                }
                                
                                final userRole = roleSnapshot.data;
                                final isCollegeAdmin = userRole == 'college_admin';
                                
                                // For college admins, show college name (read-only)
                                if (isCollegeAdmin) {
                                  return Obx(() {
                                    final colleges = _collegesController.colleges;
                                    final isLoading = _collegesController.isLoading;
                                    
                                    // Wait for colleges to load
                                    if (isLoading || colleges.isEmpty) {
                                      return _buildTextField(
                                        controller: TextEditingController(text: 'Loading colleges...'),
                                        label: 'College',
                                        hint: 'Loading...',
                                        icon: Icons.school,
                                        enabled: false,
                                      );
                                    }
                                    
                                    final selectedCollege = colleges.firstWhereOrNull(
                                      (c) => c.id == _collegeIdController.text,
                                    );
                                    
                                    return _buildTextField(
                                      controller: TextEditingController(
                                        text: selectedCollege?.name ?? 'College not found',
                                      ),
                                      label: 'College',
                                      hint: 'Your college',
                                      icon: Icons.school,
                                      enabled: false, // Read-only for college admins
                                    );
                                  });
                                }
                                
                                // For super admins, show editable field
                                return _buildTextField(
                                  controller: _collegeIdController,
                                  label: 'College ID *',
                                  hint: 'Enter college UUID',
                                  icon: Icons.school,
                                  validator: (value) =>
                                      value?.isEmpty ?? true ? 'Required' : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Info text
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Students must be associated with a college. Make sure to enter a valid college ID.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditMode ? 'Update Student' : 'Add Student'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required';
            if (value!.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Enter password',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
