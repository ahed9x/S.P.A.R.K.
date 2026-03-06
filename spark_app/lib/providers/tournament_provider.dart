import 'package:flutter/foundation.dart';
import 'package:spark_app/models/player.dart';
import 'package:spark_app/models/match_result.dart';
import 'package:spark_app/providers/player_provider.dart';

/// Single-elimination tournament engine (4 or 8 players).
class TournamentProvider extends ChangeNotifier {
  PlayerProvider? _players;
  void linkPlayers(PlayerProvider p) => _players = p;

  bool get isActive => _rounds.isNotEmpty;
  String? tournamentId;

  // Bracket structure: list of rounds, each round has matches.
  List<List<BracketMatch>> _rounds = [];
  List<List<BracketMatch>> get rounds => _rounds;

  int get totalRounds => _rounds.length;
  BracketMatch? _currentMatch;
  BracketMatch? get currentMatch => _currentMatch;

  /// Generate a single-elimination bracket for [entrants].
  void createBracket(List<Player> entrants) {
    assert(entrants.length == 4 || entrants.length == 8);
    tournamentId = DateTime.now().millisecondsSinceEpoch.toString();
    final n = entrants.length;
    final numRounds = n == 4 ? 2 : 3;
    _rounds = List.generate(numRounds, (_) => []);

    // Seed first round
    for (int i = 0; i < n ~/ 2; i++) {
      _rounds[0].add(BracketMatch(
        roundIndex: 0,
        matchIndex: i,
        slotA: BracketSlot(player: entrants[i * 2]),
        slotB: BracketSlot(player: entrants[i * 2 + 1]),
      ));
    }

    // Placeholder matches for subsequent rounds
    for (int r = 1; r < numRounds; r++) {
      final matchCount = n ~/ (2 << r);
      for (int m = 0; m < matchCount; m++) {
        _rounds[r].add(BracketMatch(roundIndex: r, matchIndex: m));
      }
    }

    _currentMatch = _rounds[0][0];
    notifyListeners();
  }

  /// Record the result of the current bracket match.
  void recordMatchResult(int scoreA, int scoreB) {
    if (_currentMatch == null) return;
    final match = _currentMatch!;
    match.slotA.score = scoreA;
    match.slotB.score = scoreB;
    match.completed = true;

    final aWins = scoreA > scoreB;
    match.slotA.isWinner = aWins;
    match.slotB.isWinner = !aWins;
    final winner = aWins ? match.slotA.player : match.slotB.player;

    // Update player stats via provider
    if (_players != null && match.slotA.player != null && match.slotB.player != null) {
      _players!.recordResult(
        winnerId: winner!.id,
        loserId: (aWins ? match.slotB.player! : match.slotA.player!).id,
        winnerPoints: aWins ? scoreA : scoreB,
        loserPoints: aWins ? scoreB : scoreA,
        longestRally: 0,
      );
    }

    // Advance winner into next round
    final r = match.roundIndex;
    final m = match.matchIndex;
    if (r + 1 < _rounds.length) {
      final nextMatch = _rounds[r + 1][m ~/ 2];
      if (m % 2 == 0) {
        nextMatch.slotA = BracketSlot(player: winner);
      } else {
        nextMatch.slotB = BracketSlot(player: winner);
      }
    }

    // Find next unplayed match
    _currentMatch = _findNextMatch();
    notifyListeners();
  }

  BracketMatch? _findNextMatch() {
    for (final round in _rounds) {
      for (final match in round) {
        if (!match.completed &&
            match.slotA.player != null &&
            match.slotB.player != null) {
          return match;
        }
      }
    }
    return null; // tournament complete
  }

  bool get isComplete => _currentMatch == null && _rounds.isNotEmpty;

  Player? get champion {
    if (!isComplete) return null;
    final finalMatch = _rounds.last.last;
    return finalMatch.winner;
  }

  void reset() {
    _rounds = [];
    _currentMatch = null;
    tournamentId = null;
    notifyListeners();
  }
}
