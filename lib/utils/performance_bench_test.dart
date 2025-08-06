import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'performance_testing.dart';
import '../ui/player/player_controller.dart';

/// Performance bench testing utility for measuring rebuild performance
class PerformanceBenchTest {
  static const Duration _testDuration = Duration(seconds: 30);
  static const Duration _skipTrackInterval = Duration(seconds: 5);
  static const Duration _panelToggleInterval = Duration(seconds: 7);
  
  static Timer? _testTimer;
  static Timer? _skipTrackTimer;
  static Timer? _panelToggleTimer;
  
  static Map<String, int>? _baselineResults;
  static Map<String, int>? _optimizedResults;
  
  /// Start performance benchmark test
  static void startBenchmarkTest({
    bool enableDebugPrint = true,
    bool isBaseline = false,
  }) {
    if (!kDebugMode) {
      print('Performance testing is only available in debug mode');
      return;
    }
    
    print('\n🔥 Starting Performance Benchmark Test ${isBaseline ? "(BASELINE)" : "(OPTIMIZED)"}\n');
    print('Test Duration: ${_testDuration.inSeconds} seconds');
    print('Track Skip Interval: ${_skipTrackInterval.inSeconds} seconds');
    print('Panel Toggle Interval: ${_panelToggleInterval.inSeconds} seconds\n');
    
    // Reset counters and enable debug printing
    PerformanceTesting.resetCounters();
    if (enableDebugPrint) {
      PerformanceTesting.enableDebugRebuildPrint();
    }
    
    // Start the test timer
    _testTimer = Timer(_testDuration, () {
      _stopBenchmarkTest(isBaseline: isBaseline);
    });
    
    // Start automated interactions
    _startAutomatedInteractions();
  }
  
  /// Stop performance benchmark test
  static void _stopBenchmarkTest({required bool isBaseline}) {
    // Stop all timers
    _testTimer?.cancel();
    _skipTrackTimer?.cancel();
    _panelToggleTimer?.cancel();
    
    // Disable debug printing
    PerformanceTesting.disableDebugRebuildPrint();
    
    // Get final results
    final results = PerformanceTesting.getRebuildCounts();
    
    if (isBaseline) {
      _baselineResults = Map.from(results);
      print('\n📊 BASELINE TEST RESULTS CAPTURED\n');
    } else {
      _optimizedResults = Map.from(results);
      print('\n📊 OPTIMIZED TEST RESULTS CAPTURED\n');
    }
    
    // Print results
    _printBenchmarkResults(results, isBaseline);
    
    // If we have both results, compare them
    if (_baselineResults != null && _optimizedResults != null) {
      _printComparisonResults();
    }
  }
  
  /// Start automated interactions for testing
  static void _startAutomatedInteractions() {
    final playerController = Get.find<PlayerController>();
    
    // Skip tracks every 5 seconds
    _skipTrackTimer = Timer.periodic(_skipTrackInterval, (timer) {
      try {
        playerController.next();
        print('🎵 Skipped to next track (${timer.tick})');
      } catch (e) {
        print('❌ Error skipping track: $e');
      }
    });
    
    // Toggle panels every 7 seconds
    _panelToggleTimer = Timer.periodic(_panelToggleInterval, (timer) {
      try {
        if (playerController.playerPanelController.isPanelOpen) {
          playerController.playerPanelController.close();
          print('📱 Closed player panel (${timer.tick})');
        } else {
          playerController.playerPanelController.open();
          print('📱 Opened player panel (${timer.tick})');
        }
        
        // Also toggle queue panel occasionally
        if (timer.tick % 3 == 0) {
          if (playerController.queuePanelController.isPanelOpen) {
            playerController.queuePanelController.close();
            print('📜 Closed queue panel (${timer.tick})');
          } else {
            playerController.queuePanelController.open();
            print('📜 Opened queue panel (${timer.tick})');
          }
        }
      } catch (e) {
        print('❌ Error toggling panel: $e');
      }
    });
    
    print('🤖 Automated interactions started');
  }
  
  /// Print benchmark results
  static void _printBenchmarkResults(Map<String, int> results, bool isBaseline) {
    final testType = isBaseline ? 'BASELINE' : 'OPTIMIZED';
    
    print('='.padRight(60, '='));
    print('$testType TEST RESULTS');
    print('='.padRight(60, '='));
    
    // Sort by rebuild count (descending)
    final sortedEntries = results.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    print('Widget Name'.padRight(40) + 'Rebuilds');
    print('-'.padRight(60, '-'));
    
    for (final entry in sortedEntries) {
      print('${entry.key.padRight(40)} ${entry.value}');
    }
    
    final totalRebuilds = results.values.fold(0, (sum, count) => sum + count);
    print('-'.padRight(60, '-'));
    print('${'TOTAL REBUILDS'.padRight(40)} $totalRebuilds');
    print('='.padRight(60, '='));
    print('');
  }
  
  /// Print comparison results between baseline and optimized
  static void _printComparisonResults() {
    if (_baselineResults == null || _optimizedResults == null) return;
    
    print('🔍 PERFORMANCE COMPARISON ANALYSIS');
    print('='.padRight(80, '='));
    
    // Get all unique widget names
    final allWidgets = {..._baselineResults!.keys, ..._optimizedResults!.keys};
    
    print('Widget Name'.padRight(30) + 
          'Baseline'.padRight(12) + 
          'Optimized'.padRight(12) + 
          'Difference'.padRight(12) + 
          'Improvement');
    print('-'.padRight(80, '-'));
    
    var totalBaselineRebuilds = 0;
    var totalOptimizedRebuilds = 0;
    
    for (final widget in allWidgets) {
      final baselineCount = _baselineResults![widget] ?? 0;
      final optimizedCount = _optimizedResults![widget] ?? 0;
      final difference = baselineCount - optimizedCount;
      final improvement = baselineCount > 0 
          ? ((difference / baselineCount) * 100).toStringAsFixed(1) + '%'
          : 'N/A';
      
      totalBaselineRebuilds += baselineCount;
      totalOptimizedRebuilds += optimizedCount;
      
      // Color coding for terminal output
      final diffIcon = difference > 0 ? '✅' : difference < 0 ? '❌' : '➖';
      
      print('${widget.padRight(30)} '
           '${baselineCount.toString().padRight(12)} '
           '${optimizedCount.toString().padRight(12)} '
           '${difference.toString().padRight(12)} '
           '$diffIcon $improvement');
    }
    
    print('-'.padRight(80, '-'));
    
    final totalDifference = totalBaselineRebuilds - totalOptimizedRebuilds;
    final totalImprovement = totalBaselineRebuilds > 0 
        ? ((totalDifference / totalBaselineRebuilds) * 100).toStringAsFixed(1) + '%'
        : 'N/A';
    
    print('${'TOTAL'.padRight(30)} '
         '${totalBaselineRebuilds.toString().padRight(12)} '
         '${totalOptimizedRebuilds.toString().padRight(12)} '
         '${totalDifference.toString().padRight(12)} '
         '🎯 $totalImprovement');
    
    print('='.padRight(80, '='));
    
    // Summary
    print('\n📈 SUMMARY:');
    print('• Baseline Total Rebuilds: $totalBaselineRebuilds');
    print('• Optimized Total Rebuilds: $totalOptimizedRebuilds');
    print('• Rebuild Reduction: $totalDifference rebuilds');
    print('• Performance Improvement: $totalImprovement');
    
    // Check if we achieved the 60% improvement target
    final targetReduction = totalBaselineRebuilds * 0.6;
    if (totalDifference >= targetReduction) {
      print('🎉 TARGET ACHIEVED: 60%+ rebuild reduction!');
    } else {
      final actualPercentage = totalBaselineRebuilds > 0 
          ? (totalDifference / totalBaselineRebuilds * 100).toStringAsFixed(1)
          : '0';
      print('⚠️  Target not met. Current improvement: $actualPercentage% (Target: 60%)');
    }
    
    print('');
  }
  
  /// Generate markdown report
  static String generateMarkdownReport() {
    if (_baselineResults == null || _optimizedResults == null) {
      return '# Performance Test Results\n\nIncomplete test data. Please run both baseline and optimized tests.';
    }
    
    final buffer = StringBuffer();
    
    buffer.writeln('# Performance Refactor Results');
    buffer.writeln('');
    buffer.writeln('## Test Configuration');
    buffer.writeln('- Test Duration: ${_testDuration.inSeconds} seconds');
    buffer.writeln('- Track Skip Interval: ${_skipTrackInterval.inSeconds} seconds');
    buffer.writeln('- Panel Toggle Interval: ${_panelToggleInterval.inSeconds} seconds');
    buffer.writeln('- Test Date: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    
    // Calculate totals
    final totalBaselineRebuilds = _baselineResults!.values.fold(0, (sum, count) => sum + count);
    final totalOptimizedRebuilds = _optimizedResults!.values.fold(0, (sum, count) => sum + count);
    final totalDifference = totalBaselineRebuilds - totalOptimizedRebuilds;
    final totalImprovement = totalBaselineRebuilds > 0 
        ? ((totalDifference / totalBaselineRebuilds) * 100).toStringAsFixed(1)
        : '0';
    
    buffer.writeln('## Summary');
    buffer.writeln('| Metric | Value |');
    buffer.writeln('|--------|-------|');
    buffer.writeln('| Baseline Total Rebuilds | $totalBaselineRebuilds |');
    buffer.writeln('| Optimized Total Rebuilds | $totalOptimizedRebuilds |');
    buffer.writeln('| Rebuild Reduction | $totalDifference |');
    buffer.writeln('| Performance Improvement | $totalImprovement% |');
    buffer.writeln('');
    
    // Detailed results table
    buffer.writeln('## Detailed Results');
    buffer.writeln('| Widget Name | Baseline | Optimized | Difference | Improvement |');
    buffer.writeln('|-------------|----------|-----------|------------|-------------|');
    
    // Get all unique widget names and sort by baseline rebuilds
    final allWidgets = {..._baselineResults!.keys, ..._optimizedResults!.keys}
        .toList()
        ..sort((a, b) => (_baselineResults![b] ?? 0).compareTo(_baselineResults![a] ?? 0));
    
    for (final widget in allWidgets) {
      final baselineCount = _baselineResults![widget] ?? 0;
      final optimizedCount = _optimizedResults![widget] ?? 0;
      final difference = baselineCount - optimizedCount;
      final improvement = baselineCount > 0 
          ? ((difference / baselineCount) * 100).toStringAsFixed(1) + '%'
          : 'N/A';
      
      buffer.writeln('| $widget | $baselineCount | $optimizedCount | $difference | $improvement |');
    }
    
    buffer.writeln('');
    
    // Hottest rebuild areas
    buffer.writeln('## Hottest Rebuild Areas');
    buffer.writeln('These components had the highest rebuild counts:');
    buffer.writeln('');
    
    final hotAreas = _baselineResults!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < 5 && i < hotAreas.length; i++) {
      final entry = hotAreas[i];
      final optimizedCount = _optimizedResults![entry.key] ?? 0;
      final reduction = entry.value - optimizedCount;
      
      buffer.writeln('${i + 1}. **${entry.key}**: ${entry.value} → $optimizedCount rebuilds (${reduction} reduction)');
    }
    
    buffer.writeln('');
    
    // Conclusion
    buffer.writeln('## Conclusion');
    final targetReduction = totalBaselineRebuilds * 0.6;
    if (totalDifference >= targetReduction) {
      buffer.writeln('✅ **Target Achieved**: Successfully reduced rebuilds by $totalImprovement%, exceeding the 60% target.');
    } else {
      buffer.writeln('⚠️ **Target Not Met**: Achieved $totalImprovement% reduction, target was 60%.');
    }
    
    buffer.writeln('');
    buffer.writeln('The performance refactor focused on:');
    buffer.writeln('- Wrapping hot rebuild areas with `PerformanceOverlay` tracking');
    buffer.writeln('- Implementing granular reactive widgets with `Obx()` wrappers');
    buffer.writeln('- Optimizing widget rebuild boundaries in mini player components');
    buffer.writeln('- Adding performance tracking to player controls and queue panels');
    
    return buffer.toString();
  }
  
  /// Save results to markdown file
  static Future<void> saveResultsToFile() async {
    try {
      final markdownContent = generateMarkdownReport();
      
      // In a real app, you would write to file here
      // For now, just print the markdown content
      print('\n📄 MARKDOWN REPORT GENERATED:\n');
      print(markdownContent);
      
      developer.log(
        'Performance test results ready for docs/perf_refactor_results.md',
        name: 'PerformanceBenchTest',
      );
    } catch (e) {
      print('❌ Error generating report: $e');
    }
  }
  
  /// Quick test for specific scenarios
  static void runQuickTest(String scenario) {
    switch (scenario) {
      case 'skip-tracks':
        _runTrackSkipTest();
        break;
      case 'panel-toggle':
        _runPanelToggleTest();
        break;
      default:
        print('Unknown test scenario: $scenario');
    }
  }
  
  static void _runTrackSkipTest() {
    print('🎵 Running track skip test...');
    PerformanceTesting.resetCounters();
    PerformanceTesting.enableDebugRebuildPrint();
    
    final playerController = Get.find<PlayerController>();
    
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (timer.tick > 20) {
        timer.cancel();
        PerformanceTesting.disableDebugRebuildPrint();
        PerformanceTesting.printRebuildStats();
        return;
      }
      
      playerController.next();
    });
  }
  
  static void _runPanelToggleTest() {
    print('📱 Running panel toggle test...');
    PerformanceTesting.resetCounters();
    PerformanceTesting.enableDebugRebuildPrint();
    
    final playerController = Get.find<PlayerController>();
    
    Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (timer.tick > 10) {
        timer.cancel();
        PerformanceTesting.disableDebugRebuildPrint();
        PerformanceTesting.printRebuildStats();
        return;
      }
      
      if (playerController.playerPanelController.isPanelOpen) {
        playerController.playerPanelController.close();
      } else {
        playerController.playerPanelController.open();
      }
    });
  }
}
