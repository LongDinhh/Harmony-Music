import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Performance optimization utilities
class PerformanceOptimizer {
  static const String _cachePrefix = 'perf_cache_';
  
  /// Debounce rapid rebuilds
  static Timer? _debounceTimer;
  static void debounce(VoidCallback action, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, action);
  }

  /// Cache frequently accessed data
  static Future<T?> getCached<T>(String key, Future<T> Function() fetcher, {Duration cacheDuration = const Duration(minutes: 5)}) async {
    final cacheKey = '$_cachePrefix$key';
    final box = Hive.box('SongsCache');
    
    final cached = box.get(cacheKey);
    if (cached != null) {
      final timestamp = box.get('${cacheKey}_timestamp');
      if (timestamp != null && DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp)) < cacheDuration) {
        return cached as T;
      }
    }
    
    final result = await fetcher();
    if (result != null) {
      await box.put(cacheKey, result);
      await box.put('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    }
    
    return result;
  }

  /// Clear expired cache entries
  static Future<void> clearExpiredCache() async {
    final box = Hive.box('SongsCache');
    final keysToDelete = <String>[];
    
    for (final key in box.keys) {
      if (key.toString().startsWith(_cachePrefix)) {
        final timestampKey = '${key}_timestamp';
        final timestamp = box.get(timestampKey);
        if (timestamp == null) continue;
        
        final cacheAge = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
        if (cacheAge > const Duration(hours: 24)) {
          keysToDelete.add(key.toString());
          keysToDelete.add(timestampKey);
        }
      }
    }
    
    await box.deleteAll(keysToDelete);
  }

  /// Memory management for large objects
  static void disposeLargeObjects(List<dynamic> objects) {
    for (final obj in objects) {
      if (obj is ChangeNotifier) {
        obj.dispose();
      }
    }
  }
}