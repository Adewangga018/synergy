import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/chat_message.dart';

/// Service untuk mengelola AI Chatbot dengan Gemini
/// Menyediakan operasi chat, history, dan context-aware responses
class GeminiChatService {
  final _supabase = Supabase.instance.client;

  /// Get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Send message ke AI chatbot dan dapatkan response
  /// 
  /// Parameters:
  /// - [message]: Pesan dari user
  /// - [includeContext]: Include user data dari database (default: true)
  /// - [conversationHistory]: Riwayat percakapan untuk context (optional)
  /// 
  /// Returns: AI response sebagai String
  Future<String> sendMessage({
    required String message,
    bool includeContext = true,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User tidak login');
      }

      // Prepare conversation history untuk dikirim ke Edge Function
      final List<Map<String, dynamic>> history = [];
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        // Ambil max 10 pesan terakhir untuk context (avoid token limit)
        final recentMessages = conversationHistory.length > 10
            ? conversationHistory.sublist(conversationHistory.length - 10)
            : conversationHistory;

        for (final msg in recentMessages) {
          history.add(ConversationMessage.fromChatMessage(msg).toJson());
        }
      }

      // Call Supabase Edge Function
      print('🚀 Calling edge function: gemini-chat'); // Debug
      print('📦 Body: message=$message, include_context=$includeContext'); // Debug
      
      // Only send auth header if include_context is true
      Map<String, String>? headers;
      
      if (includeContext) {
        final s = await _supabase.auth.refreshSession(); // Ensure token is fresh
        if (s.session == null) {
          throw Exception('No active session - please log in again');
        }
        
        print('🔑 Using access token: ${s.session!.accessToken.substring(0, 20)}...'); // Debug
        
        headers = {
          'Authorization': 'Bearer ${s.session!.accessToken}',
        };
      } else {
        print('⚠️ No auth header (include_context=false)'); // Debug
      }

      print('Request: { message: $message, include_context: $includeContext, conversation_history_length: ${history.length}, headers: $headers }'); // Debug
      
      final response = await _supabase.functions.invoke(
        'gemini-chat',
        body: {
          'message': message,
          'include_context': includeContext,
          'conversation_history': history,
        },
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}'
        },
      );

      print('📡 Response status: ${response.status}'); // Debug
      print('📡 Response data: ${response.data}'); // Debug

      if (response.status == 401) {
        print('🚨 UNAUTHORIZED - Token invalid! Force logout required');
        // Force logout to clear corrupted token
        try {
          await _supabase.auth.signOut();
          throw Exception(
            'Session expired. Please log in again.',
          );
        } catch (logoutError) {
          throw Exception(
            'Session expired. Please restart app and log in again.',
          );
        }
      }

      if (response.status != 200) {
        throw Exception(
          'Error dari AI: ${response.data['error'] ?? 'Unknown error'}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        return data['response'] as String;
      } else {
        throw Exception(data['error'] ?? 'Gagal mendapatkan response dari AI');
      }
    } catch (e) {
      print('Error sending message to AI: $e');
      rethrow;
    }
  }

  /// Get chat history untuk user saat ini
  /// 
  /// Parameters:
  /// - [limit]: Jumlah maksimal pesan yang diambil (default: 50)
  /// 
  /// Returns: List of ChatMessage, ordered by created_at DESC
  Future<List<ChatMessage>> getChatHistory({int limit = 50}) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User tidak login');
      }

      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false)
          .limit(limit);

      final messages = (response as List)
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      // Reverse agar urutan terbaru di bawah (chat UI convention)
      return messages.reversed.toList();
    } catch (e) {
      print('Error getting chat history: $e');
      rethrow;
    }
  }

  /// Get chat messages untuk hari ini
  Future<List<ChatMessage>> getTodayMessages() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User tidak login');
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('user_id', _currentUserId!)
          .gte('created_at', startOfDay.toIso8601String())
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting today messages: $e');
      rethrow;
    }
  }

  /// Clear semua chat history untuk user saat ini
  /// 
  /// Returns: Jumlah pesan yang dihapus
  Future<int> clearChatHistory() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User tidak login');
      }

      // Call RPC function untuk clear history
      final response = await _supabase.rpc(
        'clear_chat_history',
        params: {'p_user_id': _currentUserId},
      );

      return response as int;
    } catch (e) {
      print('Error clearing chat history: $e');
      rethrow;
    }
  }

  /// Delete specific chat message
  Future<void> deleteMessage(String messageId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User tidak login');
      }

      await _supabase
          .from('chat_messages')
          .delete()
          .eq('id', messageId)
          .eq('user_id', _currentUserId!);
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  /// Stream chat messages (real-time updates)
  /// 
  /// Useful untuk menampilkan chat dengan real-time updates
  Stream<List<ChatMessage>> streamChatMessages() {
    if (_currentUserId == null) {
      throw Exception('User tidak login');
    }

    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId!)
        .order('created_at', ascending: true)
        .map(
          (data) => data
              .map((json) => ChatMessage.fromJson(json))
              .toList(),
        );
  }

  /// Get statistik chat untuk user
  Future<Map<String, dynamic>> getChatStats() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User tidak login');
      }

      // Total messages count
      final totalResponse = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('user_id', _currentUserId!);

      final totalCount = (totalResponse as List).length;

      // User messages count
      final userResponse = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('user_id', _currentUserId!)
          .eq('is_from_user', true);

      final userCount = (userResponse as List).length;

      // AI messages count
      final aiCount = totalCount - userCount;

      // First chat date
      DateTime? firstChatDate;
      final firstChatResponse = await _supabase
          .from('chat_messages')
          .select('created_at')
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: true)
          .limit(1);

      if (firstChatResponse.isNotEmpty) {
        firstChatDate = DateTime.parse(
          firstChatResponse[0]['created_at'] as String,
        );
      }

      return {
        'total_messages': totalCount,
        'user_messages': userCount,
        'ai_messages': aiCount,
        'first_chat_date': firstChatDate,
      };
    } catch (e) {
      print('Error getting chat stats: $e');
      rethrow;
    }
  }

  /// Quick helper untuk kirim pesan dengan error handling
  /// 
  /// Returns: Pair of (success, aiResponse/errorMessage)
  Future<(bool, String)> sendMessageSafely({
    required String message,
    bool includeContext = true,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      final response = await sendMessage(
        message: message,
        includeContext: includeContext,
        conversationHistory: conversationHistory,
      );
      return (true, response);
    } catch (e) {
      print('❌ CHAT ERROR DETAIL: $e'); // Debug log
      
      String errorMessage = 'Terjadi kesalahan saat menghubungi AI';
      
      if (e.toString().contains('GEMINI_API_KEY')) {
        errorMessage = 'API Key Gemini belum dikonfigurasi di server';
      } else if (e.toString().contains('Invalid authentication')) {
        errorMessage = 'Sesi login telah berakhir, silakan login ulang';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet';
      }
      
      return (false, errorMessage);
    }
  }
}
