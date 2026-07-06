// MIGRATION: TypeScript discriminated union `SensorData = AudioSensorData | LightSensorData | AccelerometerSensorData`
//            → Dart sealed class hierarchy (Dart 3+).
//            Sealed classes give exhaustive pattern-matching via switch expressions,
//            replacing TS's `sensorData.sensorType === 'audio'` narrowing.
//
//            All numeric fields kept as `String` (encrypted form) matching source
//            schema — decryption happens in EncryptionService, not the model.

// ═══════════════════════════════════════════════════════════════════════════
// Base
// ═══════════════════════════════════════════════════════════════════════════

sealed class SensorData {
  final String id;
  final String userId;
  final String timestamp; // Unix milliseconds as string (matches source)
  final String date;      // YYYY-MM-DD
  final String sensorType; // 'audio' | 'light' | 'accelerometer'

  const SensorData({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.date,
    required this.sensorType,
  });

  // MIGRATION: TS discriminated union fromJson → factory with runtime dispatch.
  factory SensorData.fromJson(Map<String, dynamic> json) {
    final type = json['sensorType'] as String;
    return switch (type) {
      'audio' => AudioSensorData.fromJson(json),
      'light' => LightSensorData.fromJson(json),
      'accelerometer' => AccelerometerSensorData.fromJson(json),
      _ => throw ArgumentError('Unknown sensorType: $type'),
    };
  }

  Map<String, dynamic> toJson();
}

// ═══════════════════════════════════════════════════════════════════════════
// Audio
// ═══════════════════════════════════════════════════════════════════════════

// MIGRATION: TypeScript `ambientNoiseLevel: 'quiet'|'moderate'|'loud'|'very_loud'`
//            → Dart enum (compile-time exhaustive checking, no magic strings).
enum AmbientNoiseLevel { quiet, moderate, loud, veryLoud }

extension AmbientNoiseLevelJson on AmbientNoiseLevel {
  String toJson() {
    const m = {
      AmbientNoiseLevel.quiet: 'quiet',
      AmbientNoiseLevel.moderate: 'moderate',
      AmbientNoiseLevel.loud: 'loud',
      AmbientNoiseLevel.veryLoud: 'very_loud',
    };
    return m[this]!;
  }

  static AmbientNoiseLevel fromJson(String v) {
    const m = {
      'quiet': AmbientNoiseLevel.quiet,
      'moderate': AmbientNoiseLevel.moderate,
      'loud': AmbientNoiseLevel.loud,
      'very_loud': AmbientNoiseLevel.veryLoud,
    };
    return m[v] ?? AmbientNoiseLevel.quiet;
  }
}

class FrequencyBands {
  final String low;
  final String mid;
  final String high;
  const FrequencyBands({required this.low, required this.mid, required this.high});

  factory FrequencyBands.fromJson(Map<String, dynamic> json) => FrequencyBands(
        low: json['low'] as String? ?? '0',
        mid: json['mid'] as String? ?? '0',
        high: json['high'] as String? ?? '0',
      );

  Map<String, dynamic> toJson() => {'low': low, 'mid': mid, 'high': high};

  FrequencyBands copyWith({String? low, String? mid, String? high}) =>
      FrequencyBands(low: low ?? this.low, mid: mid ?? this.mid, high: high ?? this.high);
}

final class AudioSensorData extends SensorData {
  final String averageDecibels;
  final String peakDecibels;
  final FrequencyBands frequencyBands;
  final String? audioClipUri;
  final bool snoreDetected;
  final AmbientNoiseLevel ambientNoiseLevel;

  const AudioSensorData({
    required super.id,
    required super.userId,
    required super.timestamp,
    required super.date,
    required this.averageDecibels,
    required this.peakDecibels,
    required this.frequencyBands,
    this.audioClipUri,
    required this.snoreDetected,
    required this.ambientNoiseLevel,
  }) : super(sensorType: 'audio');

  AudioSensorData copyWith({
    String? id,
    String? userId,
    String? timestamp,
    String? date,
    String? averageDecibels,
    String? peakDecibels,
    FrequencyBands? frequencyBands,
    String? audioClipUri,
    bool? snoreDetected,
    AmbientNoiseLevel? ambientNoiseLevel,
  }) =>
      AudioSensorData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        timestamp: timestamp ?? this.timestamp,
        date: date ?? this.date,
        averageDecibels: averageDecibels ?? this.averageDecibels,
        peakDecibels: peakDecibels ?? this.peakDecibels,
        frequencyBands: frequencyBands ?? this.frequencyBands,
        audioClipUri: audioClipUri ?? this.audioClipUri,
        snoreDetected: snoreDetected ?? this.snoreDetected,
        ambientNoiseLevel: ambientNoiseLevel ?? this.ambientNoiseLevel,
      );

  factory AudioSensorData.fromJson(Map<String, dynamic> json) => AudioSensorData(
        id: json['id'] as String,
        userId: json['userId'] as String,
        timestamp: json['timestamp'].toString(),
        date: json['date'] as String,
        averageDecibels: json['averageDecibels'] as String? ?? '0',
        peakDecibels: json['peakDecibels'] as String? ?? '0',
        frequencyBands: FrequencyBands.fromJson(
            json['frequencyBands'] is String
                ? <String, dynamic>{} // will be re-parsed if stored as JSON string
                : (json['frequencyBands'] as Map<String, dynamic>? ?? {})),
        audioClipUri: json['audioClipUri'] as String?,
        // MIGRATION: SQLite stores booleans as INTEGER (0/1). Handle both.
        snoreDetected: json['snoreDetected'] == true || json['snoreDetected'] == 1,
        ambientNoiseLevel: AmbientNoiseLevelJson.fromJson(
            json['ambientNoiseLevel'] as String? ?? 'quiet'),
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'timestamp': timestamp,
        'date': date,
        'sensorType': sensorType,
        'averageDecibels': averageDecibels,
        'peakDecibels': peakDecibels,
        'frequencyBands': frequencyBands.toJson(),
        if (audioClipUri != null) 'audioClipUri': audioClipUri,
        'snoreDetected': snoreDetected,
        'ambientNoiseLevel': ambientNoiseLevel.toJson(),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Light
// ═══════════════════════════════════════════════════════════════════════════

enum LightLevel { dark, dim, moderate, bright }

extension LightLevelJson on LightLevel {
  String toJson() => name;
  static LightLevel fromJson(String v) =>
      LightLevel.values.firstWhere((e) => e.name == v, orElse: () => LightLevel.dark);
}

final class LightSensorData extends SensorData {
  final String illuminance; // lux value as string (may be encrypted)
  final LightLevel lightLevel;

  const LightSensorData({
    required super.id,
    required super.userId,
    required super.timestamp,
    required super.date,
    required this.illuminance,
    required this.lightLevel,
  }) : super(sensorType: 'light');

  LightSensorData copyWith({
    String? id,
    String? userId,
    String? timestamp,
    String? date,
    String? illuminance,
    LightLevel? lightLevel,
  }) =>
      LightSensorData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        timestamp: timestamp ?? this.timestamp,
        date: date ?? this.date,
        illuminance: illuminance ?? this.illuminance,
        lightLevel: lightLevel ?? this.lightLevel,
      );

  factory LightSensorData.fromJson(Map<String, dynamic> json) => LightSensorData(
        id: json['id'] as String,
        userId: json['userId'] as String,
        timestamp: json['timestamp'].toString(),
        date: json['date'] as String,
        illuminance: json['illuminance'] as String? ?? '0',
        lightLevel:
            LightLevelJson.fromJson(json['lightLevel'] as String? ?? 'dark'),
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'timestamp': timestamp,
        'date': date,
        'sensorType': sensorType,
        'illuminance': illuminance,
        'lightLevel': lightLevel.toJson(),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Accelerometer
// ═══════════════════════════════════════════════════════════════════════════

enum MovementIntensity { still, light, moderate, active }

extension MovementIntensityJson on MovementIntensity {
  String toJson() => name;
  static MovementIntensity fromJson(String v) => MovementIntensity.values
      .firstWhere((e) => e.name == v, orElse: () => MovementIntensity.still);
}

final class AccelerometerSensorData extends SensorData {
  final String x;
  final String y;
  final String z;
  final String magnitude;
  final MovementIntensity movementIntensity;

  const AccelerometerSensorData({
    required super.id,
    required super.userId,
    required super.timestamp,
    required super.date,
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.movementIntensity,
  }) : super(sensorType: 'accelerometer');

  AccelerometerSensorData copyWith({
    String? id,
    String? userId,
    String? timestamp,
    String? date,
    String? x,
    String? y,
    String? z,
    String? magnitude,
    MovementIntensity? movementIntensity,
  }) =>
      AccelerometerSensorData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        timestamp: timestamp ?? this.timestamp,
        date: date ?? this.date,
        x: x ?? this.x,
        y: y ?? this.y,
        z: z ?? this.z,
        magnitude: magnitude ?? this.magnitude,
        movementIntensity: movementIntensity ?? this.movementIntensity,
      );

  factory AccelerometerSensorData.fromJson(Map<String, dynamic> json) =>
      AccelerometerSensorData(
        id: json['id'] as String,
        userId: json['userId'] as String,
        timestamp: json['timestamp'].toString(),
        date: json['date'] as String,
        x: json['x'] as String? ?? '0',
        y: json['y'] as String? ?? '0',
        z: json['z'] as String? ?? '0',
        magnitude: json['magnitude'] as String? ?? '0',
        movementIntensity: MovementIntensityJson.fromJson(
            json['movementIntensity'] as String? ?? 'still'),
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'timestamp': timestamp,
        'date': date,
        'sensorType': sensorType,
        'x': x,
        'y': y,
        'z': z,
        'magnitude': magnitude,
        'movementIntensity': movementIntensity.toJson(),
      };
}
