import 'package:flutter/material.dart';

class LevelBadge extends StatelessWidget {
  final String level;

  const LevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color textColor;
    IconData icon;

    switch (level.toLowerCase()) {
      case 'gold':
        badgeColor = const Color(0xFFFFD700).withValues(alpha: 0.2);
        textColor = const Color(0xFFB8860B); // 👈 Memperbaiki typo '0 textC:'
        icon = Icons.stars_rounded;
        break;
      case 'silver':
        badgeColor = const Color(0xFFC0C0C0).withValues(alpha: 0.2);
        textColor = const Color(0xFF7F8C8D);
        icon = Icons.workspace_premium_rounded;
        break;
      case 'bronze':
      default:
        badgeColor = const Color(0xFFCD7F32).withValues(alpha: 0.2);
        textColor = const Color(0xFFA0522D);
        icon = Icons.military_tech_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: textColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            level.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
