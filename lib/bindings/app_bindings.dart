import 'package:get/get.dart';
import '/services/music_service.dart';
import '/services/downloader.dart';
import '/services/piped_service.dart';
import '/ui/player/player_controller.dart';
import '/ui/screens/Home/home_screen_controller.dart';
import '/ui/screens/Settings/settings_screen_controller.dart';
import '/ui/screens/Library/library_controller.dart';
import '/ui/screens/Artists/artist_screen_controller.dart';
import '/ui/utils/theme_controller.dart';
import '/repositories/repositories.dart';

/// App-wide dependency injection bindings
/// This ensures proper lifecycle management and prevents memory leaks
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Core services - initialized once per app lifecycle
    _bindCoreServices();

    // Repository layer - data access layer
    _bindRepositories();

    // UI controllers - with proper lifecycle management
    _bindUIControllers();

    // Feature-specific controllers - lazy loaded
    _bindFeatureControllers();
  }

  /// Core services that should persist throughout app lifecycle
  void _bindCoreServices() {
    // Background services - lazy loaded to prevent initialization blocking
    Get.lazyPut<MusicServices>(
      () => MusicServices(),
      fenix: true,
    );

    Get.lazyPut<Downloader>(
      () => Downloader(),
      fenix: true,
    );

    Get.lazyPut<PipedServices>(
      () => PipedServices(),
      fenix: true,
    );
  }

  /// Repository layer - clean architecture data access layer
  void _bindRepositories() {
    // Music repository - YouTube Music API integration
    Get.lazyPut<MusicRepository>(
      () => YouTubeMusicRepository(
        musicService: Get.find<MusicServices>(),
      ),
      fenix: true,
    );

    // Library repository - local Hive database
    Get.lazyPut<LibraryRepository>(
      () => HiveLibraryRepository(
        pipedService: Get.find<PipedServices>(),
      ),
      fenix: true,
    );

    // Cache repository - advanced caching with expiration
    Get.lazyPut<CacheRepository>(
      () => HiveCacheRepository(),
      fenix: true,
    );
  }

  /// UI controllers with lifecycle awareness
  void _bindUIControllers() {
    // UI controllers - lazy loaded to prevent white screen during startup
    Get.lazyPut<PlayerController>(
      () => PlayerController(),
      fenix: true,
    );

    Get.lazyPut<SettingsScreenController>(
      () => SettingsScreenController(),
      fenix: true,
    );

    Get.lazyPut<ThemeController>(
      () => ThemeController(),
      fenix: true,
    );

    Get.lazyPut<HomeScreenController>(
      () => HomeScreenController(),
      fenix: true,
    );
  }

  /// Feature controllers - lazy loaded to optimize memory
  void _bindFeatureControllers() {
    // Library controllers - lazy loaded when needed
    Get.lazyPut<LibrarySongsController>(
      () => LibrarySongsController(),
    );

    Get.lazyPut<LibraryPlaylistsController>(
      () => LibraryPlaylistsController(),
    );

    // Artist screen controller - created when needed, disposed when not used
    Get.lazyPut<ArtistScreenController>(
      () => ArtistScreenController(),
      fenix: false, // Don't recreate automatically
    );
  }
}

/// Bindings for specific screens that need custom lifecycle management
class HomeBindings extends Bindings {
  @override
  void dependencies() {
    // Only bind what's specifically needed for Home screen
    if (!Get.isRegistered<HomeScreenController>()) {
      Get.put<HomeScreenController>(
        HomeScreenController(),
        permanent: true,
      );
    }
  }
}

/// Bindings for Artist screen with proper cleanup
class ArtistBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ArtistScreenController>(
      () => ArtistScreenController(),
      fenix: false,
    );
  }
}

/// Bindings for Library screens
class LibraryBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LibrarySongsController>(
      () => LibrarySongsController(),
    );

    Get.lazyPut<LibraryPlaylistsController>(
      () => LibraryPlaylistsController(),
    );
  }
}
