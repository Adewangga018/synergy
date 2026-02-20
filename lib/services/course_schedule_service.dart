import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/course_schedule.dart';

class CourseScheduleService {
  final _supabase = Supabase.instance.client;
  final String tableName = 'course_schedules';

  /// Helper: Format TimeOfDay to string (HH:MM)
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// CREATE - Tambah jadwal kuliah baru
  Future<CourseSchedule> createSchedule({
    required String courseName,
    required String courseCode,
    required String lecturer,
    required DayOfWeek dayOfWeek,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String room,
    required int semester,
    required int credits,
    required ClassType classType,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    final data = {
      'user_id': userId,
      'course_name': courseName,
      'course_code': courseCode,
      'lecturer': lecturer,
      'day_of_week': dayOfWeek.name,
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'room': room,
      'semester': semester,
      'credits': credits,
      'class_type': classType.name,
      'notes': notes,
    };

    final response = await _supabase
        .from(tableName)
        .insert(data)
        .select()
        .single();

    return CourseSchedule.fromJson(response);
  }

  /// READ - Ambil semua jadwal kuliah user
  Future<List<CourseSchedule>> getSchedules() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => CourseSchedule.fromJson(json)).toList();
  }

  /// READ - Ambil satu jadwal berdasarkan ID
  Future<CourseSchedule> getScheduleById(String scheduleId) async {
    final response = await _supabase
        .from(tableName)
        .select()
        .eq('id', scheduleId)
        .single();

    return CourseSchedule.fromJson(response);
  }

  /// UPDATE - Update jadwal kuliah
  Future<CourseSchedule> updateSchedule({
    required String scheduleId,
    required String courseName,
    required String courseCode,
    required String lecturer,
    required DayOfWeek dayOfWeek,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String room,
    required int semester,
    required int credits,
    required ClassType classType,
    String? notes,
  }) async {
    final data = {
      'course_name': courseName,
      'course_code': courseCode,
      'lecturer': lecturer,
      'day_of_week': dayOfWeek.name,
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'room': room,
      'semester': semester,
      'credits': credits,
      'class_type': classType.name,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from(tableName)
        .update(data)
        .eq('id', scheduleId)
        .select()
        .single();

    return CourseSchedule.fromJson(response);
  }

  /// DELETE - Hapus jadwal kuliah
  Future<void> deleteSchedule(String scheduleId) async {
    await _supabase.from(tableName).delete().eq('id', scheduleId);
  }

  /// UTILITY - Get schedules by semester
  Future<List<CourseSchedule>> getSchedulesBySemester(int semester) async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .eq('semester', semester)
        .order('created_at', ascending: false);

    return (response as List).map((json) => CourseSchedule.fromJson(json)).toList();
  }

  /// UTILITY - Get schedules by day of week
  Future<List<CourseSchedule>> getSchedulesByDay(DayOfWeek day) async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .eq('day_of_week', day.name)
        .order('start_time', ascending: true);

    return (response as List).map((json) => CourseSchedule.fromJson(json)).toList();
  }

  /// UTILITY - Search schedules
  Future<List<CourseSchedule>> searchSchedules(String keyword) async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .or('course_name.ilike.%$keyword%,course_code.ilike.%$keyword%,lecturer.ilike.%$keyword%,room.ilike.%$keyword%')
        .order('created_at', ascending: false);

    return (response as List).map((json) => CourseSchedule.fromJson(json)).toList();
  }

  /// UTILITY - Get total SKS by semester
  Future<int> getTotalCreditsBySemester(int semester) async {
    final schedules = await getSchedulesBySemester(semester);
    return schedules.fold<int>(0, (sum, schedule) => sum + schedule.credits);
  }

  /// UTILITY - Group schedules by day (for weekly view)
  Future<Map<DayOfWeek, List<CourseSchedule>>> getSchedulesGroupedByDay() async {
    final schedules = await getSchedules();
    final grouped = <DayOfWeek, List<CourseSchedule>>{};

    for (final day in DayOfWeek.values) {
      grouped[day] = schedules
          .where((s) => s.dayOfWeek == day)
          .toList()
        ..sort((a, b) {
          final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
          final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
          return aMinutes.compareTo(bMinutes);
        });
    }

    return grouped;
  }
}
