import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Low-level WebSocket transport to the ESP32 Master on port 81.
///
/// Exposes typed streams for each ESP32 message type so providers
/// can listen without parsing JSON themselves.
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  String _host = '';
  int _port = 81;
  bool _intentionalClose = false;

  // ---------- typed broadcast controllers ----------
  final _stateCtrl      = StreamController<Map<String, dynamic>>.broadcast();
  final _hitCtrl        = StreamController<Map<String, dynamic>>.broadcast();
  final _piezoCtrl      = StreamController<Map<String, dynamic>>.broadcast();
  final _envCtrl        = StreamController<Map<String, dynamic>>.broadcast();
  final _eventCtrl      = StreamController<Map<String, dynamic>>.broadcast();
  final _gameOverCtrl   = StreamController<Map<String, dynamic>>.broadcast();
  final _heartbeatCtrl  = StreamController<Map<String, dynamic>>.broadcast();
  final _calibTapCtrl   = StreamController<Map<String, dynamic>>.broadcast();
  final _hitHistoryCtrl = StreamController<List<dynamic>>.broadcast();
  final _rawCtrl        = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onState      => _stateCtrl.stream;
  Stream<Map<String, dynamic>> get onHit        => _hitCtrl.stream;
  Stream<Map<String, dynamic>> get onPiezo      => _piezoCtrl.stream;
  Stream<Map<String, dynamic>> get onEnv        => _envCtrl.stream;
  Stream<Map<String, dynamic>> get onEvent      => _eventCtrl.stream;
  Stream<Map<String, dynamic>> get onGameOver   => _gameOverCtrl.stream;
  Stream<Map<String, dynamic>> get onHeartbeat  => _heartbeatCtrl.stream;
  Stream<Map<String, dynamic>> get onCalibTap   => _calibTapCtrl.stream;
  Stream<List<dynamic>>        get onHitHistory => _hitHistoryCtrl.stream;
  Stream<Map<String, dynamic>> get onRaw        => _rawCtrl.stream;

  // ---------- connection state ----------
  final _connectedCtrl = StreamController<bool>.broadcast();
  Stream<bool> get onConnected => _connectedCtrl.stream;
  bool _connected = false;
  bool get isConnected => _connected;

  /// Connect to ws://<host>:<port>
  void connect(String host, {int port = 81}) {
    _host = host;
    _port = port;
    _intentionalClose = false;
    _doConnect();
  }

  void _doConnect() {
    _sub?.cancel();
    _channel?.sink.close();

    final uri = Uri.parse('ws://$_host:$_port');
    debugPrint('[WS] connecting to $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
    } catch (e) {
      debugPrint('[WS] connect error: $e');
      _scheduleReconnect();
      return;
    }

    _sub = _channel!.stream.listen(
      _onMessage,
      onDone: () {
        debugPrint('[WS] closed');
        _setConnected(false);
        if (!_intentionalClose) _scheduleReconnect();
      },
      onError: (e) {
        debugPrint('[WS] error: $e');
        _setConnected(false);
        if (!_intentionalClose) _scheduleReconnect();
      },
    );

    _setConnected(true);
  }

  void _setConnected(bool v) {
    _connected = v;
    _connectedCtrl.add(v);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), _doConnect);
  }

  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _setConnected(false);
  }

  // ---------- incoming ----------
  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _rawCtrl.add(j);

      switch (j['type'] as String?) {
        case 'state':
          _stateCtrl.add(j);
          break;
        case 'hit':
          _hitCtrl.add(j);
          break;
        case 'piezo':
          _piezoCtrl.add(j);
          break;
        case 'env':
          _envCtrl.add(j);
          break;
        case 'event':
          _eventCtrl.add(j);
          break;
        case 'gameOver':
          _gameOverCtrl.add(j);
          break;
        case 'heartbeat':
          _heartbeatCtrl.add(j);
          break;
        case 'calibTap':
          _calibTapCtrl.add(j);
          break;
        case 'hitHistory':
          _hitHistoryCtrl.add(j['hits'] as List<dynamic>);
          break;
      }
    } catch (e) {
      debugPrint('[WS] parse error: $e');
    }
  }

  // ---------- outgoing commands ----------
  void send(Map<String, dynamic> json) {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(jsonEncode(json));
  }

  void startGame({int firstServer = 0}) =>
      send({'cmd': 'start', 'firstServer': firstServer});

  void resetGame() => send({'cmd': 'reset'});

  void setLedMode(String mode) => send({'cmd': 'led', 'mode': mode});

  void setLedColor(int r, int g, int b) =>
      send({'cmd': 'ledColor', 'r': r, 'g': g, 'b': b});

  void playSound(String file) => send({'cmd': 'playSound', 'file': file});

  void requestEnv() => send({'cmd': 'getEnv'});

  void requestHitHistory() => send({'cmd': 'getHits'});

  void calibStart() => send({'cmd': 'calibStart'});

  void calibNext() => send({'cmd': 'calibNext'});

  void calibStop() => send({'cmd': 'calibStop'});

  void dispose() {
    disconnect();
    _stateCtrl.close();
    _hitCtrl.close();
    _piezoCtrl.close();
    _envCtrl.close();
    _eventCtrl.close();
    _gameOverCtrl.close();
    _heartbeatCtrl.close();
    _calibTapCtrl.close();
    _hitHistoryCtrl.close();
    _rawCtrl.close();
    _connectedCtrl.close();
  }
}
