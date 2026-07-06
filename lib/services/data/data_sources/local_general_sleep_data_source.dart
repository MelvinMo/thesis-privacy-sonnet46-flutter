// MIGRATION: LocalGeneralSleepDataSource.ts → Dart.
//            Uses SharedPreferences (same as AsyncStorage in source).

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/general_sleep_data.dart';
import '../../encryption_service.dart';
import 'general_sleep_data_source.dart';

class LocalGeneralSleepDataSource implements GeneralSleepDataSource {
  final SharedPreferences _prefs;
  final EncryptionService _encryption;

  static const _keyPrefix = 'generalSleepData_';

  LocalGeneralSleepDataSource({
    required SharedPreferences prefs,
    required EncryptionService encryption,
  })  : _prefs = prefs,
        _encryption = encryption;

  @override
  Future<GeneralSleepData?> getSleepData(String userId) async {
    final raw = _prefs.getString('$_keyPrefix$userId');
    if (raw == null) return null;
    final data = GeneralSleepData.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
    return _encryption.decryptGeneralSleepData(data);
  }

  @override
  Future<GeneralSleepData> createSleepData(GeneralSleepData sleepData) async {
    final encrypted = await _encryption.encryptGeneralSleepData(sleepData);
    await _prefs.setString(
        '$_keyPrefix${sleepData.userId}', jsonEncode(encrypted.toJson()));
    return sleepData; // Return unencrypted.
  }

  @override
  Future<void> deleteSleepData(String userId) async {
    await _prefs.remove('$_keyPrefix$userId');
  }
}
