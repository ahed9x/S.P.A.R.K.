import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Persistent player profile stored in local SQLite.
class Player {
  final String id;
  String name;
  String avatar;       // emoji or asset key
  int totalWins;
  int totalPoints;
  int longestRally;
  int edgeHits;        // hits within 50 mm of table edge
  int totalHits;       // all hits
  DateTime createdAt;

  Player({
    String? id,
    required this.name,
    this.avatar = '🏓',
    this.totalWins = 0,
    this.totalPoints = 0,
    this.longestRally = 0,
    this.edgeHits = 0,
    this.totalHits = 0,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  double get edgeAccuracy =>
      totalHits > 0 ? (edgeHits / totalHits * 100) : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'totalWins': totalWins,
        'totalPoints': totalPoints,
        'longestRally': longestRally,
        'edgeHits': edgeHits,
        'totalHits': totalHits,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Player.fromMap(Map<String, dynamic> m) => Player(
        id: m['id'] as String,
        name: m['name'] as String,
        avatar: m['avatar'] as String? ?? '🏓',
        totalWins: m['totalWins'] as int? ?? 0,
        totalPoints: m['totalPoints'] as int? ?? 0,
        longestRally: m['longestRally'] as int? ?? 0,
        edgeHits: m['edgeHits'] as int? ?? 0,
        totalHits: m['totalHits'] as int? ?? 0,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  bool operator ==(Object other) => other is Player && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
