# Requirements Document

## Introduction

This document specifies the requirements for adding question paper upload functionality to the book creation/editing dialog in a Flutter admin application. The feature enables administrators to associate multiple question papers with books, providing a comprehensive educational content management system.

## Glossary

- **Book_Dialog**: The UI component for creating or editing book records
- **Question_Paper**: An educational assessment document with metadata (title, subject, year, semester, exam type, marks) and an associated PDF file
- **Question_Paper_API**: The backend REST API service that handles question paper CRUD operations and file uploads
- **Books_Controller**: The GetX state management controller for book operations
- **File_Picker**: The UI component that allows users to select PDF files from their device
- **Upload_Progress**: Visual feedback showing the status of file upload operations
- **Validation_Service**: The component that validates file type and size constraints

## Requirements

### Requirement 1: Question Paper Section in Book Dialog

**User Story:** As an administrator, I want to see a dedicated section for question papers in the book dialog, so that I can manage question papers associated with a book.

#### Acceptance Criteria

1. WHEN the Book_Dialog is opened for creating or editing a book, THE Book_Dialog SHALL display a question papers section below the existing book fields
2. THE Book_Dialog SHALL display a list of all question papers currently associated with the book being edited
3. WHEN no question papers are associated with a book, THE Book_Dialog SHALL display an empty state message indicating no question papers exist
4. THE Book_Dialog SHALL provide an "Add Question Paper" button to initiate question paper creation

### Requirement 2: Question Paper Form Fields

**User Story:** As an administrator, I want to enter question paper metadata, so that I can properly categorize and identify each question paper.

#### Acceptance Criteria

1. WHEN a user clicks "Add Question Paper", THE Book_Dialog SHALL display input fields for title, subject, year, and semester
2. THE Book_Dialog SHALL provide a dropdown field for exam_type with options: midterm, final, quiz, and practice
3. THE Book_Dialog SHALL provide an optional numeric input field for marks
4. THE Book_Dialog SHALL provide an optional text area field for description
5. THE Book_Dialog SHALL mark title, subject, year, and semester fields as required with visual indicators
6. WHEN a required field is empty and the user attempts to save, THE Validation_Service SHALL prevent submission and display an error message

### Requirement 3: PDF File Upload

**User Story:** As an administrator, I want to upload a PDF file for each question paper, so that students can access the question paper content.

#### Acceptance Criteria

1. THE Book_Dialog SHALL provide a File_Picker button for selecting PDF files
2. WHEN a user clicks the file picker button, THE File_Picker SHALL open a file selection dialog filtered to PDF files only
3. WHEN a user selects a non-PDF file, THE Validation_Service SHALL reject the file and display an error message
4. WHEN a user selects a PDF file larger than 50MB, THE Validation_Service SHALL reject the file and display an error message indicating the size limit
5. WHEN a valid PDF file is selected, THE Book_Dialog SHALL display the selected filename
6. THE Book_Dialog SHALL allow users to change the selected file before submission

### Requirement 4: Question Paper Creation and Upload

**User Story:** As an administrator, I want to save question papers with their PDF files, so that they are stored in the system and associated with the book.

#### Acceptance Criteria

1. WHEN a user completes the question paper form and clicks save, THE Books_Controller SHALL create a question paper record via the Question_Paper_API POST /api/question-papers endpoint
2. WHEN the question paper record is created successfully, THE Books_Controller SHALL upload the PDF file via the Question_Paper_API POST /api/question-papers/:id/upload-pdf endpoint using multipart/form-data with field name "question_paper"
3. WHEN the PDF upload is in progress, THE Book_Dialog SHALL display Upload_Progress feedback showing percentage completion
4. WHEN the PDF upload completes successfully, THE Book_Dialog SHALL add the new question paper to the displayed list and clear the form
5. IF the question paper creation fails, THEN THE Books_Controller SHALL display an error message and not attempt PDF upload
6. IF the PDF upload fails after question paper creation, THEN THE Books_Controller SHALL display an error message indicating the question paper was created but the file upload failed

### Requirement 5: Multiple Question Papers Management

**User Story:** As an administrator, I want to add multiple question papers to a single book, so that I can provide comprehensive assessment materials.

#### Acceptance Criteria

1. THE Book_Dialog SHALL allow users to add multiple question papers to a single book without closing the dialog
2. WHEN a question paper is successfully added, THE Book_Dialog SHALL display it in the question papers list with its title, subject, year, semester, and exam type
3. THE Book_Dialog SHALL display all question papers in a scrollable list when more than 5 question papers exist
4. WHEN the book is saved, THE Books_Controller SHALL persist all associations between the book and its question papers

### Requirement 6: Question Paper Deletion

**User Story:** As an administrator, I want to delete question papers from a book, so that I can remove outdated or incorrect materials.

#### Acceptance Criteria

1. WHEN a question paper is displayed in the list, THE Book_Dialog SHALL provide a delete button for each question paper
2. WHEN a user clicks the delete button, THE Book_Dialog SHALL display a confirmation dialog asking the user to confirm deletion
3. WHEN a user confirms deletion, THE Books_Controller SHALL call the Question_Paper_API DELETE endpoint to remove the question paper
4. WHEN deletion is successful, THE Book_Dialog SHALL remove the question paper from the displayed list
5. IF deletion fails, THEN THE Books_Controller SHALL display an error message and keep the question paper in the list

### Requirement 7: File Validation

**User Story:** As an administrator, I want the system to validate uploaded files, so that only valid PDF files within size limits are accepted.

#### Acceptance Criteria

1. WHEN a file is selected, THE Validation_Service SHALL check the file extension is .pdf
2. WHEN a file is selected, THE Validation_Service SHALL check the file size is less than or equal to 50MB
3. WHEN validation fails, THE Validation_Service SHALL display a specific error message indicating whether the file type or size constraint was violated
4. THE Validation_Service SHALL perform validation before any API calls are made
5. WHEN a file passes validation, THE Book_Dialog SHALL enable the save button

### Requirement 8: User Feedback and Error Handling

**User Story:** As an administrator, I want clear feedback on upload operations, so that I understand the status of my actions.

#### Acceptance Criteria

1. WHEN a question paper creation is in progress, THE Book_Dialog SHALL display a loading indicator
2. WHEN a PDF upload is in progress, THE Book_Dialog SHALL display Upload_Progress with percentage completion
3. WHEN an operation succeeds, THE Book_Dialog SHALL display a success message for 3 seconds
4. WHEN an operation fails, THE Book_Dialog SHALL display an error message with details about the failure
5. WHEN a network error occurs, THE Books_Controller SHALL display a user-friendly error message indicating connectivity issues
6. THE Book_Dialog SHALL remain open after errors to allow users to retry operations

### Requirement 9: Web Platform Compatibility

**User Story:** As a system architect, I want the file upload to work on web platforms, so that administrators can use the application in web browsers.

#### Acceptance Criteria

1. WHEN running on web platform, THE File_Picker SHALL use file bytes instead of file paths for upload operations
2. THE Books_Controller SHALL handle file selection using platform-appropriate APIs that work on Flutter web
3. THE Books_Controller SHALL send file data as multipart/form-data compatible with web browser constraints
4. WHEN uploading files on web, THE Upload_Progress SHALL accurately reflect upload progress

### Requirement 10: UI/UX Consistency

**User Story:** As an administrator, I want the question paper upload interface to match the existing application design, so that I have a consistent user experience.

#### Acceptance Criteria

1. THE Book_Dialog SHALL use the same styling, colors, and typography as existing dialog components
2. THE Book_Dialog SHALL follow the same form layout patterns used in other dialogs (add_edit_user_dialog, add_edit_student_dialog)
3. THE Book_Dialog SHALL use the same button styles and positioning as existing dialogs
4. THE Book_Dialog SHALL use the same error message display patterns as existing forms
5. THE Book_Dialog SHALL maintain responsive layout behavior consistent with other dialogs
