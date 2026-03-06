import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/providers/connection_provider.dart';

/// Step 1: Verify WebSocket connection and display BME680 environment data.
class StepConnect extends StatelessWidget {
  final VoidCallback onNext;
  const StepConnect({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(
            conn.connected ? Icons.wifi : Icons.wifi_off,
            size: 64,
            color: conn.connected ? SparkTheme.green : SparkTheme.red,
          ),
          const SizedBox(height: 16),
          Text(
            conn.connected
                ? 'Connected to ${conn.host}'
                : 'Not connected — go back and connect first',
            style: TextStyle(
              fontSize: 18,
              color: conn.connected ? SparkTheme.green : SparkTheme.red,
            ),
          ),
          const SizedBox(height: 32),

          if (conn.connected) ...[
            // Request fresh environment data
            OutlinedButton.icon(
              onPressed: () => conn.ws.requestEnv(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Environment'),
            ),
            const SizedBox(height: 24),

            // Environment cards
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _EnvCard(
                  icon: Icons.thermostat,
                  label: 'Temperature',
                  value: '${conn.temperature.toStringAsFixed(1)} °C',
                  color: SparkTheme.red,
                ),
                _EnvCard(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '${conn.humidity.toStringAsFixed(0)} %RH',
                  color: SparkTheme.blue,
                ),
                _EnvCard(
                  icon: Icons.compress,
                  label: 'Pressure',
                  value: '${conn.pressure.toStringAsFixed(0)} hPa',
                  color: SparkTheme.purple,
                ),
                _EnvCard(
                  icon: Icons.speed,
                  label: 'Speed of Sound',
                  value: '${conn.speedOfSound.toStringAsFixed(1)} m/s',
                  color: SparkTheme.yellow,
                ),
                _EnvCard(
                  icon: Icons.air,
                  label: 'Fan PWM',
                  value: '${(conn.fanPWM / 2.55).round()} %',
                  color: SparkTheme.green,
                ),
              ],
            ),
          ],

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: conn.connected
                  ? () {
                      conn.ws.calibStart();
                      onNext();
                    }
                  : null,
              child: const Text('Begin Calibration →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _EnvCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SparkTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: SparkTheme.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
