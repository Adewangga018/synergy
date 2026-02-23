import 'package:flutter/material.dart';

/// Model untuk Chat Message dengan AI Assistant
class ChatMessage {
  final String id;
  final String userId;
  final String message;
  final bool isFromUser;
  final Map<String, dynamic>? userContext;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.isFromUser,
    this.userContext,
    required this.createdAt,
  });

  /// Create ChatMessage dari JSON (dari Supabase)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      isFromUser: json['is_from_user'] as bool,
      userContext: json['user_context'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert ChatMessage ke JSON (untuk kirim ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'message': message,
      'is_from_user': isFromUser,
      'user_context': userContext,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy dengan perubahan tertentu
  ChatMessage copyWith({
    String? id,
    String? userId,
    String? message,
    bool? isFromUser,
    Map<String, dynamic>? userContext,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      isFromUser: isFromUser ?? this.isFromUser,
      userContext: userContext ?? this.userContext,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get warna bubble berdasarkan sender
  Color getBubbleColor(BuildContext context) {
    if (isFromUser) {
      return Theme.of(context).primaryColor;
    } else {
      return Colors.grey[300]!;
    }
  }

  /// Get warna text berdasarkan sender
  Color getTextColor(BuildContext context) {
    if (isFromUser) {
      return Colors.white;
    } else {
      return Colors.black87;
    }
  }

  /// Get alignment berdasarkan sender
  Alignment getAlignment() {
    return isFromUser ? Alignment.centerRight : Alignment.centerLeft;
  }

  /// Format waktu untuk display (contoh: "10:30" atau "Kemarin")
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      // Hari ini - tampilkan jam
      final hour = createdAt.hour.toString().padLeft(2, '0');
      final minute = createdAt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      // Format hari dalam bahasa Indonesia
      final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      return days[createdAt.weekday % 7];
    } else {
      // Format tanggal (dd/MM/yyyy)
      final day = createdAt.day.toString().padLeft(2, '0');
      final month = createdAt.month.toString().padLeft(2, '0');
      final year = createdAt.year;
      return '$day/$month/$year';
    }
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, isFromUser: $isFromUser, message: $message, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model untuk conversation history (untuk dikirim ke Gemini API)
class ConversationMessage {
  final String role; // 'user' atau 'assistant'
  final String content;

  ConversationMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }

  factory ConversationMessage.fromChatMessage(ChatMessage chatMessage) {
    return ConversationMessage(
      role: chatMessage.isFromUser ? 'user' : 'assistant',
      content: chatMessage.message,
    );
  }
}
