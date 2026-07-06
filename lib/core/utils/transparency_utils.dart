// MIGRATION: utils/transparency.ts → Dart.
//            Replaces: getPrivacyRiskColor, getPrivacyRiskIcon,
//                      getPrivacyRiskLabel, formatPrivacyViolations,
//                      handleLinkPress, getPrivacyRiskIconForPage.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../models/transparency.dart';

// MIGRATION: TS `getPrivacyRiskColor(risk: PrivacyRisk) => string` →
//            returns Flutter Color. Colors.ts hex values preserved (Rule 2).
Color getPrivacyRiskColor(PrivacyRisk? risk) {
  return switch (risk) {
    PrivacyRisk.low => AppColors.privacyLow,
    PrivacyRisk.medium => AppColors.privacyMedium,
    PrivacyRisk.high => AppColors.privacyHigh,
    null => AppColors.privacyLow,
  };
}

// MIGRATION: TS `getPrivacyRiskIcon(risk) => string` image name →
//            Dart returns asset path string used in Image.asset().
String getPrivacyRiskIcon(PrivacyRisk? risk) {
  return switch (risk) {
    PrivacyRisk.high => 'assets/images/privacy/privacy-high.png',
    PrivacyRisk.medium => 'assets/images/privacy/privacy-medium.png',
    _ => 'assets/images/privacy/privacy-low.png',
  };
}

// MIGRATION: `getPrivacyRiskIconForPage` accepts a list of risks and returns
//            the highest-severity icon path (same logic as source).
String getPrivacyRiskIconForPage(List<PrivacyRisk?> risks) {
  if (risks.contains(PrivacyRisk.high)) return getPrivacyRiskIcon(PrivacyRisk.high);
  if (risks.contains(PrivacyRisk.medium)) return getPrivacyRiskIcon(PrivacyRisk.medium);
  return getPrivacyRiskIcon(PrivacyRisk.low);
}

// MIGRATION: TS `getPrivacyRiskLabel(risk) => string` → Dart String.
//            Labels match transparency.ts exactly.
String getPrivacyRiskLabel(PrivacyRisk? risk) {
  return switch (risk) {
    PrivacyRisk.low => 'No Privacy Violations Detected',
    PrivacyRisk.medium => 'Some Privacy Concerns Detected:',
    PrivacyRisk.high => 'Major Privacy Violation Detected:',
    null => 'No Privacy Violations Detected',
  };
}

// MIGRATION: TS `formatPrivacyViolations(transparency) => string` →
//            Returns the privacyExplanation string (AI-generated).
String formatPrivacyViolations(TransparencyEvent transparency) {
  return transparency.aiExplanation?.privacyExplanation ?? '';
}

// MIGRATION: TS `handleLinkPress(regulationLink) => opens PIPEDA link` →
//            uses url_launcher (replaces expo-web-browser / Linking).
Future<void> handleLinkPress(String? link) async {
  if (link == null || link.isEmpty) return;

  // MIGRATION_FLAG: Source opens a PIPEDA regulation URL using expo-linking.
  //                 The exact base URL is not in the source code.
  //                 Using a hardcoded PIPEDA base URL as placeholder.
  //                 Update to match the actual backend-provided URL.
  final pipedaBase = 'https://www.priv.gc.ca/en/privacy-topics/privacy-laws-in-canada/the-personal-information-protection-and-electronic-documents-act-pipeda/p_principle/';
  final uri = Uri.tryParse(link.startsWith('http') ? link : '$pipedaBase$link');
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
