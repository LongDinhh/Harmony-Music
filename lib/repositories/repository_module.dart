import 'package:get/get.dart';

// Interfaces
import 'interfaces/music_repository.dart';
import 'interfaces/library_repository.dart';
import 'interfaces/cache_repository.dart';
import 'interfaces/user_repository.dart';

// Implementations
import 'implementations/youtube_music_repository.dart';
import 'implementations/hive_library_repository.dart';
import 'implementations/hive_cache_repository.dart';
import 'implementations/hive_user_repository.dart';

// Services
import '../services/music_service.dart';
import '../services/api_service.dart';

/// Repository module for dependency injection setup
class RepositoryModule {
  /// Initialize and register all repositories with GetX dependency injection
  static Future<void> init() async {
    // Register repositories in order of dependencies
    
    // 1. First register the cache repository (no dependencies)
    Get.lazyPut<CacheRepository>(
      () => HiveCacheRepository(),
      fenix: true,
    );
    
    // 2. Register user repository (no dependencies)
    Get.lazyPut<UserRepository>(
      () => HiveUserRepository(),
      fenix: true,
    );
    
    // 3. Register library repository (no dependencies)
    Get.lazyPut<LibraryRepository>(
      () => HiveLibraryRepository(),
      fenix: true,
    );
    
    // 4. Register APIService first (extracted from MusicServices)
    Get.lazyPut<APIService>(
      () => Get.find<MusicServices>().apiService,
      fenix: true,
    );

    // 5. Register music repository (uses YouTubeMusicRepository)
    Get.lazyPut<MusicRepository>(
      () => YouTubeMusicRepository(
        Get.find<APIService>(),
        Get.find<CacheRepository>(),
      ),
      fenix: true,
    );
  }
  
  /// Clean up all repositories
  static void dispose() {
    if (Get.isRegistered<MusicRepository>()) {
      Get.delete<MusicRepository>();
    }
    if (Get.isRegistered<LibraryRepository>()) {
      Get.delete<LibraryRepository>();
    }
    if (Get.isRegistered<CacheRepository>()) {
      Get.delete<CacheRepository>();
    }
    if (Get.isRegistered<UserRepository>()) {
      Get.delete<UserRepository>();
    }
  }
  
  /// Reset all repositories (useful for testing or app reset)
  static Future<void> reset() async {
    dispose();
    await init();
  }
}