import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:metadata_god/metadata_god.dart'; // Có vấn đề FFI trên iOS
import 'package:path_provider/path_provider.dart';

import '/utils/get_localization.dart';
import 'utils/app_link_controller.dart';
import '/services/audio_handler.dart';
import '/ui/home.dart';
import '/ui/utils/theme_controller.dart';
import '/services/youtube_cookie_manager.dart';
import '/services/music_service.dart';
import '/services/downloader.dart';
import '/services/piped_service.dart';
import '/repositories/repository_module.dart';
import '/utils/helper.dart';
import '/utils/error_handler.dart';

import 'utils/update_check_flag_file.dart';

Future<void> main() async {
  try {
    AppErrorHandler.logInfo('Starting app initialization', context: 'Main');

    WidgetsFlutterBinding.ensureInitialized();

    // Configure system UI early
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addObserver(LifecycleHandler());
    
    // Enable performance testing in debug mode
    // To enable, uncomment the performance testing import and this line:
    // PerformanceTesting.enableDebugRebuildPrint();

    AppErrorHandler.logInfo('Starting initialization with timeout',
        context: 'Main');

    // Initialize with overall timeout to prevent infinite loading
    await _initializeAppParallel().timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        AppErrorHandler.logWarning('Overall initialization timeout',
            context: 'Main');
        throw TimeoutException(
            'App initialization timeout', const Duration(seconds: 20));
      },
    );

    AppErrorHandler.logInfo('Initialization successful, running main app',
        context: 'Main');
    runApp(const MyApp());
  } catch (error, stackTrace) {
    AppErrorHandler.handleError(error, stackTrace,
        context: 'Main Initialization Failed');

    // Run fallback app with retry capability
    AppErrorHandler.logInfo('Running fallback app', context: 'Main');
    runApp(const FallbackApp());
  }
}

/// Prepare background services for lazy loading
Future<void> _prepareBackgroundServices() async {
  // Pre-warm services that will be needed soon
  // This runs in parallel with other initialization
  try {
    // Warm up YouTube Cookie Manager
    unawaited(YouTubeCookieManager.init());

    // Pre-allocate service instances (they'll be registered via bindings later)
    // This just ensures class loading happens early
    unawaited(Future.microtask(() {
      // Trigger class loading without actual instantiation
      PipedServices;
      Downloader;
    }));
  } catch (e) {
    printERROR('Error preparing background services: $e');
  }
}

/// Optimized parallel initialization of app components with timeout
Future<void> _initializeAppParallel() async {
  try {
    AppErrorHandler.logInfo('Starting critical initialization',
        context: 'Init');

    // Initialize Hive first (most critical)
    await initHive().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        AppErrorHandler.logWarning('Hive initialization timeout',
            context: 'Init');
        throw TimeoutException(
            'Hive initialization timed out', const Duration(seconds: 10));
      },
    );

    AppErrorHandler.logInfo('Hive initialized successfully', context: 'Init');

    // Set app preferences after Hive is ready
    await _setAppInitPrefsAsync();

    AppErrorHandler.logInfo('App preferences set', context: 'Init');

    // Initialize essential services that controllers depend on
    Get.put<MusicServices>(MusicServices(), permanent: true);
    Get.lazyPut<Downloader>(() => Downloader(), fenix: true);
    Get.lazyPut<PipedServices>(() => PipedServices(), fenix: true);
    AppErrorHandler.logInfo('Essential services initialized', context: 'Init');

    // Initialize repositories
    try {
      await RepositoryModule.init();
      AppErrorHandler.logInfo('Repositories initialized', context: 'Init');
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Repository Init');
      // Continue without repositories - controllers will fall back to direct service calls
    }

    // Initialize audio service with timeout
    try {
      final audioHandler = await initAudioService().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          AppErrorHandler.logWarning('Audio service timeout', context: 'Init');
          throw TimeoutException(
              'Audio service timeout', const Duration(seconds: 8));
        },
      );
      Get.put<AudioHandler>(audioHandler, permanent: true);
      AppErrorHandler.logInfo('Audio service initialized', context: 'Init');
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Audio Service Init');
      // Continue without audio service - app can still function
    }

    // Background services (non-blocking)
    unawaited(_prepareBackgroundServices());

    AppErrorHandler.logInfo('Initialization completed successfully',
        context: 'Init');
  } catch (e, stackTrace) {
    AppErrorHandler.handleError(e, stackTrace, context: 'Parallel Init');
    rethrow; // Let main() handle with fallback
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    try {
      AppErrorHandler.logInfo('Building MyApp widget', context: 'MyApp');

      if (!GetPlatform.isDesktop) Get.put(AppLinksController());
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      return GetMaterialApp(
          title: 'Harmony Music',
          home: const Home(),
          debugShowCheckedModeBanner: false,
          translations: Languages(),
          locale: Locale(
              Hive.box("AppPrefs").get('currentAppLanguageCode') ?? "vi"),
          fallbackLocale: const Locale("vi"),
          // No initial binding - let controllers initialize lazily to prevent blocking
          builder: (context, child) {
            try {
              final mQuery = MediaQuery.of(context);
              final scale = mQuery.textScaler
                  .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.1);
              return Stack(
                children: [
                  // Safely get ThemeController with fallback initialization
                  GetX<ThemeController>(
                    init: ThemeController(), // Fallback init if bindings fail
                    builder: (controller) {
                      try {
                        return MediaQuery(
                          data: mQuery.copyWith(textScaler: scale),
                          child: AnimatedTheme(
                              duration: const Duration(milliseconds: 700),
                              data: controller.themedata.value!,
                              child: child!),
                        );
                      } catch (e) {
                        AppErrorHandler.handleError(e, null,
                            context: 'ThemeController Builder');
                        // Fallback to basic theme
                        return MediaQuery(
                          data: mQuery.copyWith(textScaler: scale),
                          child: Theme(
                            data: ThemeData.dark(),
                            child: child!,
                          ),
                        );
                      }
                    },
                  ),
                  GestureDetector(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        color: Colors.transparent,
                        height: mQuery.padding.bottom,
                        width: mQuery.size.width,
                      ),
                    ),
                  )
                ],
              );
            } catch (e) {
              AppErrorHandler.handleError(e, null, context: 'MyApp Builder');
              return child ?? Container();
            }
          });
    } catch (error, stackTrace) {
      AppErrorHandler.handleError(error, stackTrace, context: 'MyApp Build');
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error loading app. Please restart.'),
          ),
        ),
      );
    }
  }
}

Future<void> initHive() async {
  String applicationDataDirectoryPath;
  if (GetPlatform.isDesktop) {
    applicationDataDirectoryPath =
        "${(await getApplicationSupportDirectory()).path}/db";
  } else {
    applicationDataDirectoryPath =
        (await getApplicationDocumentsDirectory()).path;
  }
  await Hive.initFlutter(applicationDataDirectoryPath);

  // Open critical boxes first (for app to start)
  await Hive.openBox("AppPrefs");

  // Open other boxes in parallel for better performance
  await Future.wait([
    Hive.openBox("SongsCache"),
    Hive.openBox("SongDownloads"),
    Hive.openBox('SongsUrlCache'),
    Hive.openBox("YTBCookies"),
  ]);

  // Initialize YouTube Cookie Manager in background
  unawaited(_initYouTubeCookieManager());
}

Future<void> _initYouTubeCookieManager() async {
  await YouTubeCookieManager.init();
  YouTubeCookieManager.startBackgroundCleanup();
}

Future<void> _setAppInitPrefsAsync() async {
  final appPrefs = Hive.box("AppPrefs");
  if (appPrefs.isEmpty) {
    appPrefs.putAll({
      'themeModeType': 0,
      "cacheSongs": false,
      "skipSilenceEnabled": false,
      'streamingQuality': 1,
      'themePrimaryColor': 4278199603,
      'discoverContentType': "QP",
      'newVersionVisibility': updateCheckFlag,
      "cacheHomeScreenData": true,
      'currentAppLanguageCode': "vi",
      'noOfHomeScreenContent': 7
    });
  }
}

/// Fallback app when main initialization fails
class FallbackApp extends StatefulWidget {
  const FallbackApp({super.key});

  @override
  State<FallbackApp> createState() => _FallbackAppState();
}

class _FallbackAppState extends State<FallbackApp> {
  bool _showRetry = false;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _showRetryAfterDelay();
  }

  void _showRetryAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showRetry = true;
          _status = 'Initialization taking longer than expected';
        });
      }
    });
  }

  void _retryInitialization() {
    setState(() {
      _showRetry = false;
      _status = 'Retrying...';
    });

    // Try to restart the app
    _initializeAndRestart();
  }

  Future<void> _initializeAndRestart() async {
    try {
      AppErrorHandler.logInfo('Retrying app initialization',
          context: 'Fallback');

      // Try basic initialization
      await initHive().timeout(const Duration(seconds: 5));
      await _setAppInitPrefsAsync();

      // If successful, navigate to main app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyApp()),
        );
      }
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Fallback Retry');
      if (mounted) {
        setState(() {
          _status = 'Unable to initialize. Please restart the app.';
          _showRetry = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harmony Music',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'Harmony Music',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _status,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                if (!_showRetry) ...[
                  CircularProgressIndicator(),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _retryInitialization,
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Force close app
                      SystemNavigator.pop();
                    },
                    child: Text('Close App'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else if (state == AppLifecycleState.detached) {
      try {
        await Get.find<AudioHandler>().customAction("saveSession");
      } catch (e) {
        AppErrorHandler.handleError(e, null, context: 'LifecycleHandler');
      }
    }
  }
}
