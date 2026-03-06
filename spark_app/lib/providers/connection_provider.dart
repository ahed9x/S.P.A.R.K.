import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:spark_app/services/websocket_service.dart';

/// Manages the WebSocket connection to the ESP32 and exposes env data.
class ConnectionProvider extends ChangeNotifier {
  final WebSocketService ws = WebSocketService();

  bool _connected = false;
  bool get connected => _connected;

  String _host = '';
  String get host => _host;

  // BME680 environment
  double temperature   = 0;
  double humidity       = 0;
  double pressure       = 0;
  double speedOfSound   = 343;
  int    fanPWM         = 0;
  bool   calibMode      = false;
  int    calibStep      = 0;

  StreamSubscription? _connSub;
  StreamSubscription? _envSub;

  ConnectionProvider() {
    _connSub = ws.onConnected.listen((v) {
      _connected = v;
      notifyListeners();
    });
    _envSub = ws.onEnv.listen((j) {
      temperature  = (j['temp'] as num?)?.toDouble() ?? temperature;
      humidity     = (j['humidity'] as num?)?.toDouble() ?? humidity;
      pressure     = (j['pressure'] as num?)?.toDouble() ?? pressure;
      speedOfSound = (j['speedOfSound'] as num?)?.toDouble() ?? speedOfSound;
      fanPWM       = (j['fanPWM'] as num?)?.toInt() ?? fanPWM;
      calibMode    = j['calibMode'] as bool? ?? false;
      calibStep    = (j['calibStep'] as num?)?.toInt() ?? 0;
      notifyListeners();
    });
  }

  void connect(String host, {int port = 81}) {
    _host = host;
    ws.connect(host, port: port);
  }

  void disconnect() {
    ws.disconnect();
    _connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _envSub?.cancel();
    ws.dispose();
    super.dispose();
  }
}
