#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:math';

// Mock performance timeline generator
class MockTimelineGenerator {
  final Random _random = Random();

  Future<void> generateMockTimeline() async {
    print(
        '🔥 Generating mock performance timeline based on detected hotspots...');

    // Read the rebuild hotspots data
    final hotspotsFile = File('widget_complexity_analysis.json');
    if (!await hotspotsFile.exists()) {
      throw Exception(
          'Please run rebuild_analyzer.dart first to generate hotspots data');
    }

    final hotspotsData = jsonDecode(await hotspotsFile.readAsString());
    final hotspots = hotspotsData['rebuildHotspots'] as List;
    final topHotspots = hotspots.take(20).toList(); // Top 20 hotspots

    // Generate timeline events
    final timelineEvents = <Map<String, dynamic>>[];

    // Simulate 30 seconds of profiling data
    const profileDurationMs = 30000;
    const frameTargetMs = 16.67; // 60 FPS target

    var currentTimeMs = 0;
    var frameNumber = 0;

    print('📊 Simulating navigation: Home → Player → Settings...');

    while (currentTimeMs < profileDurationMs) {
      // Generate frame events
      final frameBuildTime =
          _generateFrameBuildTime(currentTimeMs, topHotspots);

      // Frame start
      timelineEvents.add({
        'name': 'Frame',
        'cat': 'flutter',
        'ph': 'B', // Begin
        'ts': currentTimeMs * 1000, // Convert to microseconds
        'pid': 1,
        'tid': 1,
        'args': {
          'frame': frameNumber,
        }
      });

      // Widget build events
      var buildStartTime = currentTimeMs + 2;
      for (final hotspot in topHotspots) {
        final buildTime = hotspot['estimatedBuildTimeMs'] as double;
        final variance = buildTime * 0.3; // 30% variance
        final actualBuildTime =
            buildTime + (_random.nextDouble() - 0.5) * variance;

        if (actualBuildTime > 1.0 && _random.nextDouble() < 0.8) {
          // 80% chance of rebuild
          // Widget build start
          timelineEvents.add({
            'name': 'Build ${_extractWidgetName(hotspot)}',
            'cat': 'flutter',
            'ph': 'B',
            'ts': buildStartTime * 1000,
            'pid': 1,
            'tid': 1,
            'args': {
              'file': hotspot['filePath'],
              'line': hotspot['line'],
              'rebuilds': hotspot['estimatedRebuildsPerMinute'],
            }
          });

          // Widget build end
          timelineEvents.add({
            'name': 'Build ${_extractWidgetName(hotspot)}',
            'cat': 'flutter',
            'ph': 'E',
            'ts': (buildStartTime + actualBuildTime.round()) * 1000,
            'pid': 1,
            'tid': 1,
          });

          buildStartTime += actualBuildTime.round() + 1;
        }
      }

      // Frame end
      timelineEvents.add({
        'name': 'Frame',
        'cat': 'flutter',
        'ph': 'E',
        'ts': (currentTimeMs + frameBuildTime.round()) * 1000,
        'pid': 1,
        'tid': 1,
        'args': {
          'duration_ms': frameBuildTime,
          'janky': frameBuildTime > frameTargetMs,
        }
      });

      // Add memory usage events
      if (frameNumber % 10 == 0) {
        timelineEvents.add({
          'name': 'Memory Usage',
          'cat': 'memory',
          'ph': 'C', // Counter
          'ts': currentTimeMs * 1000,
          'pid': 1,
          'args': {
            'heap': 45000000 + _random.nextInt(10000000), // 45-55 MB
            'rss': 120000000 + _random.nextInt(20000000), // 120-140 MB
          }
        });
      }

      currentTimeMs += frameBuildTime.round();
      frameNumber++;
    }

    // Create performance timeline JSON
    final timeline = {
      'traceEvents': timelineEvents,
      'displayTimeUnit': 'ms',
      'otherData': {
        'version': '1.0.0',
        'profileName': 'Harmony Music - Rebuild Hotspots Analysis',
        'generatedBy': 'Mock Timeline Generator',
        'profileDuration': '${profileDurationMs}ms',
        'totalFrames': frameNumber,
        'averageFps': (frameNumber / (profileDurationMs / 1000)).round(),
        'jankyFrames': timelineEvents
            .where((e) =>
                e['name'] == 'Frame' &&
                e['ph'] == 'E' &&
                (e['args']?['janky'] == true))
            .length,
      }
    };

    // Save timeline
    await File('flutter_performance_timeline.json')
        .writeAsString(JsonEncoder.withIndent('  ').convert(timeline));

    // Generate widget rebuild summary
    await _generateRebuildSummary(topHotspots, frameNumber);

    // Generate flame chart data for visualization
    await _generateFlameChartData(timelineEvents);

    print('✅ Mock timeline generation complete!');
    print('📁 Generated files:');
    print('  - flutter_performance_timeline.json');
    print('  - widget_rebuild_summary.json');
    print('  - flame_chart_data.json');
    print('');
    print('📈 Performance Summary:');
    print('  - Total frames: $frameNumber');
    print('  - Profile duration: ${profileDurationMs}ms');
    print(
        '  - Average FPS: ${(frameNumber / (profileDurationMs / 1000)).round()}');
    print(
        '  - Janky frames: ${timelineEvents.where((e) => e['name'] == 'Frame' && e['ph'] == 'E' && (e['args']?['janky'] == true)).length}');
  }

  double _generateFrameBuildTime(int currentTimeMs, List topHotspots) {
    // Base frame time
    var frameTime = 12.0; // Base 12ms

    // Add complexity based on navigation phase
    if (currentTimeMs < 10000) {
      // Home screen phase
      frameTime += 3.0;
    } else if (currentTimeMs < 20000) {
      // Player screen phase
      frameTime += 8.0; // Player has more rebuilds
    } else {
      // Settings screen phase
      frameTime += 5.0; // Settings has dropdown rebuilds
    }

    // Add random variance
    frameTime += (_random.nextDouble() - 0.5) * 4.0;

    // Occasionally add frame spikes for heavy rebuilds
    if (_random.nextDouble() < 0.05) {
      // 5% chance
      frameTime += 10.0 + _random.nextDouble() * 15.0;
    }

    return frameTime.clamp(8.0, 50.0); // Keep reasonable bounds
  }

  String _extractWidgetName(Map<String, dynamic> hotspot) {
    final filePath = hotspot['filePath'] as String;
    final fileName = filePath.split('/').last.replaceAll('.dart', '');
    final widgetName = hotspot['widgetName'] as String;

    if (widgetName != 'Unknown') {
      return widgetName;
    }

    // Extract widget name from filename
    return fileName
        .split('_')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join('');
  }

  Future<void> _generateRebuildSummary(
      List topHotspots, int totalFrames) async {
    final summary = {
      'rebuildAnalysis': {
        'profileDuration': '30s',
        'totalFrames': totalFrames,
        'targetFPS': 60,
        'actualFPS': (totalFrames / 30).round(),
      },
      'topRebuilders': topHotspots.map((hotspot) {
        final estimatedRebuilds =
            (hotspot['estimatedRebuildsPerMinute'] as int) / 2; // 30s = 0.5 min
        return {
          'widget': _extractWidgetName(hotspot),
          'file': hotspot['filePath'],
          'line': hotspot['line'],
          'rebuildsInProfile': estimatedRebuilds,
          'avgBuildTimeMs': hotspot['estimatedBuildTimeMs'],
          'totalBuildTimeMs':
              estimatedRebuilds * (hotspot['estimatedBuildTimeMs'] as double),
          'severity': hotspot['severity'],
          'reason': hotspot['reason'],
        };
      }).toList(),
      'performanceMetrics': {
        'widgetsOver200RebuildsPer30s': topHotspots
            .where((h) => (h['estimatedRebuildsPerMinute'] as int) / 2 > 100)
            .length,
        'widgetsOver5msBuildTime': topHotspots
            .where((h) => (h['estimatedBuildTimeMs'] as double) > 5.0)
            .length,
        'totalEstimatedRebuildTimeMs': topHotspots.fold(
            0.0,
            (sum, h) =>
                sum +
                ((h['estimatedRebuildsPerMinute'] as int) /
                    2 *
                    (h['estimatedBuildTimeMs'] as double))),
      },
      'recommendations': [
        'Add RepaintBoundary around MiniPlayer to isolate rebuilds',
        'Use const constructors where possible in player components',
        'Consider extracting Obx widgets to separate methods with keys',
        'Optimize Settings screen dropdowns with SelectableBuilder pattern',
        'Add widget keys to ListView items to prevent unnecessary rebuilds',
      ],
      'generatedAt': DateTime.now().toIso8601String(),
    };

    await File('widget_rebuild_summary.json')
        .writeAsString(JsonEncoder.withIndent('  ').convert(summary));
  }

  Future<void> _generateFlameChartData(
      List<Map<String, dynamic>> events) async {
    // Process events into flame chart format
    final flameChartData = {
      'type': 'FlameChart',
      'frames': _processEventsIntoFrames(events),
      'totalDuration': 30000,
      'metadata': {
        'sampleCount': events.length,
        'frameCount':
            events.where((e) => e['name'] == 'Frame' && e['ph'] == 'B').length,
        'profileType': 'Widget Rebuild Analysis',
      }
    };

    await File('flame_chart_data.json')
        .writeAsString(JsonEncoder.withIndent('  ').convert(flameChartData));
  }

  List<Map<String, dynamic>> _processEventsIntoFrames(
      List<Map<String, dynamic>> events) {
    final frames = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentFrame;
    final openEvents = <String, Map<String, dynamic>>{};

    for (final event in events) {
      if (event['name'] == 'Frame') {
        if (event['ph'] == 'B') {
          currentFrame = {
            'start': event['ts'],
            'duration': 0,
            'widgets': <Map<String, dynamic>>[],
          };
        } else if (event['ph'] == 'E' && currentFrame != null) {
          currentFrame['duration'] =
              (event['ts'] as int) - (currentFrame['start'] as int);
          currentFrame['janky'] = event['args']?['janky'] ?? false;
          frames.add(currentFrame);
          currentFrame = null;
        }
      } else if (event['name'].toString().startsWith('Build ')) {
        if (event['ph'] == 'B') {
          openEvents[event['name']] = event;
        } else if (event['ph'] == 'E') {
          final startEvent = openEvents.remove(event['name']);
          if (startEvent != null && currentFrame != null) {
            (currentFrame['widgets'] as List).add({
              'name': event['name'],
              'start':
                  (startEvent['ts'] as int) - (currentFrame['start'] as int),
              'duration': (event['ts'] as int) - (startEvent['ts'] as int),
              'file': startEvent['args']?['file'],
              'line': startEvent['args']?['line'],
            });
          }
        }
      }
    }

    return frames;
  }
}

Future<void> main() async {
  try {
    final generator = MockTimelineGenerator();
    await generator.generateMockTimeline();
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
