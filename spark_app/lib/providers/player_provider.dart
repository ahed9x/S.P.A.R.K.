import 'package:flutter/foundation.dart';
import 'package:spark_app/models/player.dart';
import 'package:spark_app/services/database_service.dart';

/// CRUD provider for the persistent player database.
class PlayerProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  List<Player> players = [];

  Future<void> loadPlayers() async {
    players = await _db.getPlayers();
    notifyListeners();
  }

  Future<void> addPlayer(Player p) async {
    await _db.upsertPlayer(p);
    await loadPlayers();
  }

  Future<void> updatePlayer(Player p) async {
    await _db.upsertPlayer(p);
    await loadPlayers();
  }

  Future<void> deletePlayer(String id) async {
    await _db.deletePlayer(id);
    await loadPlayers();
  }

  Player? getById(String id) {
    try { return players.firstWhere((p) => p.id == id); }
    catch (_) { return null; }
  }

  /// Record a game result — update lifetime stats for both players.
  Future<void> recordResult({
    required String winnerId,
    required String loserId,
    required int winnerPoints,
    required int loserPoints,
    required int longestRally,
  }) async {
    final w = getById(winnerId);
    final l = getById(loserId);
    if (w != null) {
      w.totalWins++;
      w.totalPoints += winnerPoints;
      if (longestRally > w.longestRally) w.longestRally = longestRally;
      await _db.upsertPlayer(w);
    }
    if (l != null) {
      l.totalPoints += loserPoints;
      if (longestRally > l.longestRally) l.longestRally = longestRally;
      await _db.upsertPlayer(l);
    }
    await loadPlayers();
  }
}
