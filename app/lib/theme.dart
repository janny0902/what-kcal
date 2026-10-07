import 'package:flutter/material.dart';

class AppColors {
  static const mint = Color(0xFF14C4B4);
  static const mintDeep = Color(0xFF0E9E92);
  static const mintSoft = Color(0xFFE7FAF6);
  static const headerTop = Color(0xFF3ADCCB);
  static const bg = Color(0xFFE7EEF0);
  static const ink = Color(0xFF243033);
  static const muted = Color(0xFF7D8D90);
  static const rose = Color(0xFFFF8FA3);
  static const line = Color(0xFFE4ECEE);
  static const card = Colors.white;
}

ThemeData appTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.mint, primary: AppColors.mint, surface: AppColors.card),
    fontFamily: null,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    splashFactory: NoSplash.splashFactory,
  );
}
