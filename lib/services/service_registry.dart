import 'package:get/get.dart' as getx;
import 'network_service.dart';
import 'cookie_service.dart';
import 'api_service.dart';
import 'youtube_data_parser_service.dart';
import 'music_service.dart';

/// Service Registry để quản lý tất cả các service dependencies
class ServiceRegistry {
  static ServiceRegistry? _instance;
  static ServiceRegistry get instance => _instance ??= ServiceRegistry._();

  ServiceRegistry._();

  bool _isInitialized = false;

  /// Initialize tất cả services theo đúng thứ tự dependency
  Future<void> initializeServices() async {
    if (_isInitialized) return;

    try {
      // Services sẽ được initialize lazily thông qua singleton pattern
      // Chỉ cần đảm bảo MusicServices được register với GetX
      if (!getx.Get.isRegistered<MusicServices>()) {
        getx.Get.put<MusicServices>(MusicServices(), permanent: true);
      }

      _isInitialized = true;
      print('✅ All services initialized successfully');
    } catch (e) {
      print('❌ Error initializing services: $e');
      rethrow;
    }
  }

  /// Clean up all services
  Future<void> cleanupServices() async {
    try {
      if (getx.Get.isRegistered<MusicServices>()) {
        await getx.Get.delete<MusicServices>();
      }

      _isInitialized = false;
      print('✅ All services cleaned up successfully');
    } catch (e) {
      print('❌ Error cleaning up services: $e');
    }
  }

  /// Get service instance
  T getService<T>() {
    return getx.Get.find<T>();
  }

  /// Check if services are initialized
  bool get isInitialized => _isInitialized;

  /// Get all service status for debugging
  Map<String, bool> getServiceStatus() {
    return {
      'MusicServices': getx.Get.isRegistered<MusicServices>(),
      'ServiceRegistry': _isInitialized,
    };
  }
}
