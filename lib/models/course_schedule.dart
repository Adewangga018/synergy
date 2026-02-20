import 'package:flutter/material.dart';

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Senin';
      case DayOfWeek.tuesday:
        return 'Selasa';
      case DayOfWeek.wednesday:
        return 'Rabu';
      case DayOfWeek.thursday:
        return 'Kamis';
      case DayOfWeek.friday:
        return 'Jumat';
      case DayOfWeek.saturday:
        return 'Sabtu';
      case DayOfWeek.sunday:
        return 'Minggu';
    }
  }

  static DayOfWeek fromString(String day) {
    return DayOfWeek.values.firstWhere(
      (d) => d.name.toLowerCase() == day.toLowerCase(),
      orElse: () => DayOfWeek.monday,
    );
  }
}

enum ClassType {
  lecture,
  lab,
  seminar,
  workshop,
  other;

  String get displayName {
    switch (this) {
      case ClassType.lecture:
        return 'Teori';
      case ClassType.lab:
        return 'Praktikum';
      case ClassType.seminar:
        return 'Seminar';
      case ClassType.workshop:
        return 'Workshop';
      case ClassType.other:
        return 'Lainnya';
    }
  }

  static ClassType fromString(String type) {
    return ClassType.values.firstWhere(
      (t) => t.name.toLowerCase() == type.toLowerCase(),
      orElse: () => ClassType.lecture,
    );
  }
}

class CourseSchedule {
  final String id;
  final String userId;
  final String courseName;
  final String courseCode;
  final String lecturer;
  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String room;
  final int semester;
  final int credits;
  final ClassType classType;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseSchedule({
    required this.id,
    required this.userId,
    required this.courseName,
    required this.courseCode,
    required this.lecturer,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.semester,
    required this.credits,
    required this.classType,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseSchedule.fromJson(Map<String, dynamic> json) {
    return CourseSchedule(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseName: json['course_name'] as String,
      courseCode: json['course_code'] as String,
      lecturer: json['lecturer'] as String,
      dayOfWeek: DayOfWeek.fromString(json['day_of_week'] as String),
      startTime: _parseTime(json['start_time'] as String),
      endTime: _parseTime(json['end_time'] as String),
      room: json['room'] as String,
      semester: json['semester'] as int,
      credits: json['credits'] as int,
      classType: ClassType.fromString(json['class_type'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'course_name': courseName,
      'course_code': courseCode,
      'lecturer': lecturer,
      'day_of_week': dayOfWeek.name,
      'start_time': formatTime(startTime),
      'end_time': formatTime(endTime),
      'room': room,
      'semester': semester,
      'credits': credits,
      'class_type': classType.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Helper: Parse time string (HH:MM) to TimeOfDay
  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Helper: Format TimeOfDay to string (HH:MM)
  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Helper: Format waktu untuk display (HH:MM)
  String get formattedTime {
    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  /// Helper: Durasi kuliah dalam menit
  int get durationInMinutes {
    final start = startTime.hour * 60 + startTime.minute;
    final end = endTime.hour * 60 + endTime.minute;
    return end - start;
  }

  /// Helper: Format durasi untuk display
  String get formattedDuration {
    final hours = durationInMinutes ~/ 60;
    final minutes = durationInMinutes % 60;
    
    if (hours == 0) {
      return '$minutes menit';
    } else if (minutes == 0) {
      return '$hours jam';
    } else {
      return '$hours jam $minutes menit';
    }
  }

  /// Helper: Day index untuk sorting (1=Monday, 7=Sunday)
  int get dayIndex {
    return dayOfWeek.index + 1;
  }

  CourseSchedule copyWith({
    String? id,
    String? userId,
    String? courseName,
    String? courseCode,
    String? lecturer,
    DayOfWeek? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? room,
    int? semester,
    int? credits,
    ClassType? classType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      lecturer: lecturer ?? this.lecturer,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      semester: semester ?? this.semester,
      credits: credits ?? this.credits,
      classType: classType ?? this.classType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
