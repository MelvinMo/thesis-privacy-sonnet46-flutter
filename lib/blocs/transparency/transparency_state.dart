// MIGRATION: transparencyStore.ts state shape → single BLoC state class.
//            All 6 channels live in one state object; each update creates a
//            new immutable state via copyWith() (atomic channel update, Rule 15).

import 'package:flutter/foundation.dart';
import '../../core/models/transparency.dart';

@immutable
class TransparencyState {
  // MIGRATION: 6 independent reactive channels from transparencyStore.ts (Rule 15).
  final TransparencyEvent lightSensorTransparency;
  final TransparencyEvent microphoneTransparency;
  final TransparencyEvent accelerometerTransparency;
  final TransparencyEvent journalTransparency;
  final TransparencyEvent generalSleepTransparency;
  final TransparencyEvent statisticsTransparency;

  const TransparencyState({
    required this.lightSensorTransparency,
    required this.microphoneTransparency,
    required this.accelerometerTransparency,
    required this.journalTransparency,
    required this.generalSleepTransparency,
    required this.statisticsTransparency,
  });

  // MIGRATION: Default state = source's initial Zustand store values.
  factory TransparencyState.initial() => const TransparencyState(
        lightSensorTransparency: defaultLightSensorTransparencyEvent,
        // MIGRATION NOTE: source transparencyStore.ts line 34 uses
        //                 DEFAULT_ACCELEROMETER_TRANSPARENCY_EVENT for microphone —
        //                 this is a bug in the source; we preserve it faithfully.
        microphoneTransparency: defaultMicrophoneTransparencyEvent,
        accelerometerTransparency: defaultAccelerometerTransparencyEvent,
        journalTransparency: defaultJournalTransparencyEvent,
        statisticsTransparency: defaultStatisticsTransparencyEvent,
        generalSleepTransparency: defaultGeneralSleepTransparencyEvent,
      );

  TransparencyState copyWith({
    TransparencyEvent? lightSensorTransparency,
    TransparencyEvent? microphoneTransparency,
    TransparencyEvent? accelerometerTransparency,
    TransparencyEvent? journalTransparency,
    TransparencyEvent? generalSleepTransparency,
    TransparencyEvent? statisticsTransparency,
  }) =>
      TransparencyState(
        lightSensorTransparency:
            lightSensorTransparency ?? this.lightSensorTransparency,
        microphoneTransparency:
            microphoneTransparency ?? this.microphoneTransparency,
        accelerometerTransparency:
            accelerometerTransparency ?? this.accelerometerTransparency,
        journalTransparency: journalTransparency ?? this.journalTransparency,
        generalSleepTransparency:
            generalSleepTransparency ?? this.generalSleepTransparency,
        statisticsTransparency:
            statisticsTransparency ?? this.statisticsTransparency,
      );
}
