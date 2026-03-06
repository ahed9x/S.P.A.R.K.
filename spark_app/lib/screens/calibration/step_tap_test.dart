import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/providers/connection_provider.dart';
import 'package:spark_app/providers/game_provider.dart';

/// Step 2: Tap each sensor and verify it fires — visual grid of 10 piezos.
class StepTapTest extends StatefulWidget {
  final VoidCallback onNext;
  const StepTapTest({super.key, required this.onNext});

  @override
  State<StepTapTest> createState() => _StepTapTestState();
}

class _StepTapTestState extends State<StepTapTest> {
  // Track which sensors have been verified at least once
  final List<bool> _verified = List.filled(10, false);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    // Mark sensors as verified when they fire
    for (int i = 0; i < 10; i++) {
      if (game.piezoFired[i]) _verified[i] = true;
    }

    final allVerified = _verified.every((v) => v);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'Tap each sensor on the table',
            style: TextStyle(
              fontSize: 18,
              color: SparkTheme.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sensors will light up when they detect a tap. '
            'Verify all 10 turn green before continuing.',
            style: TextStyle(color: SparkTheme.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Table diagram
          Expanded(child: _TableDiagram(piezoFired: game.piezoFired, verified: _verified)),

          const SizedBox(height: 16),
          Text(
            '${_verified.where((v) => v).length} / 10 sensors verified',
            style: TextStyle(
              fontSize: 16,
              color: allVerified ? SparkTheme.green : SparkTheme.yellow,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < _verified.length; i++) {
                        _verified[i] = false;
                      }
                    });
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: allVerified
                      ? () {
                          final conn = context.read<ConnectionProvider>();
                          conn.ws.calibNext();
                          widget.onNext();
                        }
                      : null,
                  child: const Text('Next Step →'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Schematic table view showing the 10 piezo locations.
class _TableDiagram extends StatelessWidget {
  final List<bool> piezoFired;
  final List<bool> verified;

  const _TableDiagram({required this.piezoFired, required this.verified});

  // Sensor layout on the 2740 × 1525 mm table (normalized 0‥1)
  // Alpha (node 1): 4 piezos on Side-A  [indices 0-3]
  // Beta  (node 2): 4 piezos on Side-B [indices 4-7], 2 net piezos [indices 8-9]
  static const _positions = <_SensorPos>[
    // Alpha Side-A piezos (top side in landscape view)
    _SensorPos(0.12, 0.08, 'A0'),
    _SensorPos(0.37, 0.08, 'A1'),
    _SensorPos(0.62, 0.08, 'A2'),
    _SensorPos(0.88, 0.08, 'A3'),
    // Beta Side-B piezos (bottom side)
    _SensorPos(0.12, 0.92, 'B0'),
    _SensorPos(0.37, 0.92, 'B1'),
    _SensorPos(0.62, 0.92, 'B2'),
    _SensorPos(0.88, 0.92, 'B3'),
    // Beta net piezos (center)
    _SensorPos(0.35, 0.50, 'N0'),
    _SensorPos(0.65, 0.50, 'N1'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Stack(
        children: [
          // Table outline
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A3D2A), // dark green table
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SparkTheme.border, width: 2),
              ),
            ),
          ),
          // Net line
          Positioned(
            left: 0,
            right: 0,
            top: h * 0.5 - 1,
            child: Container(height: 2, color: Colors.white30),
          ),
          // Center line
          Positioned(
            left: w * 0.5 - 1,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: Colors.white12),
          ),
          // Labels
          Positioned(
            top: h * 0.25,
            left: 0,
            right: 0,
            child: Text(
              'SIDE A',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Positioned(
            top: h * 0.68,
            left: 0,
            right: 0,
            child: Text(
              'SIDE B',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          // Sensors
          for (int i = 0; i < _positions.length; i++)
            Positioned(
              left: _positions[i].x * w - 22,
              top: _positions[i].y * h - 22,
              child: _SensorDot(
                label: _positions[i].label,
                firing: piezoFired[i],
                verified: verified[i],
              ),
            ),
        ],
      );
    });
  }
}

class _SensorPos {
  final double x, y;
  final String label;
  const _SensorPos(this.x, this.y, this.label);
}

class _SensorDot extends StatelessWidget {
  final String label;
  final bool firing;
  final bool verified;

  const _SensorDot({
    required this.label,
    required this.firing,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (firing) {
      color = SparkTheme.accent;
    } else if (verified) {
      color = SparkTheme.green;
    } else {
      color = SparkTheme.muted;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(firing ? 0.9 : 0.6),
        border: Border.all(color: color, width: 2),
        boxShadow: firing
            ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 16, spreadRadius: 4)]
            : [],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: firing || verified ? SparkTheme.bg : SparkTheme.text,
          ),
        ),
      ),
    );
  }
}
