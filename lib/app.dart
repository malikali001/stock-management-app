import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class PsxPortfolioApp extends ConsumerStatefulWidget {
  const PsxPortfolioApp({super.key});

  @override
  ConsumerState<PsxPortfolioApp> createState() => _PsxPortfolioAppState();
}

class _PsxPortfolioAppState extends ConsumerState<PsxPortfolioApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PSX Portfolio Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
