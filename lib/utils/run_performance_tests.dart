import 'dart:async';
import 'package:flutter/foundation.dart';
import 'performance_bench_test.dart';
import 'performance_testing.dart';

/// Example script for running performance tests
/// 
/// Usage:
/// 1. Run in debug mode with `flutter run --debug`
/// 2. Call `RunPerformanceTests.runFullBenchmark()` from anywhere in your app
/// 3. Wait for tests to complete and check console output
/// 4. Results will be printed and ready for documentation

class RunPerformanceTests {
  
  /// Run the complete benchmark test suite
  static Future<void> runFullBenchmark() async {
    if (!kDebugMode) {
      print('❌ Performance tests require debug mode. Run with `flutter run --debug`');
      return;
    }
    
    print('🚀 Starting Full Performance Benchmark Suite');
    print('This will take approximately 60 seconds to complete...\n');
    
    // Step 1: Run baseline test (simulating pre-optimization)
    print('🏁 Step 1: Running BASELINE test...');
    await _runBaselineTest();
    
    // Wait between tests
    print('⏳ Waiting 5 seconds between tests...\n');
    await Future.delayed(Duration(seconds: 5));
    
    // Step 2: Run optimized test
    print('⚡ Step 2: Running OPTIMIZED test...');
    await _runOptimizedTest();
    
    // Step 3: Generate final report
    print('📊 Step 3: Generating performance report...');
    await PerformanceBenchTest.saveResultsToFile();
    
    print('✅ Performance benchmark complete!');
    print('📄 Check the output above for the markdown report to add to docs/perf_refactor_results.md');
  }
  
  /// Run baseline test (simulate pre-optimization performance)
  static Future<void> _runBaselineTest() async {
    // For demonstration, we'll simulate a baseline by temporarily removing tracking
    // In practice, you would run this with the old version of the code
    
    final completer = Completer<void>();
    
    print('Starting baseline performance test...');
    PerformanceBenchTest.startBenchmarkTest(
      isBaseline: true,
      enableDebugPrint: false, // Reduce console noise for demo
    );
    
    // Wait for test to complete (30 seconds)
    Timer(Duration(seconds: 32), () {
      completer.complete();
    });
    
    await completer.future;
    print('✓ Baseline test completed\n');
  }
  
  /// Run optimized test (with performance tracking)
  static Future<void> _runOptimizedTest() async {
    final completer = Completer<void>();
    
    print('Starting optimized performance test...');
    PerformanceBenchTest.startBenchmarkTest(
      isBaseline: false,
      enableDebugPrint: false, // Reduce console noise for demo
    );
    
    // Wait for test to complete (30 seconds)
    Timer(Duration(seconds: 32), () {
      completer.complete();
    });
    
    await completer.future;
    print('✓ Optimized test completed\n');
  }
  
  /// Run quick demonstration tests
  static void runQuickDemo() {
    if (!kDebugMode) {
      print('❌ Performance tests require debug mode');
      return;
    }
    
    print('🎯 Running Quick Performance Demo\n');
    
    // Enable performance tracking
    PerformanceTesting.enableDebugRebuildPrint();
    
    // Run a quick track skip test
    print('Testing track skip performance...');
    PerformanceBenchTest.runQuickTest('skip-tracks');
    
    Timer(Duration(seconds: 12), () {
      print('\nTesting panel toggle performance...');
      PerformanceBenchTest.runQuickTest('panel-toggle');
      
      Timer(Duration(seconds: 12), () {
        print('\n📊 Quick demo completed!');
        PerformanceTesting.printRebuildStats();
        PerformanceTesting.disableDebugRebuildPrint();
      });
    });
  }
  
  /// Enable/disable performance tracking manually
  static void enablePerformanceTracking({bool enabled = true}) {
    if (!kDebugMode) {
      print('❌ Performance tracking requires debug mode');
      return;
    }
    
    if (enabled) {
      PerformanceTesting.enableDebugRebuildPrint();
      print('✅ Performance tracking enabled');
    } else {
      PerformanceTesting.disableDebugRebuildPrint();
      print('🔇 Performance tracking disabled');
    }
  }
  
  /// Print current rebuild statistics
  static void printCurrentStats() {
    if (!kDebugMode) {
      print('❌ Performance stats require debug mode');
      return;
    }
    
    PerformanceTesting.printRebuildStats();
  }
  
  /// Reset performance counters
  static void resetCounters() {
    if (!kDebugMode) return;
    
    PerformanceTesting.resetCounters();
    print('🔄 Performance counters reset');
  }
}

/// Helper function to easily run tests from anywhere
void runPerformanceTests() {
  RunPerformanceTests.runFullBenchmark();
}

/// Helper function for quick testing
void runQuickPerformanceDemo() {
  RunPerformanceTests.runQuickDemo();
}

/// Example usage in widget code:
/// 
/// ```dart
/// // In any widget where you want to test performance
/// FloatingActionButton(
///   onPressed: () {
///     runPerformanceTests(); // Run full benchmark
///     // OR
///     runQuickPerformanceDemo(); // Run quick demo
///   },
///   child: Icon(Icons.speed),
/// )
/// ```
