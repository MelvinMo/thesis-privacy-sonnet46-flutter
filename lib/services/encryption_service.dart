// MIGRATION: services/EncryptionService.ts → Dart singleton class.
//
//            Crypto mapping:
//              crypto-js AES-256-CBC-PKCS7 → pointycastle ^3 AES/CBC/PKCS7
//              expo-secure-store            → flutter_secure_storage ^9
//
//            KEY COMPATIBILITY (Rule 12):
//              The source uses:
//                key  = CryptoJS.lib.WordArray.random(256/8) stored as Base64.
//                iv   = CryptoJS.lib.WordArray.random(128/8) stored as Base64.
//                wire = "<ivBase64>:<ciphertextBase64>"
//
//              This Dart implementation uses the SAME wire format:
//                key  = raw 32 bytes, stored as Base64 in SecureStorage.
//                iv   = random 16 bytes, prepended as Base64, ':' separator.
//                mode = AES/CBC/PKCS7Padding (identical to CryptoJS defaults).
//
//              An existing row encrypted by the React Native app IS readable
//              by this service if the same key is loaded from SecureStorage,
//              because the format and algorithm are identical.
//
//            PBKDF2 note (Rule 12):
//              The source generates a raw random key — it does NOT derive it via
//              PBKDF2. PBKDF2 would change the key and break existing data.
//              We preserve the raw-random-key approach.
//              MIGRATION_FLAG: If you need to migrate to PBKDF2, all previously
//                              encrypted rows must be re-encrypted first.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

import '../blocs/transparency/transparency_bloc.dart';
import '../blocs/transparency/transparency_event.dart';
import '../core/constants/transparency_config.dart';
import '../core/models/general_sleep_data.dart';
import '../core/models/journal_data.dart';
import '../core/models/sensor_data.dart';
import '../core/models/transparency.dart';
import '../core/models/user.dart';

class EncryptionService {
  // Singleton pattern — matches source EncryptionService.getInstance().
  static EncryptionService? _instance;
  static EncryptionService getInstance() {
    _instance ??= EncryptionService._();
    return _instance!;
  }

  EncryptionService._();

  static const _keyName = 'myAppEncryptionKey'; // same key name as source
  final _secureStorage = const FlutterSecureStorage();
  Uint8List? _keyBytes;

  /// Lazily initialized future — all encrypt/decrypt calls await this.
  late final Future<void> _initialized = _initializeKey();

  // Optional reference to TransparencyBloc for emitting encryption events.
  // MIGRATION: Source calls useTransparencyStore.getState().setX(...) directly.
  //            In Flutter we pass the BLoC reference so the service remains
  //            testable without a BuildContext.
  TransparencyBloc? _transparencyBloc;

  void setTransparencyBloc(TransparencyBloc bloc) {
    _transparencyBloc = bloc;
  }

  // ---------------------------------------------------------------------------
  // Key initialisation (mirrors initializeKey() in source).
  // ---------------------------------------------------------------------------
  Future<void> _initializeKey() async {
    final existing = await _secureStorage.read(key: _keyName);
    if (existing != null) {
      _keyBytes = base64.decode(existing);
    } else {
      // MIGRATION: CryptoJS.lib.WordArray.random(256/8) → Dart's Random.secure().
      final rng = Random.secure();
      final keyBytes = Uint8List.fromList(
          List.generate(32, (_) => rng.nextInt(256)));
      final keyB64 = base64.encode(keyBytes);
      await _secureStorage.write(key: _keyName, value: keyB64);
      _keyBytes = keyBytes;
    }
  }

  // ---------------------------------------------------------------------------
  // Core encrypt — mirrors encrypt(data: string): Promise<string>
  // Wire format: "<ivBase64>:<ciphertextBase64>"
  // ---------------------------------------------------------------------------
  Future<String> encrypt(String data) async {
    await _initialized;
    final key = _keyBytes!;

    // Random 16-byte IV (same as CryptoJS 128-bit IV).
    final rng = Random.secure();
    final iv = Uint8List.fromList(List.generate(16, (_) => rng.nextInt(256)));

    final plainBytes = Uint8List.fromList(utf8.encode(data));
    final cipherBytes = _aesCbcEncrypt(key, iv, plainBytes);

    // MIGRATION: CryptoJS returns "<ivB64>:<cipherB64>" — identical format here.
    return '${base64.encode(iv)}:${base64.encode(cipherBytes)}';
  }

  // ---------------------------------------------------------------------------
  // Core decrypt — mirrors decrypt(encryptedBase64: string): Promise<string>
  // ---------------------------------------------------------------------------
  Future<String> decrypt(String encryptedBase64) async {
    await _initialized;
    final key = _keyBytes!;

    final parts = encryptedBase64.split(':');
    if (parts.length != 2) {
      throw ArgumentError(
          'Invalid encrypted data format. Expected "IV:Ciphertext".');
    }
    final iv = base64.decode(parts[0]);
    final cipherBytes = base64.decode(parts[1]);

    final plainBytes = _aesCbcDecrypt(key, Uint8List.fromList(iv), cipherBytes);
    return utf8.decode(plainBytes);
  }

  // ---------------------------------------------------------------------------
  // AES-CBC helpers using pointycastle.
  // ---------------------------------------------------------------------------
  Uint8List _aesCbcEncrypt(Uint8List key, Uint8List iv, Uint8List plaintext) {
    // MIGRATION: CryptoJS.mode.CBC + CryptoJS.pad.Pkcs7 → AES/CBC/PKCS7Padding.
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );
    cipher.init(
      true, // encrypt
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );
    return cipher.process(plaintext);
  }

  Uint8List _aesCbcDecrypt(Uint8List key, Uint8List iv, Uint8List ciphertext) {
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );
    cipher.init(
      false, // decrypt
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );
    return cipher.process(ciphertext);
  }

  // ---------------------------------------------------------------------------
  // Determine the EncryptionMethod based on demo config flags.
  // MIGRATION: Inlined logic from EncryptionService.ts L156.
  // ---------------------------------------------------------------------------
  EncryptionMethod get _activeEncryptionMethod =>
      TransparencyConfig.encryptDataAtRest
          ? EncryptionMethod.aes256
          : EncryptionMethod.none;

  // ---------------------------------------------------------------------------
  // encryptJournalData / decryptJournalData
  // ---------------------------------------------------------------------------
  Future<JournalData> encryptJournalData(JournalData journalData) async {
    // Only encrypt if config requires it.
    if (!TransparencyConfig.encryptDataAtRest) {
      _emitJournalEncryptionMethod(EncryptionMethod.none);
      return journalData;
    }
    final encrypted = journalData.copyWith(
      bedtime: journalData.bedtime.isNotEmpty
          ? await encrypt(journalData.bedtime)
          : journalData.bedtime,
      alarmTime: journalData.alarmTime.isNotEmpty
          ? await encrypt(journalData.alarmTime)
          : journalData.alarmTime,
      sleepDuration: journalData.sleepDuration.isNotEmpty
          ? await encrypt(journalData.sleepDuration)
          : journalData.sleepDuration,
      diaryEntry: journalData.diaryEntry.isNotEmpty
          ? await encrypt(journalData.diaryEntry)
          : journalData.diaryEntry,
      // MIGRATION: sleepNotes.map(note => encrypt(note)) preserved as List.
      sleepNotes: await Future.wait(
        journalData.sleepNotes.map((n) async =>
            SleepNoteJson.fromJson(await encrypt(n.toJson()))),
      ),
    );
    _emitJournalEncryptionMethod(_activeEncryptionMethod);
    return encrypted;
  }

  Future<JournalData> decryptJournalData(JournalData encrypted) async {
    if (!TransparencyConfig.encryptDataAtRest) return encrypted;
    return encrypted.copyWith(
      bedtime: encrypted.bedtime.isNotEmpty
          ? await decrypt(encrypted.bedtime)
          : encrypted.bedtime,
      alarmTime: encrypted.alarmTime.isNotEmpty
          ? await decrypt(encrypted.alarmTime)
          : encrypted.alarmTime,
      sleepDuration: encrypted.sleepDuration.isNotEmpty
          ? await decrypt(encrypted.sleepDuration)
          : encrypted.sleepDuration,
      diaryEntry: encrypted.diaryEntry.isNotEmpty
          ? await decrypt(encrypted.diaryEntry)
          : encrypted.diaryEntry,
      sleepNotes: await Future.wait(
        encrypted.sleepNotes.map((n) async =>
            SleepNoteJson.fromJson(await decrypt(n.toJson()))),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // encryptUserData / decryptUserData
  // ---------------------------------------------------------------------------
  Future<AppUser> encryptUserData(AppUser userData) async {
    if (!TransparencyConfig.encryptDataAtRest) return userData;
    return userData.copyWith(
      firstName: await encrypt(userData.firstName),
      lastName: await encrypt(userData.lastName),
      email: await encrypt(userData.email),
      // MIGRATION: Source comment: "Do NOT encrypt password here."
    );
  }

  Future<AppUser> decryptUserData(AppUser encryptedUser) async {
    if (!TransparencyConfig.encryptDataAtRest) return encryptedUser;
    return encryptedUser.copyWith(
      firstName: await decrypt(encryptedUser.firstName),
      lastName: await decrypt(encryptedUser.lastName),
      email: await decrypt(encryptedUser.email),
    );
  }

  // ---------------------------------------------------------------------------
  // encryptGeneralSleepData / decryptGeneralSleepData
  // ---------------------------------------------------------------------------
  Future<GeneralSleepData> encryptGeneralSleepData(
      GeneralSleepData data) async {
    if (!TransparencyConfig.encryptDataAtRest) {
      _emitGeneralSleepEncryptionMethod(EncryptionMethod.none);
      return data;
    }
    final encrypted = data.copyWith(
      currentSleepDuration: data.currentSleepDuration.isNotEmpty
          ? await encrypt(data.currentSleepDuration)
          : data.currentSleepDuration,
      snoring:
          data.snoring.isNotEmpty ? await encrypt(data.snoring) : data.snoring,
      tirednessFrequency: data.tirednessFrequency.isNotEmpty
          ? await encrypt(data.tirednessFrequency)
          : data.tirednessFrequency,
      daytimeSleepiness: data.daytimeSleepiness.isNotEmpty
          ? await encrypt(data.daytimeSleepiness)
          : data.daytimeSleepiness,
    );
    _emitGeneralSleepEncryptionMethod(_activeEncryptionMethod);
    return encrypted;
  }

  Future<GeneralSleepData> decryptGeneralSleepData(
      GeneralSleepData data) async {
    if (!TransparencyConfig.encryptDataAtRest) return data;
    return data.copyWith(
      currentSleepDuration: data.currentSleepDuration.isNotEmpty
          ? await decrypt(data.currentSleepDuration)
          : data.currentSleepDuration,
      snoring:
          data.snoring.isNotEmpty ? await decrypt(data.snoring) : data.snoring,
      tirednessFrequency: data.tirednessFrequency.isNotEmpty
          ? await decrypt(data.tirednessFrequency)
          : data.tirednessFrequency,
      daytimeSleepiness: data.daytimeSleepiness.isNotEmpty
          ? await decrypt(data.daytimeSleepiness)
          : data.daytimeSleepiness,
    );
  }

  // ---------------------------------------------------------------------------
  // encryptSensorData / decryptSensorData
  // MIGRATION: TS switch on sensorData.sensorType → Dart sealed class switch.
  // ---------------------------------------------------------------------------
  Future<SensorData> encryptSensorData(SensorData sensorData) async {
    if (!TransparencyConfig.encryptDataAtRest) {
      _emitSensorEncryptionMethod(sensorData.sensorType, EncryptionMethod.none);
      return sensorData;
    }
    final SensorData result = switch (sensorData) {
      AudioSensorData d => d.copyWith(
          averageDecibels: await encrypt(d.averageDecibels),
          peakDecibels: await encrypt(d.peakDecibels),
          frequencyBands: d.frequencyBands.copyWith(
            low: await encrypt(d.frequencyBands.low),
            mid: await encrypt(d.frequencyBands.mid),
            high: await encrypt(d.frequencyBands.high),
          ),
        ),
      LightSensorData d => d.copyWith(
          illuminance: await encrypt(d.illuminance),
        ),
      AccelerometerSensorData d => d.copyWith(
          x: await encrypt(d.x),
          y: await encrypt(d.y),
          z: await encrypt(d.z),
          magnitude: await encrypt(d.magnitude),
        ),
    };
    _emitSensorEncryptionMethod(sensorData.sensorType, _activeEncryptionMethod);
    return result;
  }

  Future<SensorData> decryptSensorData(SensorData sensorData) async {
    if (!TransparencyConfig.encryptDataAtRest) return sensorData;
    return switch (sensorData) {
      AudioSensorData d => d.copyWith(
          averageDecibels: await decrypt(d.averageDecibels),
          peakDecibels: await decrypt(d.peakDecibels),
          frequencyBands: d.frequencyBands.copyWith(
            low: await decrypt(d.frequencyBands.low),
            mid: await decrypt(d.frequencyBands.mid),
            high: await decrypt(d.frequencyBands.high),
          ),
        ),
      LightSensorData d => d.copyWith(illuminance: await decrypt(d.illuminance)),
      AccelerometerSensorData d => d.copyWith(
          x: await decrypt(d.x),
          y: await decrypt(d.y),
          z: await decrypt(d.z),
          magnitude: await decrypt(d.magnitude),
        ),
    };
  }

  // ---------------------------------------------------------------------------
  // Transparency BLoC emission helpers.
  // MIGRATION: Source calls useTransparencyStore.getState().setX({ ...ev, encryptionMethod }).
  //            We dispatch BLoC events instead (no BuildContext needed).
  // ---------------------------------------------------------------------------
  void _emitJournalEncryptionMethod(EncryptionMethod method) {
    final bloc = _transparencyBloc;
    if (bloc == null) return;
    final current = bloc.state.journalTransparency;
    bloc.add(SetJournalTransparencyEvent(
        current.copyWith(encryptionMethod: method)));
  }

  void _emitGeneralSleepEncryptionMethod(EncryptionMethod method) {
    final bloc = _transparencyBloc;
    if (bloc == null) return;
    final current = bloc.state.generalSleepTransparency;
    bloc.add(SetGeneralSleepTransparencyEvent(
        current.copyWith(encryptionMethod: method)));
  }

  void _emitSensorEncryptionMethod(String type, EncryptionMethod method) {
    final bloc = _transparencyBloc;
    if (bloc == null) return;
    switch (type) {
      case 'audio':
        final c = bloc.state.microphoneTransparency;
        bloc.add(SetMicrophoneTransparencyEvent(
            c.copyWith(encryptionMethod: method)));
      case 'light':
        final c = bloc.state.lightSensorTransparency;
        bloc.add(SetLightSensorTransparencyEvent(
            c.copyWith(encryptionMethod: method)));
      case 'accelerometer':
        final c = bloc.state.accelerometerTransparency;
        bloc.add(SetAccelerometerTransparencyEvent(
            c.copyWith(encryptionMethod: method)));
    }
  }
}
