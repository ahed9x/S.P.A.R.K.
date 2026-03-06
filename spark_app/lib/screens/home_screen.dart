import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/providers/connection_provider.dart';
import 'package:spark_app/screens/arena/arena_screen.dart';
import 'package:spark_app/screens/calibration/calibration_wizard.dart';
import 'package:spark_app/screens/players/players_screen.dart';
import 'package:spark_app/screens/tournament/tournament_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Text(
                  '⚡ SPARK',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: SparkTheme.accent,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart Ping-Pong Automated Referee Kit',
                  style: TextStyle(
                    fontSize: 14,
                    color: SparkTheme.muted,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 48),

                // Connection status
                _ConnectionCard(conn: conn),
                const SizedBox(height: 36),

                // Navigation grid
                _buildGrid(context, conn.connected),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, bool connected) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: [
        _NavTile(
          icon: Icons.tune,
          label: 'Calibration',
          color: SparkTheme.yellow,
          enabled: connected,
          onTap: () => _push(context, const CalibrationWizard()),
        ),
        _NavTile(
          icon: Icons.sports_esports,
          label: 'Live Arena',
          color: SparkTheme.green,
          enabled: connected,
          onTap: () => _push(context, const ArenaScreen()),
        ),
        _NavTile(
          icon: Icons.people,
          label: 'Players',
          color: SparkTheme.blue,
          enabled: true,
          onTap: () => _push(context, const PlayersScreen()),
        ),
        _NavTile(
          icon: Icons.emoji_events,
          label: 'Tournament',
          color: SparkTheme.purple,
          enabled: true,
          onTap: () => _push(context, const TournamentScreen()),
        ),
      ],
    );
  }

  void _push(BuildContext ctx, Widget screen) {
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => screen));
  }
}

// -----------  Connection card  -----------

class _ConnectionCard extends StatefulWidget {
  final ConnectionProvider conn;
  const _ConnectionCard({required this.conn});

  @override
  State<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard> {
  final _ctrl = TextEditingController(text: '192.168.4.1');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conn = widget.conn;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  conn.connected ? Icons.wifi : Icons.wifi_off,
                  color: conn.connected ? SparkTheme.green : SparkTheme.red,
                ),
                const SizedBox(width: 12),
                Text(
                  conn.connected
                      ? 'Connected to ${conn.host}'
                      : 'Not connected',
                  style: TextStyle(
                    color:
                        conn.connected ? SparkTheme.green : SparkTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'ESP32 IP address',
                      prefixText: 'ws://',
                      suffixText: ':81',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (conn.connected) {
                      conn.disconnect();
                    } else {
                      conn.connect(_ctrl.text.trim());
                    }
                  },
                  child: Text(conn.connected ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),
            if (conn.connected) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _EnvChip('${conn.temperature.toStringAsFixed(1)} °C', Icons.thermostat),
                  _EnvChip('${conn.humidity.toStringAsFixed(0)} %RH', Icons.water_drop),
                  _EnvChip('${conn.speedOfSound.toStringAsFixed(1)} m/s', Icons.speed),
                  _EnvChip('Fan ${(conn.fanPWM / 2.55).round()}%', Icons.air),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EnvChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _EnvChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: SparkTheme.accent),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: SparkTheme.surface,
      side: const BorderSide(color: SparkTheme.border),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 180,
          height: 160,
          decoration: BoxDecoration(
            color: SparkTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
