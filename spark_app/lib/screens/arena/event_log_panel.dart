import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/providers/game_provider.dart';
import 'package:intl/intl.dart';

/// Scrolling event-log ticker for the arena dashboard.
class EventLogPanel extends StatelessWidget {
  const EventLogPanel({super.key});

  static final _timeFmt = DateFormat.Hms();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      decoration: BoxDecoration(
        color: SparkTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SparkTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: SparkTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.list_alt, size: 16, color: SparkTheme.accent),
                const SizedBox(width: 8),
                const Text(
                  'EVENT LOG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SparkTheme.accent,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${game.events.length}',
                  style: TextStyle(color: SparkTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SparkTheme.border),

          // Event list
          Expanded(
            child: game.events.isEmpty
                ? Center(
                    child: Text(
                      'No events yet\nStart a game!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SparkTheme.muted, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: game.events.length,
                    itemBuilder: (context, i) {
                      final e = game.events[i];
                      return _EventRow(
                        event: e.event,
                        detail: e.detail,
                        time: _timeFmt.format(e.ts),
                        isNew: i == 0,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final String event;
  final String detail;
  final String time;
  final bool isNew;

  const _EventRow({
    required this.event,
    required this.detail,
    required this.time,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isNew ? SparkTheme.accent.withOpacity(0.05) : Colors.transparent,
      child: Row(
        children: [
          // Icon
          Icon(_icon, size: 16, color: _color),
          const SizedBox(width: 8),
          // Event type
          SizedBox(
            width: 80,
            child: Text(
              event,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Detail
          Expanded(
            child: Text(
              detail,
              style: TextStyle(
                fontSize: 12,
                color: SparkTheme.text.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Timestamp
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: SparkTheme.muted,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (event.toLowerCase()) {
      case 'point':
      case 'score':
        return Icons.star;
      case 'serve':
        return Icons.sports_tennis;
      case 'net':
      case 'let':
        return Icons.grid_on;
      case 'bounce':
        return Icons.blur_circular;
      case 'fault':
      case 'out':
        return Icons.warning_amber;
      case 'gameover':
        return Icons.emoji_events;
      default:
        return Icons.circle;
    }
  }

  Color get _color {
    switch (event.toLowerCase()) {
      case 'point':
      case 'score':
        return SparkTheme.green;
      case 'serve':
        return SparkTheme.yellow;
      case 'net':
      case 'let':
        return SparkTheme.accent;
      case 'fault':
      case 'out':
        return SparkTheme.red;
      case 'gameover':
        return SparkTheme.purple;
      default:
        return SparkTheme.muted;
    }
  }
}
