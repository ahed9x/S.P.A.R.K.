import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/providers/connection_provider.dart';
import 'package:spark_app/screens/calibration/step_connect.dart';
import 'package:spark_app/screens/calibration/step_tap_test.dart';
import 'package:spark_app/screens/calibration/step_table_map.dart';

/// 3-step guided calibration wizard.
class CalibrationWizard extends StatefulWidget {
  const CalibrationWizard({super.key});

  @override
  State<CalibrationWizard> createState() => _CalibrationWizardState();
}

class _CalibrationWizardState extends State<CalibrationWizard> {
  int _step = 0;
  final _controller = PageController();

  static const _titles = [
    '1 — Connect & Environment',
    '2 — Sensor Tap Test',
    '3 — Table Mapping',
  ];

  void _next() {
    if (_step >= 2) {
      // Wizard complete — stop calibration, go back
      final conn = context.read<ConnectionProvider>();
      conn.ws.calibStop();
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step++);
    _controller.animateToPage(_step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _back() {
    if (_step <= 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
    _controller.animateToPage(_step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_step]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _StepProgress(current: _step),
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StepConnect(onNext: _next),
                StepTapTest(onNext: _next),
                StepTableMap(onNext: _next),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int current;
  const _StepProgress({required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      color: SparkTheme.surface,
      child: Row(
        children: List.generate(3, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: done
                      ? SparkTheme.green
                      : active
                          ? SparkTheme.accent
                          : SparkTheme.border,
                  child: done
                      ? const Icon(Icons.check, size: 16, color: SparkTheme.bg)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: active ? SparkTheme.bg : SparkTheme.muted,
                          ),
                        ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done ? SparkTheme.green : SparkTheme.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
