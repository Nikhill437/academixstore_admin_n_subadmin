# Design Document: Question Paper Upload for Books

## Overview

This design document specifies the implementation of question paper upload functionality within the book creation/editing dialog of a Flutter admin application. The feature enables administrators to associate multiple question papers with books, each containing metadata (title, subject, year, semester, exam type, marks) and a PDF file. The implementation integrates with existing question paper API endpoints and follows established patterns in the codebase for state management (GetX), API services (BaseApiService), and UI components.

The solution extends the existing `AddEditBookDialog` to include a dedicated question papers section, creates a new `QuestionPapersApiService` for API interactions, and adds question paper management capabilities to the `BooksController`. The design prioritizes web platform compatibility, consistent UI/UX patterns, and robust error handling.

## Architecture

### Component Structure

The implementation follows a layered architecture consistent with the existing codebase:

```
Presentation Layer (UI)
├── AddEditBookDialog (extended)
│   ├── Question Papers Section
│   ├── Question Paper Form
│   └── Question Paper List Display
│
State Management Layer
├── BooksController (extended)
│   ├── Question Paper State Management
│   ├── Question Paper CRUD Operations
│   └── File Upload Coordination
│
Service Layer
├── QuestionPapersApiService (new)
│   ├── Create Question Paper
│   ├── Upload PDF
│   ├── Delete Question Paper
│   └── Get Question Papers
│
└── BaseApiService (existing)
    └── HTTP Operations with JWT Auth
```

### Data Flow

1. **Question Paper Creation Flow**:
   - User fills question paper form in dialog
   - User selects PDF file via file picker
   - User clicks save
   - Controller validates form data
   - Controller creates question paper via API (receives ID)
   - Controller uploads PDF using question paper ID
   - Controller updates local state
   - UI displays new question paper in list

2. **Question Paper Deletion Flow**:
   - User clicks delete button on question paper
   - UI shows confirmation dialog
   - User confirms deletion
   - Controller calls delete API endpoint
   - Controller updates local state
   - UI removes question paper from list

3. **Book Save Flow with Question Papers**:
   - User completes book form and question papers
   - Controller saves book data
   - Controller saves all question papers
   - Controller uploads all PDFs
   - Dialog closes on success

## Components and Interfaces

### 1. QuestionPaper Model

```dart
class QuestionPaper {
  final String id;
  final String title;
  final String subject;
  final int year;
  final int semester;
  final String? description;
  final String? examType; // 'midterm', 'final', 'quiz', 'practice'
  final int? marks;
  final String? collegeId;
  final String? pdfUrl;
  final String? pdfAccessUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  QuestionPaper({
    required this.id,
    required this.title,
    required this.subject,
    required this.year,
    required this.semester,
    this.description,
    this.examType,
    this.marks,
    this.collegeId,
    this.pdfUrl,
    this.pdfAccessUrl,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory QuestionPaper.fromJson(Map<String, dynamic> json) {
    return QuestionPaper(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      year: json['year'] as int,
      semester: json['semester'] as int,
      description: json['description'] as String?,
      examType: json['exam_type'] as String?,
      marks: json['marks'] as int?,
      collegeId: json['college_id'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      pdfAccessUrl: json['pdf_access_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'year': year,
      'semester': semester,
      if (description != null) 'description': description,
      if (examType != null) 'exam_type': examType,
      if (marks != null) 'marks': marks,
      if (collegeId != null) 'college_id': collegeId,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      if (pdfAccessUrl != null) 'pdf_access_url': pdfAccessUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
```

### 2. QuestionPapersApiService

```dart
class QuestionPapersApiService extends GetxService {
  final BaseApiService _baseApiService = Get.find<BaseApiService>();
  final RoleAccessService _roleAccessService = Get.find<RoleAccessService>();

  static const String _questionPapersEndpoint = '/question-papers';

  /// Create a new question paper
  /// Returns the created question paper with ID
  Future<QuestionPaper> createQuestionPaper(
    Map<String, dynamic> questionPaperData,
  ) async {
    // Validate modify access
    if (!_roleAccessService.canModify('question_papers')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('question_papers'),
      );
    }

    try {
      Get.log('Creating question paper: ${questionPaperData['title']}', 
        isError: false);

      final response = await _baseApiService.post(
        _questionPapersEndpoint,
        data: questionPaperData,
      );

      final data = response.data as Map<String, dynamic>;
      final questionPaperJson = data['data']['question_paper'] 
          as Map<String, dynamic>;
      
      final questionPaper = QuestionPaper.fromJson(questionPaperJson);

      Get.log('Question paper created: ${questionPaper.id}', isError: false);

      return questionPaper;
    } catch (e) {
      Get.log('Error creating question paper: $e', isError: true);
      rethrow;
    }
  }

  /// Upload PDF for a question paper
  /// Returns updated question paper with PDF URL
  Future<Map<String, dynamic>> uploadQuestionPaperPdf(
    String questionPaperId,
    String? filePath, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    // Validate modify access
    if (!_roleAccessService.canModify('question_papers')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('question_papers'),
      );
    }

    try {
      Get.log('Uploading PDF for question paper: $questionPaperId', 
        isError: false);

      final response = await _baseApiService.uploadFile(
        '$_questionPapersEndpoint/$questionPaperId/upload-pdf',
        filePath ?? '',
        'question_paper',
        fileBytes: fileBytes,
        fileName: fileName,
      );

      final data = response.data as Map<String, dynamic>;
      
      Get.log('Question paper PDF uploaded successfully', isError: false);

      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      Get.log('Error uploading question paper PDF: $e', isError: true);
      rethrow;
    }
  }

  /// Delete a question paper
  /// Returns true if deletion was successful
  Future<bool> deleteQuestionPaper(String questionPaperId) async {
    // Validate modify access
    if (!_roleAccessService.canModify('question_papers')) {
      throw UnauthorizedAccessException(
        _roleAccessService.getAccessDeniedMessage('question_papers'),
      );
    }

    try {
      Get.log('Deleting question paper: $questionPaperId', isError: false);

      await _baseApiService.delete(
        '$_questionPapersEndpoint/$questionPaperId',
      );

      Get.log('Question paper deleted successfully', isError: false);

      return true;
    } catch (e) {
      Get.log('Error deleting question paper: $e', isError: true);
      rethrow;
    }
  }

  /// Get question papers with optional filters
  /// Returns list of question papers
  Future<List<QuestionPaper>> getQuestionPapers({
    String? subject,
    int? year,
    int? semester,
    String? examType,
  }) async {
    // Validate access
    _roleAccessService.validateAccess('question_papers');

    try {
      final queryParams = <String, dynamic>{};
      if (subject != null) queryParams['subject'] = subject;
      if (year != null) queryParams['year'] = year;
      if (semester != null) queryParams['semester'] = semester;
      if (examType != null) queryParams['exam_type'] = examType;

      Get.log('Fetching question papers with filters: $queryParams', 
        isError: false);

      final response = await _baseApiService.get(
        _questionPapersEndpoint,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final questionPapersData = data['data']['question_papers'] as List;
      
      final questionPapers = questionPapersData
          .map((json) => QuestionPaper.fromJson(json as Map<String, dynamic>))
          .toList();

      Get.log('Fetched ${questionPapers.length} question papers', 
        isError: false);

      return questionPapers;
    } catch (e) {
      Get.log('Error fetching question papers: $e', isError: true);
      rethrow;
    }
  }
}
```

### 3. BooksController Extensions

Add the following to the existing `BooksController`:

```dart
// Observable list for question papers
final RxList<QuestionPaper> _questionPapers = <QuestionPaper>[].obs;

// Getter for UI access
List<QuestionPaper> get questionPapers => _questionPapers.toList();

// Question papers API service
final QuestionPapersApiService _questionPapersApiService = 
    Get.find<QuestionPapersApiService>();

/// Create question paper with PDF upload
/// Returns the created question paper if successful, null otherwise
Future<QuestionPaper?> createQuestionPaperWithPdf(
  Map<String, dynamic> questionPaperData,
  String? pdfFilePath, {
  List<int>? pdfFileBytes,
  String? pdfFileName,
}) async {
  if (!_roleAccessService.canModify('question_papers')) {
    _showAccessDeniedError('create question papers');
    return null;
  }

  try {
    _isLoading.value = true;
    _error.value = '';

    // Step 1: Create question paper
    Get.log('Creating question paper: ${questionPaperData['title']}', 
      isError: false);
    
    final questionPaper = await _questionPapersApiService
        .createQuestionPaper(questionPaperData);

    Get.log('Question paper created with ID: ${questionPaper.id}', 
      isError: false);

    // Step 2: Upload PDF if provided
    if (pdfFileName != null && 
        (pdfFilePath != null || pdfFileBytes != null)) {
      Get.log('Uploading PDF: $pdfFileName', isError: false);
      
      await _questionPapersApiService.uploadQuestionPaperPdf(
        questionPaper.id,
        pdfFilePath,
        fileBytes: pdfFileBytes,
        fileName: pdfFileName,
      );

      Get.log('PDF uploaded successfully', isError: false);
    }

    // Add to local list
    _questionPapers.add(questionPaper);

    Get.snackbar(
      'Success',
      'Question paper "${questionPaper.title}" created successfully',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
    );

    return questionPaper;
  } catch (e) {
    _error.value = _handleError(e);
    Get.log('Error creating question paper: $e', isError: true);
    
    Get.snackbar(
      'Error',
      'Failed to create question paper: ${_error.value}',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
    
    return null;
  } finally {
    _isLoading.value = false;
  }
}

/// Delete a question paper
Future<bool> deleteQuestionPaper(String questionPaperId) async {
  if (!_roleAccessService.canModify('question_papers')) {
    _showAccessDeniedError('delete question papers');
    return false;
  }

  try {
    _isLoading.value = true;
    _error.value = '';

    final success = await _questionPapersApiService
        .deleteQuestionPaper(questionPaperId);

    if (success) {
      // Remove from local list
      _questionPapers.removeWhere((qp) => qp.id == questionPaperId);

      Get.snackbar(
        'Success',
        'Question paper deleted successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      return true;
    }

    return false;
  } catch (e) {
    _error.value = _handleError(e);
    Get.log('Error deleting question paper: $e', isError: true);
    
    Get.snackbar(
      'Error',
      'Failed to delete question paper: ${_error.value}',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
    
    return false;
  } finally {
    _isLoading.value = false;
  }
}

/// Clear question papers list
void clearQuestionPapers() {
  _questionPapers.clear();
}
```

### 4. AddEditBookDialog Extensions

Add the following UI components to the existing dialog:

```dart
// State variables for question paper form
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

// Initialize controllers in initState
_qpTitleController = TextEditingController();
_qpSubjectController = TextEditingController();
_qpYearController = TextEditingController();
_qpSemesterController = TextEditingController();
_qpDescriptionController = TextEditingController();
_qpMarksController = TextEditingController();

// Dispose controllers in dispose
_qpTitleController.dispose();
_qpSubjectController.dispose();
_qpYearController.dispose();
_qpSemesterController.dispose();
_qpDescriptionController.dispose();
_qpMarksController.dispose();

// File picker for question paper PDF
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

      // Validate file size (50MB = 52428800 bytes)
      if (file.size > 52428800) {
        Get.snackbar(
          'File Too Large',
          'PDF file must be less than 50MB',
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

// Save question paper
Future<void> _saveQuestionPaper() async {
  if (!_questionPaperFormKey.currentState!.validate()) {
    Get.snackbar(
      'Validation Error',
      'Please fill in all required fields',
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade900,
      snackPosition: SnackPosition.TOP,
    );
    return;
  }

  if (_qpPdfFileName == null) {
    Get.snackbar(
      'PDF Required',
      'Please select a PDF file',
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade900,
      snackPosition: SnackPosition.TOP,
    );
    return;
  }

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

  final questionPaper = await _booksController.createQuestionPaperWithPdf(
    questionPaperData,
    _qpPdfFilePath,
    pdfFileBytes: _qpPdfFileBytes,
    pdfFileName: _qpPdfFileName,
  );

  if (questionPaper != null) {
    // Clear form
    _clearQuestionPaperForm();
    setState(() {
      _showQuestionPaperForm = false;
    });
  }
}

// Clear question paper form
void _clearQuestionPaperForm() {
  _qpTitleController.clear();
  _qpSubjectController.clear();
  _qpYearController.clear();
  _qpSemesterController.clear();
  _qpDescriptionController.clear();
  _qpMarksController.clear();
  setState(() {
    _qpExamType = null;
    _qpPdfFilePath = null;
    _qpPdfFileName = null;
    _qpPdfFileBytes = null;
  });
}

// Delete question paper with confirmation
Future<void> _deleteQuestionPaper(String questionPaperId) async {
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

  if (confirmed == true) {
    await _booksController.deleteQuestionPaper(questionPaperId);
  }
}
```

## Data Models

### QuestionPaper Data Model

The `QuestionPaper` model represents a question paper entity with the following structure:

**Core Fields**:
- `id` (String, required): Unique identifier (UUID)
- `title` (String, required): Question paper title (1-500 characters)
- `subject` (String, required): Subject name (1-100 characters)
- `year` (int, required): Academic year (1-4)
- `semester` (int, required): Semester number (1-8)

**Optional Fields**:
- `description` (String?): Detailed description
- `examType` (String?): Type of exam ('midterm', 'final', 'quiz', 'practice')
- `marks` (int?): Total marks (>= 0)
- `collegeId` (String?): Associated college UUID

**System Fields**:
- `pdfUrl` (String?): S3 storage URL for PDF
- `pdfAccessUrl` (String?): Signed URL for PDF access (expires in 1 hour)
- `isActive` (bool): Soft delete flag (default: true)
- `createdAt` (DateTime): Creation timestamp
- `updatedAt` (DateTime?): Last update timestamp

### Validation Rules

**Title Validation**:
- Required field
- Length: 1-500 characters
- Cannot be empty or whitespace only

**Subject Validation**:
- Required field
- Length: 1-100 characters
- Cannot be empty or whitespace only

**Year Validation**:
- Required field
- Must be integer
- Range: 1-4
- Error message: "Year must be between 1 and 4"

**Semester Validation**:
- Required field
- Must be integer
- Range: 1-8
- Error message: "Semester must be between 1 and 8"

**Exam Type Validation**:
- Optional field
- Must be one of: 'midterm', 'final', 'quiz', 'practice'
- Displayed as dropdown in UI

**Marks Validation**:
- Optional field
- Must be integer
- Must be >= 0
- Error message: "Marks must be a positive number"

**PDF File Validation**:
- Required for upload
- File type: PDF only (.pdf extension)
- Maximum size: 50MB (52,428,800 bytes)
- Error message for type: "Only PDF files are allowed"
- Error message for size: "PDF file must be less than 50MB"

### API Request/Response Formats

**Create Question Paper Request**:
```json
{
  "title": "Midterm Exam - Data Structures",
  "subject": "Data Structures",
  "year": 2,
  "semester": 3,
  "description": "Covers arrays, linked lists, stacks, queues",
  "exam_type": "midterm",
  "marks": 100,
  "college_id": "uuid-here"
}
```

**Create Question Paper Response**:
```json
{
  "success": true,
  "message": "Question paper created successfully",
  "data": {
    "question_paper": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Midterm Exam - Data Structures",
      "subject": "Data Structures",
      "year": 2,
      "semester": 3,
      "exam_type": "midterm",
      "marks": 100,
      "college_id": "660e8400-e29b-41d4-a716-446655440000",
      "is_active": true,
      "created_at": "2026-01-29T10:00:00Z"
    }
  }
}
```

**Upload PDF Request**:
- Content-Type: multipart/form-data
- Field name: "question_paper"
- File: PDF binary data

**Upload PDF Response**:
```json
{
  "success": true,
  "message": "Question paper PDF uploaded successfully",
  "data": {
    "question_paper_id": "550e8400-e29b-41d4-a716-446655440000",
    "pdf_url": "https://bucket.s3.amazonaws.com/question-papers/pdfs/550e8400.../file.pdf",
    "signed_url": "https://bucket.s3.amazonaws.com/...?X-Amz-Expires=3600",
    "original_name": "midterm-exam.pdf"
  }
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Question Paper Display Completeness

*For any* question paper in the displayed list, the UI SHALL render all required fields including title, subject, year, semester, and exam type.

**Validates: Requirements 1.2, 5.2**

### Property 2: Required Field Validation

*For any* required field (title, subject, year, semester) that is empty or contains only whitespace, form validation SHALL fail and prevent submission.

**Validates: Requirements 2.6**

### Property 3: PDF File Type Validation

*For any* file selected for upload, if the file extension is not .pdf, the validation service SHALL reject the file and display an error message.

**Validates: Requirements 3.3, 7.1**

### Property 4: PDF File Size Validation

*For any* PDF file selected for upload, if the file size exceeds 50MB (52,428,800 bytes), the validation service SHALL reject the file and display an error message indicating the size limit.

**Validates: Requirements 3.4, 7.2**

### Property 5: Filename Display After Selection

*For any* valid PDF file that passes validation, the Book_Dialog SHALL display the filename in the UI.

**Validates: Requirements 3.5**

### Property 6: Question Paper Creation API Call

*For any* valid question paper form data, when the user clicks save, the Books_Controller SHALL invoke the Question_Paper_API POST /api/question-papers endpoint with the form data.

**Validates: Requirements 4.1**

### Property 7: PDF Upload After Creation

*For any* successfully created question paper with a selected PDF file, the Books_Controller SHALL invoke the Question_Paper_API POST /api/question-papers/:id/upload-pdf endpoint with the PDF file data.

**Validates: Requirements 4.2**

### Property 8: List Update After Successful Upload

*For any* question paper that is successfully created and uploaded, the Book_Dialog SHALL add the question paper to the displayed list and clear the form fields.

**Validates: Requirements 4.4**

### Property 9: Delete Button Presence

*For any* question paper displayed in the list, the UI SHALL provide a delete button associated with that question paper.

**Validates: Requirements 6.1**

### Property 10: Delete API Call on Confirmation

*For any* question paper deletion that is confirmed by the user, the Books_Controller SHALL invoke the Question_Paper_API DELETE /api/question-papers/:id endpoint.

**Validates: Requirements 6.3**

### Property 11: List Update After Successful Deletion

*For any* question paper that is successfully deleted, the Book_Dialog SHALL remove the question paper from the displayed list.

**Validates: Requirements 6.4**

### Property 12: Save Button Enablement After Validation

*For any* question paper form where all required fields are filled and a valid PDF file is selected, the save button SHALL be enabled.

**Validates: Requirements 7.5**

### Property 13: Validation Error Messages

*For any* validation failure (file type or file size), the Validation_Service SHALL display a specific error message indicating which constraint was violated.

**Validates: Requirements 7.3**

### Property 14: Success Message Display

*For any* successful operation (question paper creation, PDF upload, deletion), the Book_Dialog SHALL display a success message.

**Validates: Requirements 8.3**

### Property 15: Error Message Display

*For any* failed operation (question paper creation, PDF upload, deletion), the Books_Controller SHALL display an error message with details about the failure.

**Validates: Requirements 8.4**

### Property 16: Book-Question Paper Association Persistence

*For any* book with associated question papers, when the book is saved, all associations between the book and its question papers SHALL be persisted.

**Validates: Requirements 5.4**

## Error Handling

### Error Categories

**Validation Errors**:
- Empty required fields (title, subject, year, semester)
- Invalid file type (non-PDF files)
- File size exceeds 50MB
- Invalid year (not 1-4)
- Invalid semester (not 1-8)
- Invalid marks (negative number)

**API Errors**:
- Network connectivity issues (timeout, connection refused)
- Authentication errors (401 Unauthorized)
- Authorization errors (403 Forbidden)
- Resource not found (404 Not Found)
- Server errors (500 Internal Server Error)
- Question paper creation failure
- PDF upload failure
- Question paper deletion failure

**Platform Errors**:
- File picker cancellation
- File access permission denied
- Insufficient storage space
- Browser compatibility issues (web platform)

### Error Handling Strategy

**Validation Error Handling**:
1. Perform client-side validation before API calls
2. Display inline error messages next to invalid fields
3. Highlight invalid fields with red borders
4. Show snackbar with summary of validation errors
5. Keep form data intact for user correction
6. Disable save button until validation passes

**API Error Handling**:
1. Catch all API exceptions in controller methods
2. Parse error responses from API
3. Display user-friendly error messages via snackbar
4. Log detailed error information for debugging
5. Keep dialog open to allow retry
6. For creation failures: don't attempt PDF upload
7. For upload failures: inform user that question paper was created but PDF upload failed

**Network Error Handling**:
1. Detect network errors (SocketException, TimeoutException)
2. Display message: "Network error. Please check your connection and try again."
3. Provide retry option
4. Show loading indicator during retry

**File Picker Error Handling**:
1. Handle file picker cancellation gracefully (no error message)
2. Handle permission denied errors with appropriate message
3. Log file picker errors for debugging

**Error Recovery**:
1. All errors keep the dialog open
2. Form data is preserved after errors
3. Users can correct errors and retry
4. Provide clear guidance on how to fix errors
5. For partial failures (creation succeeded, upload failed), provide option to retry upload

### Error Message Examples

**Validation Errors**:
- "Title is required"
- "Subject is required"
- "Year must be between 1 and 4"
- "Semester must be between 1 and 8"
- "Only PDF files are allowed"
- "PDF file must be less than 50MB"
- "Marks must be a positive number"

**API Errors**:
- "Failed to create question paper: [error details]"
- "Question paper created but PDF upload failed: [error details]"
- "Failed to delete question paper: [error details]"
- "Network error. Please check your connection and try again."
- "Authentication required. Please sign in again."
- "You don't have permission to perform this action."

**Success Messages**:
- "Question paper '[title]' created successfully"
- "PDF uploaded successfully"
- "Question paper deleted successfully"

## Testing Strategy

### Dual Testing Approach

This feature requires both unit tests and property-based tests to ensure comprehensive coverage:

**Unit Tests**: Focus on specific examples, edge cases, and integration points
- Test specific UI interactions (button clicks, form submissions)
- Test error handling for specific scenarios
- Test platform-specific behavior (web vs mobile file handling)
- Test integration with existing components (BooksController, BaseApiService)

**Property-Based Tests**: Verify universal properties across all inputs
- Test validation logic with randomly generated inputs
- Test API integration with various data combinations
- Test state management with different sequences of operations
- Test file handling with various file sizes and types

### Property-Based Testing Configuration

**Testing Library**: Use the appropriate property-based testing library for Dart/Flutter:
- For Dart: Use `test` package with custom property test helpers or `faker` for data generation
- Minimum 100 iterations per property test to ensure comprehensive coverage

**Property Test Tags**: Each property test must include a comment tag referencing the design property:
```dart
// Feature: question-paper-upload-for-books, Property 1: Question Paper Display Completeness
test('property: all question paper fields are displayed', () {
  // Test implementation
});
```

### Unit Test Coverage

**UI Component Tests**:
- Test that question papers section is visible in dialog
- Test that "Add Question Paper" button exists and triggers form display
- Test that form fields are rendered correctly
- Test that exam type dropdown contains correct options
- Test that empty state message is shown when no question papers exist
- Test that delete button is shown for each question paper
- Test that confirmation dialog appears on delete button click

**Validation Tests**:
- Test required field validation with empty strings
- Test required field validation with whitespace-only strings
- Test year validation with values outside 1-4 range
- Test semester validation with values outside 1-8 range
- Test marks validation with negative numbers
- Test PDF file type validation with non-PDF files
- Test PDF file size validation with files > 50MB
- Test that validation occurs before API calls

**Controller Tests**:
- Test createQuestionPaperWithPdf method with valid data
- Test createQuestionPaperWithPdf method with API failure
- Test deleteQuestionPaper method with valid ID
- Test deleteQuestionPaper method with API failure
- Test that question papers list is updated after creation
- Test that question papers list is updated after deletion
- Test error message display for various error scenarios

**API Service Tests**:
- Test createQuestionPaper method calls correct endpoint
- Test uploadQuestionPaperPdf method calls correct endpoint with multipart data
- Test deleteQuestionPaper method calls correct endpoint
- Test getQuestionPapers method with various filters
- Test error handling for network errors
- Test error handling for authentication errors

**File Handling Tests**:
- Test file picker on web platform (uses bytes)
- Test file picker on mobile platform (uses path)
- Test file validation before upload
- Test multipart form data creation for PDF upload

### Property-Based Test Coverage

**Property 1: Question Paper Display Completeness**
```dart
// Feature: question-paper-upload-for-books, Property 1: Question Paper Display Completeness
// Generate random question papers and verify all fields are displayed
```

**Property 2: Required Field Validation**
```dart
// Feature: question-paper-upload-for-books, Property 2: Required Field Validation
// Generate random combinations of empty/whitespace required fields
// Verify validation fails for each combination
```

**Property 3: PDF File Type Validation**
```dart
// Feature: question-paper-upload-for-books, Property 3: PDF File Type Validation
// Generate random file extensions (excluding .pdf)
// Verify validation rejects all non-PDF files
```

**Property 4: PDF File Size Validation**
```dart
// Feature: question-paper-upload-for-books, Property 4: PDF File Size Validation
// Generate random file sizes > 50MB
// Verify validation rejects all oversized files
```

**Property 5: Filename Display After Selection**
```dart
// Feature: question-paper-upload-for-books, Property 5: Filename Display After Selection
// Generate random valid PDF filenames
// Verify filename is displayed after selection
```

**Property 6: Question Paper Creation API Call**
```dart
// Feature: question-paper-upload-for-books, Property 6: Question Paper Creation API Call
// Generate random valid question paper data
// Verify API endpoint is called with correct data
```

**Property 7: PDF Upload After Creation**
```dart
// Feature: question-paper-upload-for-books, Property 7: PDF Upload After Creation
// Generate random question papers with PDFs
// Verify upload endpoint is called after successful creation
```

**Property 8: List Update After Successful Upload**
```dart
// Feature: question-paper-upload-for-books, Property 8: List Update After Successful Upload
// Generate random question papers
// Verify list is updated and form is cleared after upload
```

**Property 9: Delete Button Presence**
```dart
// Feature: question-paper-upload-for-books, Property 9: Delete Button Presence
// Generate random lists of question papers
// Verify delete button exists for each question paper
```

**Property 10: Delete API Call on Confirmation**
```dart
// Feature: question-paper-upload-for-books, Property 10: Delete API Call on Confirmation
// Generate random question paper IDs
// Verify delete endpoint is called when deletion is confirmed
```

**Property 11: List Update After Successful Deletion**
```dart
// Feature: question-paper-upload-for-books, Property 11: List Update After Successful Deletion
// Generate random question papers to delete
// Verify list is updated after successful deletion
```

**Property 12: Save Button Enablement After Validation**
```dart
// Feature: question-paper-upload-for-books, Property 12: Save Button Enablement After Validation
// Generate random valid form data with valid PDFs
// Verify save button is enabled
```

**Property 13: Validation Error Messages**
```dart
// Feature: question-paper-upload-for-books, Property 13: Validation Error Messages
// Generate random validation failures (type and size)
// Verify appropriate error messages are displayed
```

**Property 14: Success Message Display**
```dart
// Feature: question-paper-upload-for-books, Property 14: Success Message Display
// Generate random successful operations
// Verify success messages are displayed
```

**Property 15: Error Message Display**
```dart
// Feature: question-paper-upload-for-books, Property 15: Error Message Display
// Generate random failed operations
// Verify error messages with details are displayed
```

**Property 16: Book-Question Paper Association Persistence**
```dart
// Feature: question-paper-upload-for-books, Property 16: Book-Question Paper Association Persistence
// Generate random books with question papers
// Verify all associations are persisted when book is saved
```

### Integration Testing

**End-to-End Workflows**:
1. Open book dialog → Add question paper → Upload PDF → Verify in list
2. Open book dialog → Add multiple question papers → Verify all in list
3. Open book dialog → Add question paper → Delete question paper → Verify removed
4. Open book dialog → Add question paper with invalid data → Verify validation errors
5. Open book dialog → Add question paper → Upload oversized PDF → Verify error
6. Open book dialog → Add question paper → Simulate API failure → Verify error handling

**Platform-Specific Testing**:
- Test file upload on web platform (using bytes)
- Test file upload on mobile platform (using paths)
- Test responsive layout on different screen sizes
- Test dialog behavior on different platforms

### Test Data Generation

**Valid Question Paper Data**:
- Titles: 1-500 characters, various subjects
- Subjects: 1-100 characters, various topics
- Years: 1, 2, 3, 4
- Semesters: 1, 2, 3, 4, 5, 6, 7, 8
- Exam types: 'midterm', 'final', 'quiz', 'practice'
- Marks: 0 to 200
- PDF files: Valid PDFs under 50MB

**Invalid Question Paper Data**:
- Empty required fields
- Whitespace-only required fields
- Years outside 1-4 range
- Semesters outside 1-8 range
- Negative marks
- Non-PDF files
- PDF files over 50MB

### Mocking Strategy

**API Mocking**:
- Mock QuestionPapersApiService for controller tests
- Mock BaseApiService for API service tests
- Simulate successful API responses
- Simulate various error responses (401, 403, 404, 500)
- Simulate network errors

**File Picker Mocking**:
- Mock FilePicker.platform.pickFiles for file selection tests
- Simulate file selection with various file types and sizes
- Simulate file picker cancellation
- Simulate permission denied errors

**Platform Mocking**:
- Mock platform detection for web vs mobile tests
- Mock file bytes for web platform tests
- Mock file paths for mobile platform tests
