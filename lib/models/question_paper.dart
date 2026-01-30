/// QuestionPaper model representing a question paper entity
/// Contains all necessary fields for question paper management
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

  const QuestionPaper({
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

  /// Create QuestionPaper from JSON
  factory QuestionPaper.fromJson(Map<String, dynamic> json) {
    try {
      return QuestionPaper(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        year: json['year'] as int? ?? 0,
        semester: json['semester'] as int? ?? 0,
        description: json['description']?.toString(),
        examType: json['exam_type']?.toString(),
        marks: json['marks'] as int?,
        collegeId: json['college_id']?.toString(),
        pdfUrl: json['pdf_url']?.toString(),
        pdfAccessUrl: json['pdf_access_url']?.toString(),
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'].toString())
            : null,
      );
    } catch (e, stackTrace) {
      print('Error parsing QuestionPaper from JSON: $e');
      print('JSON data: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Convert QuestionPaper to JSON
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

  /// Create a copy of QuestionPaper with updated fields
  QuestionPaper copyWith({
    String? id,
    String? title,
    String? subject,
    int? year,
    int? semester,
    String? description,
    String? examType,
    int? marks,
    String? collegeId,
    String? pdfUrl,
    String? pdfAccessUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionPaper(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      description: description ?? this.description,
      examType: examType ?? this.examType,
      marks: marks ?? this.marks,
      collegeId: collegeId ?? this.collegeId,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfAccessUrl: pdfAccessUrl ?? this.pdfAccessUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted exam type display
  String get formattedExamType {
    if (examType == null) return 'N/A';
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
        return examType!;
    }
  }

  /// Get year and semester display
  String get yearSemester => 'Year $year, Sem $semester';

  /// Get formatted marks display
  String get formattedMarks => marks != null ? '$marks marks' : 'N/A';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionPaper && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QuestionPaper(id: $id, title: $title, subject: $subject, year: $year, semester: $semester, examType: ${examType ?? 'N/A'})';
  }
}

/// Exam type enumeration for question papers
enum ExamType {
  midterm('midterm', 'Midterm'),
  final_('final', 'Final'),
  quiz('quiz', 'Quiz'),
  practice('practice', 'Practice');

  const ExamType(this.value, this.displayName);

  final String value;
  final String displayName;

  static ExamType? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return ExamType.values.firstWhere(
        (type) => type.value.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => value;
}

/// Question paper filters for search and pagination
class QuestionPaperFilters {
  final String? subject;
  final int? year;
  final int? semester;
  final String? examType;
  final String? collegeId;
  final bool? isActive;

  const QuestionPaperFilters({
    this.subject,
    this.year,
    this.semester,
    this.examType,
    this.collegeId,
    this.isActive,
  });

  /// Convert filters to query parameters
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (subject != null && subject!.isNotEmpty) {
      params['subject'] = subject;
    }
    if (year != null) {
      params['year'] = year;
    }
    if (semester != null) {
      params['semester'] = semester;
    }
    if (examType != null && examType!.isNotEmpty) {
      params['exam_type'] = examType;
    }
    if (collegeId != null && collegeId!.isNotEmpty) {
      params['college_id'] = collegeId;
    }
    if (isActive != null) {
      params['is_active'] = isActive;
    }

    return params;
  }

  /// Create a copy with updated filters
  QuestionPaperFilters copyWith({
    String? subject,
    int? year,
    int? semester,
    String? examType,
    String? collegeId,
    bool? isActive,
  }) {
    return QuestionPaperFilters(
      subject: subject ?? this.subject,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      examType: examType ?? this.examType,
      collegeId: collegeId ?? this.collegeId,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if any filters are applied
  bool get hasFilters {
    return subject != null ||
        year != null ||
        semester != null ||
        examType != null ||
        collegeId != null ||
        isActive != null;
  }

  /// Clear all filters
  QuestionPaperFilters clear() {
    return const QuestionPaperFilters();
  }
}
