# Implementation Plan: Question Paper Upload for Books

## Overview

This implementation plan breaks down the question paper upload feature into discrete, incremental tasks. Each task builds on previous work and includes validation through testing. The implementation follows the existing codebase patterns for state management (GetX), API services (BaseApiService), and UI components (Flutter dialogs).

## Tasks

- [ ] 1. Create QuestionPaper model and QuestionPapersApiService
  - [x] 1.1 Create QuestionPaper model class with JSON serialization
    - Create `lib/models/question_paper.dart`
    - Implement `QuestionPaper` class with all required and optional fields
    - Implement `fromJson` factory constructor for API response parsing
    - Implement `toJson` method for API request serialization
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 2.3, 2.4_

  - [x] 1.2 Write property test for QuestionPaper JSON serialization
    - **Property 1: Serialization round trip**
    - **Validates: Requirements 1.1**
    - Test that for any valid QuestionPaper object, serializing then deserializing produces an equivalent object

  - [x] 1.3 Create QuestionPapersApiService class
    - Create `lib/services/api/question_papers_api_service.dart`
    - Implement `createQuestionPaper` method using BaseApiService
    - Implement `uploadQuestionPaperPdf` method with multipart/form-data support
    - Implement `deleteQuestionPaper` method
    - Implement `getQuestionPapers` method with optional filters
    - Add role-based access control checks using RoleAccessService
    - _Requirements: 4.1, 4.2, 6.3_

  - [ ] 1.4 Write property test for API service methods
    - **Property 6: Question Paper Creation API Call**
    - **Validates: Requirements 4.1**
    - Test that for any valid question paper data, the create method calls the correct endpoint

  - [x] 1.5 Write unit tests for QuestionPapersApiService
    - Test createQuestionPaper with valid data
    - Test uploadQuestionPaperPdf with file bytes and file path
    - Test deleteQuestionPaper with valid ID
    - Test getQuestionPapers with various filters
    - Test error handling for network errors and API errors

- [ ] 2. Extend BooksController with question paper management
  - [x] 2.1 Add question paper state management to BooksController
    - Add `RxList<QuestionPaper> _questionPapers` observable list
    - Add getter `List<QuestionPaper> get questionPapers`
    - Inject `QuestionPapersApiService` dependency
    - _Requirements: 4.4, 5.1, 5.2, 6.4_

  - [x] 2.2 Implement createQuestionPaperWithPdf method
    - Create method that calls API service to create question paper
    - Upload PDF file after successful creation
    - Update local question papers list
    - Display success/error messages via snackbar
    - Handle partial failures (creation succeeded, upload failed)
    - _Requirements: 4.1, 4.2, 4.4, 4.5, 4.6, 8.3, 8.4_

  - [x] 2.3 Write property test for question paper creation workflow
    - **Property 7: PDF Upload After Creation**
    - **Validates: Requirements 4.2**
    - Test that for any successfully created question paper with a PDF, the upload endpoint is called

  - [x] 2.4 Implement deleteQuestionPaper method
    - Create method that calls API service to delete question paper
    - Update local question papers list on success
    - Display success/error messages via snackbar
    - _Requirements: 6.3, 6.4, 6.5, 8.3, 8.4_

  - [x] 2.5 Write property test for question paper deletion
    - **Property 11: List Update After Successful Deletion**
    - **Validates: Requirements 6.4**
    - Test that for any successfully deleted question paper, it is removed from the list

  - [x] 2.6 Implement clearQuestionPapers method
    - Create method to clear the question papers list
    - _Requirements: 5.1_

  - [x] 2.7 Write unit tests for BooksController question paper methods
    - Test createQuestionPaperWithPdf with valid data
    - Test createQuestionPaperWithPdf with API failure
    - Test createQuestionPaperWithPdf with upload failure after creation
    - Test deleteQuestionPaper with valid ID
    - Test deleteQuestionPaper with API failure
    - Test clearQuestionPapers

- [x] 3. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Create file validation utility
  - [x] 4.1 Create FileValidationService class
    - Create `lib/services/file_validation_service.dart`
    - Implement `validatePdfFile` method that checks file extension and size
    - Return validation result with specific error messages
    - Maximum file size: 50MB (52,428,800 bytes)
    - _Requirements: 3.3, 3.4, 7.1, 7.2, 7.3_

  - [x] 4.2 Write property test for file type validation
    - **Property 3: PDF File Type Validation**
    - **Validates: Requirements 3.3, 7.1**
    - Test that for any file with non-PDF extension, validation fails

  - [x] 4.3 Write property test for file size validation
    - **Property 4: PDF File Size Validation**
    - **Validates: Requirements 3.4, 7.2**
    - Test that for any file larger than 50MB, validation fails

  - [x] 4.4 Write property test for validation error messages
    - **Property 13: Validation Error Messages**
    - **Validates: Requirements 7.3**
    - Test that for any validation failure, a specific error message is returned

  - [x] 4.5 Write unit tests for FileValidationService
    - Test validatePdfFile with valid PDF under 50MB
    - Test validatePdfFile with non-PDF file
    - Test validatePdfFile with PDF over 50MB
    - Test validatePdfFile with edge case: exactly 50MB
    - Test error message content for each failure type

- [x] 5. Extend AddEditBookDialog with question paper UI
  - [x] 5.1 Add question paper form state variables
    - Add form key, text controllers for all fields
    - Add state variables for exam type dropdown, file selection
    - Add boolean flag for showing/hiding question paper form
    - Initialize controllers in initState
    - Dispose controllers in dispose
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1_

  - [x] 5.2 Implement question paper PDF file picker
    - Create `_pickQuestionPaperPdf` method using FilePicker
    - Support both web (bytes) and mobile (path) platforms
    - Validate file using FileValidationService
    - Display selected filename in UI
    - Show error messages for invalid files
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 9.1_

  - [x] 5.3 Write property test for filename display
    - **Property 5: Filename Display After Selection**
    - **Validates: Requirements 3.5**
    - Test that for any valid PDF file, the filename is displayed after selection

  - [x] 5.4 Implement question paper form validation
    - Add validators for required fields (title, subject, year, semester)
    - Add validator for year (1-4 range)
    - Add validator for semester (1-8 range)
    - Add validator for marks (positive number)
    - Ensure PDF file is selected before enabling save
    - _Requirements: 2.5, 2.6, 7.4, 7.5_

  - [x] 5.5 Write property test for required field validation
    - **Property 2: Required Field Validation**
    - **Validates: Requirements 2.6**
    - Test that for any empty or whitespace-only required field, validation fails

  - [x] 5.6 Implement saveQuestionPaper method
    - Validate form using form key
    - Check that PDF file is selected
    - Build question paper data map from form fields
    - Call BooksController.createQuestionPaperWithPdf
    - Clear form and hide form on success
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

  - [x] 5.7 Write property test for save button enablement
    - **Property 12: Save Button Enablement After Validation**
    - **Validates: Requirements 7.5**
    - Test that for any valid form with valid PDF, save button is enabled

  - [x] 5.8 Implement clearQuestionPaperForm method
    - Clear all text controllers
    - Reset exam type dropdown
    - Clear file selection state
    - _Requirements: 4.4_

  - [x] 5.9 Implement deleteQuestionPaper method with confirmation
    - Show confirmation dialog when delete button is clicked
    - Call BooksController.deleteQuestionPaper on confirmation
    - Handle cancellation gracefully
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [x] 5.10 Write unit tests for dialog methods
    - Test _pickQuestionPaperPdf with valid PDF
    - Test _pickQuestionPaperPdf with invalid file
    - Test _pickQuestionPaperPdf with oversized file
    - Test _saveQuestionPaper with valid data
    - Test _saveQuestionPaper with invalid data
    - Test _deleteQuestionPaper with confirmation
    - Test _deleteQuestionPaper with cancellation

- [x] 6. Build question papers section UI widgets
  - [x] 6.1 Create question papers section header
    - Add section title "Question Papers"
    - Add "Add Question Paper" button
    - Toggle form visibility on button click
    - _Requirements: 1.1, 1.4_

  - [x] 6.2 Create question paper form widget
    - Build form with all input fields (title, subject, year, semester, description, exam type, marks)
    - Add exam type dropdown with options: midterm, final, quiz, practice
    - Add PDF file picker button
    - Display selected filename
    - Add save and cancel buttons
    - Apply consistent styling with existing dialogs
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.5, 10.1, 10.2, 10.3_

  - [x] 6.3 Create question papers list widget
    - Display list of question papers with title, subject, year, semester, exam type
    - Show empty state message when list is empty
    - Make list scrollable when more than 5 items
    - Add delete button for each question paper
    - Apply consistent styling with existing dialogs
    - _Requirements: 1.2, 1.3, 5.2, 5.3, 6.1, 10.1, 10.2, 10.3_

  - [x] 6.4 Write property test for question paper display
    - **Property 1: Question Paper Display Completeness**
    - **Validates: Requirements 1.2, 5.2**
    - Test that for any question paper, all required fields are displayed

  - [x] 6.5 Write property test for delete button presence
    - **Property 9: Delete Button Presence**
    - **Validates: Requirements 6.1**
    - Test that for any question paper in the list, a delete button exists

  - [x] 6.6 Write unit tests for UI widgets
    - Test that question papers section is visible
    - Test that "Add Question Paper" button exists
    - Test that form is shown when button is clicked
    - Test that form fields are rendered correctly
    - Test that exam type dropdown has correct options
    - Test that empty state message is shown when list is empty
    - Test that delete button is shown for each question paper

- [x] 7. Integrate question papers section into AddEditBookDialog
  - [x] 7.1 Add question papers section to dialog layout
    - Insert question papers section after file upload section
    - Ensure proper spacing and layout
    - Maintain responsive behavior
    - _Requirements: 1.1, 10.5_

  - [x] 7.2 Wire up question papers state with BooksController
    - Use Obx to observe question papers list from controller
    - Update UI when list changes
    - Clear question papers list when dialog closes
    - _Requirements: 1.2, 4.4, 5.1, 6.4_

  - [x] 7.3 Write property test for list update after upload
    - **Property 8: List Update After Successful Upload**
    - **Validates: Requirements 4.4**
    - Test that for any successful upload, the list is updated and form is cleared

  - [x] 7.4 Test dialog behavior with question papers
    - Test opening dialog for new book (empty question papers list)
    - Test opening dialog for existing book (load question papers)
    - Test adding multiple question papers without closing dialog
    - Test deleting question papers
    - Test dialog remains open after errors
    - _Requirements: 5.1, 8.6_

  - [x] 7.5 Write unit tests for dialog integration
    - Test that question papers section is visible in dialog
    - Test that question papers list updates when controller state changes
    - Test that dialog remains open after errors
    - Test that question papers list is cleared when dialog closes

- [x] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Implement error handling and user feedback
  - [x] 9.1 Add loading indicators for async operations
    - Show loading indicator during question paper creation
    - Show loading indicator during PDF upload
    - Disable form inputs during loading
    - _Requirements: 8.1_

  - [x] 9.2 Implement success message display
    - Show success snackbar after question paper creation
    - Show success snackbar after PDF upload
    - Show success snackbar after question paper deletion
    - Auto-dismiss after 3 seconds
    - _Requirements: 8.3_

  - [x] 9.3 Write property test for success messages
    - **Property 14: Success Message Display**
    - **Validates: Requirements 8.3**
    - Test that for any successful operation, a success message is displayed

  - [x] 9.4 Implement error message display
    - Show error snackbar for validation errors
    - Show error snackbar for API errors
    - Show error snackbar for network errors
    - Include error details in messages
    - Keep dialog open after errors
    - _Requirements: 8.4, 8.5, 8.6_

  - [x] 9.5 Write property test for error messages
    - **Property 15: Error Message Display**
    - **Validates: Requirements 8.4**
    - Test that for any failed operation, an error message with details is displayed

  - [x] 9.6 Handle partial failure scenarios
    - Show specific message when question paper is created but PDF upload fails
    - Provide option to retry PDF upload
    - _Requirements: 4.6_

  - [x] 9.7 Write unit tests for error handling
    - Test loading indicator display during operations
    - Test success message display for each operation
    - Test error message display for validation errors
    - Test error message display for API errors
    - Test error message display for network errors
    - Test partial failure message (creation succeeded, upload failed)
    - Test that dialog remains open after errors

- [x] 10. Add service initialization and dependency injection
  - [x] 10.1 Register QuestionPapersApiService in dependency injection
    - Add service initialization in main.dart or service initialization file
    - Ensure service is available before BooksController initialization
    - _Requirements: 4.1_

  - [x] 10.2 Register FileValidationService in dependency injection
    - Add service initialization in main.dart or service initialization file
    - Make service available to dialog components
    - _Requirements: 7.1_

  - [x] 10.3 Write integration tests for service initialization
    - Test that QuestionPapersApiService is properly initialized
    - Test that FileValidationService is properly initialized
    - Test that services are accessible from controllers and dialogs

- [-] 11. Final integration testing and polish
  - [x] 11.1 Test complete workflow: create book with question papers
    - Open dialog, fill book form
    - Add multiple question papers with PDFs
    - Save book
    - Verify all data is persisted
    - _Requirements: 5.4_

  - [x] 11.2 Write property test for book-question paper association
    - **Property 16: Book-Question Paper Association Persistence**
    - **Validates: Requirements 5.4**
    - Test that for any book with question papers, all associations are persisted

  - [x] 11.3 Test complete workflow: edit book with question papers
    - Open dialog for existing book
    - Add new question papers
    - Delete existing question papers
    - Save book
    - Verify changes are persisted
    - _Requirements: 5.1, 6.3, 6.4_

  - [x] 11.4 Test error recovery workflows
    - Test retry after validation error
    - Test retry after API error
    - Test retry after network error
    - Verify form data is preserved
    - _Requirements: 8.6_

  - [ ] 11.5 Test platform-specific behavior
    - Test file upload on web platform (using bytes)
    - Test file upload on mobile platform (using paths)
    - Verify multipart/form-data is correctly formatted
    - _Requirements: 9.1, 9.3_

  - [ ] 11.6 Write integration tests for complete workflows
    - Test end-to-end: create book with question papers
    - Test end-to-end: edit book, add question papers
    - Test end-to-end: edit book, delete question papers
    - Test error recovery: validation error → fix → retry
    - Test error recovery: API error → retry
    - Test platform-specific: web file upload
    - Test platform-specific: mobile file upload

- [ ] 12. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- All tasks are required for comprehensive implementation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end workflows
- The implementation follows existing codebase patterns for consistency
