// MIGRATION: TypeScript enums → Dart enums (Dart enums are first-class types,
//            no numeric backing needed). String .name / toString() replaces
//            TS enum string literals for JSON serialisation.
//
//            TypeScript interfaces → Dart classes with named constructors,
//            copyWith(), fromJson(), toJson() for SharedPreferences persistence.
//            `any` / unknown fields → typed or removed (Rule 3: no `dynamic`
//            unless truly unavoidable — userRiskTolerance is the only exception).

import 'package:privacy_transparency_sleep_tracker/core/models/user_consent_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Enums
// ═══════════════════════════════════════════════════════════════════════════

enum DataType {
  sensorAudio,   // 'SENSOR_AUDIO'
  sensorMotion,  // 'SENSOR_MOTION'
  sensorLight,   // 'SENSOR_LIGHT'
  userJournal,   // 'USER_JOURNAL'
  userProfile,   // 'USER_PROFILE'
  generalSleep,  // 'GENERAL_SLEEP'
  sleepStatistics,
  deviceInfo,
  location,
  usageAnalytics,
}

// MIGRATION: TS string enum serialisation: DataType.SENSOR_AUDIO →
//            Dart extension .toJson() / DataType.fromJson() helpers below.
extension DataTypeJson on DataType {
  String toJson() {
    const map = {
      DataType.sensorAudio: 'SENSOR_AUDIO',
      DataType.sensorMotion: 'SENSOR_MOTION',
      DataType.sensorLight: 'SENSOR_LIGHT',
      DataType.userJournal: 'USER_JOURNAL',
      DataType.userProfile: 'USER_PROFILE',
      DataType.generalSleep: 'GENERAL_SLEEP',
      DataType.sleepStatistics: 'SLEEP_STATISTICS',
      DataType.deviceInfo: 'DEVICE_INFO',
      DataType.location: 'LOCATION',
      DataType.usageAnalytics: 'USAGE_ANALYTICS',
    };
    return map[this]!;
  }

  static DataType fromJson(String v) {
    const map = {
      'SENSOR_AUDIO': DataType.sensorAudio,
      'SENSOR_MOTION': DataType.sensorMotion,
      'SENSOR_LIGHT': DataType.sensorLight,
      'USER_JOURNAL': DataType.userJournal,
      'USER_PROFILE': DataType.userProfile,
      'GENERAL_SLEEP': DataType.generalSleep,
      'SLEEP_STATISTICS': DataType.sleepStatistics,
      'DEVICE_INFO': DataType.deviceInfo,
      'LOCATION': DataType.location,
      'USAGE_ANALYTICS': DataType.usageAnalytics,
    };
    return map[v] ?? DataType.sensorAudio;
  }
}

// ---------------------------------------------------------------------------

enum DataSource {
  microphone,
  accelerometer,
  lightSensor,
  userInput,
  derivedData,
  systemInfo,
}

extension DataSourceJson on DataSource {
  String toJson() {
    const map = {
      DataSource.microphone: 'MICROPHONE',
      DataSource.accelerometer: 'ACCELEROMETER',
      DataSource.lightSensor: 'LIGHT_SENSOR',
      DataSource.userInput: 'USER_INPUT',
      DataSource.derivedData: 'DERIVED_DATA',
      DataSource.systemInfo: 'SYSTEM_INFO',
    };
    return map[this]!;
  }

  static DataSource fromJson(String v) {
    const map = {
      'MICROPHONE': DataSource.microphone,
      'ACCELEROMETER': DataSource.accelerometer,
      'LIGHT_SENSOR': DataSource.lightSensor,
      'USER_INPUT': DataSource.userInput,
      'DERIVED_DATA': DataSource.derivedData,
      'SYSTEM_INFO': DataSource.systemInfo,
    };
    return map[v] ?? DataSource.userInput;
  }
}

// ---------------------------------------------------------------------------

enum DataDestination {
  asyncStorage,   // SharedPreferences in Flutter
  secureStore,    // flutter_secure_storage
  sqliteDb,
  memory,
  googleCloud,
  thirdParty,
}

extension DataDestinationJson on DataDestination {
  String toJson() {
    const map = {
      DataDestination.asyncStorage: 'ASYNC_STORAGE',
      DataDestination.secureStore: 'SECURE_STORE',
      DataDestination.sqliteDb: 'SQLITE_DB',
      DataDestination.memory: 'MEMORY',
      DataDestination.googleCloud: 'GOOGLE_CLOUD',
      DataDestination.thirdParty: 'THIRD_PARTY',
    };
    return map[this]!;
  }

  static DataDestination fromJson(String v) {
    const map = {
      'ASYNC_STORAGE': DataDestination.asyncStorage,
      'SECURE_STORE': DataDestination.secureStore,
      'SQLITE_DB': DataDestination.sqliteDb,
      'MEMORY': DataDestination.memory,
      'GOOGLE_CLOUD': DataDestination.googleCloud,
      'THIRD_PARTY': DataDestination.thirdParty,
    };
    return map[v] ?? DataDestination.sqliteDb;
  }
}

// ---------------------------------------------------------------------------

enum EncryptionMethod { none, aes256, jwt, deviceKeychain }

extension EncryptionMethodJson on EncryptionMethod {
  String toJson() {
    const map = {
      EncryptionMethod.none: 'NONE',
      EncryptionMethod.aes256: 'AES_256',
      EncryptionMethod.jwt: 'JWT',
      EncryptionMethod.deviceKeychain: 'DEVICE_KEYCHAIN',
    };
    return map[this]!;
  }

  static EncryptionMethod fromJson(String v) {
    const map = {
      'NONE': EncryptionMethod.none,
      'AES_256': EncryptionMethod.aes256,
      'JWT': EncryptionMethod.jwt,
      'DEVICE_KEYCHAIN': EncryptionMethod.deviceKeychain,
    };
    return map[v] ?? EncryptionMethod.none;
  }
}

// ---------------------------------------------------------------------------

enum PrivacyRisk { low, medium, high }

extension PrivacyRiskJson on PrivacyRisk {
  String toJson() {
    const map = {
      PrivacyRisk.low: 'LOW',
      PrivacyRisk.medium: 'MEDIUM',
      PrivacyRisk.high: 'HIGH',
    };
    return map[this]!;
  }

  static PrivacyRisk fromJson(String v) {
    const map = {
      'LOW': PrivacyRisk.low,
      'MEDIUM': PrivacyRisk.medium,
      'HIGH': PrivacyRisk.high,
    };
    return map[v] ?? PrivacyRisk.low;
  }
}

// ---------------------------------------------------------------------------

enum RegulatoryFramework {
  // MIGRATION: Original TS note — PIPEDA is the focus; others for extensibility.
  pipeda,
  phipa,
  gdpr,
}

extension RegulatoryFrameworkJson on RegulatoryFramework {
  String toJson() => name.toUpperCase();
  static RegulatoryFramework fromJson(String v) {
    return RegulatoryFramework.values.firstWhere(
      (e) => e.name.toUpperCase() == v,
      orElse: () => RegulatoryFramework.pipeda,
    );
  }
}

// ---------------------------------------------------------------------------
// MIGRATION: TS enums for protocol literal union type 'HTTP'|'HTTPS'|'WSS'
//            → Dart enum (avoids stringly-typed comparisons).
// ---------------------------------------------------------------------------
enum TransmissionProtocol { http, https, wss }

extension TransmissionProtocolJson on TransmissionProtocol {
  String toJson() => name.toUpperCase();
  static TransmissionProtocol fromJson(String v) {
    return TransmissionProtocol.values.firstWhere(
      (e) => e.name.toUpperCase() == v,
      orElse: () => TransmissionProtocol.https,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Value objects
// ═══════════════════════════════════════════════════════════════════════════

class RegulatoryCompliance {
  final RegulatoryFramework framework;
  final bool compliant;
  final String? issues;
  final List<String> relevantSections;

  const RegulatoryCompliance({
    required this.framework,
    required this.compliant,
    this.issues,
    this.relevantSections = const [],
  });

  RegulatoryCompliance copyWith({
    RegulatoryFramework? framework,
    bool? compliant,
    String? issues,
    List<String>? relevantSections,
  }) =>
      RegulatoryCompliance(
        framework: framework ?? this.framework,
        compliant: compliant ?? this.compliant,
        issues: issues ?? this.issues,
        relevantSections: relevantSections ?? this.relevantSections,
      );

  factory RegulatoryCompliance.fromJson(Map<String, dynamic> json) =>
      RegulatoryCompliance(
        framework: RegulatoryFrameworkJson.fromJson(json['framework'] as String),
        compliant: json['compliant'] as bool,
        issues: json['issues'] as String?,
        relevantSections: (json['relevantSections'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'framework': framework.toJson(),
        'compliant': compliant,
        if (issues != null) 'issues': issues,
        'relevantSections': relevantSections,
      };
}

// ---------------------------------------------------------------------------

class AiExplanation {
  final String why;
  final String storage;
  final String access;
  final String privacyExplanation;
  final List<String> privacyPolicyLink;
  final List<String> regulationLink;

  const AiExplanation({
    required this.why,
    required this.storage,
    required this.access,
    required this.privacyExplanation,
    this.privacyPolicyLink = const [],
    this.regulationLink = const [],
  });

  AiExplanation copyWith({
    String? why,
    String? storage,
    String? access,
    String? privacyExplanation,
    List<String>? privacyPolicyLink,
    List<String>? regulationLink,
  }) =>
      AiExplanation(
        why: why ?? this.why,
        storage: storage ?? this.storage,
        access: access ?? this.access,
        privacyExplanation: privacyExplanation ?? this.privacyExplanation,
        privacyPolicyLink: privacyPolicyLink ?? this.privacyPolicyLink,
        regulationLink: regulationLink ?? this.regulationLink,
      );

  factory AiExplanation.fromJson(Map<String, dynamic> json) => AiExplanation(
        why: json['why'] as String? ?? '',
        storage: json['storage'] as String? ?? '',
        access: json['access'] as String? ?? '',
        privacyExplanation: json['privacyExplanation'] as String? ?? '',
        privacyPolicyLink: (json['privacyPolicyLink'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        regulationLink: (json['regulationLink'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'why': why,
        'storage': storage,
        'access': access,
        'privacyExplanation': privacyExplanation,
        'privacyPolicyLink': privacyPolicyLink,
        'regulationLink': regulationLink,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// TransparencyEvent — the core domain object
// ═══════════════════════════════════════════════════════════════════════════

class TransparencyEvent {
  final DateTime? timestamp;
  final DataType dataType;
  final DataSource source;

  // sensor-specific
  final String? sensorType;
  final double? samplingRate;
  final double? duration;

  // storage
  final EncryptionMethod? encryptionMethod;
  final DataDestination? storageLocation;

  // transmission
  final String? endpoint;
  final TransmissionProtocol? protocol;

  final bool? backgroundMode;

  // AI-generated fields
  final PrivacyRisk? privacyRisk;
  final RegulatoryCompliance? regulatoryCompliance;
  final AiExplanation? aiExplanation;

  const TransparencyEvent({
    this.timestamp,
    required this.dataType,
    required this.source,
    this.sensorType,
    this.samplingRate,
    this.duration,
    this.encryptionMethod,
    this.storageLocation,
    this.endpoint,
    this.protocol,
    this.backgroundMode,
    this.privacyRisk,
    this.regulatoryCompliance,
    this.aiExplanation,
  });

  TransparencyEvent copyWith({
    DateTime? timestamp,
    DataType? dataType,
    DataSource? source,
    String? sensorType,
    double? samplingRate,
    double? duration,
    EncryptionMethod? encryptionMethod,
    DataDestination? storageLocation,
    String? endpoint,
    TransmissionProtocol? protocol,
    bool? backgroundMode,
    PrivacyRisk? privacyRisk,
    RegulatoryCompliance? regulatoryCompliance,
    AiExplanation? aiExplanation,
  }) =>
      TransparencyEvent(
        timestamp: timestamp ?? this.timestamp,
        dataType: dataType ?? this.dataType,
        source: source ?? this.source,
        sensorType: sensorType ?? this.sensorType,
        samplingRate: samplingRate ?? this.samplingRate,
        duration: duration ?? this.duration,
        encryptionMethod: encryptionMethod ?? this.encryptionMethod,
        storageLocation: storageLocation ?? this.storageLocation,
        endpoint: endpoint ?? this.endpoint,
        protocol: protocol ?? this.protocol,
        backgroundMode: backgroundMode ?? this.backgroundMode,
        privacyRisk: privacyRisk ?? this.privacyRisk,
        regulatoryCompliance: regulatoryCompliance ?? this.regulatoryCompliance,
        aiExplanation: aiExplanation ?? this.aiExplanation,
      );

  factory TransparencyEvent.fromJson(Map<String, dynamic> json) =>
      TransparencyEvent(
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
        dataType: DataTypeJson.fromJson(json['dataType'] as String),
        source: DataSourceJson.fromJson(json['source'] as String),
        sensorType: json['sensorType'] as String?,
        samplingRate: (json['samplingRate'] as num?)?.toDouble(),
        duration: (json['duration'] as num?)?.toDouble(),
        encryptionMethod: json['encryptionMethod'] != null
            ? EncryptionMethodJson.fromJson(json['encryptionMethod'] as String)
            : null,
        storageLocation: json['storageLocation'] != null
            ? DataDestinationJson.fromJson(json['storageLocation'] as String)
            : null,
        endpoint: json['endpoint'] as String?,
        protocol: json['protocol'] != null
            ? TransmissionProtocolJson.fromJson(json['protocol'] as String)
            : null,
        backgroundMode: json['backgroundMode'] as bool?,
        privacyRisk: json['privacyRisk'] != null
            ? PrivacyRiskJson.fromJson(json['privacyRisk'] as String)
            : null,
        regulatoryCompliance: json['regulatoryCompliance'] != null
            ? RegulatoryCompliance.fromJson(
                json['regulatoryCompliance'] as Map<String, dynamic>)
            : null,
        aiExplanation: json['aiExplanation'] != null
            ? AiExplanation.fromJson(
                json['aiExplanation'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
        'dataType': dataType.toJson(),
        'source': source.toJson(),
        if (sensorType != null) 'sensorType': sensorType,
        if (samplingRate != null) 'samplingRate': samplingRate,
        if (duration != null) 'duration': duration,
        if (encryptionMethod != null) 'encryptionMethod': encryptionMethod!.toJson(),
        if (storageLocation != null) 'storageLocation': storageLocation!.toJson(),
        if (endpoint != null) 'endpoint': endpoint,
        if (protocol != null) 'protocol': protocol!.toJson(),
        if (backgroundMode != null) 'backgroundMode': backgroundMode,
        if (privacyRisk != null) 'privacyRisk': privacyRisk!.toJson(),
        if (regulatoryCompliance != null)
          'regulatoryCompliance': regulatoryCompliance!.toJson(),
        if (aiExplanation != null) 'aiExplanation': aiExplanation!.toJson(),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// AIPrompt — sent to the backend transparency endpoint
// MIGRATION: TypeScript AIPrompt interface → Dart class.
//            userRiskTolerance: any → Object? (least-evil option; truly unknown
//            shape from future API. MIGRATION_FLAG: refine when API shape is known).
// ═══════════════════════════════════════════════════════════════════════════

// MIGRATION_FLAG: userRiskTolerance has no defined shape in the source code.
//                 Typed as Object? until the backend API contract is specified.
class AiPrompt {
  final TransparencyEvent transparencyEvent;
  final String privacyPolicy;
  final UserConsentPreferences userConsentPreferences;
  final List<RegulatoryFramework> regulationFrameworks;
  final String? pipedaRegulations;
  final Object? userRiskTolerance;

  const AiPrompt({
    required this.transparencyEvent,
    required this.privacyPolicy,
    required this.userConsentPreferences,
    required this.regulationFrameworks,
    this.pipedaRegulations,
    this.userRiskTolerance,
  });

  Map<String, dynamic> toJson() => {
        'transparencyEvent': transparencyEvent.toJson(),
        'privacyPolicy': privacyPolicy,
        'userConsentPreferences': userConsentPreferences.toJson(),
        'regulationFrameworks':
            regulationFrameworks.map((f) => f.toJson()).toList(),
        if (pipedaRegulations != null) 'pipedaRegulations': pipedaRegulations,
        if (userRiskTolerance != null) 'userRiskTolerance': userRiskTolerance,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Default TransparencyEvent instances (mirrors TS constants in Transparency.ts)
// ═══════════════════════════════════════════════════════════════════════════

const _defaultCompliance = RegulatoryCompliance(
  framework: RegulatoryFramework.pipeda,
  compliant: true,
  issues: '',
  relevantSections: [],
);

const defaultJournalTransparencyEvent = TransparencyEvent(
  dataType: DataType.userJournal,
  source: DataSource.userInput,
  privacyRisk: PrivacyRisk.low,
  regulatoryCompliance: _defaultCompliance,
  aiExplanation: AiExplanation(
    why: 'To analyze how your daily mood, habits, sleep goals affects your sleep quality.',
    privacyExplanation: '',
    storage: '',
    access: '',
  ),
);

const defaultLightSensorTransparencyEvent = TransparencyEvent(
  dataType: DataType.sensorLight,
  source: DataSource.lightSensor,
  privacyRisk: PrivacyRisk.low,
  regulatoryCompliance: _defaultCompliance,
  aiExplanation: AiExplanation(
    why: 'To understand how the light conditions in your sleep environment may affect your sleep quality',
    privacyExplanation: '',
    storage: '',
    access: '',
  ),
);

const defaultMicrophoneTransparencyEvent = TransparencyEvent(
  dataType: DataType.sensorAudio,
  source: DataSource.microphone,
  privacyRisk: PrivacyRisk.low,
  regulatoryCompliance: _defaultCompliance,
  aiExplanation: AiExplanation(
    why: 'To analyze sleep disturbances such as snoring and talking, as well as understanding the noise level in your sleep environment',
    privacyExplanation: '',
    storage: '',
    access: '',
  ),
);

const defaultAccelerometerTransparencyEvent = TransparencyEvent(
  dataType: DataType.sensorMotion,
  source: DataSource.accelerometer,
  privacyRisk: PrivacyRisk.low,
  regulatoryCompliance: _defaultCompliance,
  aiExplanation: AiExplanation(
    why: 'To analyze how your movements during sleep and throughout the day impact sleep quality',
    privacyExplanation: '',
    storage: '',
    access: '',
  ),
);

const defaultStatisticsTransparencyEvent = TransparencyEvent(
  dataType: DataType.sleepStatistics,
  source: DataSource.derivedData,
  privacyRisk: PrivacyRisk.low,
  regulatoryCompliance: _defaultCompliance,
  aiExplanation: AiExplanation(
    why: 'Provide summaries and actionable insights to help improve your sleep quality',
    privacyExplanation: 'No privacy risks',
    storage: 'This data is stored securely in your preferred storage location with encryption.',
    access: 'No third parties have access to this data. Only you can view it through the app.',
    privacyPolicyLink: ['derivedData'],
    regulationLink: ['access'],
  ),
);

const defaultGeneralSleepTransparencyEvent = TransparencyEvent(
  dataType: DataType.generalSleep,
  source: DataSource.userInput,
  privacyRisk: PrivacyRisk.low,
  regulatoryCompliance: _defaultCompliance,
  aiExplanation: AiExplanation(
    why: 'To understand your current sleep quality and how we can improve it',
    privacyExplanation: '',
    storage: '',
    access: '',
  ),
);
