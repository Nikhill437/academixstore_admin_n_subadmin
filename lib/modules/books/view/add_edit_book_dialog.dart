import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../controller/books_controller.dart';
import '../../../models/book.dart';
import '../../colleges/controller/colleges_controller.dart';
import '../../../services/file_validation_service.dart';

class AddEditBookDialog extends StatefulWidget {
  final Book? book; // null for add, Book instance for edit

  const AddEditBookDialog({super.key, this.book});

  @override
  State<AddEditBookDialog> createState() => _AddEditBookDialogState();
}

class _AddEditBookDialogState extends State<AddEditBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final BooksController _booksController = Get.find<BooksController>();
  final CollegesController _collegesController = Get.find<CollegesController>();

  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _authorController;
  late final TextEditingController _isbnController;
  late final TextEditingController _publisherController;
  late final TextEditingController _publicationYearController;
  late final TextEditingController _categoryController;
  late final TextEditingController _subjectController;
  late final TextEditingController _languageController;
  late final TextEditingController _yearController;
  late final TextEditingController _semesterController;
  late final TextEditingController _pagesController;
  late final TextEditingController _rateController;
  late final TextEditingController _ratingController;
  // Selected college
  String? _selectedCollegeId;

  // File paths and bytes
  String? _pdfFilePath;
  String? _coverFilePath;
  String? _pdfFileName;
  String? _coverFileName;
  List<int>? _pdfFileBytes;
  List<int>? _coverFileBytes;

  bool _isLoading = false;
  bool _isEditMode = false;

  // Question paper form state variables
  final _questionPaperFormKey = GlobalKey<FormState>();
  late final TextEditingController _qpTitleController;
  late final TextEditingController _qpSubjectController;
  late final TextEditingController _qpYearController;
  late final TextEditingController _qpSemesterController;
  late final TextEditingController _qpDescriptionController;
  late final TextEditingController _qpMarksController;
  String? _qpExamType;
  String? _qpPdfFilePath;
  String? _qpPdfFileName;
  List<int>? _qpPdfFileBytes;
  bool _showQuestionPaperForm = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.book != null;

    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(text: widget.book?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.book?.description ?? '',
    );
    _authorController = TextEditingController(
      text: widget.book?.authorname ?? '',
    );
    _isbnController = TextEditingController(text: widget.book?.isbn ?? '');
    _publisherController = TextEditingController(
      text: widget.book?.publisher ?? '',
    );
    _publicationYearController = TextEditingController(
      text: widget.book?.publicationYear?.toString() ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.book?.category ?? '',
    );
    _subjectController = TextEditingController(
      text: widget.book?.subject ?? '',
    );
    _languageController = TextEditingController(
      text: widget.book?.language ?? 'English',
    );
    _yearController = TextEditingController(
      text: widget.book?.year?.toString() ?? '',
    );
    _semesterController = TextEditingController(
      text: widget.book?.semester?.toString() ?? '',
    );
    _pagesController = TextEditingController(
      text: widget.book?.pages?.toString() ?? '',
    );
    _rateController = TextEditingController(
      text: widget.book?.rate?.toString() ?? '',
    );
    _ratingController = TextEditingController(
      text: widget.book?.rating?.toString() ?? '',
    );
    // Set selected college if editing
    _selectedCollegeId = widget.book?.collegeId;

    // Initialize question paper controllers
    _qpTitleController = TextEditingController();
    _qpSubjectController = TextEditingController();
    _qpYearController = TextEditingController();
    _qpSemesterController = TextEditingController();
    _qpDescriptionController = TextEditingController();
    _qpMarksController = TextEditingController();

    // Load colleges if not already loaded
    if (_collegesController.colleges.isEmpty) {
      _collegesController.loadColleges();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _publicationYearController.dispose();
    _categoryController.dispose();
    _subjectController.dispose();
    _languageController.dispose();
    _yearController.dispose();
    _semesterController.dispose();
    _pagesController.dispose();
    _rateController.dispose();
    _ratingController.dispose();
    
    // Dispose question paper controllers
    _qpTitleController.dispose();
    _qpSubjectController.dispose();
    _qpYearController.dispose();
    _qpSemesterController.dispose();
    _qpDescriptionController.dispose();
    _qpMarksController.dispose();
    
    // Clear question papers list when dialog closes
    _booksController.clearQuestionPapers();
    
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      Get.log('📄 Starting PDF file picker...', isError: false);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Important: enables bytes for web platform
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;

        // Determine platform and get appropriate file data
        String? filePath;
        List<int>? fileBytes;

        if (file.bytes != null) {
          // Web platform: use bytes
          fileBytes = file.bytes;
          Get.log(
            '✅ PDF file selected (web): ${file.name}, bytes: ${fileBytes!.length}',
            isError: false,
          );
        } else {
          // Desktop/Mobile platform: use path
          filePath = file.path;
          Get.log(
            '✅ PDF file selected (desktop): ${file.name}, path: $filePath',
            isError: false,
          );
        }

        setState(() {
          _pdfFilePath = filePath;
          _pdfFileName = file.name;
          _pdfFileBytes = fileBytes;
        });

        Get.snackbar(
          'Success',
          'PDF file selected: ${file.name}',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.log('ℹ️ No file selected', isError: false);
      }
    } catch (e, stackTrace) {
      Get.log('❌ Error picking PDF file: $e', isError: true);
      Get.log('Stack trace: $stackTrace', isError: true);
      Get.snackbar(
        'Error',
        'Failed to pick PDF file: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      Get.log('🖼️ Starting cover image picker...', isError: false);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // Important: enables bytes for web platform
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;

        // Determine platform and get appropriate file data
        String? filePath;
        List<int>? fileBytes;

        if (file.bytes != null) {
          // Web platform: use bytes
          fileBytes = file.bytes;
          Get.log(
            '✅ Cover image selected (web): ${file.name}, bytes: ${fileBytes!.length}',
            isError: false,
          );
        } else {
          // Desktop/Mobile platform: use path
          filePath = file.path;
          Get.log(
            '✅ Cover image selected (desktop): ${file.name}, path: $filePath',
            isError: false,
          );
        }

        setState(() {
          _coverFilePath = filePath;
          _coverFileName = file.name;
          _coverFileBytes = fileBytes;
        });

        Get.snackbar(
          'Success',
          'Cover image selected: ${file.name}',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.log('ℹ️ No image selected', isError: false);
      }
    } catch (e, stackTrace) {
      Get.log('❌ Error picking cover image: $e', isError: true);
      Get.log('Stack trace: $stackTrace', isError: true);
      Get.snackbar(
        'Error',
        'Failed to pick cover image: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> _pickQuestionPaperPdf() async {
    try {
      Get.log('📄 Starting question paper PDF picker...', isError: false);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;

        // Validate file using FileValidationService
        final validationService = FileValidationService();
        final validationResult = validationService.validatePdfFile(
          fileName: file.name,
          fileSizeBytes: file.size,
        );

        if (!validationResult.isValid) {
          Get.snackbar(
            'Invalid File',
            validationResult.errorMessage!,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade900,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }

        String? filePath;
        List<int>? fileBytes;

        if (file.bytes != null) {
          fileBytes = file.bytes;
          Get.log('✅ Question paper PDF selected (web): ${file.name}', 
            isError: false);
        } else {
          filePath = file.path;
          Get.log('✅ Question paper PDF selected (desktop): ${file.name}', 
            isError: false);
        }

        setState(() {
          _qpPdfFilePath = filePath;
          _qpPdfFileName = file.name;
          _qpPdfFileBytes = fileBytes;
        });

        Get.snackbar(
          'Success',
          'PDF file selected: ${file.name}',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.log('❌ Error picking question paper PDF: $e', isError: true);
      Get.snackbar(
        'Error',
        'Failed to pick PDF file: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // Validation methods for question paper form
  String? _validateRequiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Year is required';
    }
    final year = int.tryParse(value.trim());
    if (year == null) {
      return 'Year must be a number';
    }
    if (year < 1 || year > 4) {
      return 'Year must be between 1 and 4';
    }
    return null;
  }

  String? _validateSemester(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Semester is required';
    }
    final semester = int.tryParse(value.trim());
    if (semester == null) {
      return 'Semester must be a number';
    }
    if (semester < 1 || semester > 8) {
      return 'Semester must be between 1 and 8';
    }
    return null;
  }

  String? _validateMarks(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Marks is optional
    }
    final marks = int.tryParse(value.trim());
    if (marks == null) {
      return 'Marks must be a number';
    }
    if (marks < 0) {
      return 'Marks must be a positive number';
    }
    return null;
  }

  bool _isQuestionPaperFormValid() {
    return _questionPaperFormKey.currentState?.validate() ?? false;
  }

  bool _isQuestionPaperSaveEnabled() {
    // Save is enabled when form is valid and PDF is selected
    return _qpPdfFileName != null && 
           _qpTitleController.text.trim().isNotEmpty &&
           _qpSubjectController.text.trim().isNotEmpty &&
           _qpYearController.text.trim().isNotEmpty &&
           _qpSemesterController.text.trim().isNotEmpty;
  }

  Future<void> _saveQuestionPaper() async {
    // Validate form
    if (!_questionPaperFormKey.currentState!.validate()) {
      Get.snackbar(
        'Validation Error',
        'Please fill in all required fields correctly',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // Check that PDF file is selected
    if (_qpPdfFileName == null) {
      Get.snackbar(
        'PDF Required',
        'Please select a PDF file for the question paper',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // Build question paper data map from form fields
    final questionPaperData = {
      'title': _qpTitleController.text.trim(),
      'subject': _qpSubjectController.text.trim(),
      'year': int.parse(_qpYearController.text.trim()),
      'semester': int.parse(_qpSemesterController.text.trim()),
      if (_qpDescriptionController.text.trim().isNotEmpty)
        'description': _qpDescriptionController.text.trim(),
      if (_qpExamType != null) 'exam_type': _qpExamType,
      if (_qpMarksController.text.trim().isNotEmpty)
        'marks': int.parse(_qpMarksController.text.trim()),
      if (_selectedCollegeId != null) 'college_id': _selectedCollegeId,
    };

    // Call BooksController.createQuestionPaperWithPdf
    final questionPaper = await _booksController.createQuestionPaperWithPdf(
      questionPaperData,
      _qpPdfFilePath,
      pdfFileBytes: _qpPdfFileBytes,
      pdfFileName: _qpPdfFileName,
    );

    // Clear form and hide form on success
    if (questionPaper != null) {
      _clearQuestionPaperForm();
      setState(() {
        _showQuestionPaperForm = false;
      });
    }
  }

  void _clearQuestionPaperForm() {
    // Clear all text controllers
    _qpTitleController.clear();
    _qpSubjectController.clear();
    _qpYearController.clear();
    _qpSemesterController.clear();
    _qpDescriptionController.clear();
    _qpMarksController.clear();
    
    // Reset exam type dropdown
    setState(() {
      _qpExamType = null;
      
      // Clear file selection state
      _qpPdfFilePath = null;
      _qpPdfFileName = null;
      _qpPdfFileBytes = null;
    });
  }

  Future<void> _deleteQuestionPaper(String questionPaperId) async {
    // Show confirmation dialog when delete button is clicked
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Question Paper'),
        content: const Text(
          'Are you sure you want to delete this question paper? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Handle cancellation gracefully
    if (confirmed != true) {
      return;
    }

    // Call BooksController.deleteQuestionPaper on confirmation
    await _booksController.deleteQuestionPaper(questionPaperId);
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Validation Error',
        'Please fill in all required fields',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse and validate required numeric fields
      final year = int.tryParse(_yearController.text.trim());
      final semester = int.tryParse(_semesterController.text.trim());

      if (year == null) {
        Get.snackbar(
          'Invalid Year',
          'Please enter a valid year (e.g., 2024)',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.TOP,
        );
        setState(() => _isLoading = false);
        return;
      }

      if (semester == null) {
        Get.snackbar(
          'Invalid Semester',
          'Please enter a valid semester (1-8)',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.TOP,
        );
        setState(() => _isLoading = false);
        return;
      }

      final bookData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'authorname': _authorController.text.trim(),
        'isbn': _isbnController.text.trim(),
        'publisher': _publisherController.text.trim(),
        'rate': _rateController.text.trim(),
        'rating': _ratingController.text.trim(),
        'publication_year': int.tryParse(
          _publicationYearController.text.trim(),
        ),
        'category': _categoryController.text.trim(),
        'subject': _subjectController.text.trim(),
        'language': _languageController.text.trim(),
        'year': year,
        'semester': semester,
        'pages': int.tryParse(_pagesController.text.trim()),
        if (_selectedCollegeId != null)
          'college_id': _selectedCollegeId, // Only add if selected
      };

      Get.log('📝 Book data to send: $bookData', isError: false);

      String? bookId;

      if (_isEditMode) {
        // Update existing book
        final success = await _booksController.updateBook(
          widget.book!.id,
          bookData,
        );
        if (success) {
          bookId = widget.book!.id;
        }
      } else {
        // Create new book and get the ID
        bookId = await _booksController.createBook(bookData);
      }

      if (bookId != null) {
        Get.log('📚 Book saved with ID: $bookId', isError: false);

        // Upload PDF if selected
        if (_pdfFileName != null &&
            (_pdfFilePath != null || _pdfFileBytes != null)) {
          Get.log('📄 Uploading PDF: $_pdfFileName', isError: false);
          final pdfSuccess = await _booksController.uploadBookPdf(
            bookId,
            _pdfFilePath,
            fileBytes: _pdfFileBytes,
            fileName: _pdfFileName,
          );
          if (pdfSuccess) {
            Get.log('✅ PDF uploaded successfully', isError: false);
          } else {
            Get.log('❌ PDF upload failed', isError: true);
          }
        }

        // Upload cover if selected
        if (_coverFileName != null &&
            (_coverFilePath != null || _coverFileBytes != null)) {
          Get.log('🖼️ Uploading cover: $_coverFileName', isError: false);
          final coverSuccess = await _booksController.uploadBookCover(
            bookId,
            _coverFilePath,
            fileBytes: _coverFileBytes,
            fileName: _coverFileName,
          );
          if (coverSuccess) {
            Get.log('✅ Cover uploaded successfully', isError: false);
          } else {
            Get.log('❌ Cover upload failed', isError: true);
          }
        }

        Get.back(); // Close dialog
      } else {
        Get.snackbar('Error', 'Failed to save book');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save book: $e');
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
        width: 800,
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
                  _isEditMode ? 'Edit Book' : 'Add New Book',
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
                      // Book Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Book Name *',
                        hint: 'Enter book name',
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // College Selection
                      _buildCollegeDropdown(),
                      const SizedBox(height: 16),

                      // Description
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Enter book description',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Author and ISBN
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _authorController,
                              label: 'Author Name *',
                              hint: 'Enter author name',
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _isbnController,
                              label: 'ISBN',
                              hint: 'Enter ISBN',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Publisher and Publication Year
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _publisherController,
                              label: 'Publisher',
                              hint: 'Enter publisher name',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _publicationYearController,
                              label: 'Publication Year',
                              hint: 'e.g., 2024',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _ratingController,
                              label: 'Rating',
                              hint: 'Enter book rating',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _rateController,
                              label: 'Rate',
                              hint: 'Enter book rate',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category and Subject
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _categoryController,
                              label: 'Category *',
                              hint: 'e.g., Computer Science',
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _subjectController,
                              label: 'Subject',
                              hint: 'e.g., Programming',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Language, Year, Semester, Pages
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _languageController,
                              label: 'Language',
                              hint: 'e.g., English',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _yearController,
                              label: 'Academic Year *',
                              hint: 'e.g., 2024',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                final year = int.tryParse(value!);
                                if (year == null) return 'Invalid year';
                                if (year < 2000 || year > 2100)
                                  return 'Year must be between 2000-2100';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _semesterController,
                              label: 'Semester *',
                              hint: 'e.g., 1, 2, 3... (1 to 8)',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                final semester = int.tryParse(value!);
                                if (semester == null) return 'Enter a number';
                                if (semester < 1 || semester > 8)
                                  return 'Must be between 1 and 8';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _pagesController,
                              label: 'Pages',
                              hint: 'e.g., 500',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // File Upload Section
                      const Text(
                        'Upload Files',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PDF Upload
                      _buildFileUploadButton(
                        label: 'Upload PDF',
                        icon: Icons.picture_as_pdf,
                        fileName: _pdfFileName,
                        onPressed: _pickPdfFile,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),

                      // Cover Image Upload
                      _buildFileUploadButton(
                        label: 'Upload Cover Image',
                        icon: Icons.image,
                        fileName: _coverFileName,
                        onPressed: _pickCoverImage,
                        color: Colors.blue,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Question Papers Section
                      _buildQuestionPapersSection(),
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
                  onPressed: _isLoading ? null : _saveBook,
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
                      : Text(_isEditMode ? 'Update Book' : 'Add Book'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
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
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
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

  Widget _buildFileUploadButton({
    required String label,
    required IconData icon,
    required String? fileName,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (fileName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    fileName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(fileName == null ? 'Choose File' : 'Change'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeDropdown() {
    return Obx(() {
      final colleges = _collegesController.colleges;
      final isLoading = _collegesController.isLoading;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'College (Optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCollegeId,
            decoration: InputDecoration(
              hintText: isLoading
                  ? 'Loading colleges...'
                  : 'Select college (optional)',
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
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No College (System-wide)'),
              ),
              ...colleges.map((college) {
                return DropdownMenuItem<String>(
                  value: college.id,
                  child: Text(college.name),
                );
              }).toList(),
            ],
            onChanged: isLoading
                ? null
                : (value) {
                    setState(() {
                      _selectedCollegeId = value;
                    });
                  },
          ),
        ],
      );
    });
  }
  
  Widget _buildQuestionPapersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Text(
              'Question Papers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showQuestionPaperForm = !_showQuestionPaperForm;
                });
              },
              icon: Icon(_showQuestionPaperForm ? Icons.close : Icons.add),
              label: Text(_showQuestionPaperForm ? 'Cancel' : 'Add Question Paper'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Question Paper Form (conditionally shown)
        if (_showQuestionPaperForm) ...[
          _buildQuestionPaperForm(),
          const SizedBox(height: 16),
        ],
        
        // Question Papers List
        _buildQuestionPapersList(),
      ],
    );
  }
  
  Widget _buildQuestionPaperForm() {
    return Obx(() {
      final isLoading = _booksController.isLoading;
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Form(
          key: _questionPaperFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loading indicator
              if (isLoading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],
              
              // Title and Subject
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _qpTitleController,
                      label: 'Title *',
                      hint: 'Enter question paper title',
                      validator: (value) => _validateRequiredField(value, 'Title'),
                      enabled: !isLoading,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _qpSubjectController,
                      label: 'Subject *',
                      hint: 'Enter subject name',
                      validator: (value) => _validateRequiredField(value, 'Subject'),
                      enabled: !isLoading,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            
            // Year and Semester
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _qpYearController,
                    label: 'Year *',
                    hint: '1-4',
                    keyboardType: TextInputType.number,
                    validator: _validateYear,
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _qpSemesterController,
                    label: 'Semester *',
                    hint: '1-8',
                    keyboardType: TextInputType.number,
                    validator: _validateSemester,
                    enabled: !isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Exam Type and Marks
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exam Type',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _qpExamType,
                        decoration: InputDecoration(
                          hintText: 'Select exam type',
                          filled: true,
                          fillColor: isLoading ? Colors.grey.shade200 : Colors.grey.shade50,
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
                        items: const [
                          DropdownMenuItem(value: 'midterm', child: Text('Midterm')),
                          DropdownMenuItem(value: 'final', child: Text('Final')),
                          DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                          DropdownMenuItem(value: 'practice', child: Text('Practice')),
                        ],
                        onChanged: isLoading ? null : (value) {
                          setState(() {
                            _qpExamType = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _qpMarksController,
                    label: 'Marks',
                    hint: 'Total marks',
                    keyboardType: TextInputType.number,
                    validator: _validateMarks,
                    enabled: !isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            _buildTextField(
              controller: _qpDescriptionController,
              label: 'Description',
              hint: 'Enter description (optional)',
              maxLines: 3,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            
            // PDF File Picker
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Question Paper PDF *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_qpPdfFileName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _qpPdfFileName!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _pickQuestionPaperPdf,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(_qpPdfFileName == null ? 'Choose File' : 'Change'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isLoading ? null : () {
                    _clearQuestionPaperForm();
                    setState(() {
                      _showQuestionPaperForm = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (isLoading || !_isQuestionPaperSaveEnabled()) ? null : _saveQuestionPaper,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Question Paper'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    });
  }
  
  Widget _buildQuestionPapersList() {
    return Obx(() {
      final questionPapers = _booksController.questionPapers;
      
      if (questionPapers.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No question papers added yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      return Container(
        constraints: BoxConstraints(
          maxHeight: questionPapers.length > 5 ? 300 : double.infinity,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ListView.separated(
          shrinkWrap: questionPapers.length <= 5,
          itemCount: questionPapers.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.grey.shade300,
          ),
          itemBuilder: (context, index) {
            final qp = questionPapers[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.indigo,
                  size: 24,
                ),
              ),
              title: Text(
                qp.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${qp.subject} • Year ${qp.year} • Semester ${qp.semester}${qp.examType != null ? ' • ${_formatExamType(qp.examType!)}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteQuestionPaper(qp.id),
                tooltip: 'Delete question paper',
              ),
            );
          },
        ),
      );
    });
  }
  
  String _formatExamType(String examType) {
    switch (examType) {
      case 'midterm':
        return 'Midterm';
      case 'final':
        return 'Final';
      case 'quiz':
        return 'Quiz';
      case 'practice':
        return 'Practice';
      default:
        return examType;
    }
  }
}
