import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/models/player.dart';
import 'package:spark_app/providers/player_provider.dart';
import 'package:spark_app/screens/players/player_form_dialog.dart';
import 'package:spark_app/screens/players/player_stats_sheet.dart';

/// Player roster screen with CRUD and lifetime stats.
class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadPlayers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    final players = provider.players;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PLAYERS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Player',
            onPressed: () => _showForm(context),
          ),
        ],
      ),
      body: players.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: SparkTheme.border),
                  const SizedBox(height: 16),
                  Text(
                    'No players yet',
                    style: TextStyle(color: SparkTheme.muted, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Player'),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: players.length,
              itemBuilder: (context, i) => _PlayerCard(player: players[i]),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: SparkTheme.accent,
        foregroundColor: SparkTheme.bg,
        onPressed: () => _showForm(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showForm(BuildContext ctx, {Player? player}) {
    showDialog(
      context: ctx,
      builder: (_) => PlayerFormDialog(existing: player),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showStats(context),
        onLongPress: () => _showOptions(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: SparkTheme.surface,
                child: Text(
                  player.avatar,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                player.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: SparkTheme.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Quick stats
              _StatRow(Icons.emoji_events, '${player.totalWins} wins', SparkTheme.yellow),
              const SizedBox(height: 4),
              _StatRow(Icons.sports_score, '${player.totalPoints} pts', SparkTheme.accent),
              const SizedBox(height: 4),
              _StatRow(Icons.loop, 'Best rally ${player.longestRally}', SparkTheme.blue),
              const SizedBox(height: 4),
              _StatRow(Icons.gps_fixed, '${player.edgeAccuracy.toStringAsFixed(1)}% edge', SparkTheme.purple),
            ],
          ),
        ),
      ),
    );
  }

  void _showStats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SparkTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlayerStatsSheet(player: player),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SparkTheme.card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: SparkTheme.accent),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => PlayerFormDialog(existing: player),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: SparkTheme.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                context.read<PlayerProvider>().deletePlayer(player.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _StatRow(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: SparkTheme.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
