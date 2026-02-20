import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Stream untuk mendengarkan perubahan auth state
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Register user baru
  Future<AuthResponse> register({
    required String namaLengkap,
    required String namaPanggilan,
    required String nrp,
    required String jurusan,
    required String email,
    required String password,
    required String angkatan,
  }) async {
    try {
      // 1. Registrasi user di Supabase Auth
      // Disable email confirmation untuk menghindari rate limiting
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
        data: {
          'nrp': nrp,
          'nama_lengkap': namaLengkap,
        },
      );

      // 2. Jika registrasi berhasil, simpan profile ke tabel profiles
      if (response.user != null) {
        try {
          await _supabase.from('profiles').insert({
            'id': response.user!.id,
            'nama_lengkap': namaLengkap,
            'nama_panggilan': namaPanggilan,
            'nrp': nrp,
            'jurusan': jurusan,
            'email': email,
            'angkatan': angkatan,
          });
        } catch (profileError) {
          // Jika gagal insert profile, berikan error yang jelas
          throw Exception('Gagal menyimpan profil: ${profileError.toString()}. Silakan hubungi administrator.');
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Login dengan NRP dan password
  Future<AuthResponse> loginWithNRP({
    required String nrp,
    required String password,
  }) async {
    try {
      // 1. Cari email berdasarkan NRP di tabel profiles
      // Gunakan .select() dengan .limit(1) untuk menghindari RLS issue
      final profileData = await _supabase
          .from('profiles')
          .select('email')
          .eq('nrp', nrp)
          .limit(1);

      // Jika NRP tidak ditemukan
      if (profileData.isEmpty) {
        throw Exception('NRP tidak ditemukan. Pastikan Anda sudah terdaftar.');
      }

      final email = profileData[0]['email'] as String;

      // 2. Login dengan email dan password
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Login dengan email dan password (alternatif)
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? namaLengkap,
    String? namaPanggilan,
    String? jurusan,
    String? angkatan,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (namaLengkap != null) updates['nama_lengkap'] = namaLengkap;
      if (namaPanggilan != null) updates['nama_panggilan'] = namaPanggilan;
      if (jurusan != null) updates['jurusan'] = jurusan;
      if (angkatan != null) updates['angkatan'] = angkatan;

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  // Cek apakah NRP sudah terdaftar
  Future<bool> isNRPExists(String nrp) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('nrp')
          .eq('nrp', nrp);

      return data.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }

  // Cek apakah email sudah terdaftar
  Future<bool> isEmailExists(String email) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('email')
          .eq('email', email);

      return data.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }
}
