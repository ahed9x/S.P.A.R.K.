import 'player.dart';

/// A completed match result, persisted to SQLite.
class MatchResult {
  final String id;
  final String playerAId;
  final String playerBId;
  final int scoreA;
  final int scoreB;
  final int longestRally;
  final DateTime playedAt;
  final String? tournamentId;

  MatchResult({
    required this.id,
    required this.playerAId,
    required this.playerBId,
    required this.scoreA,
    required this.scoreB,
    this.longestRally = 0,
    DateTime? playedAt,
    this.tournamentId,
  }) : playedAt = playedAt ?? DateTime.now();

  String get winnerId => scoreA > scoreB ? playerAId : playerBId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'playerAId': playerAId,
        'playerBId': playerBId,
        'scoreA': scoreA,
        'scoreB': scoreB,
        'longestRally': longestRally,
        'playedAt': playedAt.toIso8601String(),
        'tournamentId': tournamentId,
      };

  factory MatchResult.fromMap(Map<String, dynamic> m) => MatchResult(
        id: m['id'] as String,
        playerAId: m['playerAId'] as String,
        playerBId: m['playerBId'] as String,
        scoreA: m['scoreA'] as int,
        scoreB: m['scoreB'] as int,
        longestRally: m['longestRally'] as int? ?? 0,
        playedAt:
            DateTime.tryParse(m['playedAt'] as String? ?? '') ?? DateTime.now(),
        tournamentId: m['tournamentId'] as String?,
      );
}

/// A single bracket slot in the tournament.
class BracketSlot {
  Player? player;
  int score;
  bool isWinner;

  BracketSlot({this.player, this.score = 0, this.isWinner = false});
}

/// One round-of match in the bracket (pair of slots).
class BracketMatch {
  final int roundIndex;
  final int matchIndex;
  BracketSlot slotA;
  BracketSlot slotB;
  bool completed;

  BracketMatch({
    required this.roundIndex,
    required this.matchIndex,
    BracketSlot? slotA,
    BracketSlot? slotB,
    this.completed = false,
  })  : slotA = slotA ?? BracketSlot(),
        slotB = slotB ?? BracketSlot();

  Player? get winner {
    if (!completed) return null;
    return slotA.isWinner ? slotA.player : slotB.player;
  }
}
