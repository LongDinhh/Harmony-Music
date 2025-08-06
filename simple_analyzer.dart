#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

class CodeMetrics {
  String filePath;
  int linesOfCode = 0;
  int maxNestingDepth = 0;
  List<String> widgetClasses = [];
  List<String> controllerServices = [];
  List<String> streamSubscriptions = [];
  List<String> asyncAwaitUsage = [];
  List<String> issuesFound = [];

  CodeMetrics(this.filePath);

  Map<String, dynamic> toJson() => {
        'filePath': filePath.replaceAll(
            '/Users/longdv/Code/longdinhh/Harmony-Music/', ''),
        'linesOfCode': linesOfCode,
        'maxNestingDepth': maxNestingDepth,
        'widgetClasses': widgetClasses,
        'controllerServices': controllerServices,
        'streamSubscriptions': streamSubscriptions,
        'asyncAwaitUsage': asyncAwaitUsage,
        'issuesFound': issuesFound,
      };
}

Future<void> main() async {
  print('Starting comprehensive code analysis...');

  // Parse lint report
  final lintReport = await parseLintReport();

  // Find all Dart files
  final dartFiles = await findDartFiles();
  print('Found ${dartFiles.length} Dart files');

  final allMetrics = <CodeMetrics>[];

  for (final filePath in dartFiles) {
    try {
      final metrics = await analyzeFile(filePath, lintReport);
      allMetrics.add(metrics);
      print('Analyzed: ${filePath.split('/').last}');
    } catch (e) {
      print('Error analyzing $filePath: $e');
    }
  }

  // Create summary report
  final summary = createSummaryReport(allMetrics, lintReport);

  // Save results
  await saveResults(allMetrics, summary);

  print('\n✅ Analysis complete!');
  print('📊 Generated files:');
  print('  - code_metrics.json: Detailed metrics for each file');
  print('  - analysis_summary.json: Overall project summary');
  print('\n📈 Summary:');
  print('  - Total files: ${allMetrics.length}');
  print(
      '  - Total lines of code: ${summary['projectSummary']['totalLinesOfCode']}');
  print(
      '  - Widget classes found: ${summary['widgetAnalysis']['totalWidgetClasses']}');
  print(
      '  - Controller/Service classes: ${summary['controllerAnalysis']['totalControllerServices']}');
  print(
      '  - Async/await usage: ${summary['asyncAnalysis']['totalAsyncAwaitUsage']}');
  print(
      '  - Stream subscriptions: ${summary['streamAnalysis']['totalStreamSubscriptions']}');
  print(
      '  - Max nesting depth: ${summary['projectSummary']['maxNestingDepth']}');
  print('  - Lint issues: ${lintReport['totalIssues']}');
}

Future<Map<String, dynamic>> parseLintReport() async {
  final lintFile = File('lint_report.json');
  if (!await lintFile.exists()) {
    return {'totalIssues': 0, 'issues': [], 'issuesByType': {}};
  }

  try {
    final content = await lintFile.readAsString();
    final lines =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    final issues = <Map<String, dynamic>>[];
    final issuesByType = <String, int>{};

    for (final line in lines) {
      if (line.contains('•') && line.contains('info')) {
        final parts = line.split('•');
        if (parts.length >= 4) {
          final rule = parts[3].trim();
          final issue = {
            'severity': parts[0].trim(),
            'message': parts[1].trim(),
            'location': parts[2].trim(),
            'rule': rule,
          };
          issues.add(issue);
          issuesByType[rule] = (issuesByType[rule] ?? 0) + 1;
        }
      }
    }

    return {
      'totalIssues': issues.length,
      'issues': issues,
      'issuesByType': issuesByType,
    };
  } catch (e) {
    print('Error parsing lint report: $e');
    return {'totalIssues': 0, 'issues': [], 'issuesByType': {}};
  }
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

  // Also check for test files
  final testDir = Directory('test');
  if (await testDir.exists()) {
    await for (final entity in testDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity.path);
      }
    }
  }

  return dartFiles;
}

Future<CodeMetrics> analyzeFile(
    String filePath, Map<String, dynamic> lintReport) async {
  final metrics = CodeMetrics(filePath);
  final file = File(filePath);
  final content = await file.readAsString();
  final lines = content.split('\n');

  // Count lines of code (excluding empty lines and comments)
  metrics.linesOfCode = lines
      .where((line) =>
          line.trim().isNotEmpty &&
          !line.trim().startsWith('//') &&
          !line.trim().startsWith('/*') &&
          !line.trim().startsWith('*'))
      .length;

  // Analyze content for patterns
  final fileName = filePath.split('/').last;
  var currentNestingDepth = 0;
  var maxDepth = 0;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmedLine = line.trim();

    // Count nesting depth by tracking braces
    final openBraces = '{'.allMatches(line).length;
    final closeBraces = '}'.allMatches(line).length;
    currentNestingDepth += openBraces - closeBraces;
    if (currentNestingDepth > maxDepth) {
      maxDepth = currentNestingDepth;
    }

    // Find widget classes
    if (trimmedLine.contains('extends StatelessWidget') ||
        trimmedLine.contains('extends StatefulWidget')) {
      final classMatch = RegExp(r'class\s+(\w+)').firstMatch(line);
      if (classMatch != null) {
        metrics.widgetClasses.add(classMatch.group(1)!);
      }
    }

    // Find GetX controllers and services
    if (trimmedLine.contains('extends GetxController') ||
        trimmedLine.contains('extends GetxService')) {
      final classMatch = RegExp(r'class\s+(\w+)').firstMatch(line);
      if (classMatch != null) {
        metrics.controllerServices.add(classMatch.group(1)!);
      }
    }

    // Find stream subscriptions
    if (trimmedLine.contains('.listen(') ||
        trimmedLine.contains('.stream') ||
        trimmedLine.contains('StreamSubscription')) {
      metrics.streamSubscriptions
          .add('Line ${i + 1}: ${trimmedLine.substring(0, 50)}...');
    }

    // Find async/await usage
    if (trimmedLine.contains('async') || trimmedLine.contains('await')) {
      if (trimmedLine.contains('async')) {
        final funcMatch = RegExp(r'(\w+)\s*\([^)]*\)\s*async').firstMatch(line);
        if (funcMatch != null) {
          metrics.asyncAwaitUsage.add('${funcMatch.group(1)} (async function)');
        } else if (trimmedLine.contains('{')) {
          metrics.asyncAwaitUsage.add('Anonymous async function/block');
        }
      }
      if (trimmedLine.contains('await')) {
        metrics.asyncAwaitUsage.add('Line ${i + 1}: await expression');
      }
    }
  }

  metrics.maxNestingDepth = maxDepth;

  // Add lint issues for this file
  if (lintReport['issues'] != null) {
    final issues = lintReport['issues'] as List<Map<String, dynamic>>;
    for (final issue in issues) {
      final location = issue['location'] ?? '';
      if (location.contains(fileName)) {
        metrics.issuesFound.add('${issue['rule']}: ${issue['message']}');
      }
    }
  }

  return metrics;
}

Map<String, dynamic> createSummaryReport(
    List<CodeMetrics> allMetrics, Map<String, dynamic> lintReport) {
  final totalFiles = allMetrics.length;
  final totalLinesOfCode =
      allMetrics.fold<int>(0, (sum, m) => sum + m.linesOfCode);
  final maxNestingDepth = allMetrics.fold<int>(
      0, (max, m) => m.maxNestingDepth > max ? m.maxNestingDepth : max);

  final totalWidgetClasses = allMetrics.expand((m) => m.widgetClasses).length;
  final totalControllerServices =
      allMetrics.expand((m) => m.controllerServices).length;
  final totalStreamSubscriptions =
      allMetrics.expand((m) => m.streamSubscriptions).length;
  final totalAsyncAwaitUsage =
      allMetrics.expand((m) => m.asyncAwaitUsage).length;

  final filesWithWidgets =
      allMetrics.where((m) => m.widgetClasses.isNotEmpty).length;
  final filesWithControllers =
      allMetrics.where((m) => m.controllerServices.isNotEmpty).length;
  final filesWithStreams =
      allMetrics.where((m) => m.streamSubscriptions.isNotEmpty).length;
  final filesWithAsyncAwait =
      allMetrics.where((m) => m.asyncAwaitUsage.isNotEmpty).length;

  return {
    'projectSummary': {
      'totalFiles': totalFiles,
      'totalLinesOfCode': totalLinesOfCode,
      'averageLinesPerFile':
          totalFiles > 0 ? (totalLinesOfCode / totalFiles).round() : 0,
      'maxNestingDepth': maxNestingDepth,
    },
    'widgetAnalysis': {
      'totalWidgetClasses': totalWidgetClasses,
      'filesWithWidgets': filesWithWidgets,
      'widgetFiles': allMetrics
          .where((m) => m.widgetClasses.isNotEmpty)
          .map((m) => {
                'file': m.filePath.split('/').last,
                'widgets': m.widgetClasses,
                'linesOfCode': m.linesOfCode,
              })
          .toList(),
    },
    'controllerAnalysis': {
      'totalControllerServices': totalControllerServices,
      'filesWithControllers': filesWithControllers,
      'controllerFiles': allMetrics
          .where((m) => m.controllerServices.isNotEmpty)
          .map((m) => {
                'file': m.filePath.split('/').last,
                'controllers': m.controllerServices,
                'linesOfCode': m.linesOfCode,
              })
          .toList(),
    },
    'streamAnalysis': {
      'totalStreamSubscriptions': totalStreamSubscriptions,
      'filesWithStreams': filesWithStreams,
      'streamFiles': allMetrics
          .where((m) => m.streamSubscriptions.isNotEmpty)
          .map((m) => {
                'file': m.filePath.split('/').last,
                'streamCount': m.streamSubscriptions.length,
                'streams': m.streamSubscriptions
                    .take(3)
                    .toList(), // Show first 3 examples
              })
          .toList(),
    },
    'asyncAnalysis': {
      'totalAsyncAwaitUsage': totalAsyncAwaitUsage,
      'filesWithAsyncAwait': filesWithAsyncAwait,
      'asyncFiles': allMetrics
          .where((m) => m.asyncAwaitUsage.isNotEmpty)
          .map((m) => {
                'file': m.filePath.split('/').last,
                'asyncCount': m.asyncAwaitUsage.length,
                'asyncUsages':
                    m.asyncAwaitUsage.take(3).toList(), // Show first 3 examples
              })
          .toList(),
    },
    'codeQualityMetrics': {
      'filesWithHighComplexity': allMetrics
          .where((m) => m.maxNestingDepth > 4)
          .map((m) => {
                'file': m.filePath.split('/').last,
                'nestingDepth': m.maxNestingDepth,
                'linesOfCode': m.linesOfCode,
              })
          .toList(),
      'largestFiles':
          (allMetrics..sort((a, b) => b.linesOfCode.compareTo(a.linesOfCode)))
              .take(10)
              .map((m) => {
                    'file': m.filePath.split('/').last,
                    'linesOfCode': m.linesOfCode,
                  })
              .toList(),
    },
    'lintSummary': lintReport,
    'generatedAt': DateTime.now().toIso8601String(),
  };
}

Future<void> saveResults(
    List<CodeMetrics> allMetrics, Map<String, dynamic> summary) async {
  // Save detailed metrics
  final metricsFile = File('code_metrics.json');
  await metricsFile.writeAsString(JsonEncoder.withIndent('  ')
      .convert(allMetrics.map((m) => m.toJson()).toList()));

  // Save summary report
  final summaryFile = File('analysis_summary.json');
  await summaryFile
      .writeAsString(JsonEncoder.withIndent('  ').convert(summary));
}
