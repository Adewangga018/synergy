import 'package:flutter/material.dart';

/// Enum untuk skala organisasi
enum OrganizationScale {
  department('Jurusan', 'department'),
  faculty('Fakultas', 'faculty'),
  campus('Kampus', 'campus'),
  external('Eksternal', 'external');

  final String displayName;
  final String value;

  const OrganizationScale(this.displayName, this.value);

  // Convert dari string database
  static OrganizationScale fromString(String value) {
    return OrganizationScale.values.firstWhere(
      (scale) => scale.value == value,
      orElse: () => OrganizationScale.department,
    );
  }
}

class Organization {
  final String id;
  final String userId;
  final DateTime? startDate;  // CHANGED: tanggal mulai bergabung
  final DateTime? endDate;    // CHANGED: tanggal selesai (opsional jika masih aktif)
  final String orgName;
  final OrganizationScale? scale;
  final String position;
  final DateTime createdAt;

  Organization({
    required this.id,
    required this.userId,
    this.startDate,
    this.endDate,
    required this.orgName,
    this.scale,
    required this.position,
    required this.createdAt,
  });

  // Convert dari JSON (dari Supabase)
  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'] as String) 
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'] as String) 
          : null,
      orgName: json['org_name'] as String,
      scale: json['scale'] != null 
          ? OrganizationScale.fromString(json['scale'] as String)
          : null,
      position: json['position'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert ke JSON (untuk kirim ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_date': startDate?.toIso8601String().split('T')[0],  // Format: YYYY-MM-DD
      'end_date': endDate?.toIso8601String().split('T')[0],      // Format: YYYY-MM-DD
      'org_name': orgName,
      'scale': scale?.value,
      'position': position,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper untuk mendapatkan badge color berdasarkan scale
  Color get scaleColor {
    if (scale == null) return const Color(0xFF666666);
    return getScaleColor(scale!);
  }

  // Helper untuk mendapatkan string skala
  String get scaleString {
    return scale?.displayName ?? 'Tidak Ada';
  }

  // Static helper untuk mendapatkan color dari OrganizationScale
  static Color getScaleColor(OrganizationScale scale) {
    switch (scale) {
      case OrganizationScale.department:
        return const Color(0xFF0078C1); // Blue
      case OrganizationScale.faculty:
        return const Color(0xFF013880); // Dark Blue
      case OrganizationScale.campus:
        return const Color(0xFF00A86B); // Green
      case OrganizationScale.external:
        return const Color(0xFFFF6B35); // Orange
    }
  }

  // CopyWith helper
  Organization copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? orgName,
    OrganizationScale? scale,
    String? position,
    DateTime? createdAt,
  }) {
    return Organization(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      orgName: orgName ?? this.orgName,
      scale: scale ?? this.scale,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
