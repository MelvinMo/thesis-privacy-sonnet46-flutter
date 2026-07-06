// MIGRATION: services/TransparencyService.ts → Dart.
//            Logic: builds an AIPrompt and POSTs to /transparency/ai/,
//            returns the updated TransparencyEvent with AI-generated fields.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../core/models/transparency.dart';
import '../core/models/user_consent_preferences.dart';
import 'http_client.dart';

class TransparencyService {
  final AppHttpClient _httpClient;

  TransparencyService({required AppHttpClient httpClient})
      : _httpClient = httpClient;

  // MIGRATION: Source loads privacyPolicy and pipedaRegulations from JSON asset
  //            files at runtime. Flutter equivalent: rootBundle.loadString().
  Future<String> _loadPrivacyPolicy() async {
    try {
      return await rootBundle.loadString('assets/data/privacy_policy.json');
    } catch (_) {
      return '{}';
    }
  }

  Future<String> _loadPipedaRegulations() async {
    try {
      return await rootBundle
          .loadString('assets/data/pipeda_regulations.json');
    } catch (_) {
      return '{}';
    }
  }

  // ---------------------------------------------------------------------------
  // analyzePrivacyRisks — mirrors TransparencyService.analyzePrivacyRisks()
  // ---------------------------------------------------------------------------
  Future<TransparencyEvent> analyzePrivacyRisks(
    TransparencyEvent event,
    UserConsentPreferences consentPreferences,
  ) async {
    try {
      final privacyPolicy = await _loadPrivacyPolicy();
      final pipedaRegulations = await _loadPipedaRegulations();

      final prompt = AiPrompt(
        transparencyEvent: event,
        privacyPolicy: privacyPolicy,
        userConsentPreferences: consentPreferences,
        regulationFrameworks: [RegulatoryFramework.pipeda],
        pipedaRegulations: pipedaRegulations,
      );

      final response =
          await _httpClient.post('/api/transparency/ai/', prompt.toJson());

      // MIGRATION: Backend returns the updated TransparencyEvent as JSON.
      return TransparencyEvent.fromJson(
          response as Map<String, dynamic>? ?? {
            ...event.toJson(),
          });
    } catch (e) {
      // MIGRATION: Source has fire-and-forget with console.error on failure.
      //            Return the original event unchanged on error.
      return event;
    }
  }
}
