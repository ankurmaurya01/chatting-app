import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AvatarBadge extends StatelessWidget {
  final String name;
  final double radius;
  final bool isOnline;
  final bool showOnlineIndicator;
  final bool isGroup;

  const AvatarBadge({
    super.key,
    required this.name,
    this.radius = 24,
    this.isOnline = false,
    this.showOnlineIndicator = false,
    this.isGroup = false,
  });

  String _getInitials(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return "?";
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _generateColor(String text) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
    ];
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isGroup ? AppColors.accent : _generateColor(name);

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: bgColor.withOpacity(0.18),
          child: isGroup
              ? Icon(Icons.group_rounded, color: bgColor, size: radius * 1.1)
              : Text(
                  _getInitials(name),
                  style: TextStyle(
                    color: bgColor,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.75,
                  ),
                ),
        ),
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.online : AppColors.offline,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
