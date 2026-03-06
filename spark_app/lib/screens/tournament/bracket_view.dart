import 'package:flutter/material.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/models/match_result.dart';

/// Visual single-elimination bracket rendered with CustomPaint connectors.
class BracketView extends StatelessWidget {
  final List<List<BracketMatch>> rounds;
  const BracketView({super.key, required this.rounds});

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return Center(
        child: Text('No bracket data', style: TextStyle(color: SparkTheme.muted)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int r = 0; r < rounds.length; r++) ...[
            _RoundColumn(
              roundIndex: r,
              matches: rounds[r],
              totalRounds: rounds.length,
            ),
            if (r < rounds.length - 1)
              SizedBox(
                width: 40,
                child: CustomPaint(
                  size: Size(40, _roundHeight(r)),
                  painter: _ConnectorPainter(
                    matchCount: rounds[r].length,
                    matchHeight: 100,
                    gap: 20,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  double _roundHeight(int r) {
    return rounds[r].length * 120.0;
  }
}

class _RoundColumn extends StatelessWidget {
  final int roundIndex;
  final List<BracketMatch> matches;
  final int totalRounds;

  const _RoundColumn({
    required this.roundIndex,
    required this.matches,
    required this.totalRounds,
  });

  String get _roundLabel {
    final remaining = totalRounds - roundIndex;
    if (remaining == 1) return 'FINAL';
    if (remaining == 2) return 'SEMI-FINAL';
    if (remaining == 3) return 'QUARTER-FINAL';
    return 'ROUND ${roundIndex + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _roundLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SparkTheme.accent,
              letterSpacing: 2,
            ),
          ),
        ),
        ...matches.map((m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _MatchCard(match: m),
            )),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final BracketMatch match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: SparkTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: match.completed ? SparkTheme.green.withOpacity(0.4) : SparkTheme.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SlotRow(slot: match.slotA, isTop: true),
          Container(height: 1, color: SparkTheme.border),
          _SlotRow(slot: match.slotB, isTop: false),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final BracketSlot slot;
  final bool isTop;

  const _SlotRow({required this.slot, required this.isTop});

  @override
  Widget build(BuildContext context) {
    final hasPlayer = slot.player != null;
    final color = slot.isWinner
        ? SparkTheme.green
        : hasPlayer
            ? SparkTheme.text
            : SparkTheme.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: slot.isWinner ? SparkTheme.green.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(12) : Radius.zero,
          bottom: !isTop ? const Radius.circular(12) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          if (hasPlayer)
            Text(slot.player!.avatar, style: const TextStyle(fontSize: 16))
          else
            const Icon(Icons.help_outline, size: 16, color: SparkTheme.border),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasPlayer ? slot.player!.name : 'TBD',
              style: TextStyle(
                fontSize: 13,
                fontWeight: slot.isWinner ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (slot.score > 0 || slot.isWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: slot.isWinner
                    ? SparkTheme.green.withOpacity(0.2)
                    : SparkTheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${slot.score}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints the connector lines between rounds.
class _ConnectorPainter extends CustomPainter {
  final int matchCount;
  final double matchHeight;
  final double gap;

  _ConnectorPainter({
    required this.matchCount,
    required this.matchHeight,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SparkTheme.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final totalPerMatch = matchHeight + gap;
    final totalHeight = matchCount * totalPerMatch - gap;
    final offsetY = (size.height - totalHeight) / 2;

    // For each pair of matches → one output
    for (int i = 0; i < matchCount; i += 2) {
      if (i + 1 >= matchCount) break;

      final y1 = offsetY + i * totalPerMatch + matchHeight / 2;
      final y2 = offsetY + (i + 1) * totalPerMatch + matchHeight / 2;
      final midY = (y1 + y2) / 2;
      final midX = size.width / 2;

      // Lines from match centers to connector
      canvas.drawLine(Offset(0, y1), Offset(midX, y1), paint);
      canvas.drawLine(Offset(0, y2), Offset(midX, y2), paint);
      // Vertical bar
      canvas.drawLine(Offset(midX, y1), Offset(midX, y2), paint);
      // Line to next round
      canvas.drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) => false;
}
