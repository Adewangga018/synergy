import 'package:flutter/material.dart';

/// Priority level untuk task
enum TaskPriority {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Rendah';
      case TaskPriority.medium:
        return 'Sedang';
      case TaskPriority.high:
        return 'Tinggi';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.low:
        return Icons.flag_outlined;
      case TaskPriority.medium:
        return Icons.flag;
      case TaskPriority.high:
        return Icons.priority_high;
    }
  }

  static TaskPriority fromString(String priority) {
    return TaskPriority.values.firstWhere(
      (p) => p.name.toLowerCase() == priority.toLowerCase(),
      orElse: () => TaskPriority.medium,
    );
  }
}

/// Model untuk Aktivitas/Tugas user
/// Digunakan untuk menandai jadwal aktivitas yang bersifat momentual
class UserTask {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final TimeOfDay? dueTime;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserTask({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert dari JSON (dari Supabase)
  factory UserTask.fromJson(Map<String, dynamic> json) {
    TimeOfDay? dueTime;
    if (json['due_time'] != null) {
      // Parse time string (HH:MM:SS)
      final timeParts = (json['due_time'] as String).split(':');
      dueTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    return UserTask(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      dueTime: dueTime,
      isCompleted: json['is_completed'] as bool? ?? false,
      priority: TaskPriority.fromString(json['priority'] as String? ?? 'medium'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert ke JSON (untuk kirim ke Supabase)
  Map<String, dynamic> toJson() {
    String? dueTimeString;
    if (dueTime != null) {
      dueTimeString = '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}:00';
    }

    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'due_time': dueTimeString,
      'is_completed': isCompleted,
      'priority': priority.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with (untuk update)
  UserTask copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get full DateTime (combine date + time)
  DateTime? get fullDateTime {
    if (dueTime == null) return null;
    
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      dueTime!.hour,
      dueTime!.minute,
    );
  }

  /// Format time sebagai string untuk display
  String? get formattedTime {
    if (dueTime == null) return null;
    return '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}';
  }
}
