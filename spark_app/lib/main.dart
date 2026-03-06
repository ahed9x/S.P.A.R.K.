import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spark_app/providers/connection_provider.dart';
import 'package:spark_app/providers/game_provider.dart';
import 'package:spark_app/providers/player_provider.dart';
import 'package:spark_app/providers/tournament_provider.dart';
import 'package:spark_app/services/database_service.dart';
import 'package:spark_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use FFI-based sqflite on desktop platforms (Windows/macOS/Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DatabaseService.instance.database; // warm-up

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProxyProvider<ConnectionProvider, GameProvider>(
          create: (_) => GameProvider(),
          update: (_, conn, game) => game!..linkConnection(conn),
        ),
        ChangeNotifierProvider(create: (_) => PlayerProvider()..loadPlayers()),
        ChangeNotifierProxyProvider<PlayerProvider, TournamentProvider>(
          create: (_) => TournamentProvider(),
          update: (_, players, tourney) => tourney!..linkPlayers(players),
        ),
      ],
      child: const SparkApp(),
    ),
  );
}
