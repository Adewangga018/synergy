import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/personal_note.dart';

/// Enum untuk sorting order catatan
enum NoteSortOrder {
  newestFirst, // Terbaru dulu (default)
  oldestFirst, // Terlama dulu
}

/// Service untuk mengelola Catatan Pribadi (Personal Notes)
/// Mendukung CRUD, pencarian, dan sorting
class PersonalNotesService {
  final _supabase = Supabase.instance.client;
  static const String tableName = 'personal_notes';

  /// CREATE - Tambah catatan baru
  Future<PersonalNote> createNote({
    required String title,
    String? content,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now();

      final response = await _supabase.from(tableName).insert({
        'user_id': userId,
        'title': title,
        'content': content,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).select().single();

      return PersonalNote.fromJson(response);
    } catch (e) {
      throw Exception('Gagal membuat catatan: $e');
    }
  }

  /// READ - Ambil semua catatan dengan filter & sorting
  Future<List<PersonalNote>> getNotes({
    String? searchQuery,
    NoteSortOrder sortOrder = NoteSortOrder.newestFirst,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Build query
      dynamic query = _supabase
          .from(tableName)
          .select()
          .eq('user_id', userId);

      // Filter pencarian (jika ada)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search di title dan content
        query = query.or('title.ilike.%$searchQuery%,content.ilike.%$searchQuery%');
      }

      // Sorting berdasarkan updated_at
      final ascending = sortOrder == NoteSortOrder.oldestFirst;
      query = query.order('updated_at', ascending: ascending);

      final List<dynamic> response = await query;

      return response.map((json) => PersonalNote.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil catatan: $e');
    }
  }

  /// READ - Ambil satu catatan berdasarkan ID
  Future<PersonalNote?> getNoteById(String noteId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(tableName)
          .select()
          .eq('id', noteId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return PersonalNote.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil catatan: $e');
    }
  }

  /// UPDATE - Edit catatan
  Future<PersonalNote> updateNote({
    required String noteId,
    required String title,
    String? content,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now();

      final response = await _supabase.from(tableName).update({
        'title': title,
        'content': content,
        'updated_at': now.toIso8601String(),
      }).eq('id', noteId).eq('user_id', userId).select().single();

      return PersonalNote.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update catatan: $e');
    }
  }

  /// DELETE - Hapus catatan
  Future<void> deleteNote(String noteId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from(tableName)
          .delete()
          .eq('id', noteId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Gagal hapus catatan: $e');
    }
  }

  /// UTILITY - Hitung total catatan
  Future<int> getNotesCount() async {
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
