class VolunteerActivity {
  final String id;
  final String userId;
  final String activityName;
  final String role;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  VolunteerActivity({
    required this.id,
    required this.userId,
    required this.activityName,
    required this.role,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  // Convert dari JSON (dari Supabase)
  factory VolunteerActivity.fromJson(Map<String, dynamic> json) {
    return VolunteerActivity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      activityName: json['activity_name'] as String,
      role: json['role'] as String,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert ke JSON (untuk kirim ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'activity_name': activityName,
      'role': role,
      'start_date': startDate?.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
      'end_date': endDate?.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper untuk cek apakah masih aktif
  bool get isActive {
    if (endDate == null) return true; // Jika tidak ada end date, dianggap masih aktif
    return DateTime.now().isBefore(endDate!);
  }

  // Helper untuk durasi dalam format string
  String get durationString {
    if (startDate == null) return '-';
    
    final start = '${_monthName(startDate!.month)} ${startDate!.year}';
    if (endDate == null) {
      return '$start - Sekarang';
    }
    final end = '${_monthName(endDate!.month)} ${endDate!.year}';
    return '$start - $end';
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month];
  }

  // CopyWith helper
  VolunteerActivity copyWith({
    String? id,
    String? userId,
    String? activityName,
    String? role,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return VolunteerActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityName: activityName ?? this.activityName,
      role: role ?? this.role,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
