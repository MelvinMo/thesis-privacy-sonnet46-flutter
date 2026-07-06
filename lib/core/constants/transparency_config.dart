// MIGRATION: constants/config/transparencyConfig.ts → Dart abstract class with
//            static constants. Dart has no top-level `const` module exports so
//            grouped under a class for clarity; semantics are identical.

abstract class TransparencyConfig {
  // MIGRATION: `IN_DEMO_MODE = true` (toggles demo sensor fakes + encryption flag).
  //            Preserved exactly. Rule 7 requires demo mode preserved.
  static const bool inDemoMode = true;

  // MIGRATION: transparencyDemoConfig object → nested class constants.
  static const bool demoCollectAudio = false;
  static const bool demoCollectLight = false;
  static const bool demoCollectAccelerometer = false;
  static const bool demoEncryptedAtRest = false;
  // false = locally running backend used (HTTP); true = deployed HTTPS backend.
  static const bool demoEncryptedInTransit = false;

  // MIGRATION: TRANSPARENCY_UI_CONFIG object → individual constants.
  static const bool journalTooltipEnabled = true;
  static const bool sleepPageTooltipEnabled = true;
  static const bool sleepModeTooltipEnabled = true;

  // ── Derived helpers ────────────────────────────────────────────────────
  // MIGRATION: The TS EncryptionService checks:
  //   `!IN_DEMO_MODE ? AES_256 : (encryptedAtRest ? AES_256 : NONE)`
  //   Centralised here so EncryptionService just reads this flag.
  static bool get encryptDataAtRest =>
      !inDemoMode ? true : demoEncryptedAtRest;

  static bool get useEncryptedTransit =>
      !inDemoMode ? true : demoEncryptedInTransit;

  // ── Sensor collection flags (used by SensorRepository) ────────────────
  static bool get collectAudio =>
      !inDemoMode ? true : demoCollectAudio;

  static bool get collectLight =>
      !inDemoMode ? true : demoCollectLight;

  static bool get collectAccelerometer =>
      !inDemoMode ? true : demoCollectAccelerometer;
}
