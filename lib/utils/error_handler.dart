import 'package:flutter/foundation.dart';
import 'helper.dart';

/// Centralized error handling for the app
class AppErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace,
      {String? context}) {
    final errorMessage = error.toString();
    final contextInfo = context != null ? '[$context] ' : '';

    printERROR('${contextInfo}App Error: $errorMessage');

    if (kDebugMode && stackTrace != null) {
      printERROR('Stack trace: $stackTrace');
    }

    // Log to console for debugging
    debugPrint('🔴 ${contextInfo}ERROR: $errorMessage');
    if (stackTrace != null) {
      debugPrint('📍 STACK: ${stackTrace.toString()}');
    }
  }

  static void handleControllerError(
      String controllerName, dynamic error, StackTrace? stackTrace) {
    handleError(error, stackTrace, context: 'Controller: $controllerName');
  }

  static void handleBindingError(
      String bindingName, dynamic error, StackTrace? stackTrace) {
    handleError(error, stackTrace, context: 'Binding: $bindingName');
  }

  static void logInfo(String message, {String? context}) {
    final contextInfo = context != null ? '[$context] ' : '';
    printINFO('$contextInfo$message');
    debugPrint('ℹ️ $contextInfo$message');
  }

  static void logWarning(String message, {String? context}) {
    final contextInfo = context != null ? '[$context] ' : '';
    printWARN('$contextInfo$message');
    debugPrint('⚠️ $contextInfo$message');
  }
}
