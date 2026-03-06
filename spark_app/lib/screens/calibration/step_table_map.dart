import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/providers/connection_provider.dart';

/// Step 3: Table mapping — user taps 4 physical corners; ESP32 sends
/// calibTap messages with TDOA-computed coordinates. We show them on a 2D canvas.
class StepTableMap extends StatefulWidget {
  final VoidCallback onNext;
  const StepTableMap({super.key, required this.onNext});

  @override
  State<StepTableMap> createState() => _StepTableMapState();
}

class _StepTableMapState extends State<StepTableMap> {
  final List<Offset> _corners = [];
  StreamSubscription? _calibSub;
  int _expectedCorner = 0;

  static const _cornerLabels = [
    'Top-Left (A-side)',
    'Top-Right (A-side)',
    'Bottom-Right (B-side)',
    'Bottom-Left (B-side)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conn = context.read<ConnectionProvider>();
      _calibSub = conn.ws.onCalibTap.listen(_onCalibTap);
    });
  }

  void _onCalibTap(Map<String, dynamic> j) {
    final x = (j['x'] as num?)?.toDouble() ?? 0;
    final y = (j['y'] as num?)?.toDouble() ?? 0;
    setState(() {
      if (_corners.length < 4) {
        _corners.add(Offset(x, y));
        _expectedCorner = _corners.length;
      }
    });
  }

  @override
  void dispose() {
    _calibSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _corners.length >= 4;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            done
                ? 'All 4 corners mapped!'
                : 'Tap corner: ${_cornerLabels[_expectedCorner.clamp(0, 3)]}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: done ? SparkTheme.green : SparkTheme.yellow,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            done
                ? 'Calibration data captured. You can finish the wizard.'
                : 'Firmly tap the ball on the indicated corner of the table.',
            style: TextStyle(color: SparkTheme.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Canvas
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A3D2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SparkTheme.border, width: 2),
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  return CustomPaint(
                    size: Size(box.maxWidth, box.maxHeight),
                    painter: _TableMapPainter(
                      corners: _corners,
                      tableWidth: 2740,
                      tableHeight: 1525,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _corners.clear();
                      _expectedCorner = 0;
                    });
                  },
                  child: const Text('Reset Corners'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: done ? widget.onNext : null,
                  child: const Text('Finish Calibration ✓'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableMapPainter extends CustomPainter {
  final List<Offset> corners;
  final double tableWidth;
  final double tableHeight;

  _TableMapPainter({
    required this.corners,
    required this.tableWidth,
    required this.tableHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / tableWidth;
    final sy = size.height / tableHeight;

    // Net line
    final netPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      netPaint,
    );

    // Expected corner targets (faint)
    final targetPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final targets = [
      Offset(0, 0),
      Offset(tableWidth, 0),
      Offset(tableWidth, tableHeight),
      Offset(0, tableHeight),
    ];
    for (final t in targets) {
      canvas.drawCircle(Offset(t.dx * sx, t.dy * sy), 18, targetPaint);
    }

    // Captured corners
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = SparkTheme.accent.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw polygon if we have enough points
    if (corners.length >= 2) {
      final path = Path();
      path.moveTo(corners[0].dx * sx, corners[0].dy * sy);
      for (int i = 1; i < corners.length; i++) {
        path.lineTo(corners[i].dx * sx, corners[i].dy * sy);
      }
      if (corners.length == 4) path.close();
      canvas.drawPath(path, linePaint);
    }

    // Draw corner dots
    for (int i = 0; i < corners.length; i++) {
      final c = corners[i];
      dotPaint.color = SparkTheme.accent;
      canvas.drawCircle(Offset(c.dx * sx, c.dy * sy), 10, dotPaint);

      // Glow
      dotPaint.color = SparkTheme.accent.withOpacity(0.25);
      canvas.drawCircle(Offset(c.dx * sx, c.dy * sy), 20, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TableMapPainter old) => true;
}
