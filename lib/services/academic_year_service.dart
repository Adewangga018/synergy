import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/academic_year.dart';

/// Service untuk mengelola Tahun Akademik/Semester
/// Mendukung CRUD dan filtering
class AcademicYearService {
  final _supabase = Supabase.instance.client;
  static const String tableName = 'academic_years';

  /// CREATE - Tambah tahun akademik baru
  Future<AcademicYear> createAcademicYear({
    required String semesterName,
    required DateTime startDate,
    int totalActiveWeeks = 16,
    bool isActive = true,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now();

      final response = await _supabase.from(tableName).insert({
        'user_id': userId,
        'semester_name': semesterName,
        'start_date': startDate.toIso8601String().split('T')[0],
        'total_active_weeks': totalActiveWeeks,
        'is_active': isActive,
        'created_at': now.toIso8601String(),
      }).select().single();

      return AcademicYear.fromJson(response);
    } catch (e) {
      throw Exception('Gagal membuat tahun akademik: $e');
    }
  }

  /// READ - Ambil semua tahun akademik
  Future<List<AcademicYear>> getAcademicYears({
    bool? activeOnly, // Filter hanya yang aktif
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      dynamic query = _supabase
          .from(tableName)
          .select()
          .eq('user_id', userId);

      // Filter hanya yang aktif
      if (activeOnly == true) {
        query = query.eq('is_active', true);
      }

      // Sorting: yang terbaru dulu
      query = query.order('start_date', ascending: false);

      final List<dynamic> response = await query;

      return response.map((json) => AcademicYear.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil tahun akademik: $e');
    }
  }

  /// READ - Ambil tahun akademik yang aktif saat ini
  Future<AcademicYear?> getCurrentAcademicYear() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from(tableName)
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .lte('start_date', today)
          .order('start_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return AcademicYear.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// READ - Ambil satu tahun akademik berdasarkan ID
  Future<AcademicYear?> getAcademicYearById(String yearId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(tableName)
          .select()
          .eq('id', yearId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return AcademicYear.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil tahun akademik: $e');
    }
  }

  /// UPDATE - Edit tahun akademik
  Future<AcademicYear> updateAcademicYear({
    required String yearId,
    required String semesterName,
    required DateTime startDate,
    required int totalActiveWeeks,
    required bool isActive,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase.from(tableName).update({
        'semester_name': semesterName,
        'start_date': startDate.toIso8601String().split('T')[0],
        'total_active_weeks': totalActiveWeeks,
        'is_active': isActive,
      }).eq('id', yearId).eq('user_id', userId).select().single();

      return AcademicYear.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update tahun akademik: $e');
    }
  }

  /// UPDATE - Toggle status aktif
  Future<void> toggleActiveStatus(String yearId, bool isActive) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase.from(tableName).update({
        'is_active': isActive,
      }).eq('id', yearId).eq('user_id', userId);
    } catch (e) {
      throw Exception('Gagal toggle status: $e');
    }
  }

  /// DELETE - Hapus tahun akademik
  Future<void> deleteAcademicYear(String yearId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from(tableName)
          .delete()
          .eq('id', yearId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Gagal hapus tahun akademik: $e');
    }
  }

  /// UTILITY - Hitung total tahun akademik
  Future<int> getAcademicYearsCount() async {
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
