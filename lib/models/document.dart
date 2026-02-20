import 'package:flutter/material.dart';

/// Enum untuk kategori dokumen
enum DocumentCategory {
  certificate('Sertifikat', 'certificate'),
  transcript('Transkrip', 'transcript'),
  idCard('KTP/Identitas', 'id_card'),
  familyCard('Kartu Keluarga', 'family_card'),
  diploma('Ijazah', 'diploma'),
  portfolio('Portfolio', 'portfolio'),
  report('Laporan', 'report'),
  proposal('Proposal', 'proposal'),
  research('Penelitian', 'research'),
  other('Lainnya', 'other');

  final String displayName;
  final String value;

  const DocumentCategory(this.displayName, this.value);

  // Convert dari string database
  static DocumentCategory fromString(String value) {
    return DocumentCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => DocumentCategory.other,
    );
  }
}

class Document {
  final String id;
  final String userId;
  final String title;
  final String? overview;
  final DateTime? documentDate;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize; // dalam bytes
  final DocumentCategory? category;
  final List<String>? tags;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.userId,
    required this.title,
    this.overview,
    this.documentDate,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.category,
    this.tags,
    required this.createdAt,
  });

  // Convert dari JSON (dari Supabase)
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      overview: json['overview'] as String?,
      documentDate: json['document_date'] != null
          ? DateTime.parse(json['document_date'] as String)
          : null,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      category: json['category'] != null
          ? DocumentCategory.fromString(json['category'] as String)
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert ke JSON (untuk kirim ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'overview': overview,
      'document_date': documentDate?.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'category': category?.value,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper untuk mendapatkan badge color berdasarkan kategori
  Color get categoryColor {
    if (category == null) return const Color(0xFF666666);
    return getCategoryColor(category!);
  }

  // Helper untuk mendapatkan string kategori
  String get categoryString {
    return category?.displayName ?? 'Tidak Ada';
  }

  // Helper untuk format ukuran file
  String get formattedFileSize {
    if (fileSize == null) return '-';
    
    if (fileSize! < 1024) {
      return '$fileSize B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Helper untuk mendapatkan icon berdasarkan kategori
  IconData get categoryIcon {
    if (category == null) return Icons.description;
    
    switch (category!) {
      case DocumentCategory.certificate:
        return Icons.workspace_premium;
      case DocumentCategory.transcript:
        return Icons.receipt_long;
      case DocumentCategory.idCard:
        return Icons.badge;
      case DocumentCategory.familyCard:
        return Icons.family_restroom;
      case DocumentCategory.diploma:
        return Icons.school;
      case DocumentCategory.portfolio:
        return Icons.work;
      case DocumentCategory.report:
        return Icons.assessment;
      case DocumentCategory.proposal:
        return Icons.article;
      case DocumentCategory.research:
        return Icons.science;
      case DocumentCategory.other:
        return Icons.description;
    }
  }

  // Static helper untuk mendapatkan icon dari DocumentCategory
  static IconData getCategoryIcon(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.certificate:
        return Icons.workspace_premium;
      case DocumentCategory.transcript:
        return Icons.receipt_long;
      case DocumentCategory.idCard:
        return Icons.badge;
      case DocumentCategory.familyCard:
        return Icons.family_restroom;
      case DocumentCategory.diploma:
        return Icons.school;
      case DocumentCategory.portfolio:
        return Icons.work;
      case DocumentCategory.report:
        return Icons.assessment;
      case DocumentCategory.proposal:
        return Icons.article;
      case DocumentCategory.research:
        return Icons.science;
      case DocumentCategory.other:
        return Icons.description;
    }
  }

  // Static helper untuk mendapatkan color dari DocumentCategory
  static Color getCategoryColor(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.certificate:
        return const Color(0xFFFFD700); // Gold
      case DocumentCategory.transcript:
        return const Color(0xFF0078C1); // Blue
      case DocumentCategory.idCard:
        return const Color(0xFF4CAF50); // Green
      case DocumentCategory.familyCard:
        return const Color(0xFF9C27B0); // Purple
      case DocumentCategory.diploma:
        return const Color(0xFF013880); // Dark Blue
      case DocumentCategory.portfolio:
        return const Color(0xFFFF9800); // Orange
      case DocumentCategory.report:
        return const Color(0xFF2196F3); // Light Blue
      case DocumentCategory.proposal:
        return const Color(0xFF00BCD4); // Cyan
      case DocumentCategory.research:
        return const Color(0xFF009688); // Teal
      case DocumentCategory.other:
        return const Color(0xFF666666); // Grey
    }
  }

  // CopyWith helper
  Document copyWith({
    String? id,
    String? userId,
    String? title,
    String? overview,
    DateTime? documentDate,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    DocumentCategory? category,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return Document(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      documentDate: documentDate ?? this.documentDate,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper untuk check apakah ada file
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  // Helper untuk mendapatkan file extension
  String? get fileExtension {
    if (fileName == null) return null;
    final parts = fileName!.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : null;
  }

  // Helper untuk check apakah file adalah gambar
  bool get isImageFile {
    final ext = fileExtension;
    return ext != null && ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  // Helper untuk check apakah file adalah PDF
  bool get isPdfFile {
    return fileExtension == 'pdf';
  }
}
