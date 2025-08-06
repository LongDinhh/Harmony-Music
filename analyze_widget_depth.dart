#!/usr/bin/env dart

import 'dart:io';

class WidgetDepthAnalyzer {
  Map<String, WidgetDepthInfo> analysis = {};
  final int maxDepthThreshold = 15;

  void analyzeDirectory(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      print('Directory $path does not exist');
      return;
    }

    final dartFiles = directory
        .listSync(recursive: true)
        .where((entity) =>
            entity.path.endsWith('.dart') && entity.path.contains('ui/'))
        .cast<File>();

    print('Analyzing ${dartFiles.length} Dart files...');

    for (final file in dartFiles) {
      analyzeFile(file);
    }
  }

  void analyzeFile(File file) {
    try {
      final content = file.readAsStringSync();
      final lines = content.split('\n');

      int currentDepth = 0;
      int maxDepth = 0;
      List<String> deepPathExample = [];
      List<String> currentPath = [];

      for (final line in lines) {
        final trimmedLine = line.trim();

        // Skip comments and empty lines
        if (trimmedLine.isEmpty ||
            trimmedLine.startsWith('//') ||
            trimmedLine.startsWith('/*')) {
          continue;
        }

        // Count opening braces/parentheses that indicate widget nesting
        final openBraces = RegExp(r'[{(]').allMatches(line).length;
        final closeBraces = RegExp(r'[})]').allMatches(line).length;

        // Look for widget constructors
        if (isWidgetConstructor(trimmedLine)) {
          currentDepth += openBraces - closeBraces;
          final widgetName = extractWidgetName(trimmedLine);
          if (widgetName.isNotEmpty) {
            currentPath.add(widgetName);
          }

          if (currentDepth > maxDepth) {
            maxDepth = currentDepth;
            deepPathExample = List.from(currentPath);
          }
        } else {
          currentDepth += openBraces - closeBraces;
          if (currentDepth < currentPath.length) {
            currentPath = currentPath.sublist(0, currentDepth);
          }
        }

        // Ensure depth doesn't go negative
        if (currentDepth < 0) currentDepth = 0;
      }

      // Store analysis
      final fileName = file.path.split('/').last;
      analysis[file.path] = WidgetDepthInfo(
        filePath: file.path,
        fileName: fileName,
        maxDepth: maxDepth,
        deepPathExample: deepPathExample,
        isFlagged: maxDepth > maxDepthThreshold,
      );
    } catch (e) {
      print('Error analyzing ${file.path}: $e');
    }
  }

  bool isWidgetConstructor(String line) {
    // Common Flutter widgets
    final widgetPatterns = [
      r'\b(Container|Column|Row|Stack|Scaffold|AppBar|SizedBox|Padding|Center|Align|Expanded|Flexible|Positioned|Card|ListTile|Text|Icon|IconButton|ElevatedButton|FloatingActionButton|Obx|GetX|Wrap|ListView|GridView|SingleChildScrollView|CustomScrollView|SliverAppBar|SliverList|SliverGrid|Material|InkWell|GestureDetector|AnimatedContainer|FadeTransition|SlideTransition|Hero|PageView|TabBar|TabBarView|BottomNavigationBar|Drawer|StreamBuilder|FutureBuilder|AnimatedBuilder|LayoutBuilder|ConstrainedBox|AspectRatio|Opacity|Transform|ClipRRect|ClipRect|BackdropFilter|ColoredBox|DecoratedBox|FractionallySizedBox|IntrinsicHeight|IntrinsicWidth|OverflowBox|UnconstrainedBox|WillPopScope|PopScope|SafeArea|MediaQuery|Theme|Builder|StatefulBuilder|ValueListenableBuilder|NotificationListener|RepaintBoundary|SliverToBoxAdapter|SliverFillRemaining|IndexedStack|PageStorage|ScrollConfiguration|PrimaryScrollController|DefaultTextStyle|RichText|SelectableText|TextFormField|TextField|Checkbox|Radio|Switch|Slider|ProgressIndicator|CircularProgressIndicator|LinearProgressIndicator|RefreshIndicator|Dismissible|ReorderableListView|ExpansionTile|BottomSheet|ModalBottomSheet|AlertDialog|SimpleDialog|Dialog|PopupMenuButton|DropdownButton|Stepper|DataTable|PaginatedDataTable|Chip|FilterChip|InputChip|ActionChip|ChoiceChip|Badge|Banner|BottomAppBar|NavigationBar|NavigationRail|SearchBar|Autocomplete|DatePicker|TimePicker|ColorPicker)\s*\(',
    ];

    return widgetPatterns.any((pattern) => RegExp(pattern).hasMatch(line));
  }

  String extractWidgetName(String line) {
    final match = RegExp(r'\b([A-Z][a-zA-Z0-9_]*)\s*\(').firstMatch(line);
    return match?.group(1) ?? '';
  }

  void generateReport() {
    final flaggedFiles =
        analysis.values.where((info) => info.isFlagged).toList();
    final sortedByDepth = flaggedFiles
      ..sort((a, b) => b.maxDepth.compareTo(a.maxDepth));

    print('\n${'=' * 80}');
    print('WIDGET TREE DEPTH ANALYSIS REPORT');
    print('=' * 80);
    print(
        'Analysis completed. Found ${sortedByDepth.length} files with depth > $maxDepthThreshold');
    print('\nFLAGGED FILES (Depth > $maxDepthThreshold):');
    print('-' * 80);

    for (final info in sortedByDepth) {
      print('\nFile: ${info.fileName}');
      print('Path: ${info.filePath}');
      print('Max Depth: ${info.maxDepth}');
      print('Deep Path Example: ${info.deepPathExample.join(' → ')}');
      print('Status: 🚩 NEEDS OPTIMIZATION');
      print('-' * 40);
    }

    // Generate markdown report
    generateMarkdownReport(sortedByDepth);
  }

  void generateMarkdownReport(List<WidgetDepthInfo> flaggedFiles) {
    final buffer = StringBuffer();

    buffer.writeln('# Widget Tree Depth Analysis Report');
    buffer.writeln('');
    buffer.writeln('Generated on: ${DateTime.now().toString()}');
    buffer.writeln('');
    buffer.writeln('## Summary');
    buffer.writeln('- **Total files analyzed**: ${analysis.length}');
    buffer.writeln(
        '- **Files with depth > $maxDepthThreshold**: ${flaggedFiles.length}');
    buffer.writeln('- **Max depth threshold**: $maxDepthThreshold');
    buffer.writeln('');

    buffer.writeln('## Deep Widget Trees (> $maxDepthThreshold levels)');
    buffer.writeln('');

    for (int i = 0; i < flaggedFiles.length; i++) {
      final info = flaggedFiles[i];
      buffer.writeln('### ${i + 1}. ${info.fileName}');
      buffer.writeln('- **File**: `${info.filePath}`');
      buffer.writeln('- **Max Depth**: ${info.maxDepth}');
      buffer.writeln('- **Deep Path**: ${info.deepPathExample.join(' → ')}');
      buffer.writeln('- **Status**: 🚩 **NEEDS OPTIMIZATION**');
      buffer.writeln('');

      // Add optimization suggestions
      buffer.writeln('**Optimization Suggestions:**');
      if (info.maxDepth > 20) {
        buffer.writeln(
            '- ⚠️ **Critical**: Extract nested widgets into separate components');
        buffer.writeln('- 📦 Use `RepaintBoundary` for complex subtrees');
        buffer.writeln('- 🔄 Consider `LayoutBuilder` for responsive layouts');
        buffer.writeln(
            '- 📋 Replace deep nesting with `SliverList` for scrollable content');
      } else if (info.maxDepth > 17) {
        buffer.writeln('- 📦 Extract widgets into smaller, focused components');
        buffer.writeln('- 🔄 Use `LayoutBuilder` for conditional layouts');
        buffer.writeln('- 📋 Consider `SliverList` for lists with many items');
      } else {
        buffer.writeln(
            '- 📦 Extract some nested widgets into separate components');
        buffer.writeln('- 🧹 Clean up unnecessary wrapper widgets');
      }
      buffer.writeln('');
    }

    // Before/After examples
    buffer.writeln('## Optimization Examples');
    buffer.writeln('');
    buffer.writeln('### Before: Deep Nesting (Bad)');
    buffer.writeln('```dart');
    buffer.writeln('Widget build(BuildContext context) {');
    buffer.writeln('  return Scaffold(');
    buffer.writeln('    body: Container(');
    buffer.writeln('      child: Padding(');
    buffer.writeln('        child: Column(');
    buffer.writeln('          children: [');
    buffer.writeln('            Container(');
    buffer.writeln('              child: Row(');
    buffer.writeln('                children: [');
    buffer.writeln('                  Expanded(');
    buffer.writeln('                    child: Card(');
    buffer.writeln(
        '                      child: Container( // 10+ levels deep...');
    buffer.writeln('                        child: Column(');
    buffer.writeln('                          children: [/* More nesting */],');
    buffer.writeln('                        ),');
    buffer.writeln('                      ),');
    buffer.writeln('                    ),');
    buffer.writeln('                  ),');
    buffer.writeln('                ],');
    buffer.writeln('              ),');
    buffer.writeln('            ),');
    buffer.writeln('          ],');
    buffer.writeln('        ),');
    buffer.writeln('      ),');
    buffer.writeln('    ),');
    buffer.writeln('  );');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln('');

    buffer.writeln('### After: Extracted Widgets (Good)');
    buffer.writeln('```dart');
    buffer.writeln('Widget build(BuildContext context) {');
    buffer.writeln('  return Scaffold(');
    buffer.writeln('    body: Padding(');
    buffer.writeln('      padding: const EdgeInsets.all(16.0),');
    buffer.writeln('      child: Column(');
    buffer.writeln('        children: [');
    buffer.writeln('          const _HeaderSection(),');
    buffer.writeln('          Expanded(child: _ContentList()),');
    buffer.writeln('        ],');
    buffer.writeln('      ),');
    buffer.writeln('    ),');
    buffer.writeln('  );');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('class _HeaderSection extends StatelessWidget {');
    buffer.writeln('  const _HeaderSection();');
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return RepaintBoundary(');
    buffer.writeln('      child: Card(');
    buffer.writeln('        child: _HeaderContent(),');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('class _ContentList extends StatelessWidget {');
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return LayoutBuilder(');
    buffer.writeln('      builder: (context, constraints) {');
    buffer.writeln('        return SliverList.builder(');
    buffer.writeln('          itemCount: items.length,');
    buffer.writeln(
        '          itemBuilder: (context, index) => _ItemWidget(items[index]),');
    buffer.writeln('        );');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln('');

    buffer.writeln('## Recommendations');
    buffer.writeln('');
    buffer.writeln(
        '1. **Extract Components**: Break down complex widgets into smaller, focused components');
    buffer.writeln(
        '2. **Use RepaintBoundary**: Wrap expensive widgets that don\'t need frequent rebuilds');
    buffer.writeln(
        '3. **LayoutBuilder**: Use for responsive design instead of deep conditional nesting');
    buffer.writeln(
        '4. **SliverList**: Replace deeply nested scrollable content with Slivers');
    buffer.writeln(
        '5. **Const Constructors**: Use const constructors where possible to reduce rebuilds');
    buffer.writeln(
        '6. **Builder Pattern**: Use Builder widgets to limit rebuild scope');

    // Write to file
    File('widget_tree_depth.md').writeAsStringSync(buffer.toString());
    print('\n📝 Detailed report generated: widget_tree_depth.md');
  }
}

class WidgetDepthInfo {
  final String filePath;
  final String fileName;
  final int maxDepth;
  final List<String> deepPathExample;
  final bool isFlagged;

  WidgetDepthInfo({
    required this.filePath,
    required this.fileName,
    required this.maxDepth,
    required this.deepPathExample,
    required this.isFlagged,
  });
}

void main(List<String> args) {
  final analyzer = WidgetDepthAnalyzer();
  final projectPath = args.isNotEmpty ? args[0] : 'lib';

  print('🔍 Starting Widget Tree Depth Analysis...');
  print('Project path: $projectPath');

  analyzer.analyzeDirectory(projectPath);
  analyzer.generateReport();

  print('\n✅ Analysis complete!');
}
