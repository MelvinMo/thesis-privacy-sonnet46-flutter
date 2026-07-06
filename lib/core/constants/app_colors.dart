// MIGRATION: constants/Colors.ts → Dart Color constants.
//            Color hex values preserved exactly (pixel-perfect Rule 2).

import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Primary palette ──────────────────────────────────────────────────────
  // MIGRATION: Colors.background = '#1A1A2E' → Color(0xFF1A1A2E)
  static const Color background = Color(0xFF1A1A2E);

  // MIGRATION: Colors.generalBlue = '#39ACE7' from Colors.ts (exact match).
  static const Color generalBlue = Color(0xFF39ACE7);

  // MIGRATION: Colors.lightBlack = '#181719' — used for input cards on sleep screen.
  static const Color lightBlack = Color(0xFF181719);

  // ── Text colours ─────────────────────────────────────────────────────────
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFB0B0C8);
  static const Color mutedText = Color(0xFF8888AA);

  // ── Input fields ─────────────────────────────────────────────────────────
  // MIGRATION: input background #2A2A4A (inferred from screenshots; not in Colors.ts).
  static const Color inputBackground = Color(0xFF2A2A4A);
  static const Color inputBorder = Color(0xFF4A4A6A);

  // ── Privacy risk colours ─────────────────────────────────────────────────
  // MIGRATION: Colors.tooltipGreen/Yellow/Red from Colors.ts (exact hex match).
  static const Color privacyLow = Color(0xFFE0FFDF);    // tooltipGreen  #E0FFDF
  static const Color privacyMedium = Color(0xFFFFFD86); // tooltipYellow #FFFD86
  static const Color privacyHigh = Color(0xFFFD8686);   // tooltipRed    #FD8686

  // ── Hyperlink / tooltip ───────────────────────────────────────────────────
  // MIGRATION: Colors.hyperlinkBlue = '#4A90E2' from Colors.ts.
  static const Color hyperlinkBlue = Color(0xFF4A90E2);

  // MIGRATION: Colors.tooltipLinkBlue from Colors.ts.
  static const Color tooltipLinkBlue = Color(0xFF1565C0);

  // ── Tab bar ──────────────────────────────────────────────────────────────
  // MIGRATION: tabBarStyle.backgroundColor = Colors.lightBlack (#181719).
  //            tabBarInactiveTintColor = Colors.grey (#EBEBF580 = 50% opacity).
  static const Color tabBarBackground = Color(0xFF181719); // = lightBlack
  static const Color tabBarActive = generalBlue;
  static const Color tabBarInactive = Color(0x80EBEBF5);   // #EBEBF580

  // ── Cards / surfaces ─────────────────────────────────────────────────────
  static const Color cardBackground = Color(0xFF222244);
  static const Color cardBorder = Color(0xFF3A3A5A);

  // ── Button states ────────────────────────────────────────────────────────
  static const Color buttonDisabled = Color(0xFF3A3A5A);

  // ── Transparent overlays ─────────────────────────────────────────────────
  static const Color overlayDark = Color(0xAA000000);
  static const Color overlayLight = Color(0x22FFFFFF);
}
