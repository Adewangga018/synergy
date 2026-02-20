import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/volunteer_activity.dart';

/// Service untuk mengelola Kegiatan Volunteer
/// Mendukung CRUD dan filtering
class VolunteerService {
  final _supabase = Supabase.instance.client;
  static const String tableName = 'volunteer_activities';

  /// CREATE - Tambah kegiatan volunteer baru
  Future<VolunteerActivity> createActivity({
    required String activityName,
    required String role,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now();

      final response = await _supabase.from(tableName).insert({
        'user_id': userId,
        'activity_name': activityName,
        'role': role,
        'start_date': startDate?.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'created_at': now.toIso8601String(),
      }).select().single();

      return VolunteerActivity.fromJson(response);
    } catch (e) {
      throw Exception('Gagal membuat kegiatan: $e');
    }
  }

  /// READ - Ambil semua kegiatan volunteer
  Future<List<VolunteerActivity>> getActivities({
    bool? activeOnly, // Filter hanya yang masih aktif
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      dynamic query = _supabase
          .from(tableName)
          .select()
          .eq('user_id', userId);

      // Filter hanya yang aktif (end_date null atau > today)
      if (activeOnly == true) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        query = query.or('end_date.is.null,end_date.gte.$today');
      }

      // Sorting: yang terbaru dulu
      query = query.order('created_at', ascending: false);

      final List<dynamic> response = await query;

      return response.map((json) => VolunteerActivity.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil kegiatan: $e');
    }
  }

  /// READ - Ambil satu kegiatan berdasarkan ID
  Future<VolunteerActivity?> getActivityById(String activityId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(tableName)
          .select()
          .eq('id', activityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return VolunteerActivity.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil kegiatan: $e');
    }
  }

  /// UPDATE - Edit kegiatan volunteer
  Future<VolunteerActivity> updateActivity({
    required String activityId,
    required String activityName,
    required String role,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase.from(tableName).update({
        'activity_name': activityName,
        'role': role,
        'start_date': startDate?.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
      }).eq('id', activityId).eq('user_id', userId).select().single();

      return VolunteerActivity.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update kegiatan: $e');
    }
  }

  /// DELETE - Hapus kegiatan volunteer
  Future<void> deleteActivity(String activityId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from(tableName)
          .delete()
          .eq('id', activityId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Gagal hapus kegiatan: $e');
    }
  }

  /// UTILITY - Hitung total kegiatan
  Future<int> getActivitiesCount() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(tableName)
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
