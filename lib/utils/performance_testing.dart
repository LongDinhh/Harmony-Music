import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance testing utility for tracking rebuilds and wrapping widgets with performance overlays
class PerformanceTesting {
  static bool _debugPrintRebuildEnabled = false;
  static final Map<String, int> _rebuildCounters = {};
  static final Map<String, DateTime> _lastRebuildTimes = {};

  /// Enable debug rebuild printing
  static void enableDebugRebuildPrint() {
    _debugPrintRebuildEnabled = true;
    debugPrintRebuildDirtyWidgets = true;
  }

  /// Disable debug rebuild printing
  static void disableDebugRebuildPrint() {
    _debugPrintRebuildEnabled = false;
    debugPrintRebuildDirtyWidgets = false;
  }

  /// Reset rebuild counters
  static void resetCounters() {
    _rebuildCounters.clear();
    _lastRebuildTimes.clear();
  }

  /// Get current rebuild counts
  static Map<String, int> getRebuildCounts() => Map.from(_rebuildCounters);

  /// Track rebuild for a specific widget
  static void trackRebuild(String widgetName) {
    if (kDebugMode) {
      _rebuildCounters[widgetName] = (_rebuildCounters[widgetName] ?? 0) + 1;
      _lastRebuildTimes[widgetName] = DateTime.now();

      if (_debugPrintRebuildEnabled) {
        developer.log(
          'REBUILD: $widgetName (Count: ${_rebuildCounters[widgetName]})',
          name: 'PerformanceTesting',
        );
      }
    }
  }

  /// Print rebuild statistics
  static void printRebuildStats() {
    if (kDebugMode) {
      print('\n=== REBUILD STATISTICS ===');
      _rebuildCounters.entries.forEach((entry) {
        final lastRebuild = _lastRebuildTimes[entry.key];
        print('${entry.key}: ${entry.value} rebuilds (last: $lastRebuild)');
      });
      print('========================\n');
    }
  }

  /// Create a performance overlay wrapper for hot areas
  static Widget createPerformanceWrapper({
    required Widget child,
    required String widgetName,
    bool showRasterOverlay = false,
    bool showWidgetInspector = false,
  }) {
    if (!kDebugMode) return child;

    return Builder(
      builder: (context) {
        trackRebuild(widgetName);

        return Stack(
          children: [
            child,
            if (showRasterOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: PerformanceOverlay.allEnabled(),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Mixin for widgets to automatically track rebuilds
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  String get trackingName => runtimeType.toString();

  @override
  Widget build(BuildContext context) {
    PerformanceTesting.trackRebuild(trackingName);
    return buildWithTracking(context);
  }

  /// Override this instead of build() when using the mixin
  Widget buildWithTracking(BuildContext context);
}

/// Widget wrapper that automatically tracks rebuilds for StatelessWidget
class PerformanceTrackedWidget extends StatelessWidget {
  const PerformanceTrackedWidget({
    Key? key,
    required this.child,
    required this.name,
  }) : super(key: key);

  final Widget child;
  final String name;

  @override
  Widget build(BuildContext context) {
    PerformanceTesting.trackRebuild(name);
    return child;
  }
}

/// Performance overlay container for hot rebuild areas
class PerformanceOverlayContainer extends StatelessWidget {
  const PerformanceOverlayContainer({
    Key? key,
    required this.child,
    required this.name,
    this.enabled = true,
    this.showOverlay = false,
  }) : super(key: key);

  final Widget child;
  final String name;
  final bool enabled;
  final bool showOverlay;

  @override
  Widget build(BuildContext context) {
    if (!enabled || !kDebugMode) return child;

    return PerformanceTesting.createPerformanceWrapper(
      child: child,
      widgetName: name,
      showRasterOverlay: showOverlay,
    );
  }
}

/// Extension for easy performance tracking
extension PerformanceTrackingExtension on Widget {
  Widget trackPerformance(String name, {bool showOverlay = false}) {
    return PerformanceOverlayContainer(
      name: name,
      showOverlay: showOverlay,
      child: this,
    );
  }
}
