import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/competition.dart';

/// Service untuk mengelola Kompetisi Mahasiswa
/// Mendukung CRUD dan filtering
class CompetitionService {
  final _supabase = Supabase.instance.client;
  static const String tableName = 'competitions';

  /// CREATE - Tambah kompetisi baru
  Future<Competition> createCompetition({
    required String compName,
    String? category,
    String? achievement,
    DateTime? eventDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now();

      final response = await _supabase.from(tableName).insert({
        'user_id': userId,
        'comp_name': compName,
        'category': category,
        'achievement': achievement,
        'event_date': eventDate?.toIso8601String().split('T')[0],
        'created_at': now.toIso8601String(),
      }).select().single();

      return Competition.fromJson(response);
    } catch (e) {
      throw Exception('Gagal membuat kompetisi: $e');
    }
  }

  /// READ - Ambil semua kompetisi
  Future<List<Competition>> getCompetitions({
    String? categoryFilter,
    bool? achievementOnly, // Hanya yang ada prestasi
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      dynamic query = _supabase
          .from(tableName)
          .select()
          .eq('user_id', userId);

      // Filter by category
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        query = query.eq('category', categoryFilter);
      }

      // Filter hanya yang ada prestasi
      if (achievementOnly == true) {
        query = query.not('achievement', 'is', null);
      }

      // Sorting: event_date terbaru dulu, null terakhir
      query = query.order('event_date', ascending: false, nullsFirst: false);

      final List<dynamic> response = await query;

      return response.map((json) => Competition.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil kompetisi: $e');
    }
  }

  /// READ - Ambil satu kompetisi berdasarkan ID
  Future<Competition?> getCompetitionById(String competitionId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(tableName)
          .select()
          .eq('id', competitionId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return Competition.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil kompetisi: $e');
    }
  }

  /// UPDATE - Edit kompetisi
  Future<Competition> updateCompetition({
    required String competitionId,
    required String compName,
    String? category,
    String? achievement,
    DateTime? eventDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase.from(tableName).update({
        'comp_name': compName,
        'category': category,
        'achievement': achievement,
        'event_date': eventDate?.toIso8601String().split('T')[0],
      }).eq('id', competitionId).eq('user_id', userId).select().single();

      return Competition.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update kompetisi: $e');
    }
  }

  /// DELETE - Hapus kompetisi
  Future<void> deleteCompetition(String competitionId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from(tableName)
          .delete()
          .eq('id', competitionId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Gagal hapus kompetisi: $e');
    }
  }

  /// UTILITY - Hitung total kompetisi
  Future<int> getCompetitionsCount() async {
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

  /// UTILITY - Hitung total prestasi (yang ada achievement)
  Future<int> getAchievementsCount() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(tableName)
          .select('id')
          .eq('user_id', userId)
          .not('achievement', 'is', null);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// UTILITY - Get unique categories
  Future<List<String>> getCategories() async {
    try {
      final comps = await getCompetitions();
      final categories = comps
          .where((c) => c.category != null && c.category!.isNotEmpty)
          .map((c) => c.category!)
          .toSet()
          .toList();
      categories.sort();
      return categories;
    } catch (e) {
      return [];
    }
  }
}
