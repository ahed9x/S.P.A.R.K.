import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:spark_app/models/hit_event.dart';
import 'package:spark_app/providers/connection_provider.dart';
import 'package:spark_app/services/websocket_service.dart';

/// Game-state provider: scores, hits, events — driven by WS messages.
class GameProvider extends ChangeNotifier {
  // Score
  int scoreA   = 0;
  int scoreB   = 0;
  int server   = 0;           // 0=A  1=B
  int gameState = 0;          // mirrors GameState enum on ESP32
  int rally    = 0;

  // Hits (for the heat map)
  final List<HitEvent> hits = [];
  static const int maxHits = 500;

  // Event log
  final List<GameEvent> events = [];
  static const int maxEvents = 200;

  // Piezo fire indicators (for calibration tap test)  [10 sensors]
  final List<bool> piezoFired = List.filled(10, false);
  Timer? _piezoResetTimer;

  // Game-over state
  bool isGameOver     = false;
  int  gameOverWinner = -1;

  // Internal subscriptions
  ConnectionProvider? _conn;
  final List<StreamSubscription> _subs = [];

  void linkConnection(ConnectionProvider conn) {
    if (_conn == conn) return;
    _cleanup();
    _conn = conn;
    final ws = conn.ws;

    _subs.add(ws.onState.listen(_onState));
    _subs.add(ws.onHit.listen(_onHit));
    _subs.add(ws.onEvent.listen(_onEvent));
    _subs.add(ws.onPiezo.listen(_onPiezo));
    _subs.add(ws.onGameOver.listen(_onGameOver));
  }

  void _onState(Map<String, dynamic> j) {
    scoreA    = (j['scoreA'] as num?)?.toInt() ?? scoreA;
    scoreB    = (j['scoreB'] as num?)?.toInt() ?? scoreB;
    server    = (j['server'] as num?)?.toInt() ?? server;
    gameState = (j['gameState'] as num?)?.toInt() ?? gameState;
    rally     = (j['rally'] as num?)?.toInt() ?? rally;
    notifyListeners();
  }

  void _onHit(Map<String, dynamic> j) {
    final hit = HitEvent.fromJson(j);
    hits.add(hit);
    if (hits.length > maxHits) hits.removeAt(0);
    notifyListeners();
  }

  void _onEvent(Map<String, dynamic> j) {
    events.insert(0, GameEvent(
      event:  j['event'] as String? ?? '',
      detail: j['detail'] as String? ?? '',
      ts:     DateTime.now(),
    ));
    if (events.length > maxEvents) events.removeLast();
    notifyListeners();
  }

  void _onPiezo(Map<String, dynamic> j) {
    final sensor = (j['sensor'] as num?)?.toInt() ?? 0;
    final node   = (j['node'] as num?)?.toInt() ?? 1;
    // Alpha sensors 0-3, Beta sensors 0-5 → offset Beta by 4
    final idx = node == 2 ? sensor + 4 : sensor;
    if (idx >= 0 && idx < piezoFired.length) {
      piezoFired[idx] = true;
      notifyListeners();
      // Auto-reset after 300 ms
      _piezoResetTimer?.cancel();
      _piezoResetTimer = Timer(const Duration(milliseconds: 300), () {
        for (int i = 0; i < piezoFired.length; i++) piezoFired[i] = false;
        notifyListeners();
      });
    }
  }

  void _onGameOver(Map<String, dynamic> j) {
    isGameOver     = true;
    gameOverWinner = (j['winner'] as num?)?.toInt() ?? -1;
    notifyListeners();
  }

  void clearGameOver() {
    isGameOver = false;
    gameOverWinner = -1;
    notifyListeners();
  }

  // ---------- commands ----------
  WebSocketService? get _ws => _conn?.ws;

  void startGame({int firstServer = 0}) {
    isGameOver = false;
    hits.clear();
    events.clear();
    _ws?.startGame(firstServer: firstServer);
  }

  void resetGame() {
    isGameOver = false;
    hits.clear();
    events.clear();
    _ws?.resetGame();
  }

  void _cleanup() {
    for (final s in _subs) s.cancel();
    _subs.clear();
  }

  @override
  void dispose() {
    _cleanup();
    _piezoResetTimer?.cancel();
    super.dispose();
  }
}

class GameEvent {
  final String event;
  final String detail;
  final DateTime ts;
  const GameEvent({required this.event, required this.detail, required this.ts});
}
