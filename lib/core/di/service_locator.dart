// MIGRATION: services/index.ts (singleton exports) → Dart ServiceLocator.
//
//            services/index.ts simply instantiates all singletons at module
//            scope. Flutter has no module-scope side-effects, so we use a
//            static ServiceLocator class with an async init() that is called
//            once in main() before runApp().
//
//            All public statics exposed here mirror the named exports in the
//            TypeScript source so that screens reference them the same way:
//              TS:   generalSleepDataRepository.createSleepData(...)
//              Dart: ServiceLocator.generalSleepDataRepository.createSleepData(...)

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/transparency/transparency_bloc.dart';
import '../../blocs/transparency/transparency_event.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../services/data/data_sources/cloud_general_sleep_data_source.dart';
import '../../services/data/data_sources/cloud_journal_data_source.dart';
import '../../services/data/data_sources/cloud_sensor_data_source.dart';
import '../../services/data/data_sources/local_general_sleep_data_source.dart';
import '../../services/data/data_sources/local_journal_data_source.dart';
import '../../services/data/data_sources/local_sensor_data_source.dart';
import '../../services/data/general_sleep_data_repository.dart';
import '../../services/data/journal_data_repository.dart';
import '../../services/data/sensor_storage_repository.dart';
import '../../services/encryption_service.dart';
import '../../services/http_client.dart';
import '../../services/local_database_manager.dart';
import '../../services/sensors/device_sensor_service.dart';
import '../../services/sensors/sensor_repository.dart';
import '../../services/sensors/simulation_sensor_service.dart';
import '../../services/transparency_service.dart';
import '../constants/sensor_config.dart';

// ---------------------------------------------------------------------------
// ServiceLocator
// ---------------------------------------------------------------------------
abstract class ServiceLocator {
  // ── Cubits / BLoC (also registered as BlocProviders in main.dart) ──────────
  // MIGRATION: authStore, userProfileStore, transparencyStore → single
  //            ServiceLocator entry point so both BlocProvider and direct
  //            repository access resolve the same instance.
  static late AuthCubit authCubit;
  static late UserProfileCubit userProfileCubit;
  static late TransparencyBloc transparencyBloc;

  // ── Repositories (mirrors named exports from services/index.ts) ───────────
  static late JournalDataRepository journalDataRepository;
  static late GeneralSleepDataRepository generalSleepDataRepository;
  static late SensorStorageRepository sensorStorageRepository;
  static late SensorRepository sensorRepository;
  static late TransparencyService transparencyService;

  // Alias used by screens (matches TS source naming).
  static JournalDataRepository get journalRepository => journalDataRepository;

  // ── Low-level singletons (kept private; exposed only through repos) ────────
  static late AppHttpClient _httpClient;

  // ---------------------------------------------------------------------------
  // init — called once in main() before runApp().
  // ---------------------------------------------------------------------------
  static Future<void> init() async {
    // ── 1. Platform / async primitives ───────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    // ── 2. Infrastructure singletons ─────────────────────────────────────────
    // MIGRATION: EncryptionService.getInstance() matches source singleton.
    //            No constructor args — key is lazily loaded from SecureStorage.
    final encryption = EncryptionService.getInstance();

    // MIGRATION: LocalDatabaseManager.getInstance() matches source singleton.
    //            DB is opened lazily on first query (no eager init needed).
    final db = LocalDatabaseManager.getInstance();

    _httpClient = AppHttpClient();

    // ── 3. BLoC / Cubits ─────────────────────────────────────────────────────
    // MIGRATION: These are created here AND handed to BlocProvider in main.dart
    //            so both routing (GoRouter redirect) and repositories use the
    //            same instance.
    transparencyBloc = TransparencyBloc(prefs: prefs);
    userProfileCubit = UserProfileCubit(prefs: prefs);
    authCubit = AuthCubit(
      httpClient: _httpClient,
      secureStorage: secureStorage,
      prefs: prefs,
    );

    // MIGRATION: EncryptionService dispatches transparency events when it
    //            changes the encryption method. It needs the BLoC reference
    //            since it has no BuildContext.
    encryption.setTransparencyBloc(transparencyBloc);

    // Sync auth token into HTTP client immediately (handles app-restart case).
    // MIGRATION: Source attaches the stored token in authStore.checkAuth().
    //            Here we pre-wire so cloud data sources work from the first call.
    final token = await secureStorage.read(key: 'authToken');
    _httpClient.setAuthToken(token);

    // ── 4. Transparency service ───────────────────────────────────────────────
    transparencyService =
        TransparencyService(httpClient: _httpClient);

    // ── 5. Data sources ───────────────────────────────────────────────────────
    // MIGRATION: LocalJournalDataSource / LocalSensorDataSource wrap the same
    //            SQLite DB + EncryptionService used throughout the app (Rule 13).
    final localJournalDs = LocalJournalDataSource(
      db: db,
      encryption: encryption,
    );
    // MIGRATION: CloudJournalDataSource userId — the userId is looked up per-call
    //            in the repository method params; constructor userId kept as ''
    //            placeholder (same pattern as source).
    final cloudJournalDs = CloudJournalDataSource(
      httpClient: _httpClient,
      userId: '',
    );

    final localSensorDs = LocalSensorDataSource(
      db: db,
      encryption: encryption,
    );
    final cloudSensorDs = CloudSensorDataSource(
      httpClient: _httpClient,
      userId: '',
    );

    final localSleepDs = LocalGeneralSleepDataSource(
      prefs: prefs,
      encryption: encryption,
    );
    final cloudSleepDs = CloudGeneralSleepDataSource(
      httpClient: _httpClient,
    );

    // ── 6. Repositories ───────────────────────────────────────────────────────
    journalDataRepository = JournalDataRepository(
      localSource: localJournalDs,
      cloudSource: cloudJournalDs,
      profileCubit: userProfileCubit,
      transparencyBloc: transparencyBloc,
      transparencyService: transparencyService,
    );

    sensorStorageRepository = SensorStorageRepository(
      localSource: localSensorDs,
      cloudSource: cloudSensorDs,
      profileCubit: userProfileCubit,
      transparencyBloc: transparencyBloc,
      transparencyService: transparencyService,
    );

    generalSleepDataRepository = GeneralSleepDataRepository(
      localSource: localSleepDs,
      cloudSource: cloudSleepDs,
      profileCubit: userProfileCubit,
      transparencyBloc: transparencyBloc,
      transparencyService: transparencyService,
    );

    // ── 7. Sensor services ───────────────────────────────────────────────────
    // MIGRATION: SensorRepository selects real vs simulation based on
    //            TransparencyConfig.inDemoMode or explicit config.useSimulation.
    //            Rule 11: Android foreground service is wired in
    //            BackgroundSensorService (called from SleepModeScreen), not here.
    const sensorConfig = defaultSensorConfig;
    final deviceService = DeviceSensorService(sensorConfig);
    final simulationService = SimulationSensorService(sensorConfig);

    sensorRepository = SensorRepository(
      deviceService: deviceService,
      simulationService: simulationService,
      storageRepository: sensorStorageRepository,
      profileCubit: userProfileCubit,
      transparencyBloc: transparencyBloc,
      config: sensorConfig,
    );

    // ── 8. Load initial transparency state from persistence ───────────────────
    // MIGRATION: transparencyStore rehydrates from AsyncStorage on first access.
    //            Here we fire the load event immediately so the BLoC state is
    //            populated before the first screen renders.
    transparencyBloc.add(LoadTransparencyEvent());
  }
}
