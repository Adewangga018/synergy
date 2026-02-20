import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/project.dart';

class ProjectService {
  final _supabase = Supabase.instance.client;
  final String tableName = 'projects';

  /// CREATE - Tambah project baru
  Future<Project> createProject({
    required String title,
    String? overview,
    required DateTime startDate,
    DateTime? endDate,
    required String role,
    List<String>? technologies,
    String? projectUrl,
    String? repositoryUrl,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    final data = {
      'user_id': userId,
      'title': title,
      'overview': overview,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'role': role,
      'technologies': technologies,
      'project_url': projectUrl,
      'repository_url': repositoryUrl,
    };

    final response = await _supabase
        .from(tableName)
        .insert(data)
        .select()
        .single();

    return Project.fromJson(response);
  }

  /// READ - Ambil semua projects user yang login
  Future<List<Project>> getProjects() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .order('start_date', ascending: false);

    return (response as List).map((json) => Project.fromJson(json)).toList();
  }

  /// READ - Ambil satu project berdasarkan ID
  Future<Project> getProjectById(String projectId) async {
    final response = await _supabase
        .from(tableName)
        .select()
        .eq('id', projectId)
        .single();

    return Project.fromJson(response);
  }

  /// UPDATE - Update project
  Future<Project> updateProject({
    required String projectId,
    required String title,
    String? overview,
    required DateTime startDate,
    DateTime? endDate,
    required String role,
    List<String>? technologies,
    String? projectUrl,
    String? repositoryUrl,
  }) async {
    final data = {
      'title': title,
      'overview': overview,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'role': role,
      'technologies': technologies,
      'project_url': projectUrl,
      'repository_url': repositoryUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from(tableName)
        .update(data)
        .eq('id', projectId)
        .select()
        .single();

    return Project.fromJson(response);
  }

  /// DELETE - Hapus project
  Future<void> deleteProject(String projectId) async {
    await _supabase.from(tableName).delete().eq('id', projectId);
  }

  /// UTILITY - Search projects berdasarkan keyword
  Future<List<Project>> searchProjects(String keyword) async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .or('title.ilike.%$keyword%,overview.ilike.%$keyword%,role.ilike.%$keyword%')
        .order('start_date', ascending: false);

    return (response as List).map((json) => Project.fromJson(json)).toList();
  }

  /// UTILITY - Get ongoing projects (yang masih berjalan)
  Future<List<Project>> getOngoingProjects() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .isFilter('end_date', null)
        .order('start_date', ascending: false);

    return (response as List).map((json) => Project.fromJson(json)).toList();
  }

  /// UTILITY - Get completed projects
  Future<List<Project>> getCompletedProjects() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .not('end_date', 'is', null)
        .order('end_date', ascending: false);

    return (response as List).map((json) => Project.fromJson(json)).toList();
  }

  /// UTILITY - Get projects by technology
  Future<List<Project>> getProjectsByTechnology(String technology) async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .contains('technologies', [technology])
        .order('start_date', ascending: false);

    return (response as List).map((json) => Project.fromJson(json)).toList();
  }
}
