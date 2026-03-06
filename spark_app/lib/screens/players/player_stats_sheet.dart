import 'package:flutter/material.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/models/player.dart';

/// Bottom sheet showing detailed lifetime stats for a player.
class PlayerStatsSheet extends StatelessWidget {
  final Player player;
  const PlayerStatsSheet({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SparkTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar + name
          CircleAvatar(
            radius: 40,
            backgroundColor: SparkTheme.surface,
            child: Text(player.avatar, style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 12),
          Text(
            player.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: SparkTheme.text,
            ),
          ),
          const SizedBox(height: 24),

          // Stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatTile('Total Wins', '${player.totalWins}', SparkTheme.yellow, Icons.emoji_events),
              _StatTile('Total Points', '${player.totalPoints}', SparkTheme.accent, Icons.sports_score),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatTile('Longest Rally', '${player.longestRally}', SparkTheme.blue, Icons.loop),
              _StatTile('Edge Accuracy', '${player.edgeAccuracy.toStringAsFixed(1)}%', SparkTheme.purple, Icons.gps_fixed),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatTile('Edge Hits', '${player.edgeHits}', SparkTheme.green, Icons.adjust),
              _StatTile('Total Hits', '${player.totalHits}', SparkTheme.muted, Icons.blur_on),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SparkTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: SparkTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}
