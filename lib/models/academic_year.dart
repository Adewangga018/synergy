class AcademicYear {
  final String id;
  final String userId;
  final String semesterName;
  final DateTime startDate;
  final int totalActiveWeeks;
  final bool isActive;
  final DateTime createdAt;

  AcademicYear({
    required this.id,
    required this.userId,
    required this.semesterName,
    required this.startDate,
    required this.totalActiveWeeks,
    required this.isActive,
    required this.createdAt,
  });

  // Convert dari JSON (dari Supabase)
  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      semesterName: json['semester_name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      totalActiveWeeks: json['total_active_weeks'] as int,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert ke JSON (untuk kirim ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'semester_name': semesterName,
      'start_date': startDate.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
      'total_active_weeks': totalActiveWeeks,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper untuk mendapatkan end date (berdasarkan start + weeks)
  DateTime get endDate {
    return startDate.add(Duration(days: totalActiveWeeks * 7));
  }

  // Helper untuk cek apakah masih dalam periode
  bool get isCurrentPeriod {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Helper untuk format periode
  String get periodString {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    final start = '${months[startDate.month]} ${startDate.year}';
    final end = '${months[endDate.month]} ${endDate.year}';
    return '$start - $end';
  }

  // CopyWith helper
  AcademicYear copyWith({
    String? id,
    String? userId,
    String? semesterName,
    DateTime? startDate,
    int? totalActiveWeeks,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AcademicYear(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterName: semesterName ?? this.semesterName,
      startDate: startDate ?? this.startDate,
      totalActiveWeeks: totalActiveWeeks ?? this.totalActiveWeeks,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
