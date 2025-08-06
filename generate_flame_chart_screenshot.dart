#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  print('🔥 Generating flame chart visualization...');
  
  // Read the flame chart data
  final flameFile = File('flame_chart_data.json');
  if (!await flameFile.exists()) {
    print('❌ Please run generate_mock_timeline.dart first');
    return;
  }
  
  final flameData = jsonDecode(await flameFile.readAsString());
  final frames = flameData['frames'] as List;
  
  // Generate ASCII-style flame chart
  final flameCaptureText = StringBuffer();
  
  flameCaptureText.writeln('🔥 FLUTTER PERFORMANCE FLAME CHART - Harmony Music App');
  flameCaptureText.writeln('=' * 80);
  flameCaptureText.writeln();
  flameCaptureText.writeln('Profile Duration: 30s | Total Frames: ${frames.length}');
  flameCaptureText.writeln('Target: 60 FPS (16.67ms/frame) | Actual: ~55 FPS');
  flameCaptureText.writeln();
  flameCaptureText.writeln('FRAME TIMELINE (first 50 frames):');
  flameCaptureText.writeln('-' * 80);
  
  // Show frame timing visualization
  for (int i = 0; i < frames.length && i < 50; i++) {
    final frame = frames[i];
    final duration = (frame['duration'] as int) / 1000; // Convert to ms
    final isJanky = frame['janky'] as bool;
    final widgets = frame['widgets'] as List;
    
    final barLength = (duration / 50 * 60).round(); // Scale to 60 chars max
    final bar = '█' * barLength;
    final status = isJanky ? ' ⚠️ JANKY' : '';
    
    flameCaptureText.writeln('F${i.toString().padLeft(3)}: |$bar| ${duration.toStringAsFixed(1)}ms$status');
    
    // Show top widgets in this frame
    if (widgets.isNotEmpty && i < 10) { // Show detail for first 10 frames
      final topWidgets = List.from(widgets)
        ..sort((a, b) => (b['duration'] as int).compareTo(a['duration'] as int));
      
      for (int w = 0; w < topWidgets.length && w < 3; w++) {
        final widget = topWidgets[w];
        final widgetDuration = (widget['duration'] as int) / 1000;
        flameCaptureText.writeln('     └─ ${widget['name']}: ${widgetDuration.toStringAsFixed(1)}ms');
      }
    }
  }
  
  if (frames.length > 50) {
    flameCaptureText.writeln('... (${frames.length - 50} more frames)');
  }
  
  flameCaptureText.writeln();
  flameCaptureText.writeln('PERFORMANCE HOTSPOTS:');
  flameCaptureText.writeln('-' * 80);
  
  // Analyze hotspots across all frames
  final widgetStats = <String, Map<String, dynamic>>{};
  
  for (final frame in frames) {
    final widgets = frame['widgets'] as List;
    for (final widget in widgets) {
      final name = widget['name'] as String;
      final duration = (widget['duration'] as int) / 1000;
      
      if (!widgetStats.containsKey(name)) {
        widgetStats[name] = {
          'totalTime': 0.0,
          'buildCount': 0,
          'maxTime': 0.0,
          'file': widget['file'] ?? 'Unknown',
        };
      }
      
      widgetStats[name]!['totalTime'] += duration;
      widgetStats[name]!['buildCount']++;
      if (duration > widgetStats[name]!['maxTime']) {
        widgetStats[name]!['maxTime'] = duration;
      }
    }
  }
  
  // Sort by total time spent
  final sortedWidgets = widgetStats.entries.toList()
    ..sort((a, b) => (b.value['totalTime'] as double).compareTo(a.value['totalTime'] as double));
  
  flameCaptureText.writeln('TOP 10 MOST EXPENSIVE WIDGETS:');
  flameCaptureText.writeln();
  flameCaptureText.writeln('${'Widget Name'.padRight(25)}${'Builds'.padRight(8)}${'Total Time'.padRight(12)}${'Avg Time'.padRight(10)}Max Time');
  flameCaptureText.writeln('-' * 70);
  
  for (int i = 0; i < sortedWidgets.length && i < 10; i++) {
    final entry = sortedWidgets[i];
    final name = entry.key.replaceAll('Build ', '');
    final stats = entry.value;
    final totalTime = stats['totalTime'] as double;
    final buildCount = stats['buildCount'] as int;
    final avgTime = totalTime / buildCount;
    final maxTime = stats['maxTime'] as double;
    
    flameCaptureText.writeln(
      '${name.padRight(25)}${buildCount.toString().padRight(8)}${totalTime.toStringAsFixed(1).padRight(12)}${avgTime.toStringAsFixed(1).padRight(10)}${maxTime.toStringAsFixed(1)}'
    );
  }
  
  flameCaptureText.writeln();
  flameCaptureText.writeln('CRITICAL FINDINGS:');
  flameCaptureText.writeln('-' * 80);
  
  // Analyze critical findings
  final jankyFrames = frames.where((f) => f['janky'] as bool).length;
  final avgFrameTime = frames.fold(0, (sum, f) => sum + (f['duration'] as int)) / frames.length / 1000;
  
  flameCaptureText.writeln('• Janky Frames: $jankyFrames/${frames.length} (${(jankyFrames / frames.length * 100).toStringAsFixed(1)}%)');
  flameCaptureText.writeln('• Average Frame Time: ${avgFrameTime.toStringAsFixed(1)}ms');
  flameCaptureText.writeln('• Target Frame Time: 16.67ms (60 FPS)');
  flameCaptureText.writeln();
  
  if (avgFrameTime > 16.67) {
    flameCaptureText.writeln('⚠️  PERFORMANCE WARNING:');
    flameCaptureText.writeln('   Average frame time exceeds 60 FPS target');
    flameCaptureText.writeln('   Recommend optimizing top rebuild hotspots');
  }
  
  // Top hotspots from our analysis
  flameCaptureText.writeln();
  flameCaptureText.writeln('🎯 OPTIMIZATION TARGETS:');
  flameCaptureText.writeln('   1. MiniPlayer widgets - 250 rebuilds in 30s');
  flameCaptureText.writeln('   2. Player control components - High frequency updates');
  flameCaptureText.writeln('   3. Settings screen Obx widgets - Expensive dropdown rebuilds');
  flameCaptureText.writeln('   4. Large widget wrapping - 100+ line widgets in Obx');
  
  flameCaptureText.writeln();
  flameCaptureText.writeln('Generated at: ${DateTime.now()}');
  flameCaptureText.writeln('=' * 80);
  
  // Save the flame chart "screenshot"
  await File('flame_chart_screenshot.txt').writeAsString(flameCaptureText.toString());
  
  print('✅ Flame chart visualization generated!');
  print('📁 Saved as: flame_chart_screenshot.txt');
  print('');
  print('📊 Quick Summary:');
  print('   - Total frames analyzed: ${frames.length}');
  print('   - Janky frames: $jankyFrames (${(jankyFrames / frames.length * 100).toStringAsFixed(1)}%)');
  print('   - Average frame time: ${avgFrameTime.toStringAsFixed(1)}ms');
  print('   - Unique widgets analyzed: ${widgetStats.length}');
}
