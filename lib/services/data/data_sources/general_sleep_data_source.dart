// MIGRATION: GeneralSleepDataSource interface → Dart abstract.

import '../../../core/models/general_sleep_data.dart';

abstract class GeneralSleepDataSource {
  Future<GeneralSleepData?> getSleepData(String userId);
  Future<GeneralSleepData> createSleepData(GeneralSleepData sleepData);
  Future<void> deleteSleepData(String userId);
}
