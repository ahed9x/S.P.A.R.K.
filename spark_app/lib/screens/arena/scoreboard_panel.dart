import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/providers/game_provider.dart';

/// Massive high-contrast digital scoreboard.
class ScoreboardPanel extends StatelessWidget {
  const ScoreboardPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: SparkTheme.card,
        border: Border(bottom: BorderSide(color: SparkTheme.border)),
      ),
      child: Row(
        children: [
          // Player A
          Expanded(
            child: _PlayerScore(
              label: 'PLAYER A',
              score: game.scoreA,
              color: SparkTheme.playerA,
              isServing: game.server == 0,
            ),
          ),

          // Center info
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: SparkTheme.muted,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: SparkTheme.surface,
                  border: Border.all(color: SparkTheme.border),
                ),
                child: Text(
                  'Rally ${game.rally}',
                  style: TextStyle(
                    color: SparkTheme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Player B
          Expanded(
            child: _PlayerScore(
              label: 'PLAYER B',
              score: game.scoreB,
              color: SparkTheme.playerB,
              isServing: game.server == 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final bool isServing;

  const _PlayerScore({
    required this.label,
    required this.score,
    required this.color,
    required this.isServing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isServing)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.sports_tennis, color: SparkTheme.yellow, size: 18),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.7),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          score.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
          ),
        ),
      ],
    );
  }
}
