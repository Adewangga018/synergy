class Project {
  final String id;
  final String userId;
  final String title;
  final String? overview;
  final DateTime startDate;
  final DateTime? endDate;
  final String role;
  final List<String>? technologies;
  final String? projectUrl;
  final String? repositoryUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.userId,
    required this.title,
    this.overview,
    required this.startDate,
    this.endDate,
    required this.role,
    this.technologies,
    this.projectUrl,
    this.repositoryUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      overview: json['overview'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      role: json['role'] as String,
      technologies: json['technologies'] != null 
          ? List<String>.from(json['technologies'] as List)
          : null,
      projectUrl: json['project_url'] as String?,
      repositoryUrl: json['repository_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'overview': overview,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'role': role,
      'technologies': technologies,
      'project_url': projectUrl,
      'repository_url': repositoryUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Helper: Apakah project masih berjalan (ongoing)?
  bool get isOngoing => endDate == null;

  /// Helper: Durasi project dalam bulan (estimasi)
  int get durationInMonths {
    final end = endDate ?? DateTime.now();
    final diff = end.difference(startDate);
    return (diff.inDays / 30).round();
  }

  /// Helper: Format durasi untuk display
  String get formattedDuration {
    if (durationInMonths < 1) {
      return '< 1 bulan';
    } else if (durationInMonths == 1) {
      return '1 bulan';
    } else if (durationInMonths < 12) {
      return '$durationInMonths bulan';
    } else {
      final years = durationInMonths ~/ 12;
      final months = durationInMonths % 12;
      if (months == 0) {
        return '$years tahun';
      } else {
        return '$years tahun $months bulan';
      }
    }
  }

  Project copyWith({
    String? id,
    String? userId,
    String? title,
    String? overview,
    DateTime? startDate,
    DateTime? endDate,
    String? role,
    List<String>? technologies,
    String? projectUrl,
    String? repositoryUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      role: role ?? this.role,
      technologies: technologies ?? this.technologies,
      projectUrl: projectUrl ?? this.projectUrl,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
