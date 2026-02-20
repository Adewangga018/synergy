import 'package:flutter/material.dart';

/// Enum untuk sumber event
enum EventSource {
  courseSchedule,
  competition,
  volunteer,
  organization,
  document,
  project,
  note,
  manual, // Event yang ditambahkan manual dari Google Calendar
}

extension EventSourceExtension on EventSource {
  String get displayName {
    switch (this) {
      case EventSource.courseSchedule:
        return 'Jadwal Kuliah';
      case EventSource.competition:
        return 'Kompetisi';
      case EventSource.volunteer:
        return 'Volunteer';
      case EventSource.organization:
        return 'Organisasi';
      case EventSource.document:
        return 'Dokumen';
      case EventSource.project:
        return 'Proyek';
      case EventSource.note:
        return 'Catatan';
      case EventSource.manual:
        return 'Manual';
    }
  }

  Color get color {
    switch (this) {
      case EventSource.courseSchedule:
        return const Color(0xFF00897B); // Teal
      case EventSource.competition:
        return const Color(0xFFE91E63); // Pink
      case EventSource.volunteer:
        return const Color(0xFFFF9800); // Orange
      case EventSource.organization:
        return const Color(0xFF9C27B0); // Purple
      case EventSource.document:
        return const Color(0xFF2196F3); // Blue
      case EventSource.project:
        return const Color(0xFF4CAF50); // Green
      case EventSource.note:
        return const Color(0xFFFFEB3B); // Yellow
      case EventSource.manual:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  IconData get icon {
    switch (this) {
      case EventSource.courseSchedule:
        return Icons.schedule;
      case EventSource.competition:
        return Icons.emoji_events;
      case EventSource.volunteer:
        return Icons.volunteer_activism;
      case EventSource.organization:
        return Icons.groups;
      case EventSource.document:
        return Icons.description;
      case EventSource.project:
        return Icons.work;
      case EventSource.note:
        return Icons.note;
      case EventSource.manual:
        return Icons.event;
    }
  }
}

/// Model untuk event calendar yang agregasi dari semua sumber
class CalendarEvent {
  final String id; // ID dari sumber asli
  final EventSource source;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final bool isAllDay;
  final String? googleCalendarEventId; // ID event di Google Calendar
  final Map<String, dynamic>? metadata; // Data tambahan dari sumber

  CalendarEvent({
    required this.id,
    required this.source,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.location,
    this.isAllDay = false,
    this.googleCalendarEventId,
    this.metadata,
  });

  /// Get color based on source
  Color get color => source.color;

  /// Get icon based on source
  IconData get icon => source.icon;

  /// Check if event is in the past
  bool get isPast => endTime?.isBefore(DateTime.now()) ?? startTime.isBefore(DateTime.now());

  /// Check if event is happening now
  bool get isOngoing {
    final now = DateTime.now();
    if (endTime == null) return false;
    return startTime.isBefore(now) && endTime!.isAfter(now);
  }

  /// Check if event is today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  /// Check if event is on specific date
  bool isOnDate(DateTime date) {
    return startTime.year == date.year &&
        startTime.month == date.month &&
        startTime.day == date.day;
  }

  /// Get duration in hours
  double? get durationInHours {
    if (endTime == null) return null;
    return endTime!.difference(startTime).inMinutes / 60;
  }

  /// Convert to JSON for storage/API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source.name,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'is_all_day': isAllDay,
      'google_calendar_event_id': googleCalendarEventId,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      source: EventSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => EventSource.manual,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      location: json['location'] as String?,
      isAllDay: json['is_all_day'] as bool? ?? false,
      googleCalendarEventId: json['google_calendar_event_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Copy with
  CalendarEvent copyWith({
    String? id,
    EventSource? source,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    bool? isAllDay,
    String? googleCalendarEventId,
    Map<String, dynamic>? metadata,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      isAllDay: isAllDay ?? this.isAllDay,
      googleCalendarEventId: googleCalendarEventId ?? this.googleCalendarEventId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'CalendarEvent(id: $id, source: ${source.displayName}, title: $title, startTime: $startTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent &&
        other.id == id &&
        other.source == source;
  }

  @override
  int get hashCode => id.hashCode ^ source.hashCode;
}
