import 'package:synergy/models/calendar_event.dart';

/// Model untuk menyimpan informasi konflik antara dua event
class EventConflict {
  final CalendarEvent academicEvent;
  final CalendarEvent conflictingEvent;
  final DateTime conflictStartTime;
  final DateTime conflictEndTime;

  EventConflict({
    required this.academicEvent,
    required this.conflictingEvent,
    required this.conflictStartTime,
    required this.conflictEndTime,
  });

  /// Mendapatkan durasi konflik dalam menit
  int get conflictDurationInMinutes {
    return conflictEndTime.difference(conflictStartTime).inMinutes;
  }

  /// Mendapatkan tipe event yang bentrok (volunteer atau organization)
  String get conflictingEventType {
    return conflictingEvent.source.displayName;
  }

  /// Format waktu konflik untuk ditampilkan (e.g., "13:00 - 14:30")
  String get conflictTimeRange {
    final startHour = conflictStartTime.hour.toString().padLeft(2, '0');
    final startMinute = conflictStartTime.minute.toString().padLeft(2, '0');
    final endHour = conflictEndTime.hour.toString().padLeft(2, '0');
    final endMinute = conflictEndTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  @override
  String toString() {
    return 'EventConflict(academic: ${academicEvent.title}, conflicting: ${conflictingEvent.title}, time: $conflictTimeRange)';
  }
}

