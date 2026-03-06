import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/providers/game_provider.dart';
import 'package:spark_app/models/hit_event.dart';

/// Animated 2D heatmap of ball impacts using CustomPaint.
///
/// Each hit is rendered as a glowing dot, colour-coded by player, that
/// fades over time. The newest hits glow brightest.
class HeatmapPanel extends StatelessWidget {
  const HeatmapPanel({super.key});

  // Regulation table dimensions (mm)
  static const double tableW = 2740;
  static const double tableH = 1525;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3D2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SparkTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, box) {
            return Stack(
              children: [
                CustomPaint(
                  size: Size(box.maxWidth, box.maxHeight),
                  painter: _HeatmapPainter(
                    hits: game.hits,
                    tableWidth: tableW,
                    tableHeight: tableH,
                  ),
                ),
                // Net label
                Positioned(
                  left: 0,
                  right: 0,
                  top: box.maxHeight * 0.5 - 8,
                  child: const Center(
                    child: Text(
                      'NET',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
                // Hit counter
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SparkTheme.bg.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${game.hits.length} hits',
                      style: TextStyle(color: SparkTheme.muted, fontSize: 11),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<HitEvent> hits;
  final double tableWidth;
  final double tableHeight;

  _HeatmapPainter({
    required this.hits,
    required this.tableWidth,
    required this.tableHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / tableWidth;
    final sy = size.height / tableHeight;

    // Table markings
    _drawTableMarkings(canvas, size);

    // Draw each hit with age-based fade
    final now = DateTime.now();
    for (int i = 0; i < hits.length; i++) {
      final hit = hits[i];
      final age = now.difference(hit.time).inMilliseconds;
      final maxAge = 30000; // 30-second fade
      final alpha = ((1 - (age / maxAge)).clamp(0.15, 1.0) * 255).toInt();

      // Player colour
      Color baseColor;
      if (hit.player == 0) {
        baseColor = SparkTheme.playerA;
      } else if (hit.player == 1) {
        baseColor = SparkTheme.playerB;
      } else {
        baseColor = SparkTheme.accent;
      }

      final cx = hit.x * sx;
      final cy = hit.y * sy;

      // Outer glow
      final glowRadius = 8 + (hit.velocity * 0.8).clamp(0, 20).toDouble();
      final glowPaint = Paint()
        ..color = baseColor.withAlpha((alpha * 0.25).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(cx, cy), glowRadius, glowPaint);

      // Inner dot
      final dotPaint = Paint()..color = baseColor.withAlpha(alpha);
      canvas.drawCircle(Offset(cx, cy), 4, dotPaint);

      // Velocity indicator ring for fast hits
      if (hit.velocity > 5) {
        final ringPaint = Paint()
          ..color = SparkTheme.yellow.withAlpha((alpha * 0.6).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(cx, cy), glowRadius + 4, ringPaint);
      }
    }
  }

  void _drawTableMarkings(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;

    // Outer border
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);

    // Net line (horizontal center)
    final netPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), netPaint);

    // Center line (vertical)
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), linePaint);

    // Edge zone indicator (50mm from each edge — where edge hits are counted)
    final edgeDist = 50.0 * (w / tableWidth);
    final edgePaint = Paint()
      ..color = SparkTheme.yellow.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    // Top edge
    canvas.drawRect(Rect.fromLTWH(0, 0, w, edgeDist), edgePaint);
    // Bottom edge
    canvas.drawRect(Rect.fromLTWH(0, h - edgeDist, w, edgeDist), edgePaint);
    // Left edge
    canvas.drawRect(Rect.fromLTWH(0, 0, edgeDist, h), edgePaint);
    // Right edge
    canvas.drawRect(Rect.fromLTWH(w - edgeDist, 0, edgeDist, h), edgePaint);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) => true;
}
