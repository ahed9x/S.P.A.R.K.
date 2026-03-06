import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:spark_app/models/player.dart';
import 'package:spark_app/models/match_result.dart';

/// Singleton SQLite database for persistent player profiles & match history.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'spark.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE players (
            id          TEXT PRIMARY KEY,
            name        TEXT NOT NULL,
            avatar      TEXT NOT NULL DEFAULT '🏓',
            totalWins   INTEGER NOT NULL DEFAULT 0,
            totalPoints INTEGER NOT NULL DEFAULT 0,
            longestRally INTEGER NOT NULL DEFAULT 0,
            edgeHits    INTEGER NOT NULL DEFAULT 0,
            totalHits   INTEGER NOT NULL DEFAULT 0,
            createdAt   TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE matches (
            id            TEXT PRIMARY KEY,
            playerAId     TEXT NOT NULL,
            playerBId     TEXT NOT NULL,
            scoreA        INTEGER NOT NULL,
            scoreB        INTEGER NOT NULL,
            longestRally  INTEGER NOT NULL DEFAULT 0,
            playedAt      TEXT NOT NULL,
            tournamentId  TEXT,
            FOREIGN KEY (playerAId) REFERENCES players(id),
            FOREIGN KEY (playerBId) REFERENCES players(id)
          )
        ''');
      },
    );
  }

  // ========================  PLAYERS  ========================

  Future<List<Player>> getPlayers() async {
    final db = await database;
    final rows = await db.query('players', orderBy: 'name ASC');
    return rows.map((r) => Player.fromMap(r)).toList();
  }

  Future<Player?> getPlayer(String id) async {
    final db = await database;
    final rows = await db.query('players', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Player.fromMap(rows.first);
  }

  Future<void> upsertPlayer(Player p) async {
    final db = await database;
    await db.insert('players', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePlayer(String id) async {
    final db = await database;
    await db.delete('players', where: 'id = ?', whereArgs: [id]);
  }

  // ========================  MATCHES  ========================

  Future<void> insertMatch(MatchResult m) async {
    final db = await database;
    await db.insert('matches', m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MatchResult>> getMatchesForPlayer(String playerId) async {
    final db = await database;
    final rows = await db.query('matches',
        where: 'playerAId = ? OR playerBId = ?',
        whereArgs: [playerId, playerId],
        orderBy: 'playedAt DESC');
    return rows.map((r) => MatchResult.fromMap(r)).toList();
  }

  Future<List<MatchResult>> getAllMatches() async {
    final db = await database;
    final rows = await db.query('matches', orderBy: 'playedAt DESC');
    return rows.map((r) => MatchResult.fromMap(r)).toList();
  }
}
