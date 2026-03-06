import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/models/player.dart';
import 'package:spark_app/models/match_result.dart';
import 'package:spark_app/providers/player_provider.dart';
import 'package:spark_app/providers/tournament_provider.dart';
import 'package:spark_app/providers/connection_provider.dart';
import 'package:spark_app/screens/tournament/bracket_view.dart';

/// Tournament setup & bracket management screen.
class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final Set<String> _selected = {};
  int _bracketSize = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadPlayers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tourney = context.watch<TournamentProvider>();
    final players = context.watch<PlayerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tourney.isActive ? '⚡ TOURNAMENT' : 'NEW TOURNAMENT'),
        actions: [
          if (tourney.isActive)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: SparkTheme.red),
              tooltip: 'Cancel Tournament',
              onPressed: () {
                tourney.reset();
                _selected.clear();
              },
            ),
        ],
      ),
      body: tourney.isActive
          ? _ActiveTournament(tourney: tourney, players: players)
          : _SetupView(
              players: players.players,
              selected: _selected,
              bracketSize: _bracketSize,
              onBracketSizeChanged: (v) => setState(() => _bracketSize = v),
              onToggle: (id) => setState(() {
                if (_selected.contains(id)) {
                  _selected.remove(id);
                } else if (_selected.length < _bracketSize) {
                  _selected.add(id);
                }
              }),
              onStart: () {
                if (_selected.length != _bracketSize) return;
                final entrants = _selected
                    .map((id) => players.getById(id))
                    .where((p) => p != null)
                    .cast<Player>()
                    .toList();
                // Shuffle for random seeding
                entrants.shuffle();
                tourney.createBracket(entrants);
              },
            ),
    );
  }
}

// ---------- Setup (pick players) ----------

class _SetupView extends StatelessWidget {
  final List<Player> players;
  final Set<String> selected;
  final int bracketSize;
  final ValueChanged<int> onBracketSizeChanged;
  final ValueChanged<String> onToggle;
  final VoidCallback onStart;

  const _SetupView({
    required this.players,
    required this.selected,
    required this.bracketSize,
    required this.onBracketSizeChanged,
    required this.onToggle,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final ready = selected.length == bracketSize;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Bracket size toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Bracket size: ', style: TextStyle(color: SparkTheme.muted)),
              ChoiceChip(
                label: const Text('4 Players'),
                selected: bracketSize == 4,
                onSelected: (_) => onBracketSizeChanged(4),
                selectedColor: SparkTheme.accent.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('8 Players'),
                selected: bracketSize == 8,
                onSelected: (_) => onBracketSizeChanged(8),
                selectedColor: SparkTheme.accent.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${selected.length} / $bracketSize selected',
            style: TextStyle(
              color: ready ? SparkTheme.green : SparkTheme.yellow,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Player picker
          Expanded(
            child: players.isEmpty
                ? Center(
                    child: Text(
                      'No players — add some in the Players screen first',
                      style: TextStyle(color: SparkTheme.muted),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: players.length,
                    itemBuilder: (context, i) {
                      final p = players[i];
                      final isSel = selected.contains(p.id);
                      return _PickCard(
                        player: p,
                        isSelected: isSel,
                        onTap: () => onToggle(p.id),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: ready ? onStart : null,
              child: Text('Start Tournament ($bracketSize Players)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickCard({
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? SparkTheme.accent.withOpacity(0.1)
              : SparkTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? SparkTheme.accent : SparkTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(player.avatar, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              player.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? SparkTheme.accent : SparkTheme.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle, color: SparkTheme.accent, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------- Active tournament ----------

class _ActiveTournament extends StatelessWidget {
  final TournamentProvider tourney;
  final PlayerProvider players;

  const _ActiveTournament({required this.tourney, required this.players});

  @override
  Widget build(BuildContext context) {
    if (tourney.isComplete) {
      return _ChampionView(champion: tourney.champion, tourney: tourney);
    }

    return Column(
      children: [
        // Bracket visualisation
        Expanded(child: BracketView(rounds: tourney.rounds)),

        // Current match info
        if (tourney.currentMatch != null) _CurrentMatchBar(match: tourney.currentMatch!, tourney: tourney),
      ],
    );
  }
}

class _CurrentMatchBar extends StatelessWidget {
  final BracketMatch match;
  final TournamentProvider tourney;

  const _CurrentMatchBar({required this.match, required this.tourney});

  @override
  Widget build(BuildContext context) {
    final a = match.slotA.player;
    final b = match.slotB.player;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SparkTheme.card,
        border: Border(top: BorderSide(color: SparkTheme.border)),
      ),
      child: Column(
        children: [
          Text(
            'Round ${match.roundIndex + 1} — Match ${match.matchIndex + 1}',
            style: TextStyle(color: SparkTheme.muted, fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${a?.avatar ?? "?"} ${a?.name ?? "TBD"}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SparkTheme.playerA,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('VS', style: TextStyle(color: SparkTheme.muted, fontWeight: FontWeight.w800)),
              ),
              Text(
                '${b?.name ?? "TBD"} ${b?.avatar ?? "?"}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SparkTheme.playerB,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScoreButton(
                label: '${a?.name ?? "A"} wins',
                color: SparkTheme.playerA,
                onPressed: () => tourney.recordMatchResult(11, 0),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => _showScoreEntry(context),
                child: const Text('Enter Score'),
              ),
              const SizedBox(width: 16),
              _ScoreButton(
                label: '${b?.name ?? "B"} wins',
                color: SparkTheme.playerB,
                onPressed: () => tourney.recordMatchResult(0, 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showScoreEntry(BuildContext context) {
    int sA = 0, sB = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: SparkTheme.card,
          title: const Text('Enter Score', style: TextStyle(color: SparkTheme.accent)),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScoreInput(
                label: match.slotA.player?.name ?? 'A',
                color: SparkTheme.playerA,
                value: sA,
                onChanged: (v) => setS(() => sA = v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(':', style: TextStyle(fontSize: 28, color: SparkTheme.muted)),
              ),
              _ScoreInput(
                label: match.slotB.player?.name ?? 'B',
                color: SparkTheme.playerB,
                value: sB,
                onChanged: (v) => setS(() => sB = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: sA != sB
                  ? () {
                      tourney.recordMatchResult(sA, sB);
                      Navigator.pop(ctx);
                      // LED victory + sound on match end
                      if (context.mounted) {
                        final conn = context.read<ConnectionProvider>();
                        conn.ws.setLedMode('victory');
                        conn.ws.playSound('victory.wav');
                      }
                    }
                  : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreInput extends StatelessWidget {
  final String label;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;

  const _ScoreInput({
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: color,
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text(
              '$value',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: color,
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ScoreButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: SparkTheme.bg,
      ),
      child: Text(label),
    );
  }
}

class _ChampionView extends StatelessWidget {
  final Player? champion;
  final TournamentProvider tourney;

  const _ChampionView({required this.champion, required this.tourney});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(
            'CHAMPION',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: SparkTheme.yellow,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 12),
          if (champion != null) ...[
            Text(
              champion!.avatar,
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 8),
            Text(
              champion!.name,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: SparkTheme.accent,
              ),
            ),
          ],
          const SizedBox(height: 32),
          // View bracket
          Expanded(child: BracketView(rounds: tourney.rounds)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () => tourney.reset(),
              child: const Text('New Tournament'),
            ),
          ),
        ],
      ),
    );
  }
}
