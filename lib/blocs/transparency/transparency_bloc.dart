// MIGRATION: transparencyStore.ts (Zustand) → TransparencyBloc (flutter_bloc ^8).
//
//            WHY FULL BLOC (not Cubit): 6 independent reactive channels each map
//            to a discrete Event type. The exhaustive switch expression in on()
//            handlers is cleaner than 6 separate Cubit methods that share state.
//            BLoC's event stream also decouples sensor producers from UI consumers,
//            exactly matching Zustand's async set() → AsyncStorage write behaviour.
//
//            Persistence: AsyncStorage → SharedPreferences (key names preserved).

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/transparency.dart';
import 'transparency_event.dart';
import 'transparency_state.dart';

class TransparencyBloc
    extends Bloc<TransparencyBlocEvent, TransparencyState> {
  final SharedPreferences _prefs;

  // MIGRATION: AsyncStorage key names from transparencyStore.ts preserved.
  static const _keys = {
    'light': 'lightSensorTransparency',
    'microphone': 'microphoneTransparency',
    'accelerometer': 'accelerometerTransparency',
    'journal': 'journalTransparency',
    'statistics': 'statisticsTransparency',
    'generalSleep': 'generalSleepTransparency',
  };

  TransparencyBloc({required SharedPreferences prefs})
      : _prefs = prefs,
        super(TransparencyState.initial()) {
    // Register event handlers.
    on<LoadTransparencyEvent>(_onLoad);
    on<SetLightSensorTransparencyEvent>(_onSetLight);
    on<SetMicrophoneTransparencyEvent>(_onSetMicrophone);
    on<SetAccelerometerTransparencyEvent>(_onSetAccelerometer);
    on<SetJournalTransparencyEvent>(_onSetJournal);
    on<SetGeneralSleepTransparencyEvent>(_onSetGeneralSleep);
    on<SetStatisticsTransparencyEvent>(_onSetStatistics);
  }

  // ---------------------------------------------------------------------------
  // Load from SharedPreferences (replaces loadTransparencyStatus in source).
  // ---------------------------------------------------------------------------
  Future<void> _onLoad(
      LoadTransparencyEvent ev, Emitter<TransparencyState> emit) async {
    try {
      TransparencyEvent load(String key, TransparencyEvent fallback) {
        final raw = _prefs.getString(key);
        if (raw == null) return fallback;
        return TransparencyEvent.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      }

      emit(state.copyWith(
        lightSensorTransparency:
            load(_keys['light']!, defaultLightSensorTransparencyEvent),
        microphoneTransparency:
            load(_keys['microphone']!, defaultMicrophoneTransparencyEvent),
        accelerometerTransparency:
            load(_keys['accelerometer']!, defaultAccelerometerTransparencyEvent),
        journalTransparency:
            load(_keys['journal']!, defaultJournalTransparencyEvent),
        statisticsTransparency:
            load(_keys['statistics']!, defaultStatisticsTransparencyEvent),
        generalSleepTransparency:
            load(_keys['generalSleep']!, defaultGeneralSleepTransparencyEvent),
      ));
    } catch (e) {
      // On failure, keep defaults — non-fatal for transparency UI.
    }
  }

  // ---------------------------------------------------------------------------
  // Channel setters (each persists + emits atomically — Rule 15).
  // ---------------------------------------------------------------------------
  Future<void> _onSetLight(
      SetLightSensorTransparencyEvent ev, Emitter<TransparencyState> emit) async {
    await _persist(_keys['light']!, ev.event);
    emit(state.copyWith(lightSensorTransparency: ev.event));
  }

  Future<void> _onSetMicrophone(
      SetMicrophoneTransparencyEvent ev, Emitter<TransparencyState> emit) async {
    await _persist(_keys['microphone']!, ev.event);
    emit(state.copyWith(microphoneTransparency: ev.event));
  }

  Future<void> _onSetAccelerometer(
      SetAccelerometerTransparencyEvent ev,
      Emitter<TransparencyState> emit) async {
    await _persist(_keys['accelerometer']!, ev.event);
    emit(state.copyWith(accelerometerTransparency: ev.event));
  }

  Future<void> _onSetJournal(
      SetJournalTransparencyEvent ev, Emitter<TransparencyState> emit) async {
    await _persist(_keys['journal']!, ev.event);
    emit(state.copyWith(journalTransparency: ev.event));
  }

  Future<void> _onSetGeneralSleep(
      SetGeneralSleepTransparencyEvent ev,
      Emitter<TransparencyState> emit) async {
    await _persist(_keys['generalSleep']!, ev.event);
    emit(state.copyWith(generalSleepTransparency: ev.event));
  }

  Future<void> _onSetStatistics(
      SetStatisticsTransparencyEvent ev,
      Emitter<TransparencyState> emit) async {
    await _persist(_keys['statistics']!, ev.event);
    emit(state.copyWith(statisticsTransparency: ev.event));
  }

  // ---------------------------------------------------------------------------
  // Persist a single channel to SharedPreferences.
  // ---------------------------------------------------------------------------
  Future<void> _persist(String key, TransparencyEvent event) async {
    await _prefs.setString(key, jsonEncode(event.toJson()));
  }
}
