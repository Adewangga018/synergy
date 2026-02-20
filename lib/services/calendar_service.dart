import 'package:synergy/models/calendar_event.dart';
import 'package:synergy/models/course_schedule.dart';
import 'package:synergy/models/competition.dart';
import 'package:synergy/models/volunteer_activity.dart';
import 'package:synergy/models/organization.dart';
import 'package:synergy/models/project.dart';
import 'package:synergy/services/course_schedule_service.dart';
import 'package:synergy/services/auth_service.dart';
import 'package:synergy/utils/semester_calculator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarService {
  final _supabase = Supabase.instance.client;
  final _courseScheduleService = CourseScheduleService();
  final _authService = AuthService();

  /// Get all events from all sources
  Future<List<CalendarEvent>> getAllEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final List<CalendarEvent> allEvents = [];

    // Get events from all sources in parallel
    final results = await Future.wait([
      _getCourseScheduleEvents(startDate: startDate, endDate: endDate),
      _getCompetitionEvents(),
      _getVolunteerEvents(),
      _getOrganizationEvents(),
      _getProjectEvents(),
    ]);

    for (final events in results) {
      allEvents.addAll(events);
    }

    // Sort by start time
    allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    return allEvents;
  }

  /// Get events for a specific date
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final allEvents = await getAllEvents(
      startDate: DateTime(date.year, date.month, date.day),
      endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
    );

    return allEvents.where((event) => event.isOnDate(date)).toList();
  }

  /// Get events for current month
  Future<Map<DateTime, List<CalendarEvent>>> getEventsForMonth(
    int year,
    int month,
  ) async {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final events = await getAllEvents(
      startDate: firstDay,
      endDate: lastDay,
    );

    // Group by date
    final Map<DateTime, List<CalendarEvent>> groupedEvents = {};
    for (final event in events) {
      final date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );

      if (groupedEvents[date] == null) {
        groupedEvents[date] = [];
      }
      groupedEvents[date]!.add(event);
    }

    return groupedEvents;
  }

  /// Convert CourseSchedule to CalendarEvents (recurring for date range)
  Future<List<CalendarEvent>> _getCourseScheduleEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final schedules = await _courseScheduleService.getSchedules();
    final events = <CalendarEvent>[];

    // Get user's angkatan from profile
    int angkatan;
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        angkatan = int.parse(profile.angkatan);
      } else {
        angkatan = DateTime.now().year;
      }
    } catch (e) {
      // Default to current year if angkatan not found
      angkatan = DateTime.now().year;
    }

    // Default to current month if no range specified
    final now = DateTime.now();
    final filterStart = startDate ?? DateTime(now.year, now.month, 1);
    final filterEnd = endDate ?? DateTime(now.year, now.month + 1, 0);

    for (final schedule in schedules) {
      // Get semester period based on angkatan
      final semesterPeriod = SemesterCalculator.getSemesterPeriod(
        angkatan,
        schedule.semester,
      );

      // Calculate range: intersection of semester period and requested range
      final rangeStart = _maxDate(semesterPeriod.startDate, filterStart);
      final rangeEnd = _minDate(semesterPeriod.endDate, filterEnd);

      // Skip if no overlap between semester period and filter range
      if (rangeStart.isAfter(rangeEnd)) continue;

      // Generate recurring events for each week in the date range
      DateTime current = rangeStart;
      while (current.isBefore(rangeEnd) || current.isAtSameMomentAs(rangeEnd)) {
        // Check if current date matches the schedule's day of week
        if (_matchesDayOfWeek(current, schedule.dayOfWeek)) {
          final eventStart = DateTime(
            current.year,
            current.month,
            current.day,
            schedule.startTime.hour,
            schedule.startTime.minute,
          );

          final eventEnd = DateTime(
            current.year,
            current.month,
            current.day,
            schedule.endTime.hour,
            schedule.endTime.minute,
          );

          events.add(CalendarEvent(
            id: '${schedule.id}_${current.toIso8601String().split('T')[0]}',
            source: EventSource.courseSchedule,
            title: schedule.courseName,
            description: '${schedule.courseCode} - ${schedule.lecturer}\n'
                '${schedule.classType.displayName} (${schedule.credits} SKS)\n'
                '${SemesterCalculator.getSemesterName(schedule.semester)} - ${SemesterCalculator.getAcademicYear(angkatan, schedule.semester)}',
            startTime: eventStart,
            endTime: eventEnd,
            location: schedule.room,
            metadata: {
              'course_code': schedule.courseCode,
              'lecturer': schedule.lecturer,
              'semester': schedule.semester,
              'credits': schedule.credits,
              'class_type': schedule.classType.name,
              'academic_year': SemesterCalculator.getAcademicYear(angkatan, schedule.semester),
              'semester_start': semesterPeriod.startDate.toIso8601String(),
              'semester_end': semesterPeriod.endDate.toIso8601String(),
            },
          ));
        }
        current = current.add(const Duration(days: 1));
      }
    }

    return events;
  }

  /// Get competition events
  Future<List<CalendarEvent>> _getCompetitionEvents() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('competitions')
        .select()
        .eq('user_id', user.id)
        .order('event_date', ascending: true);

    final competitions = (response as List)
        .map((json) => Competition.fromJson(json))
        .toList();

    return competitions
        .where((comp) => comp.eventDate != null)
        .map((comp) => CalendarEvent(
              id: comp.id,
              source: EventSource.competition,
              title: comp.compName,
              description: '${comp.category ?? ''}\nPrestasi: ${comp.achievement ?? '-'}',
              startTime: comp.eventDate!,
              isAllDay: true,
              metadata: {
                'category': comp.category,
                'achievement': comp.achievement,
              },
            ))
        .toList();
  }

  /// Get volunteer activity events
  Future<List<CalendarEvent>> _getVolunteerEvents() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('volunteer_activities')
        .select()
        .eq('user_id', user.id)
        .order('start_date', ascending: true);

    final volunteers = (response as List)
        .map((json) => VolunteerActivity.fromJson(json))
        .toList();

    final events = <CalendarEvent>[];

    for (final volunteer in volunteers) {
      if (volunteer.startDate != null) {
        // Add start date event
        events.add(CalendarEvent(
          id: '${volunteer.id}_start',
          source: EventSource.volunteer,
          title: '${volunteer.activityName} (Mulai)',
          description: 'Peran: ${volunteer.role}\n'
              '${volunteer.endDate != null ? 'Hingga: ${volunteer.endDate}' : 'Masih berlangsung'}',
          startTime: volunteer.startDate!,
          isAllDay: true,
          metadata: {
            'activity_name': volunteer.activityName,
            'role': volunteer.role,
            'is_start': true,
          },
        ));

        // Add end date event if exists
        if (volunteer.endDate != null) {
          events.add(CalendarEvent(
            id: '${volunteer.id}_end',
            source: EventSource.volunteer,
            title: '${volunteer.activityName} (Selesai)',
            description: 'Peran: ${volunteer.role}',
            startTime: volunteer.endDate!,
            isAllDay: true,
            metadata: {
              'activity_name': volunteer.activityName,
              'role': volunteer.role,
              'is_end': true,
            },
          ));
        }
      }
    }

    return events;
  }

  /// Get organization events
  Future<List<CalendarEvent>> _getOrganizationEvents() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('organizations')
        .select()
        .eq('user_id', user.id)
        .order('start_date', ascending: true);

    final organizations = (response as List)
        .map((json) => Organization.fromJson(json))
        .toList();

    final events = <CalendarEvent>[];

    for (final org in organizations) {
      if (org.startDate != null) {
        // Add start date event
        events.add(CalendarEvent(
          id: '${org.id}_start',
          source: EventSource.organization,
          title: '${org.orgName} (Bergabung)',
          description: 'Posisi: ${org.position}\n'
              'Skala: ${org.scale?.displayName ?? '-'}\n'
              '${org.endDate != null ? 'Hingga: ${org.endDate}' : 'Masih aktif'}',
          startTime: org.startDate!,
          isAllDay: true,
          metadata: {
            'org_name': org.orgName,
            'position': org.position,
            'scale': org.scale?.value,
            'is_start': true,
          },
        ));

        // Add end date event if exists
        if (org.endDate != null) {
          events.add(CalendarEvent(
            id: '${org.id}_end',
            source: EventSource.organization,
            title: '${org.orgName} (Selesai)',
            description: 'Posisi: ${org.position}',
            startTime: org.endDate!,
            isAllDay: true,
            metadata: {
              'org_name': org.orgName,
              'position': org.position,
              'is_end': true,
            },
          ));
        }
      }
    }

    return events;
  }

  /// Get project events
  Future<List<CalendarEvent>> _getProjectEvents() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('projects')
        .select()
        .eq('user_id', user.id)
        .order('start_date', ascending: true);

    final projects = (response as List)
        .map((json) => Project.fromJson(json))
        .toList();

    final events = <CalendarEvent>[];

    for (final project in projects) {
      // Add start date event
      events.add(CalendarEvent(
        id: '${project.id}_start',
        source: EventSource.project,
        title: '${project.title} (Mulai)',
        description: 'Peran: ${project.role}\n'
            '${project.overview ?? ''}\n'
            '${project.endDate != null ? 'Hingga: ${project.endDate}' : 'Masih berlangsung'}',
        startTime: project.startDate,
        isAllDay: true,
        metadata: {
          'title': project.title,
          'role': project.role,
          'technologies': project.technologies,
          'is_start': true,
        },
      ));

      // Add end date event if exists
      if (project.endDate != null) {
        events.add(CalendarEvent(
          id: '${project.id}_end',
          source: EventSource.project,
          title: '${project.title} (Selesai)',
          description: 'Peran: ${project.role}',
          startTime: project.endDate!,
          isAllDay: true,
          metadata: {
            'title': project.title,
            'role': project.role,
            'is_end': true,
          },
        ));
      }
    }

    return events;
  }

  /// Helper: Check if date matches day of week
  bool _matchesDayOfWeek(DateTime date, DayOfWeek dayOfWeek) {
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    switch (dayOfWeek) {
      case DayOfWeek.monday:
        return weekday == 1;
      case DayOfWeek.tuesday:
        return weekday == 2;
      case DayOfWeek.wednesday:
        return weekday == 3;
      case DayOfWeek.thursday:
        return weekday == 4;
      case DayOfWeek.friday:
        return weekday == 5;
      case DayOfWeek.saturday:
        return weekday == 6;
      case DayOfWeek.sunday:
        return weekday == 7;
    }
  }

  /// Helper: Get the later of two dates
  DateTime _maxDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  /// Helper: Get the earlier of two dates
  DateTime _minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  /// Get events count by source
  Future<Map<EventSource, int>> getEventsCountBySource() async {
    final events = await getAllEvents();
    final Map<EventSource, int> counts = {};

    for (final event in events) {
      counts[event.source] = (counts[event.source] ?? 0) + 1;
    }

    return counts;
  }

  /// Get upcoming events (next 7 days)
  Future<List<CalendarEvent>> getUpcomingEvents({int days = 7}) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    final events = await getAllEvents(startDate: now, endDate: endDate);

    return events.where((event) => !event.isPast).take(10).toList();
  }
}
