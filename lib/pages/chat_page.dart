import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/chat_message.dart';
import 'package:synergy/services/gemini_chat_service.dart';
import 'package:synergy/constants/app_colors.dart';

/// Halaman Chat dengan AI Assistant (Synergy AI)
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _chatService = GeminiChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refreshSessionAndLoadChat();
  }
  
  /// Refresh session before loading chat
  Future<void> _refreshSessionAndLoadChat() async {
    try {
      // Try to refresh session to ensure valid JWT token
      final response = await Supabase.instance.client.auth.refreshSession();
      
      if (response.session == null) {
        print('❌ Session refresh failed - no session');
        _handleInvalidSession();
        return;
      }
      
      print('✅ Session refreshed successfully');
    } catch (e) {
      print('❌ Session refresh failed: $e');
      _handleInvalidSession();
      return;
    }
    
    _loadChatHistory();
  }
  
  /// Handle invalid session - logout and show message
  void _handleInvalidSession() {
    if (!mounted) return;
    
    setState(() {
      _errorMessage = 'Sesi login Anda tidak valid. Silakan logout dan login ulang.';
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesi login tidak valid. Silakan logout dan login ulang.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load chat history dari database
  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await _chatService.getChatHistory(limit: 100);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Auto scroll ke bawah setelah load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat riwayat chat: $e';
        _isLoading = false;
      });
    }
  }

  /// Scroll ke pesan terbaru
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Send message ke AI
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    
    if (message.isEmpty) return;

    // Clear input field
    _messageController.clear();

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      // Refresh session before sending to ensure valid JWT
      // print('🔄 Refreshing session before sending message...');
      // await Supabase.instance.client.auth.refreshSession();
      // print('✅ Session valid');
      
      // Get AI response dengan conversation history
      final (success, response) = await _chatService.sendMessageSafely(
        message: message,
        includeContext: true, // Include user context for personalized AI responses
        conversationHistory: _messages,
      );

      if (success) {
        // Reload chat history untuk mendapatkan pesan baru
        await _loadChatHistory();
      } else {
        // Show error
        setState(() {
          _errorMessage = response;
        });
        
        // Show snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengirim pesan: $e';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  /// Clear chat history dengan konfirmasi
  Future<void> _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Chat?'),
        content: const Text(
          'Semua percakapan dengan AI akan dihapus. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatService.clearChatHistory();
        setState(() {
          _messages.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Riwayat chat berhasil dihapus'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus riwayat: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// Show chat stats dialog
  Future<void> _showChatStats() async {
    try {
      final stats = await _chatService.getChatStats();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Statistik Chat'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatRow(
                icon: Icons.message,
                label: 'Total Pesan',
                value: '${stats['total_messages']}',
              ),
              const SizedBox(height: 8),
              _StatRow(
                icon: Icons.person,
                label: 'Pesan Kamu',
                value: '${stats['user_messages']}',
              ),
              const SizedBox(height: 8),
              _StatRow(
                icon: Icons.smart_toy,
                label: 'Respon AI',
                value: '${stats['ai_messages']}',
              ),
              if (stats['first_chat_date'] != null) ...[
                const SizedBox(height: 8),
                _StatRow(
                  icon: Icons.calendar_today,
                  label: 'Chat Pertama',
                  value: _formatDate(stats['first_chat_date'] as DateTime),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat statistik: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Oct', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Synergy AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Asisten Cerdas Kamu',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showChatStats,
            tooltip: 'Statistik Chat',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _clearChatHistory();
              } else if (value == 'refresh') {
                _loadChatHistory();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Riwayat', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red[100],
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[900], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900], fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                    color: Colors.red[900],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat riwayat chat...'),
                      ],
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _ChatBubble(message: message);
                        },
                      ),
          ),

          // Typing indicator
          if (_isSending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI sedang berpikir...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Tanya sesuatu...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isSending,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.white,
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada percakapan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Mulai chat dengan AI untuk mendapatkan bantuan seputar jadwal, tugas, dan kegiatanmu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _SuggestionChip(
                label: '📚 Jadwal minggu ini',
                onTap: () {
                  _messageController.text = 'Jadwal kuliah aku minggu ini apa aja?';
                },
              ),
              _SuggestionChip(
                label: '✅ Tugas terdekat',
                onTap: () {
                  _messageController.text = 'Apa aja tugas yang harus aku kerjakan?';
                },
              ),
              _SuggestionChip(
                label: '🏢 Kegiatan organisasi',
                onTap: () {
                  _messageController.text = 'Organisasi apa aja yang aku ikuti?';
                },
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/// Widget untuk chat bubble
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.getAlignment(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: message.isFromUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.getBubbleColor(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: message.isFromUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: message.isFromUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: message.getTextColor(context),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                message.getFormattedTime(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget untuk suggestion chip
class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.grey[100],
      labelStyle: const TextStyle(fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

/// Widget untuk statistics row
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
