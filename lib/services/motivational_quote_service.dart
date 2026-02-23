import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/motivational_quote.dart';

class MotivationalQuoteService {
  final _supabase = Supabase.instance.client;

  /// Mendapatkan quote motivasi secara random
  /// Menggunakan RPC function yang sudah dibuat di database
  Future<MotivationalQuote?> getRandomQuote() async {
    try {
      final response = await _supabase
          .rpc('get_random_motivational_quote')
          .single();

      if (response == null) {
        return null;
      }

      return MotivationalQuote.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error getting random motivational quote: $e');
      return null;
    }
  }

  /// Mendapatkan quote motivasi berdasarkan tema
  /// Contoh tema: 'general', 'kompetisi', 'organisasi', 'volunteer'
  Future<MotivationalQuote?> getQuoteByTheme(String? theme) async {
    try {
      final response = await _supabase
          .rpc('get_motivational_quote_by_theme', params: {
            'p_theme': theme,
          })
          .single();

      if (response == null) {
        return null;
      }

      return MotivationalQuote.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error getting motivational quote by theme: $e');
      return null;
    }
  }

  /// Mendapatkan semua quotes aktif (untuk keperluan admin atau debug)
  Future<List<MotivationalQuote>> getAllActiveQuotes() async {
    try {
      final response = await _supabase
          .from('motivational_quotes')
          .select()
          .eq('is_active', true)
          .order('display_priority', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MotivationalQuote.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all active quotes: $e');
      return [];
    }
  }

  /// Mendapatkan statistik penggunaan quotes (untuk keperluan monitoring)
  Future<Map<String, dynamic>?> getQuoteStatistics() async {
    try {
      final response = await _supabase
          .from('motivational_quotes')
          .select('theme, usage_count')
          .eq('is_active', true);

      final List<Map<String, dynamic>> data = 
          (response as List).cast<Map<String, dynamic>>();

      if (data.isEmpty) {
        return null;
      }

      // Aggregate statistics
      final Map<String, int> themeCount = {};
      final Map<String, int> themeUsage = {};
      int totalQuotes = 0;
      int totalUsage = 0;

      for (var row in data) {
        final theme = row['theme'] as String? ?? 'unknown';
        final usage = row['usage_count'] as int? ?? 0;

        themeCount[theme] = (themeCount[theme] ?? 0) + 1;
        themeUsage[theme] = (themeUsage[theme] ?? 0) + usage;
        totalQuotes++;
        totalUsage += usage;
      }

      return {
        'total_quotes': totalQuotes,
        'total_usage': totalUsage,
        'average_usage': totalQuotes > 0 ? totalUsage / totalQuotes : 0,
        'theme_count': themeCount,
        'theme_usage': themeUsage,
      };
    } catch (e) {
      print('Error getting quote statistics: $e');
      return null;
    }
  }

  /// Generate new motivational quotes menggunakan OpenAI via Edge Function
  /// 
  /// Parameters:
  /// - [count]: Jumlah quotes yang akan di-generate (default: 10)
  /// - [theme]: Tema quotes (optional). Contoh: 'UTS', 'UAS', 'general', dll
  /// - [context]: Konteks spesifik (optional). Jika null, akan auto-detect berdasarkan tanggal
  /// - [replaceExisting]: Jika true, akan nonaktifkan quotes lama dengan theme yang sama
  /// 
  /// Returns: Map dengan informasi hasil generate
  /// Throws: Exception jika gagal
  Future<Map<String, dynamic>> generateQuotes({
    int count = 10,
    String? theme,
    String? context,
    bool replaceExisting = false,
  }) async {
    try {
      print('🎯 Generating quotes (no auth required)'); // Debug
      
      // Don't send Authorization header - edge function doesn't need it
      final response = await _supabase.functions.invoke(
        'generate-motivational-quotes',
        body: {
          'count': count,
          if (theme != null) 'theme': theme,
          if (context != null) 'context': context,
          'replace_existing': replaceExisting,
        },
        headers: {}, // Empty headers to prevent auto Authorization header
      );

      print('📊 Quote generation status: ${response.status}'); // Debug

      if (response.status == 401) {
        print('⚠️ Got 401 but edge function should not require auth');
        print('⚠️ Retrying without invoking through Supabase client...');
        throw Exception('Authentication issue - please restart app');
      }

      if (response.status != 200) {
        throw Exception('Failed to generate quotes: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Unknown error generating quotes');
      }

      return data;
    } catch (e) {
      print('Error generating quotes: $e');
      rethrow;
    }
  }

  /// Deteksi apakah user adalah mahasiswa tingkat akhir (semester 7-8)
  /// yang sedang mengerjakan Tugas Akhir (TA)
  /// 
  /// Kriteria: Pernah mengambil mata kuliah di semester 7 atau 8
  Future<bool> _isFinalYearStudent(String userId) async {
    try {
      final response = await _supabase
          .from('course_schedules')
          .select('semester')
          .eq('user_id', userId)
          .or('semester.eq.7,semester.eq.8')
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking final year status: $e');
      return false;
    }
  }

  /// Get quote of the day - Smart daily quote system
  /// Strategi: Generate 1x per hari saja (hemat API & UX cepat)
  /// 
  /// Flow:
  /// 1. Deteksi apakah user mahasiswa tingkat akhir (semester 7-8)
  /// 2. Cek apakah sudah ada quote yang di-generate HARI INI
  /// 3. Jika YA -> Return quote hari ini (dari database, super cepat!)
  /// 4. Jika TIDAK -> Generate 1 quote baru via Gemini AI dengan tema TA jika perlu
  /// 
  /// Returns: Quote text (String)
  Future<String> getOrGenerateDailyQuote({String? userId}) async {
    try {
      // Step 1: Deteksi apakah user mahasiswa tingkat akhir (TA)
      bool isFinalYear = false;
      String? themeContext;
      
      if (userId != null) {
        isFinalYear = await _isFinalYearStudent(userId);
        if (isFinalYear) {
          themeContext = 'tugas-akhir';
          print('Detected final year student - using TA motivation theme');
        }
      }

      // Step 2: Cek apakah sudah ada quote hari ini
      final todayQuote = await _getTodayQuote();
      
      if (todayQuote != null) {
        // Ada quote hari ini, langsung return (cepat!)
        print('Using today\'s quote from database');
        return todayQuote.quoteText;
      }

      // Step 3: Belum ada quote hari ini, generate baru
      print('No quote for today, generating new one...');
      
      try {
        final result = await generateQuotes(
          count: 1,
          theme: themeContext, // Auto-detect theme atau gunakan 'tugas-akhir' untuk mahasiswa tingkat akhir
          context: null, // Auto-detect context akademik
          replaceExisting: false,
        );

        final quotesPreview = result['quotes_preview'] as List?;
        
        if (quotesPreview != null && quotesPreview.isNotEmpty) {
          return quotesPreview[0] as String;
        } else {
          return getFallbackQuote();
        }
      } catch (generateError) {
        print('⚠️ Failed to generate quote (using fallback): $generateError');
        // Fallback jika generate gagal (termasuk 401 error)
        return getFallbackQuote();
      }
    } catch (e) {
      print('Error getting/generating daily quote: $e');
      // Fallback jika error
      return getFallbackQuote();
    }
  }

  /// Get quote yang di-generate hari ini (internal helper)
  Future<MotivationalQuote?> _getTodayQuote() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final response = await _supabase
          .from('motivational_quotes')
          .select()
          .eq('is_active', true)
          .gte('created_at', todayStart.toIso8601String())
          .lt('created_at', todayEnd.toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);

      if (response == null || (response as List).isEmpty) {
        return null;
      }

      return MotivationalQuote.fromJson((response as List).first as Map<String, dynamic>);
    } catch (e) {
      print('Error getting today\'s quote: $e');
      return null;
    }
  }

  /// Fallback quotes jika database tidak tersedia
  /// Ini sebagai backup agar app tetap berjalan
  static const List<String> fallbackQuotes = [
    'Setiap langkah kecil adalah kemajuan menuju kesuksesan besar.',
    'Prestasi hari ini adalah investasi untuk masa depan cemerlang.',
    'Jangan takut gagal, karena kegagalan adalah guru terbaik.',
    'Kompetensi + Karakter = Mahasiswa Unggul!',
    'Konsisten lebih penting dari intensitas sesaat.',
    'Fokus pada progress, bukan perfection.',
  ];

  /// Mendapatkan fallback quote jika terjadi error
  String getFallbackQuote() {
    final random = DateTime.now().millisecondsSinceEpoch % fallbackQuotes.length;
    return fallbackQuotes[random];
  }
}
