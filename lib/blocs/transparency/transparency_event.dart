// MIGRATION: transparencyStore.ts (Zustand) setters → BLoC Events.
//            Each of the 6 independent channels emits its own typed Event,
//            satisfying Rule 15 (atomic updates per channel).
//
//            WHY BLOC (not Cubit): The 6 independent reactive channels each
//            correspond to a distinct Event type — exhaustive switch in the
//            BLoC handler is cleaner than 6 separate Cubit methods with shared
//            state. Also, the BLoC pattern decouples producers (sensor service,
//            repositories) from the UI observer, matching the source's Zustand
//            async set() → AsyncStorage write flow.

import 'package:flutter/foundation.dart';
import '../../core/models/transparency.dart';

@immutable
sealed class TransparencyBlocEvent {
  const TransparencyBlocEvent();
}

/// Load all 6 channels from SharedPreferences on app start.
final class LoadTransparencyEvent extends TransparencyBlocEvent {
  const LoadTransparencyEvent();
}

/// Update channel 1: light sensor.
final class SetLightSensorTransparencyEvent extends TransparencyBlocEvent {
  final TransparencyEvent event;
  const SetLightSensorTransparencyEvent(this.event);
}

/// Update channel 2: microphone.
final class SetMicrophoneTransparencyEvent extends TransparencyBlocEvent {
  final TransparencyEvent event;
  const SetMicrophoneTransparencyEvent(this.event);
}

/// Update channel 3: accelerometer.
final class SetAccelerometerTransparencyEvent extends TransparencyBlocEvent {
  final TransparencyEvent event;
  const SetAccelerometerTransparencyEvent(this.event);
}

/// Update channel 4: journal.
final class SetJournalTransparencyEvent extends TransparencyBlocEvent {
  final TransparencyEvent event;
  const SetJournalTransparencyEvent(this.event);
}

/// Update channel 5: general sleep.
final class SetGeneralSleepTransparencyEvent extends TransparencyBlocEvent {
  final TransparencyEvent event;
  const SetGeneralSleepTransparencyEvent(this.event);
}

/// Update channel 6: statistics.
final class SetStatisticsTransparencyEvent extends TransparencyBlocEvent {
  final TransparencyEvent event;
  const SetStatisticsTransparencyEvent(this.event);
}
