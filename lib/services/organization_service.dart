import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/organization.dart';

/// Service untuk mengelola Organisasi
/// Mendukung CRUD dan filtering berdasarkan skala
class OrganizationService {
  final _supabase = Supabase.instance.client;
  static const String tableName = 'organizations';

  /// CREATE - Tambah organisasi baru
  Future<Organization> createOrganization({
    required String orgName,
    required OrganizationScale scale,
    required String position,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now();

      final response = await _supabase.from(tableName).insert({
        'user_id': userId,
        'start_date': startDate?.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'org_name': orgName,
        'scale': scale.value,
        'position': position,
        'created_at': now.toIso8601String(),
      }).select().single();

      return Organization.fromJson(response);
    } catch (e) {
      throw Exception('Gagal membuat organisasi: $e');
    }
  }

  /// READ - Ambil semua organisasi dengan filter
  Future<List<Organization>> getOrganizations({
    OrganizationScale? filterByScale,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      dynamic query = _supabase
          .from(tableName)
          .select()
          .eq('user_id', userId);

      // Filter by scale
      if (filterByScale != null) {
        query = query.eq('scale', filterByScale.value);
      }

      // Sorting: yang terbaru dulu
      query = query.order('created_at', ascending: false);

      final List<dynamic> response = await query;

      return response.map((json) => Organization.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil organisasi: $e');
    }
  }

  /// READ - Ambil satu organisasi berdasarkan ID
  Future<Organization?> getOrganizationById(String organizationId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(tableName)
          .select()
          .eq('id', organizationId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return Organization.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil organisasi: $e');
    }
  }

  /// UPDATE - Edit organisasi
  Future<Organization> updateOrganization({
    required String organizationId,
    required String orgName,
    required OrganizationScale scale,
    required String position,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase.from(tableName).update({
        'start_date': startDate?.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'org_name': orgName,
        'scale': scale.value,
        'position': position,
      }).eq('id', organizationId).eq('user_id', userId).select().single();

      return Organization.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update organisasi: $e');
    }
  }

  /// DELETE - Hapus organisasi
  Future<void> deleteOrganization(String organizationId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from(tableName)
          .delete()
          .eq('id', organizationId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Gagal hapus organisasi: $e');
    }
  }

  /// UTILITY - Hitung total organisasi
  Future<int> getOrganizationsCount() async {
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

  /// UTILITY - Hitung organisasi per skala
  Future<Map<OrganizationScale, int>> getCountByScale() async {
    try {
      final orgs = await getOrganizations();
      final Map<OrganizationScale, int> counts = {};

      for (var scale in OrganizationScale.values) {
        counts[scale] = orgs.where((org) => org.scale == scale).length;
      }

      return counts;
    } catch (e) {
      return {};
    }
  }
}
