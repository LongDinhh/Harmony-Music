#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;

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
    'filePath': filePath,
    'linesOfCode': linesOfCode,
    'maxNestingDepth': maxNestingDepth,
    'widgetClasses': widgetClasses,
    'controllerServices': controllerServices,
    'streamSubscriptions': streamSubscriptions,
    'asyncAwaitUsage': asyncAwaitUsage,
    'issuesFound': issuesFound,
  };
}

class DartCodeAnalyzer extends RecursiveAstVisitor<void> {
  final CodeMetrics metrics;
  int _currentNestingDepth = 0;

  DartCodeAnalyzer(this.metrics);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;
    
    // Check for widget classes
    final extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final superClassName = extendsClause.superclass.name.name;
      if (superClassName == 'StatelessWidget' || superClassName == 'StatefulWidget') {
        metrics.widgetClasses.add(className);
      } else if (superClassName == 'GetxController' || superClassName == 'GetxService') {
        metrics.controllerServices.add(className);
      }
    }
    
    // Check implements clause for widgets
    final implementsClause = node.implementsClause;
    if (implementsClause != null) {
      for (final type in implementsClause.interfaces) {
        final typeName = type.name.name;
        if (typeName.endsWith('Widget')) {
          metrics.widgetClasses.add(className);
        }
      }
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _increaseNesting();
    
    // Check for async methods
    if (node.isAsync) {
      metrics.asyncAwaitUsage.add('${node.name.lexeme} (async method)');
    }
    
    super.visitMethodDeclaration(node);
    _decreaseNesting();
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _increaseNesting();
    
    // Check for async functions
    if (node.functionExpression.body?.isAsync ?? false) {
      metrics.asyncAwaitUsage.add('${node.name.lexeme} (async function)');
    }
    
    super.visitFunctionDeclaration(node);
    _decreaseNesting();
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    metrics.asyncAwaitUsage.add('await expression at line ${node.offset}');
    super.visitAwaitExpression(node);
  }

  @override
  void visitStreamSubscription(Expression node) {
    if (node.toString().contains('.listen(')) {
      metrics.streamSubscriptions.add('Stream subscription at line ${node.offset}');
    }
    super.visitExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    
    // Check for stream subscriptions
    if (methodName == 'listen' || methodName == 'stream') {
      metrics.streamSubscriptions.add('$methodName call at line ${node.offset}');
    }
    
    super.visitMethodInvocation(node);
  }

  @override
  void visitBlock(Block node) {
    _increaseNesting();
    super.visitBlock(node);
    _decreaseNesting();
  }

  @override
  void visitIfStatement(IfStatement node) {
    _increaseNesting();
    super.visitIfStatement(node);
    _decreaseNesting();
  }

  @override
  void visitForStatement(ForStatement node) {
    _increaseNesting();
    super.visitForStatement(node);
    _decreaseNesting();
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _increaseNesting();
    super.visitWhileStatement(node);
    _decreaseNesting();
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _increaseNesting();
    super.visitSwitchStatement(node);
    _decreaseNesting();
  }

  void _increaseNesting() {
    _currentNestingDepth++;
    if (_currentNestingDepth > metrics.maxNestingDepth) {
      metrics.maxNestingDepth = _currentNestingDepth;
    }
  }

  void _decreaseNesting() {
    _currentNestingDepth--;
  }
}

Future<void> main(List<String> args) async {
  final projectRoot = Directory.current.path;
  print('Analyzing project: $projectRoot');

  // Parse lint report if exists
  final lintReport = await parseLintReport();
  
  // Find all Dart files
  final dartFiles = await findDartFiles(projectRoot);
  print('Found ${dartFiles.length} Dart files');

  final allMetrics = <CodeMetrics>[];
  
  // Create analysis context
  final collection = AnalysisContextCollection(
    includedPaths: [projectRoot],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  for (final filePath in dartFiles) {
    try {
      final metrics = await analyzeFile(collection, filePath, lintReport);
      allMetrics.add(metrics);
      print('Analyzed: ${path.basename(filePath)}');
    } catch (e) {
      print('Error analyzing $filePath: $e');
    }
  }

  // Create summary report
  final summary = createSummaryReport(allMetrics, lintReport);
  
  // Save results
  await saveResults(allMetrics, summary);
  
  print('\nAnalysis complete!');
  print('Generated files:');
  print('- code_metrics.json: Detailed metrics for each file');
  print('- lint_report.json: Parsed lint issues');
  print('- analysis_summary.json: Overall project summary');
}

Future<Map<String, dynamic>> parseLintReport() async {
  final lintFile = File('lint_report.json');
  if (!await lintFile.exists()) {
    return {};
  }
  
  try {
    final content = await lintFile.readAsString();
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    final issues = <Map<String, dynamic>>[];
    for (final line in lines) {
      if (line.contains('•') && (line.contains('info') || line.contains('warning') || line.contains('error'))) {
        final parts = line.split('•');
        if (parts.length >= 4) {
          issues.add({
            'severity': parts[0].trim(),
            'message': parts[1].trim(),
            'location': parts[2].trim(),
            'rule': parts[3].trim(),
          });
        }
      }
    }
    
    return {
      'totalIssues': issues.length,
      'issues': issues,
      'issuesByType': groupIssuesByType(issues),
    };
  } catch (e) {
    print('Error parsing lint report: $e');
    return {};
  }
}

Map<String, int> groupIssuesByType(List<Map<String, dynamic>> issues) {
  final grouped = <String, int>{};
  for (final issue in issues) {
    final rule = issue['rule'] ?? 'unknown';
    grouped[rule] = (grouped[rule] ?? 0) + 1;
  }
  return grouped;
}

Future<List<String>> findDartFiles(String rootPath) async {
  final dartFiles = <String>[];
  final libDir = Directory(path.join(rootPath, 'lib'));
  
  if (await libDir.exists()) {
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity.path);
      }
    }
  }
  
  // Also check for test files
  final testDir = Directory(path.join(rootPath, 'test'));
  if (await testDir.exists()) {
    await for (final entity in testDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity.path);
      }
    }
  }
  
  return dartFiles;
}

Future<CodeMetrics> analyzeFile(AnalysisContextCollection collection, String filePath, Map<String, dynamic> lintReport) async {
  final metrics = CodeMetrics(filePath);
  
  // Count lines of code
  final file = File(filePath);
  final content = await file.readAsString();
  metrics.linesOfCode = content.split('\n').where((line) => line.trim().isNotEmpty && !line.trim().startsWith('//')).length;
  
  // Get analysis context for this file
  final context = collection.contextFor(filePath);
  final session = context.currentSession;
  
  // Get parsed unit
  final result = await session.getResolvedUnit(filePath);
  if (result is ResolvedUnitResult) {
    final analyzer = DartCodeAnalyzer(metrics);
    result.unit.accept(analyzer);
  }
  
  // Add lint issues for this file
  if (lintReport.containsKey('issues')) {
    final issues = lintReport['issues'] as List<Map<String, dynamic>>;
    for (final issue in issues) {
      final location = issue['location'] ?? '';
      if (location.contains(path.basename(filePath))) {
        metrics.issuesFound.add('${issue['rule']}: ${issue['message']}');
      }
    }
  }
  
  return metrics;
}

Map<String, dynamic> createSummaryReport(List<CodeMetrics> allMetrics, Map<String, dynamic> lintReport) {
  final totalFiles = allMetrics.length;
  final totalLinesOfCode = allMetrics.fold<int>(0, (sum, m) => sum + m.linesOfCode);
  final maxNestingDepth = allMetrics.fold<int>(0, (max, m) => m.maxNestingDepth > max ? m.maxNestingDepth : max);
  
  final totalWidgetClasses = allMetrics.expand((m) => m.widgetClasses).length;
  final totalControllerServices = allMetrics.expand((m) => m.controllerServices).length;
  final totalStreamSubscriptions = allMetrics.expand((m) => m.streamSubscriptions).length;
  final totalAsyncAwaitUsage = allMetrics.expand((m) => m.asyncAwaitUsage).length;
  
  final filesWithWidgets = allMetrics.where((m) => m.widgetClasses.isNotEmpty).length;
  final filesWithControllers = allMetrics.where((m) => m.controllerServices.isNotEmpty).length;
  final filesWithStreams = allMetrics.where((m) => m.streamSubscriptions.isNotEmpty).length;
  final filesWithAsyncAwait = allMetrics.where((m) => m.asyncAwaitUsage.isNotEmpty).length;
  
  return {
    'projectSummary': {
      'totalFiles': totalFiles,
      'totalLinesOfCode': totalLinesOfCode,
      'averageLinesPerFile': totalFiles > 0 ? (totalLinesOfCode / totalFiles).round() : 0,
      'maxNestingDepth': maxNestingDepth,
    },
    'widgetAnalysis': {
      'totalWidgetClasses': totalWidgetClasses,
      'filesWithWidgets': filesWithWidgets,
      'widgetFiles': allMetrics.where((m) => m.widgetClasses.isNotEmpty).map((m) => {
        'file': path.basename(m.filePath),
        'widgets': m.widgetClasses,
      }).toList(),
    },
    'controllerAnalysis': {
      'totalControllerServices': totalControllerServices,
      'filesWithControllers': filesWithControllers,
      'controllerFiles': allMetrics.where((m) => m.controllerServices.isNotEmpty).map((m) => {
        'file': path.basename(m.filePath),
        'controllers': m.controllerServices,
      }).toList(),
    },
    'streamAnalysis': {
      'totalStreamSubscriptions': totalStreamSubscriptions,
      'filesWithStreams': filesWithStreams,
      'streamFiles': allMetrics.where((m) => m.streamSubscriptions.isNotEmpty).map((m) => {
        'file': path.basename(m.filePath),
        'streamCount': m.streamSubscriptions.length,
      }).toList(),
    },
    'asyncAnalysis': {
      'totalAsyncAwaitUsage': totalAsyncAwaitUsage,
      'filesWithAsyncAwait': filesWithAsyncAwait,
      'asyncFiles': allMetrics.where((m) => m.asyncAwaitUsage.isNotEmpty).map((m) => {
        'file': path.basename(m.filePath),
        'asyncCount': m.asyncAwaitUsage.length,
      }).toList(),
    },
    'lintSummary': lintReport,
    'generatedAt': DateTime.now().toIso8601String(),
  };
}

Future<void> saveResults(List<CodeMetrics> allMetrics, Map<String, dynamic> summary) async {
  // Save detailed metrics
  final metricsFile = File('code_metrics.json');
  await metricsFile.writeAsString(JsonEncoder.withIndent('  ').convert(
    allMetrics.map((m) => m.toJson()).toList()
  ));
  
  // Save summary report
  final summaryFile = File('analysis_summary.json');
  await summaryFile.writeAsString(JsonEncoder.withIndent('  ').convert(summary));
}
