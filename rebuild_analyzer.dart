#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

class RebuildHotspot {
  String filePath;
  String widgetName;
  int line;
  String obxPattern;
  String severity; // HIGH, MEDIUM, LOW
  String reason;
  int estimatedRebuildsPerMinute;
  double estimatedBuildTimeMs;
  List<String> dependencies;

  RebuildHotspot({
    required this.filePath,
    required this.widgetName,
    required this.line,
    required this.obxPattern,
    required this.severity,
    required this.reason,
    required this.estimatedRebuildsPerMinute,
    required this.estimatedBuildTimeMs,
    required this.dependencies,
  });

  Map<String, dynamic> toJson() => {
    'filePath': filePath.replaceAll('/Users/longdv/Code/longdinhh/Harmony-Music/', ''),
    'widgetName': widgetName,
    'line': line,
    'obxPattern': obxPattern,
    'severity': severity,
    'reason': reason,
    'estimatedRebuildsPerMinute': estimatedRebuildsPerMinute,
    'estimatedBuildTimeMs': estimatedBuildTimeMs,
    'dependencies': dependencies,
  };
}

class WidgetComplexity {
  String filePath;
  String widgetName;
  int nestingDepth;
  int childCount;
  bool hasAnimations;
  bool hasComplexLayouts;
  List<String> expensiveOperations;

  WidgetComplexity({
    required this.filePath,
    required this.widgetName,
    required this.nestingDepth,
    required this.childCount,
    required this.hasAnimations,
    required this.hasComplexLayouts,
    required this.expensiveOperations,
  });

  Map<String, dynamic> toJson() => {
    'filePath': filePath.replaceAll('/Users/longdv/Code/longdinhh/Harmony-Music/', ''),
    'widgetName': widgetName,
    'nestingDepth': nestingDepth,
    'childCount': childCount,
    'hasAnimations': hasAnimations,
    'hasComplexLayouts': hasComplexLayouts,
    'expensiveOperations': expensiveOperations,
  };
}

Future<void> main() async {
  print('🔍 Starting Rebuild & Performance Hot-spots Analysis...');

  // Step 1: Detect heavily rebuilt widgets
  print('\n📊 Step 1: Scanning for Obx/GetX rebuild patterns...');
  final rebuildHotspots = await detectRebuildHotspots();

  // Step 2: Analyze widget complexity
  print('\n🏗️ Step 2: Analyzing widget complexity...');
  final complexWidgets = await analyzeWidgetComplexity();

  // Step 3: Generate CSV report
  print('\n📋 Step 3: Generating rebuild hotspots report...');
  await generateRebuildHotspotsCSV(rebuildHotspots, complexWidgets);

  // Step 4: Provide Flutter profile run instructions
  print('\n⚡ Step 4: Performance profiling instructions...');
  await generateProfileInstructions();

  print('\n✅ Analysis complete!');
  print('📁 Generated files:');
  print('  - rebuild_hotspots.csv: Ranked list of rebuild hotspots');
  print('  - widget_complexity_analysis.json: Detailed widget analysis');
  print('  - performance_profile_guide.md: Instructions for performance profiling');

  // Summary
  final highSeverityCount = rebuildHotspots.where((h) => h.severity == 'HIGH').length;
  final mediumSeverityCount = rebuildHotspots.where((h) => h.severity == 'MEDIUM').length;

  print('\n📈 Summary:');
  print('  - Total hotspots found: ${rebuildHotspots.length}');
  print('  - High severity: $highSeverityCount');
  print('  - Medium severity: $mediumSeverityCount');
  print('  - Complex widgets analyzed: ${complexWidgets.length}');
  print('  - Hotspots >200 rebuilds/min: ${rebuildHotspots.where((h) => h.estimatedRebuildsPerMinute > 200).length}');
  print('  - Widgets >5ms build time: ${rebuildHotspots.where((h) => h.estimatedBuildTimeMs > 5).length}');
}

Future<List<RebuildHotspot>> detectRebuildHotspots() async {
  final hotspots = <RebuildHotspot>[];
  final dartFiles = await findDartFiles();

  for (final filePath in dartFiles) {
    final content = await File(filePath).readAsString();
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();

      // Detect Obx patterns
      if (trimmedLine.contains('Obx(') || trimmedLine.contains('GetX<')) {
        final hotspot = analyzeObxPattern(filePath, i + 1, line, lines, i);
        if (hotspot != null) {
          hotspots.add(hotspot);
        }
      }
    }
  }

  // Sort by estimated impact (rebuilds per minute * build time)
  hotspots.sort((a, b) {
    final aImpact = a.estimatedRebuildsPerMinute * a.estimatedBuildTimeMs;
    final bImpact = b.estimatedRebuildsPerMinute * b.estimatedBuildTimeMs;
    return bImpact.compareTo(aImpact);
  });

  return hotspots;
}

RebuildHotspot? analyzeObxPattern(String filePath, int lineNum, String line, List<String> allLines, int currentIndex) {
  final fileName = filePath.split('/').last;
  String widgetName = 'Unknown';
  String severity = 'MEDIUM';
  String reason = '';
  int estimatedRebuilds = 100; // Base estimate
  double estimatedBuildTime = 2.0; // Base estimate in ms
  List<String> dependencies = [];

  // Try to find widget/class name
  for (int i = currentIndex - 1; i >= 0 && i >= currentIndex - 20; i--) {
    final prevLine = allLines[i].trim();
    if (prevLine.contains('class ') && prevLine.contains('Widget')) {
      final classMatch = RegExp(r'class\s+(\w+)').firstMatch(prevLine);
      if (classMatch != null) {
        widgetName = classMatch.group(1)!;
        break;
      }
    }
  }

  // Analyze the Obx pattern and surrounding context
  final obxPattern = line.trim();

  // Check for nested Obx (HIGH severity)
  if (line.contains('Obx(') && isNestedInBuildMethod(allLines, currentIndex)) {
    severity = 'HIGH';
    reason = 'Obx nested inside build method without id/tag';
    estimatedRebuilds = 300;
    estimatedBuildTime = 8.0;
  }

  // Check for large widgets in Obx
  final widgetSize = estimateWidgetSize(allLines, currentIndex);
  if (widgetSize > 50) {
    severity = 'HIGH';
    reason = 'Large widget (${widgetSize} lines) wrapped in Obx - rebuilds entirely';
    estimatedRebuilds = 250;
    estimatedBuildTime = 10.0;
  }

  // Check for Obx without id/tag in lists
  if (isInListView(allLines, currentIndex) && !line.contains('id:') && !line.contains('tag:')) {
    severity = 'HIGH';
    reason = 'Obx in ListView without id/tag - causes excessive rebuilds';
    estimatedRebuilds = 400;
    estimatedBuildTime = 6.0;
  }

  // Detect expensive operations in Obx
  final expensiveOps = findExpensiveOperations(allLines, currentIndex);
  if (expensiveOps.isNotEmpty) {
    severity = 'HIGH';
    reason = 'Obx contains expensive operations: ${expensiveOps.join(', ')}';
    estimatedRebuilds = 200;
    estimatedBuildTime = 15.0;
  }

  // Find GetX dependencies
  dependencies = findGetXDependencies(allLines, currentIndex);

  // Specific analysis for key UI components
  if (fileName.contains('mini_player') || fileName.contains('player')) {
    estimatedRebuilds = 500; // Player updates frequently
    estimatedBuildTime += 3.0;
  }

  if (fileName.contains('settings') && obxPattern.contains('DropdownButton')) {
    estimatedRebuilds = 150;
    estimatedBuildTime = 4.0;
  }

  return RebuildHotspot(
    filePath: filePath,
    widgetName: widgetName,
    line: lineNum,
    obxPattern: obxPattern.length > 100 ? obxPattern.substring(0, 100) + '...' : obxPattern,
    severity: severity,
    reason: reason.isEmpty ? 'Standard Obx usage' : reason,
    estimatedRebuildsPerMinute: estimatedRebuilds,
    estimatedBuildTimeMs: estimatedBuildTime,
    dependencies: dependencies,
  );
}

bool isNestedInBuildMethod(List<String> lines, int currentIndex) {
  for (int i = currentIndex - 1; i >= 0 && i >= currentIndex - 30; i--) {
    final line = lines[i].trim();
    if (line.contains('Widget build(BuildContext context)')) {
      return true;
    }
    if (line.contains('class ') && line.contains('{')) {
      break; // Reached class boundary
    }
  }
  return false;
}

int estimateWidgetSize(List<String> lines, int startIndex) {
  int braceCount = 0;
  int widgetLines = 0;
  bool started = false;

  for (int i = startIndex; i < lines.length && i < startIndex + 100; i++) {
    final line = lines[i];

    braceCount += '{'.allMatches(line).length;
    braceCount -= '}'.allMatches(line).length;

    if (braceCount > 0 || line.contains('Obx(')) {
      started = true;
      widgetLines++;
    }

    if (started && braceCount <= 0) {
      break;
    }
  }

  return widgetLines;
}

bool isInListView(List<String> lines, int currentIndex) {
  for (int i = currentIndex - 1; i >= 0 && i >= currentIndex - 20; i--) {
    final line = lines[i].trim();
    if (line.contains('ListView') || line.contains('itemBuilder')) {
      return true;
    }
  }
  return false;
}

List<String> findExpensiveOperations(List<String> lines, int startIndex) {
  final expensiveOps = <String>[];

  for (int i = startIndex; i < lines.length && i < startIndex + 20; i++) {
    final line = lines[i].toLowerCase();

    if (line.contains('image.') || line.contains('imagewidget')) {
      expensiveOps.add('Image operations');
    }
    if (line.contains('animation') || line.contains('tween')) {
      expensiveOps.add('Animations');
    }
    if (line.contains('http.') || line.contains('dio.')) {
      expensiveOps.add('Network calls');
    }
    if (line.contains('json.decode') || line.contains('jsonencode')) {
      expensiveOps.add('JSON parsing');
    }
    if (line.contains('future.') || line.contains('await')) {
      expensiveOps.add('Async operations');
    }
  }

  return expensiveOps.toSet().toList();
}

List<String> findGetXDependencies(List<String> lines, int startIndex) {
  final deps = <String>[];

  for (int i = startIndex; i < lines.length && i < startIndex + 10; i++) {
    final line = lines[i];
    final getFinds = RegExp(r'Get\.find<(\w+)>').allMatches(line);
    for (final match in getFinds) {
      deps.add(match.group(1)!);
    }
  }

  return deps.toSet().toList();
}

Future<List<WidgetComplexity>> analyzeWidgetComplexity() async {
  final complexWidgets = <WidgetComplexity>[];
  final dartFiles = await findDartFiles();

  for (final filePath in dartFiles) {
    if (!filePath.contains('/ui/')) continue; // Focus on UI files

    final content = await File(filePath).readAsString();
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.contains('class ') && line.contains('Widget')) {
        final complexity = analyzeWidgetComplexityAt(filePath, lines, i);
        if (complexity != null) {
          complexWidgets.add(complexity);
        }
      }
    }
  }

  return complexWidgets;
}

WidgetComplexity? analyzeWidgetComplexityAt(String filePath, List<String> lines, int startIndex) {
  final classLine = lines[startIndex];
  final classMatch = RegExp(r'class\s+(\w+)').firstMatch(classLine);
  if (classMatch == null) return null;

  final widgetName = classMatch.group(1)!;

  // Find build method
  int buildMethodIndex = -1;
  for (int i = startIndex; i < lines.length && i < startIndex + 100; i++) {
    if (lines[i].contains('Widget build(BuildContext context)')) {
      buildMethodIndex = i;
      break;
    }
  }

  if (buildMethodIndex == -1) return null;

  // Analyze complexity
  int nestingDepth = 0;
  int maxNesting = 0;
  int childCount = 0;
  bool hasAnimations = false;
  bool hasComplexLayouts = false;
  List<String> expensiveOps = [];

  for (int i = buildMethodIndex; i < lines.length && i < buildMethodIndex + 200; i++) {
    final line = lines[i];

    // Count nesting
    nestingDepth += '{'.allMatches(line).length;
    nestingDepth -= '}'.allMatches(line).length;
    if (nestingDepth > maxNesting) maxNesting = nestingDepth;

    // Count child widgets
    if (line.contains('child:') || line.contains('children:')) {
      childCount++;
    }

    // Check for animations
    if (line.contains('Animation') || line.contains('Tween') || line.contains('AnimatedContainer')) {
      hasAnimations = true;
    }

    // Check for complex layouts
    if (line.contains('CustomPaint') || line.contains('Transform') || line.contains('ClipPath')) {
      hasComplexLayouts = true;
    }

    // Find expensive operations
    if (line.contains('Image') || line.contains('NetworkImage')) {
      expensiveOps.add('Image loading');
    }
    if (line.contains('FutureBuilder') || line.contains('StreamBuilder')) {
      expensiveOps.add('Async widgets');
    }

    // Stop at end of build method
    if (nestingDepth <= 0 && i > buildMethodIndex + 5) break;
  }

  return WidgetComplexity(
    filePath: filePath,
    widgetName: widgetName,
    nestingDepth: maxNesting,
    childCount: childCount,
    hasAnimations: hasAnimations,
    hasComplexLayouts: hasComplexLayouts,
    expensiveOperations: expensiveOps.toSet().toList(),
  );
}

Future<void> generateRebuildHotspotsCSV(List<RebuildHotspot> hotspots, List<WidgetComplexity> complexWidgets) async {
  final csv = StringBuffer();

  // CSV Header
  csv.writeln('File,Widget,Line,Severity,Rebuilds/Min,Build Time (ms),Reason,Dependencies,Pattern Preview');

  for (final hotspot in hotspots) {
    // Escape CSV values
    final escapedReason = hotspot.reason.replaceAll(',', ';').replaceAll('"', '""');
    final escapedPattern = hotspot.obxPattern.replaceAll(',', ';').replaceAll('"', '""');
    final escapedDeps = hotspot.dependencies.join(';');

    csv.writeln('"${hotspot.filePath}","${hotspot.widgetName}",${hotspot.line},"${hotspot.severity}",${hotspot.estimatedRebuildsPerMinute},${hotspot.estimatedBuildTimeMs},"$escapedReason","$escapedDeps","$escapedPattern"');
  }

  await File('rebuild_hotspots.csv').writeAsString(csv.toString());

  // Also generate detailed JSON analysis
  final analysis = {
    'rebuildHotspots': hotspots.map((h) => h.toJson()).toList(),
    'widgetComplexity': complexWidgets.map((w) => w.toJson()).toList(),
    'summary': {
      'totalHotspots': hotspots.length,
      'highSeverityHotspots': hotspots.where((h) => h.severity == 'HIGH').length,
      'hotspotsOver200Rebuilds': hotspots.where((h) => h.estimatedRebuildsPerMinute > 200).length,
      'hotspotsOver5msBuildTime': hotspots.where((h) => h.estimatedBuildTimeMs > 5).length,
      'topRebuildFiles': hotspots.take(10).map((h) => {
        'file': h.filePath.split('/').last,
        'rebuildsPerMinute': h.estimatedRebuildsPerMinute,
        'buildTimeMs': h.estimatedBuildTimeMs,
        'impact': h.estimatedRebuildsPerMinute * h.estimatedBuildTimeMs,
      }).toList(),
    },
    'generatedAt': DateTime.now().toIso8601String(),
  };

  await File('widget_complexity_analysis.json').writeAsString(
    JsonEncoder.withIndent('  ').convert(analysis)
  );
}

Future<void> generateProfileInstructions() async {
  final instructions = '''
# Flutter Performance Profiling Guide

## Step 1: Run Flutter in Profile Mode
```bash
# Clean and run in profile mode with widget creation tracking
flutter clean
flutter run --profile --track-widget-creation

# For more detailed profiling:
flutter run --profile --track-widget-creation --dart-define=dart.vm.profile=true
```

## Step 2: Navigate Through Key Screens
Perform these actions while profiling:
1. **Home Screen**: Scroll through music content, switch categories
2. **Player Screen**:
   - Open/close mini player
   - Switch between standard/gesture player
   - Control playback (play/pause/skip)
3. **Settings Screen**:
   - Open/close expansion tiles
   - Change dropdown values
   - Toggle switches

## Step 3: Capture Performance Data

### Using Flutter Inspector (Recommended)
1. Open Flutter Inspector in your IDE
2. Enable "Select Widget Mode"
3. Navigate through screens while monitoring:
   - Widget rebuild count
   - Frame rendering times
   - Memory usage

### Using Dart VM Timeline
```bash
# Run with observatory enabled
flutter run --profile --enable-dart-profiling

# In another terminal, capture timeline:
curl -o timeline.json http://localhost:8181/_flutter/traceEvents?timeOriginMicros=0&timeExtentMicros=30000000
```

## Step 4: Generate Flame Chart Screenshots
1. Open Chrome DevTools (chrome://inspect)
2. Click "Open dedicated DevTools for Node"
3. Go to Performance tab
4. Load the timeline.json file
5. Take screenshots of:
   - Main thread activity
   - Widget build times
   - Frame drops/janky frames

## Key Metrics to Monitor
- **Widget Rebuilds**: Look for widgets rebuilding >200 times per minute
- **Build Times**: Identify widgets taking >5ms to build
- **Frame Drops**: Watch for frames taking >16ms (60fps) or >8ms (120fps)
- **Memory Usage**: Monitor for memory leaks during navigation

## Critical Areas to Profile
Based on the rebuild hotspots analysis:

### High Priority Files:
- `mini_player.dart` - Expected ~500 rebuilds/min
- `settings_screen.dart` - Multiple Obx widgets
- `player_control.dart` - Frequent progress updates
- `home_screen.dart` - Dynamic content loading

### Focus Points:
1. **Mini Player**: Progress bar updates every ~100ms
2. **Settings Dropdowns**: State changes trigger rebuilds
3. **Player Controls**: Frequent playback state updates
4. **Image Widgets**: Check for unnecessary reloads

## Expected Results
After profiling, you should have:
- Timeline trace files (.json)
- Flame chart screenshots (.png)
- Widget rebuild counts
- Frame timing analysis
- Memory usage patterns

## Analysis Tips
- Compare profile data before/after optimizations
- Look for patterns in rebuild cascades
- Identify unused rebuilds (widgets that rebuild but don't change visually)
- Check for expensive operations in build methods
''';

  await File('performance_profile_guide.md').writeAsString(instructions);
}

Future<List<String>> findDartFiles() async {
  final dartFiles = <String>[];
  final libDir = Directory('lib');

  if (await libDir.exists()) {
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity.path);
      }
    }
  }

  return dartFiles;
}
