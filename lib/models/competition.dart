import 'package:flutter/material.dart';

class Competition {
  final String id;
  final String userId;
  final String compName;
  final String? category;
  final String? achievement;
  final DateTime? eventDate;
  final DateTime createdAt;

  Competition({
    required this.id,
    required this.userId,
    required this.compName,
    this.category,
    this.achievement,
    this.eventDate,
    required this.createdAt,
  });

  // Convert dari JSON (dari Supabase)
  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      compName: json['comp_name'] as String,
      category: json['category'] as String?,
      achievement: json['achievement'] as String?,
      eventDate: json['event_date'] != null 
          ? DateTime.parse(json['event_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert ke JSON (untuk kirim ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'comp_name': compName,
      'category': category,
      'achievement': achievement,
      'event_date': eventDate?.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper untuk format tanggal event
  String get eventDateString {
    if (eventDate == null) return '-';
    
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${eventDate!.day} ${months[eventDate!.month]} ${eventDate!.year}';
  }

  // Alias untuk formattedEventDate
  String get formattedEventDate => eventDateString;

  // Helper untuk mendapatkan badge color berdasarkan achievement
  Color get achievementColor {
    if (achievement == null) return const Color(0xFF666666);
    
    final lower = achievement!.toLowerCase();
    if (lower.contains('juara 1') || lower.contains('emas') || lower.contains('gold')) {
      return const Color(0xFFFFD700); // Gold
    } else if (lower.contains('juara 2') || lower.contains('perak') || lower.contains('silver')) {
      return const Color(0xFFC0C0C0); // Silver
    } else if (lower.contains('juara 3') || lower.contains('perunggu') || lower.contains('bronze')) {
      return const Color(0xFFCD7F32); // Bronze
    } else if (lower.contains('harapan') || lower.contains('favorit')) {
      return const Color(0xFF00A86B); // Green
    }
    return const Color(0xFF0078C1); // Blue (default)
  }

  // Helper untuk cek jika event sudah lewat
  bool get isPastEvent {
    if (eventDate == null) return false;
    return DateTime.now().isAfter(eventDate!);
  }

  // CopyWith helper
  Competition copyWith({
    String? id,
    String? userId,
    String? compName,
    String? category,
    String? achievement,
    DateTime? eventDate,
    DateTime? createdAt,
  }) {
    return Competition(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      compName: compName ?? this.compName,
      category: category ?? this.category,
      achievement: achievement ?? this.achievement,
      eventDate: eventDate ?? this.eventDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
