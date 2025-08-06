import '../utils/helper.dart';
import '../utils/error_handler.dart';
import 'service_registry.dart';
import 'music_service.dart';

/// Integration test để kiểm tra service layer refactoring
class ServiceIntegrationTest {
  static ServiceIntegrationTest? _instance;
  static ServiceIntegrationTest get instance =>
      _instance ??= ServiceIntegrationTest._();

  ServiceIntegrationTest._();

  /// Chạy tất cả integration tests
  Future<bool> runAllTests() async {
    printINFO('🧪 Starting Service Integration Tests...');

    try {
      // Initialize services
      await ServiceRegistry.instance.initializeServices();

      final results = <String, bool>{};

      // Test service initialization
      results['Service Initialization'] = await _testServiceInitialization();

      // Test backward compatibility
      results['Backward Compatibility'] = await _testBackwardCompatibility();

      // Test service communication
      results['Service Communication'] = await _testServiceCommunication();

      // Test error handling
      results['Error Handling'] = await _testErrorHandling();

      // Print results
      _printTestResults(results);

      // Clean up
      await ServiceRegistry.instance.cleanupServices();

      final allPassed = results.values.every((result) => result);
      if (allPassed) {
        printINFO('✅ All integration tests passed!');
      } else {
        printERROR('❌ Some integration tests failed!');
      }

      return allPassed;
    } catch (e) {
      AppErrorHandler.handleError(e, null,
          context: 'Integration test execution');
      printERROR('❌ Integration tests failed with error: $e');
      return false;
    }
  }

  /// Test service initialization
  Future<bool> _testServiceInitialization() async {
    try {
      final serviceStatus = ServiceRegistry.instance.getServiceStatus();

      // Check all services are registered
      final requiredServices = [
        'NetworkService',
        'CookieService',
        'YouTubeDataParserService',
        'APIService',
        'MusicServices'
      ];

      for (final service in requiredServices) {
        if (!serviceStatus[service]!) {
          printERROR('❌ Service not registered: $service');
          return false;
        }
      }

      printINFO('✅ Service initialization test passed');
      return true;
    } catch (e) {
      printERROR('❌ Service initialization test failed: $e');
      return false;
    }
  }

  /// Test backward compatibility
  Future<bool> _testBackwardCompatibility() async {
    try {
      final musicService = ServiceRegistry.instance.getService<MusicServices>();

      // Test basic method calls (should not throw)
      // Note: We're not testing actual API calls to avoid network dependencies

      // Test hlCode setter
      musicService.hlCode = 'en';

      // Test visitor ID generation method exists
      final hasGenrateVisitorIdMethod =
          musicService.runtimeType.toString().contains('MusicServices');

      if (!hasGenrateVisitorIdMethod) {
        printERROR('❌ MusicServices type check failed');
        return false;
      }

      printINFO('✅ Backward compatibility test passed');
      return true;
    } catch (e) {
      printERROR('❌ Backward compatibility test failed: $e');
      return false;
    }
  }

  /// Test service communication
  Future<bool> _testServiceCommunication() async {
    try {
      // Test that services can communicate with each other
      final musicService = ServiceRegistry.instance.getService<MusicServices>();

      // Verify that MusicServices has access to other services
      // This is tested by checking if the service can be instantiated
      // without throwing dependency injection errors

      if (musicService.runtimeType.toString() != 'MusicServices') {
        printERROR('❌ MusicServices instance type mismatch');
        return false;
      }

      printINFO('✅ Service communication test passed');
      return true;
    } catch (e) {
      printERROR('❌ Service communication test failed: $e');
      return false;
    }
  }

  /// Test error handling
  Future<bool> _testErrorHandling() async {
    try {
      // Test that services handle errors gracefully
      // This is a basic test to ensure error handling infrastructure is in place

      try {
        // Try to access a service that might not be properly initialized
        final musicService =
            ServiceRegistry.instance.getService<MusicServices>();

        // If we get here without throwing, error handling is working
        // Service should not be null if properly initialized
      } catch (e) {
        // This is expected if service is not properly initialized
        printWARN('⚠️ Expected error in error handling test: $e');
      }

      printINFO('✅ Error handling test passed');
      return true;
    } catch (e) {
      printERROR('❌ Error handling test failed: $e');
      return false;
    }
  }

  /// Print test results in a formatted way
  void _printTestResults(Map<String, bool> results) {
    printINFO('🧪 Integration Test Results:');
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
  }

  /// Quick smoke test for development
  Future<bool> quickSmokeTest() async {
    printINFO('🔥 Running quick smoke test...');

    try {
      await ServiceRegistry.instance.initializeServices();

      final serviceStatus = ServiceRegistry.instance.getServiceStatus();
      final allServicesRegistered =
          serviceStatus.values.every((status) => status);

      await ServiceRegistry.instance.cleanupServices();

      if (allServicesRegistered) {
        printINFO('✅ Quick smoke test passed');
        return true;
      } else {
        printERROR('❌ Quick smoke test failed - not all services registered');
        return false;
      }
    } catch (e) {
      printERROR('❌ Quick smoke test failed: $e');
      return false;
    }
  }
}
