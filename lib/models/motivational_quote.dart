class MotivationalQuote {
  final String id;
  final String quoteText;
  final String? theme;
  final String? relevanceContext;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int displayPriority;
  final int usageCount;

  MotivationalQuote({
    required this.id,
    required this.quoteText,
    this.theme,
    this.relevanceContext,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.displayPriority,
    required this.usageCount,
  });

  factory MotivationalQuote.fromJson(Map<String, dynamic> json) {
    return MotivationalQuote(
      id: json['id'] as String,
      quoteText: json['quote_text'] as String,
      theme: json['theme'] as String?,
      relevanceContext: json['relevance_context'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      displayPriority: json['display_priority'] as int? ?? 0,
      usageCount: json['usage_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_text': quoteText,
      'theme': theme,
      'relevance_context': relevanceContext,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'display_priority': displayPriority,
      'usage_count': usageCount,
    };
  }
}
