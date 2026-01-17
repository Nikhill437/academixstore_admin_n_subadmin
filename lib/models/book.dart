/// Book model representing a book entity in the academic store
/// Contains all necessary fields for book management
class Book {
  final String id;
  final String name;
  final String? description;
  final String? authorname;
  final String? isbn;
  final String? publisher;
  final int? publicationYear;
  final String? language;
  final String? category;
  final String? subject;
  final String? rate;
  final double? rating;
  final String? year;
  final int? semester;
  final int? pages;
  final String? pdfUrl;
  final String? coverImageUrl;
  final String? collegeId;
  final int downloadCount;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Creator? creator;
  final College? college;

  const Book({
    required this.id,
    required this.name,
    this.description,
    this.authorname,
    this.isbn,
    this.publisher,
    this.publicationYear,
    this.language,
    this.category,
    this.subject,
    this.rate,
    this.rating,
    this.year,
    this.semester,
    this.pages,
    this.pdfUrl,
    this.coverImageUrl,
    this.collegeId,
    this.downloadCount = 0,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.creator,
    this.college,
  });

  /// Create Book from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    try {
      // Parse creator if present
      Creator? creator;
      if (json['creator'] != null) {
        try {
          creator = Creator.fromJson(json['creator'] as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing creator: $e');
          creator = null;
        }
      }

      // Parse college if present
      College? college;
      if (json['college'] != null) {
        try {
          college = College.fromJson(json['college'] as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing college: $e');
          college = null;
        }
      }

      return Book(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        authorname: json['authorname']?.toString(),
        isbn: json['isbn']?.toString(),
        publisher: json['publisher']?.toString(),
        publicationYear: json['publication_year'] as int?,
        language: json['language']?.toString(),
        category: json['category']?.toString(),
        subject: json['subject']?.toString(),
        rate: json['rate']?.toString(),
        rating: json['rating'] != null
            ? double.tryParse(json['rating'].toString())
            : null,
        year: json['year'],
        semester: json['semester'] as int?,
        pages: json['pages'] as int?,
        pdfUrl: json['pdf_url']?.toString(),
        coverImageUrl: json['cover_image_url']?.toString(),
        collegeId: json['college_id']?.toString(),
        downloadCount: json['download_count'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        createdBy: json['created_by']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
        creator: creator,
        college: college,
      );
    } catch (e, stackTrace) {
      print('Error parsing Book from JSON: $e');
      print('JSON data: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Convert Book to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (authorname != null) 'authorname': authorname,
      if (isbn != null) 'isbn': isbn,
      if (publisher != null) 'publisher': publisher,
      if (publicationYear != null) 'publication_year': publicationYear,
      if (language != null) 'language': language,
      if (category != null) 'category': category,
      if (subject != null) 'subject': subject,
      if (rate != null) 'rate': rate,
      if (year != null) 'year': year,
      if (semester != null) 'semester': semester,
      if (pages != null) 'pages': pages,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (collegeId != null) 'college_id': collegeId,
      'download_count': downloadCount,
      'is_active': isActive,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (creator != null) 'creator': creator!.toJson(),
      if (college != null) 'college': college!.toJson(),
    };
  }

  /// Create a copy of Book with updated fields
  Book copyWith({
    String? id,
    String? name,
    String? description,
    String? authorname,
    String? isbn,
    String? publisher,
    int? publicationYear,
    String? language,
    String? category,
    String? subject,
    String? rate,
    String? year,
    int? semester,
    int? pages,
    String? pdfUrl,
    String? coverImageUrl,
    String? collegeId,
    int? downloadCount,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Creator? creator,
    College? college,
  }) {
    return Book(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      authorname: authorname ?? this.authorname,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publicationYear: publicationYear ?? this.publicationYear,
      language: language ?? this.language,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      rate: rate ?? this.rate,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      pages: pages ?? this.pages,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      collegeId: collegeId ?? this.collegeId,
      downloadCount: downloadCount ?? this.downloadCount,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creator: creator ?? this.creator,
      college: college ?? this.college,
    );
  }

  /// Get formatted rating
  String get formattedRate => rate != null
      ? (double.tryParse(rate!)?.toStringAsFixed(1) ?? '0.0')
      : '0.0';

  /// Get year and semester display
  String get yearSemester => 'Year ${year ?? 'N/A'}, Sem ${semester ?? 'N/A'}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Book(id: $id, name: $name, authorname: ${authorname ?? 'Unknown'}, year: ${year ?? 'N/A'}, semester: ${semester ?? 'N/A'})';
  }
}

/// Creator model for book creator information
class Creator {
  final String id;
  final String fullName;
  final String email;

  const Creator({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'full_name': fullName, 'email': email};
  }
}

/// College model for book college information
class College {
  final String id;
  final String name;
  final String code;

  const College({required this.id, required this.name, required this.code});

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      code: json['code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }
}

/// Book category enumeration for filtering and organization
enum BookCategory {
  computerScience('Computer Science', 'Computer Science'),
  mathematics('Mathematics', 'Mathematics'),
  physics('Physics', 'Physics'),
  chemistry('Chemistry', 'Chemistry'),
  biology('Biology', 'Biology'),
  engineering('Engineering', 'Engineering'),
  medicine('Medicine', 'Medicine'),
  law('Law', 'Law'),
  business('Business', 'Business'),
  literature('Literature', 'Literature'),
  history('History', 'History'),
  philosophy('Philosophy', 'Philosophy'),
  psychology('Psychology', 'Psychology'),
  education('Education', 'Education'),
  other('Other', 'Other');

  const BookCategory(this.value, this.displayName);

  final String value;
  final String displayName;

  static BookCategory? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return BookCategory.values.firstWhere(
        (category) => category.value.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => value;
}

/// Book filters for search and pagination
class BookFilters {
  final String? search;
  final BookCategory? category;
  final String? subject;
  final int? year;
  final int? semester;
  final String? author;
  final String? publisher;
  final bool? isActive;

  const BookFilters({
    this.search,
    this.category,
    this.subject,
    this.year,
    this.semester,
    this.author,
    this.publisher,
    this.isActive,
  });

  /// Convert filters to query parameters
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (category != null) {
      params['category'] = category!.value;
    }
    if (subject != null && subject!.isNotEmpty) {
      params['subject'] = subject;
    }
    if (year != null) {
      params['year'] = year;
    }
    if (semester != null) {
      params['semester'] = semester;
    }
    if (author != null && author!.isNotEmpty) {
      params['author'] = author;
    }
    if (publisher != null && publisher!.isNotEmpty) {
      params['publisher'] = publisher;
    }
    if (isActive != null) {
      params['is_active'] = isActive;
    }

    return params;
  }

  /// Create a copy with updated filters
  BookFilters copyWith({
    String? search,
    BookCategory? category,
    String? subject,
    int? year,
    int? semester,
    String? author,
    String? publisher,
    bool? isActive,
  }) {
    return BookFilters(
      search: search ?? this.search,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if any filters are applied
  bool get hasFilters {
    return search != null ||
        category != null ||
        subject != null ||
        year != null ||
        semester != null ||
        author != null ||
        publisher != null ||
        isActive != null;
  }

  /// Clear all filters
  BookFilters clear() {
    return const BookFilters();
  }
}
