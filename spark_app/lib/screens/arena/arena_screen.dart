import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/providers/connection_provider.dart';
import 'package:spark_app/providers/game_provider.dart';
import 'package:spark_app/screens/arena/scoreboard_panel.dart';
import 'package:spark_app/screens/arena/heatmap_panel.dart';
import 'package:spark_app/screens/arena/event_log_panel.dart';

/// The main Live Arena Dashboard — landscape-optimised.
class ArenaScreen extends StatelessWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();
    final game = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ LIVE ARENA'),
        actions: [
          // Game state pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _stateColor(game.gameState).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _stateColor(game.gameState)),
            ),
            child: Center(
              child: Text(
                _stateLabel(game.gameState),
                style: TextStyle(
                  color: _stateColor(game.gameState),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Top: Scoreboard
          const ScoreboardPanel(),

          // Middle: Heatmap + Event log side by side
          Expanded(
            child: Row(
              children: const [
                Expanded(flex: 3, child: HeatmapPanel()),
                Expanded(flex: 2, child: EventLogPanel()),
              ],
            ),
          ),

          // Bottom: Controls
          _ControlBar(game: game, connected: conn.connected),
        ],
      ),
    );
  }

  static String _stateLabel(int s) {
    switch (s) {
      case 0: return 'IDLE';
      case 1: return 'SERVING';
      case 2: return 'RALLY';
      case 3: return 'POINT SCORED';
      case 4: return 'GAME OVER';
      default: return 'UNKNOWN';
    }
  }

  static Color _stateColor(int s) {
    switch (s) {
      case 0: return SparkTheme.muted;
      case 1: return SparkTheme.yellow;
      case 2: return SparkTheme.green;
      case 3: return SparkTheme.accent;
      case 4: return SparkTheme.red;
      default: return SparkTheme.muted;
    }
  }
}

class _ControlBar extends StatelessWidget {
  final GameProvider game;
  final bool connected;
  const _ControlBar({required this.game, required this.connected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: SparkTheme.card,
        border: Border(top: BorderSide(color: SparkTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BarButton(
            label: 'Start Game',
            icon: Icons.play_arrow,
            color: SparkTheme.green,
            enabled: connected && game.gameState == 0,
            onPressed: () => game.startGame(),
          ),
          const SizedBox(width: 16),
          _BarButton(
            label: 'Reset',
            icon: Icons.refresh,
            color: SparkTheme.yellow,
            enabled: connected,
            onPressed: () => game.resetGame(),
          ),
          const SizedBox(width: 16),
          _BarButton(
            label: 'LED Victory',
            icon: Icons.celebration,
            color: SparkTheme.purple,
            enabled: connected,
            onPressed: () {
              final conn = context.read<ConnectionProvider>();
              conn.ws.setLedMode('victory');
            },
          ),
          const SizedBox(width: 16),
          _BarButton(
            label: 'Play Sound',
            icon: Icons.volume_up,
            color: SparkTheme.blue,
            enabled: connected,
            onPressed: () {
              final conn = context.read<ConnectionProvider>();
              conn.ws.playSound('point.wav');
            },
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _BarButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: SparkTheme.bg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}
