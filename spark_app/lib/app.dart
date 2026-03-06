import 'package:flutter/material.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/screens/home_screen.dart';

class SparkApp extends StatelessWidget {
  const SparkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPARK',
      debugShowCheckedModeBanner: false,
      theme: SparkTheme.dark,
      home: const HomeScreen(),
    );
  }
}
