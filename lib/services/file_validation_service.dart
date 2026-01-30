/// Service for validating file uploads
/// 
/// This service provides validation for file uploads, specifically for PDF files.
/// It checks file extension and size constraints to ensure only valid files are uploaded.
class FileValidationService {
  /// Maximum allowed file size in bytes (50MB)
  static const int maxFileSizeBytes = 52428800; // 50MB = 50 * 1024 * 1024

  /// Validates a PDF file based on extension and size
  /// 
  /// Parameters:
  /// - [fileName]: The name of the file including extension
  /// - [fileSizeBytes]: The size of the file in bytes
  /// 
  /// Returns a [FileValidationResult] containing:
  /// - [isValid]: true if the file passes all validation checks
  /// - [errorMessage]: null if valid, otherwise a specific error message
  /// 
  /// Validation Rules:
  /// 1. File extension must be .pdf (case-insensitive)
  /// 2. File size must be <= 50MB (52,428,800 bytes)
  /// 
  /// Requirements: 3.3, 3.4, 7.1, 7.2, 7.3
  FileValidationResult validatePdfFile({
    required String fileName,
    required int fileSizeBytes,
  }) {
    // Check file extension (case-insensitive)
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      return FileValidationResult(
        isValid: false,
        errorMessage: 'Only PDF files are allowed',
      );
    }

    // Check file size
    if (fileSizeBytes > maxFileSizeBytes) {
      return FileValidationResult(
        isValid: false,
        errorMessage: 'PDF file must be less than 50MB',
      );
    }

    // File is valid
    return FileValidationResult(
      isValid: true,
      errorMessage: null,
    );
  }
}

/// Result of file validation
class FileValidationResult {
  /// Whether the file passed validation
  final bool isValid;

  /// Error message if validation failed, null if valid
  final String? errorMessage;

  FileValidationResult({
    required this.isValid,
    required this.errorMessage,
  });
}
