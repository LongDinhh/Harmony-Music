import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/helper.dart';

/// Enhanced ScrollController manager with automatic memory management
/// Prevents memory leaks by properly disposing controllers and managing lifecycle
class ScrollControllerManager {
  final Map<String, ScrollController> _controllers = {};
  final Map<String, Timer?> _cleanupTimers = {};
  final Map<String, DateTime> _lastUsed = {};

  // Cleanup settings
  static const Duration _cleanupDelay = Duration(minutes: 5);
  static const Duration _maxIdleTime = Duration(minutes: 10);

  /// Get or create a scroll controller with the given key
  /// Automatically tracks usage and manages lifecycle
  ScrollController getOrCreateController(
    String key, {
    bool keepScrollOffset = true,
    String? debugLabel,
  }) {
    _lastUsed[key] = DateTime.now();

    if (_controllers.containsKey(key)) {
      final controller = _controllers[key]!;

      // Cancel cleanup timer since controller is being used
      _cancelCleanupTimer(key);

      // Verify controller is still valid
      if (!controller.hasClients && controller.positions.isEmpty) {
        printINFO('ScrollController[$key]: Recreating disposed controller');
        _controllers.remove(key);
        return _createNewController(key, keepScrollOffset, debugLabel);
      }

      return controller;
    }

    return _createNewController(key, keepScrollOffset, debugLabel);
  }

  /// Create a new scroll controller
  ScrollController _createNewController(
      String key, bool keepScrollOffset, String? debugLabel) {
    final controller = ScrollController(
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel ?? 'ScrollController_$key',
    );

    _controllers[key] = controller;
    _lastUsed[key] = DateTime.now();

    // Add listener to track when controller becomes detached
    controller.addListener(() {
      if (!controller.hasClients) {
        _scheduleCleanup(key);
      }
    });

    printINFO('ScrollController[$key]: Created new controller');
    return controller;
  }

  /// Get existing controller without creating new one
  ScrollController? getController(String key) {
    if (_controllers.containsKey(key)) {
      _lastUsed[key] = DateTime.now();
      _cancelCleanupTimer(key);
      return _controllers[key];
    }
    return null;
  }

  /// Schedule cleanup for a controller that's no longer needed
  void _scheduleCleanup(String key) {
    _cancelCleanupTimer(key);

    _cleanupTimers[key] = Timer(_cleanupDelay, () {
      _cleanupController(key, 'scheduled cleanup');
    });
  }

  /// Cancel scheduled cleanup for a controller
  void _cancelCleanupTimer(String key) {
    _cleanupTimers[key]?.cancel();
    _cleanupTimers.remove(key);
  }

  /// Cleanup a specific controller
  void _cleanupController(String key, String reason) {
    final controller = _controllers[key];
    if (controller != null) {
      try {
        // Only dispose if no clients are attached
        if (!controller.hasClients) {
          controller.dispose();
          printINFO('ScrollController[$key]: Disposed ($reason)');
        } else {
          printWARN(
              'ScrollController[$key]: Skip disposal - has active clients');
          return; // Don't remove from map if still has clients
        }
      } catch (e) {
        printERROR('ScrollController[$key]: Error during disposal - $e');
      }
    }

    _controllers.remove(key);
    _lastUsed.remove(key);
    _cancelCleanupTimer(key);
  }

  /// Force cleanup of a specific controller
  void disposeController(String key) {
    _cleanupController(key, 'forced disposal');
  }

  /// Clean up idle controllers that haven't been used recently
  void cleanupIdleControllers() {
    final now = DateTime.now();
    final keysToCleanup = <String>[];

    for (final entry in _lastUsed.entries) {
      if (now.difference(entry.value) > _maxIdleTime) {
        keysToCleanup.add(entry.key);
      }
    }

    for (final key in keysToCleanup) {
      _cleanupController(key, 'idle cleanup');
    }

    if (keysToCleanup.isNotEmpty) {
      printINFO(
          'ScrollControllerManager: Cleaned up ${keysToCleanup.length} idle controllers');
    }
  }

  /// Dispose all controllers (typically called when screen is disposed)
  void disposeAll({String reason = 'dispose all'}) {
    final keys = _controllers.keys.toList();
    for (final key in keys) {
      _cleanupController(key, reason);
    }

    // Clear any remaining timers
    for (final timer in _cleanupTimers.values) {
      timer?.cancel();
    }
    _cleanupTimers.clear();

    printINFO('ScrollControllerManager: Disposed all controllers ($reason)');
  }

  /// Get status information for debugging
  Map<String, dynamic> getStatus() {
    return {
      'totalControllers': _controllers.length,
      'activeControllers':
          _controllers.values.where((c) => c.hasClients).length,
      'pendingCleanups': _cleanupTimers.length,
      'controllers': _controllers.keys.toList(),
    };
  }

  /// Check for memory leaks and report
  void performHealthCheck() {
    final now = DateTime.now();
    var leakedControllers = 0;
    var activeControllers = 0;

    for (final entry in _controllers.entries) {
      final key = entry.key;
      final controller = entry.value;
      final lastUsed = _lastUsed[key] ?? now;

      if (controller.hasClients) {
        activeControllers++;
      } else if (now.difference(lastUsed) > _maxIdleTime) {
        leakedControllers++;
        printWARN('ScrollController[$key]: Potential memory leak detected');
      }
    }

    printINFO('ScrollControllerManager Health Check: '
        'Total: ${_controllers.length}, '
        'Active: $activeControllers, '
        'Potential leaks: $leakedControllers');

    if (leakedControllers > 0) {
      cleanupIdleControllers();
    }
  }
}

/// Enhanced ScrollController management mixin for GetX controllers
mixin ScrollControllerManagerMixin on GetxController {
  late final ScrollControllerManager _scrollManager;
  Timer? _healthCheckTimer;

  @override
  void onInit() {
    super.onInit();
    _scrollManager = ScrollControllerManager();

    // Start periodic health checks
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _scrollManager.performHealthCheck(),
    );
  }

  /// Get or create a scroll controller
  ScrollController getOrCreateScrollController(
    String key, {
    bool keepScrollOffset = true,
    String? debugLabel,
  }) {
    return _scrollManager.getOrCreateController(
      key,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel ?? '${runtimeType}_$key',
    );
  }

  /// Get existing scroll controller
  ScrollController? getScrollController(String key) {
    return _scrollManager.getController(key);
  }

  /// Dispose specific scroll controller
  void disposeScrollController(String key) {
    _scrollManager.disposeController(key);
  }

  /// Clean up idle controllers
  void cleanupIdleScrollControllers() {
    _scrollManager.cleanupIdleControllers();
  }

  /// Get scroll controller status for debugging
  Map<String, dynamic> getScrollControllerStatus() {
    return _scrollManager.getStatus();
  }

  @override
  void onClose() {
    _healthCheckTimer?.cancel();
    _scrollManager.disposeAll(reason: '${runtimeType} disposal');
    super.onClose();
  }
}
