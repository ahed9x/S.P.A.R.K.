/// Represents one ball-impact event received from the ESP32 WebSocket.
class HitEvent {
  final double x;          // mm on table (0 = Side-A left corner)
  final double y;          // mm on table
  final double velocity;   // m/s estimate
  final String event;      // "paddle", "bounce", "net"
  final DateTime time;
  final int player;        // 0 = A, 1 = B, -1 = unknown

  HitEvent({
    required this.x,
    required this.y,
    this.velocity = 0,
    this.event = 'bounce',
    DateTime? time,
    this.player = -1,
  }) : time = time ?? DateTime.now();

  factory HitEvent.fromJson(Map<String, dynamic> j) {
    return HitEvent(
      x: (j['x'] as num).toDouble(),
      y: (j['y'] as num).toDouble(),
      velocity: (j['velocity'] as num?)?.toDouble() ?? 0,
      event: j['event'] as String? ?? 'bounce',
    );
  }
}
