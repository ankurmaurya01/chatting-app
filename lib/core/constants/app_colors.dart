import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0D6EFD);
  static const Color primaryLight = Color(0xFF4C8DFF);
  static const Color primaryDark = Color(0xFF004DC7);
  static const Color accent = Color(0xFF00D2D3);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightSentBubble = Color(0xFF0D6EFD);
  static const Color lightSentBubbleText = Color(0xFFFFFFFF);
  static const Color lightReceivedBubble = Color(0xFFE9ECEF);
  static const Color lightReceivedBubbleText = Color(0xFF1E293B);

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF334155);
  static const Color darkSentBubble = Color(0xFF2563EB);
  static const Color darkSentBubbleText = Color(0xFFFFFFFF);
  static const Color darkReceivedBubble = Color(0xFF334155);
  static const Color darkReceivedBubbleText = Color(0xFFF8FAFC);

  // Status & Feedback Colors
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF94A3B8);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color readTick = Color(0xFF38BDF8);
  static const Color unreadBadge = Color(0xFFEF4444);

  // Customizable Bubble Colors
  static const List<Color> customBubbleColors = [
    Color(0xFF0D6EFD), // Default Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFF10B981), // Emerald Green
    Color(0xFFEC4899), // Pink
    Color(0xFFF97316), // Orange
    Color(0xFF06B6D4), // Cyan
    Color(0xFF475569), // Slate
  ];

  // Customizable Wallpapers (Colors / Gradients)
  static const List<Color> wallpaperColors = [
    Colors.transparent, // Default system
    Color(0xFFF1F5F9),
    Color(0xFFFEF3C7),
    Color(0xFFE0E7FF),
    Color(0xFFD1FAE5),
    Color(0xFF1E293B),
    Color(0xFF18181B),
  ];
}
