import '../utils/helper.dart';
import 'service_registry.dart';
import 'music_service.dart';

/// Simple startup test để kiểm tra services hoạt động
class ServiceStartupTest {
  static Future<bool> testBasicInitialization() async {
    try {
      printINFO('🧪 Testing basic service initialization...');

      // Test ServiceRegistry initialization
      await ServiceRegistry.instance.initializeServices();

      // Test MusicServices instance
      final musicService = ServiceRegistry.instance.getService<MusicServices>();

      // Test basic method call (không cần network)
      musicService.hlCode = 'en';

      printINFO('✅ Basic service initialization test passed');
      return true;
    } catch (e) {
      printERROR('❌ Basic service initialization test failed: $e');
      return false;
    }
  }

  static Future<bool> testServiceDependencies() async {
    try {
      printINFO('🧪 Testing service dependencies...');

      final musicService = ServiceRegistry.instance.getService<MusicServices>();

      // Test lazy initialization của các services
      // Các service sẽ được initialize khi được gọi lần đầu
      try {
        // Test NetworkService initialization
        final _ = musicService.networkService;
        printINFO('✅ NetworkService lazy initialization works');

        // Test CookieService initialization
        final __ = musicService.cookieService;
        printINFO('✅ CookieService lazy initialization works');

        // Test APIService initialization
        final ___ = musicService.apiService;
        printINFO('✅ APIService lazy initialization works');

        // Test ParserService initialization
        final ____ = musicService.parserService;
        printINFO('✅ ParserService lazy initialization works');
      } catch (e) {
        printERROR('❌ Service dependency test failed: $e');
        return false;
      }

      printINFO('✅ Service dependencies test passed');
      return true;
    } catch (e) {
      printERROR('❌ Service dependencies test failed: $e');
      return false;
    }
  }

  static Future<bool> runAllTests() async {
    printINFO('🚀 Starting Service Startup Tests...');

    final results = <String, bool>{};

    // Test basic initialization
    results['Basic Initialization'] = await testBasicInitialization();

    // Test service dependencies
    results['Service Dependencies'] = await testServiceDependencies();

    // Print results
    printINFO('📊 Service Startup Test Results:');
    printINFO('═══════════════════════════════════');

    results.forEach((testName, passed) {
      final status = passed ? '✅ PASS' : '❌ FAIL';
      printINFO('$status - $testName');
    });

    printINFO('═══════════════════════════════════');

    final totalTests = results.length;
    final passedTests = results.values.where((result) => result).length;
    final failedTests = totalTests - passedTests;

    printINFO(
        '📊 Summary: $passedTests/$totalTests passed, $failedTests failed');

    final allPassed = results.values.every((result) => result);
    if (allPassed) {
      printINFO('✅ All startup tests passed! Services are ready.');
    } else {
      printERROR('❌ Some startup tests failed! Check service configuration.');
    }

    return allPassed;
  }
}
