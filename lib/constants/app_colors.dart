import 'package:flutter/material.dart';

/// Color palette untuk myITS Synergy
/// Mengikuti branding resmi myITS
class AppColors {
  // Warna Utama (Primary Color) - Branding myITS
  /// Biru Tua ITS - Warna utama branding
  /// RGB: 1, 56, 128
  static const Color primary = Color(0xFF013880);

  // Warna Pendukung (Secondary/Accent Colors)
  /// Biru Muda ITS - Untuk elemen interaktif
  /// HEX: #0078C1
  static const Color secondary = Color(0xFF0078C1);
  static const Color accent = Color(0xFF0078C1);

  // Warna Netral (Background & Surface)
  /// Putih - Latar belakang utama
  static const Color background = Color(0xFFFFFFFF);

  /// Abu-abu Sangat Muda - Latar kartu/section
  /// Memberikan dimensi visual
  static const Color surface = Color(0xFFF4F4F4);

  /// Teks Gelap - Untuk keterbacaan maksimal
  static const Color textDark = Color(0xFF333333);

  /// Teks Terang - Untuk teks di atas background gelap
  static const Color textLight = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Gradien myITS
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Prevent instantiation
  AppColors._();
}
