// MIGRATION: services/sensors/sensorConfig.ts → Dart.
//            SensorServiceConfig interface → immutable Dart class with copyWith().

class SensorServiceConfig {
  final bool useSimulation;
  final bool audioEnabled;
  final bool lightEnabled;
  final bool accelerometerEnabled;
  final SamplingRates samplingRates;
  final AudioProcessingConfig audioProcessing;

  const SensorServiceConfig({
    this.useSimulation = false,
    this.audioEnabled = true,
    this.lightEnabled = true,
    this.accelerometerEnabled = true,
    this.samplingRates = const SamplingRates(),
    this.audioProcessing = const AudioProcessingConfig(),
  });

  SensorServiceConfig copyWith({
    bool? useSimulation,
    bool? audioEnabled,
    bool? lightEnabled,
    bool? accelerometerEnabled,
    SamplingRates? samplingRates,
    AudioProcessingConfig? audioProcessing,
  }) =>
      SensorServiceConfig(
        useSimulation: useSimulation ?? this.useSimulation,
        audioEnabled: audioEnabled ?? this.audioEnabled,
        lightEnabled: lightEnabled ?? this.lightEnabled,
        accelerometerEnabled: accelerometerEnabled ?? this.accelerometerEnabled,
        samplingRates: samplingRates ?? this.samplingRates,
        audioProcessing: audioProcessing ?? this.audioProcessing,
      );
}

class SamplingRates {
  // MIGRATION: samplingRates in seconds (same as source sensorConfig.ts).
  final int audioSeconds;
  final int lightSeconds;
  final int accelerometerSeconds;

  const SamplingRates({
    this.audioSeconds = 15,
    this.lightSeconds = 15,
    this.accelerometerSeconds = 15,
  });
}

class AudioProcessingConfig {
  final bool enableSnoreDetection;
  final bool saveAudioClips;
  final int clipDurationSeconds;

  const AudioProcessingConfig({
    this.enableSnoreDetection = true,
    this.saveAudioClips = false,
    this.clipDurationSeconds = 15,
  });
}

// Default config used at app startup.
const defaultSensorConfig = SensorServiceConfig();
