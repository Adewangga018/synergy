class PersonalNote {
  final String id;
  final String userId;
  final String title;
  final String? content;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalNote({
    required this.id,
    required this.userId,
    required this.title,
    this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert dari JSON (dari Supabase)
  factory PersonalNote.fromJson(Map<String, dynamic> json) {
    return PersonalNote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert ke JSON (untuk kirim ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper untuk membuat copy dengan perubahan
  PersonalNote copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
