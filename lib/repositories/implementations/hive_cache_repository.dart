import 'dart:typed_data';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import '../../models/media_Item_builder.dart';
import '../../utils/helper.dart';
import '../repositories.dart';

/// Concrete implementation của CacheRepository sử dụng Hive database
/// Handles audio, image, and metadata caching với expire logic
class HiveCacheRepository implements CacheRepository {
  // Hive box names for different cache types
  static const String _audioCacheBox = "AudioCache";
  static const String _imageCacheBox = "ImageCache";
  static const String _metadataCacheBox = "MetadataCache";
  static const String _cacheConfigBox = "CacheConfig";
  static const String _songsCacheBox = "SongsCache";

  // Default configuration values
  static const int _defaultMaxAudioCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _defaultMaxImageCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration _defaultExpirationDuration = Duration(hours: 24);

  /// Cache entry metadata với expiration info
  Map<String, dynamic> _createCacheEntryMetadata({
    required String key,
    required CacheType type,
    required int size,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'key': key,
      'type': type.name,
      'size': size,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata ?? {},
    };
  }

  @override
  Future<void> cacheAudio(
    MediaItem song,
    Uint8List audioData, {
    Duration? expirationDuration,
  }) async {
    try {
      printINFO('💾 HiveCacheRepository: Caching audio for: ${song.title}');
      
      final box = await Hive.openBox(_audioCacheBox);
      final metadataBox = await Hive.openBox("${_audioCacheBox}_metadata");
      
      final expiresAt = expirationDuration != null 
          ? DateTime.now().add(expirationDuration)
          : DateTime.now().add(_defaultExpirationDuration);
      
      // Store audio data
      await box.put(song.id, audioData);
      
      // Store metadata
      final metadata = _createCacheEntryMetadata(
        key: song.id,
        type: CacheType.audio,
        size: audioData.length,
        expiresAt: expiresAt,
        metadata: {
          'title': song.title,
          'artist': song.artist,
          'duration': song.duration?.inSeconds,
        },
      );
      
      await metadataBox.put(song.id, metadata);
      
      await box.close();
      await metadataBox.close();
      
      printINFO('💾 HiveCacheRepository: Audio cached successfully (${audioData.length} bytes)');
      
      // Clean up if cache size exceeds limit
      await _cleanupCacheIfNeeded(CacheType.audio);
    } catch (error) {
      printERROR('❌ HiveCacheRepository.cacheAudio error: $error');
      throw CacheException.writeFailed('Failed to cache audio: $error');
    }
  }

  @override
  Future<Uint8List?> getCachedAudio(String songId) async {
    try {
      RepositoryUtils.validateNonEmpty(songId, 'songId');
      
      final metadataBox = await Hive.openBox("${_audioCacheBox}_metadata");
      final metadata = metadataBox.get(songId);
      
      if (metadata == null) {
        await metadataBox.close();
        return null;
      }
      
      // Check expiration
      final expiresAtStr = metadata['expiresAt'] as String?;
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          printINFO('💾 HiveCacheRepository: Audio cache expired for: $songId');
          await removeCachedSong(songId);
          await metadataBox.close();
          return null;
        }
      }
      
      await metadataBox.close();
      
      final box = await Hive.openBox(_audioCacheBox);
      final audioData = box.get(songId) as Uint8List?;
      await box.close();
      
      if (audioData != null) {
        printINFO('💾 HiveCacheRepository: Retrieved cached audio for: $songId');
      }
      
      return audioData;
    } catch (error) {
      printERROR('❌ HiveCacheRepository.getCachedAudio error: $error');
      throw CacheException.readFailed('Failed to get cached audio: $error');
    }
  }

  @override
  Future<bool> isAudioCached(String songId) async {
    try {
      final audioData = await getCachedAudio(songId);
      return audioData != null;
    } catch (error) {
      printERROR('❌ HiveCacheRepository.isAudioCached error: $error');
      return false;
    }
  }

  @override
  Future<void> cacheImage(
    String imageUrl,
    Uint8List imageData, {
    Duration? expirationDuration,
  }) async {
    try {
      printINFO('🖼️ HiveCacheRepository: Caching image: $imageUrl');
      
      final box = await Hive.openBox(_imageCacheBox);
      final metadataBox = await Hive.openBox("${_imageCacheBox}_metadata");
      
      final cacheKey = _generateImageCacheKey(imageUrl);
      final expiresAt = expirationDuration != null
          ? DateTime.now().add(expirationDuration)
          : DateTime.now().add(_defaultExpirationDuration);
      
      // Store image data
      await box.put(cacheKey, imageData);
      
      // Store metadata
      final metadata = _createCacheEntryMetadata(
        key: cacheKey,
        type: CacheType.image,
        size: imageData.length,
        expiresAt: expiresAt,
        metadata: {'url': imageUrl},
      );
      
      await metadataBox.put(cacheKey, metadata);
      
      await box.close();
      await metadataBox.close();
      
      printINFO('🖼️ HiveCacheRepository: Image cached successfully (${imageData.length} bytes)');
    } catch (error) {
      printERROR('❌ HiveCacheRepository.cacheImage error: $error');
      throw CacheException.writeFailed('Failed to cache image: $error');
    }
  }

  @override
  Future<Uint8List?> getCachedImage(String imageUrl) async {
    try {
      RepositoryUtils.validateNonEmpty(imageUrl, 'imageUrl');
      
      final cacheKey = _generateImageCacheKey(imageUrl);
      final metadataBox = await Hive.openBox("${_imageCacheBox}_metadata");
      final metadata = metadataBox.get(cacheKey);
      
      if (metadata == null) {
        await metadataBox.close();
        return null;
      }
      
      // Check expiration
      final expiresAtStr = metadata['expiresAt'] as String?;
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          await removeCachedImage(imageUrl);
          await metadataBox.close();
          return null;
        }
      }
      
      await metadataBox.close();
      
      final box = await Hive.openBox(_imageCacheBox);
      final imageData = box.get(cacheKey) as Uint8List?;
      await box.close();
      
      return imageData;
    } catch (error) {
      printERROR('❌ HiveCacheRepository.getCachedImage error: $error');
      throw CacheException.readFailed('Failed to get cached image: $error');
    }
  }

  @override
  Future<void> cacheMetadata(
    String key,
    Map<String, dynamic> data,
    CacheType type, {
    Duration? expirationDuration,
  }) async {
    try {
      printINFO('📋 HiveCacheRepository: Caching metadata: $key (type: ${type.name})');
      
      final boxName = "${_metadataCacheBox}_${type.name}";
      final box = await Hive.openBox(boxName);
      final metadataBox = await Hive.openBox("${boxName}_metadata");
      
      final jsonString = json.encode(data);
      final dataBytes = utf8.encode(jsonString);
      final expiresAt = expirationDuration != null
          ? DateTime.now().add(expirationDuration)
          : DateTime.now().add(_defaultExpirationDuration);
      
      // Store metadata content
      await box.put(key, data);
      
      // Store cache metadata
      final metadata = _createCacheEntryMetadata(
        key: key,
        type: type,
        size: dataBytes.length,
        expiresAt: expiresAt,
      );
      
      await metadataBox.put(key, metadata);
      
      await box.close();
      await metadataBox.close();
      
      printINFO('📋 HiveCacheRepository: Metadata cached successfully');
    } catch (error) {
      printERROR('❌ HiveCacheRepository.cacheMetadata error: $error');
      throw CacheException.writeFailed('Failed to cache metadata: $error');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedMetadata(String key, CacheType type) async {
    try {
      RepositoryUtils.validateNonEmpty(key, 'key');
      
      final boxName = "${_metadataCacheBox}_${type.name}";
      final metadataBox = await Hive.openBox("${boxName}_metadata");
      final metadata = metadataBox.get(key);
      
      if (metadata == null) {
        await metadataBox.close();
        return null;
      }
      
      // Check expiration
      final expiresAtStr = metadata['expiresAt'] as String?;
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          await _removeCachedMetadata(key, type);
          await metadataBox.close();
          return null;
        }
      }
      
      await metadataBox.close();
      
      final box = await Hive.openBox(boxName);
      final data = box.get(key) as Map<String, dynamic>?;
      await box.close();
      
      return data;
    } catch (error) {
      printERROR('❌ HiveCacheRepository.getCachedMetadata error: $error');
      throw CacheException.readFailed('Failed to get cached metadata: $error');
    }
  }

  @override
  Future<void> removeCachedSong(String songId) async {
    try {
      RepositoryUtils.validateNonEmpty(songId, 'songId');
      
      printINFO('🗑️ HiveCacheRepository: Removing cached song: $songId');
      
      // Remove from audio cache
      final audioBox = await Hive.openBox(_audioCacheBox);
      final audioMetadataBox = await Hive.openBox("${_audioCacheBox}_metadata");
      
      await audioBox.delete(songId);
      await audioMetadataBox.delete(songId);
      
      await audioBox.close();
      await audioMetadataBox.close();
      
      // Also remove from songs cache (compatibility with existing system)
      final songsBox = await Hive.openBox(_songsCacheBox);
      await songsBox.delete(songId);
      await songsBox.close();
      
      printINFO('🗑️ HiveCacheRepository: Cached song removed successfully');
    } catch (error) {
      printERROR('❌ HiveCacheRepository.removeCachedSong error: $error');
      throw CacheException.deleteFailed('Failed to remove cached song: $error');
    }
  }

  @override
  Future<void> removeCachedImage(String imageUrl) async {
    try {
      RepositoryUtils.validateNonEmpty(imageUrl, 'imageUrl');
      
      final cacheKey = _generateImageCacheKey(imageUrl);
      
      final box = await Hive.openBox(_imageCacheBox);
      final metadataBox = await Hive.openBox("${_imageCacheBox}_metadata");
      
      await box.delete(cacheKey);
      await metadataBox.delete(cacheKey);
      
      await box.close();
      await metadataBox.close();
    } catch (error) {
      printERROR('❌ HiveCacheRepository.removeCachedImage error: $error');
      throw CacheException.deleteFailed('Failed to remove cached image: $error');
    }
  }

  @override
  Future<int> clearExpiredCache() async {
    try {
      printINFO('🧹 HiveCacheRepository: Clearing expired cache entries');
      
      int totalRemoved = 0;
      final now = DateTime.now();
      
      // Clear expired audio cache
      totalRemoved += await _clearExpiredFromBox(_audioCacheBox, now);
      
      // Clear expired image cache
      totalRemoved += await _clearExpiredFromBox(_imageCacheBox, now);
      
      // Clear expired metadata caches
      for (final type in CacheType.values) {
        totalRemoved += await _clearExpiredFromBox("${_metadataCacheBox}_${type.name}", now);
      }
      
      printINFO('🧹 HiveCacheRepository: Cleared $totalRemoved expired cache entries');
      return totalRemoved;
    } catch (error) {
      printERROR('❌ HiveCacheRepository.clearExpiredCache error: $error');
      throw CacheException.deleteFailed('Failed to clear expired cache: $error');
    }
  }

  @override
  Future<int> clearCacheByType(CacheType type) async {
    try {
      printINFO('🧹 HiveCacheRepository: Clearing cache by type: ${type.name}');
      
      int totalRemoved = 0;
      
      switch (type) {
        case CacheType.audio:
          totalRemoved += await _clearBox(_audioCacheBox);
          totalRemoved += await _clearBox("${_audioCacheBox}_metadata");
          totalRemoved += await _clearBox(_songsCacheBox); // Compatibility
          break;
        case CacheType.image:
          totalRemoved += await _clearBox(_imageCacheBox);
          totalRemoved += await _clearBox("${_imageCacheBox}_metadata");
          break;
        case CacheType.metadata:
        case CacheType.searchResults:
          final boxName = "${_metadataCacheBox}_${type.name}";
          totalRemoved += await _clearBox(boxName);
          totalRemoved += await _clearBox("${boxName}_metadata");
          break;
      }
      
      printINFO('🧹 HiveCacheRepository: Cleared $totalRemoved entries for type: ${type.name}');
      return totalRemoved;
    } catch (error) {
      printERROR('❌ HiveCacheRepository.clearCacheByType error: $error');
      throw CacheException.deleteFailed('Failed to clear cache by type: $error');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      printINFO('🧹 HiveCacheRepository: Clearing all cache');
      
      for (final type in CacheType.values) {
        await clearCacheByType(type);
      }
      
      printINFO('🧹 HiveCacheRepository: All cache cleared successfully');
    } catch (error) {
      printERROR('❌ HiveCacheRepository.clearAllCache error: $error');
      throw CacheException.deleteFailed('Failed to clear all cache: $error');
    }
  }

  @override
  Future<CacheStatistics> getCacheStatistics() async {
    try {
      printINFO('📊 HiveCacheRepository: Getting cache statistics');
      
      int totalEntries = 0;
      int totalSizeBytes = 0;
      final entriesByType = <CacheType, int>{};
      final sizeByType = <CacheType, int>{};
      int expiredEntries = 0;
      
      final now = DateTime.now();
      
      // Collect statistics for each cache type
      for (final type in CacheType.values) {
        final stats = await _getBoxStatistics(type, now);
        totalEntries += stats['entries'] as int;
        totalSizeBytes += stats['size'] as int;
        entriesByType[type] = stats['entries'] as int;
        sizeByType[type] = stats['size'] as int;
        expiredEntries += stats['expired'] as int;
      }
      
      final statistics = CacheStatistics(
        totalEntries: totalEntries,
        totalSizeBytes: totalSizeBytes,
        entriesByType: entriesByType,
        sizeByType: sizeByType,
        expiredEntries: expiredEntries,
      );
      
      final sizeMB = (totalSizeBytes / 1024 / 1024).toStringAsFixed(1);
      printINFO('📊 HiveCacheRepository: Statistics - Total: $totalEntries entries, $sizeMB MB');
      return statistics;
    } catch (error) {
      printERROR('❌ HiveCacheRepository.getCacheStatistics error: $error');
      throw CacheException.readFailed('Failed to get cache statistics: $error');
    }
  }

  @override
  Future<List<CacheEntry>> getCacheEntries({
    CacheType? type,
    int? limit,
  }) async {
    try {
      printINFO('📋 HiveCacheRepository: Getting cache entries (type: $type, limit: $limit)');
      
      final entries = <CacheEntry>[];
      final typesToProcess = type != null ? [type] : CacheType.values;
      
      for (final cacheType in typesToProcess) {
        final typeEntries = await _getCacheEntriesForType(cacheType);
        entries.addAll(typeEntries);
        
        if (limit != null && entries.length >= limit) {
          break;
        }
      }
      
      // Sort by creation date (newest first) and apply limit
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      final result = limit != null && entries.length > limit
          ? entries.take(limit).toList()
          : entries;
      
      printINFO('📋 HiveCacheRepository: Retrieved ${result.length} cache entries');
      return result;
    } catch (error) {
      printERROR('❌ HiveCacheRepository.getCacheEntries error: $error');
      throw CacheException.readFailed('Failed to get cache entries: $error');
    }
  }

  @override
  Future<int> optimizeCache({
    int? maxSizeBytes,
    int? maxEntries,
  }) async {
    try {
      printINFO('🔧 HiveCacheRepository: Optimizing cache (maxSize: $maxSizeBytes, maxEntries: $maxEntries)');
      
      int totalRemoved = 0;
      
      // First, remove all expired entries
      totalRemoved += await clearExpiredCache();
      
      // Get current statistics after expired cleanup
      final stats = await getCacheStatistics();
      
      // If still over limits, remove oldest entries
      if ((maxSizeBytes != null && stats.totalSizeBytes > maxSizeBytes) ||
          (maxEntries != null && stats.totalEntries > maxEntries)) {
        
        final entries = await getCacheEntries();
        entries.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Oldest first
        
        int currentSize = stats.totalSizeBytes;
        int currentEntries = stats.totalEntries;
        
        for (final entry in entries) {
          if ((maxSizeBytes == null || currentSize <= maxSizeBytes) &&
              (maxEntries == null || currentEntries <= maxEntries)) {
            break;
          }
          
          // Remove this entry
          await _removeCacheEntry(entry);
          currentSize -= entry.size;
          currentEntries--;
          totalRemoved++;
        }
      }
      
      printINFO('🔧 HiveCacheRepository: Cache optimization completed, removed $totalRemoved entries');
      return totalRemoved;
    } catch (error) {
      printERROR('❌ HiveCacheRepository.optimizeCache error: $error');
      throw CacheException.deleteFailed('Failed to optimize cache: $error');
    }
  }

  @override
  Future<void> preloadSongs(List<MediaItem> songs, {int priority = 5}) async {
    try {
      printINFO('⬇️ HiveCacheRepository: Preloading ${songs.length} songs (priority: $priority)');
      
      // For now, just cache the song metadata for faster access
      for (final song in songs) {
        try {
          await cacheMetadata(
            'preload_${song.id}',
            MediaItemBuilder.toJson(song),
            CacheType.metadata,
            expirationDuration: const Duration(hours: 1),
          );
        } catch (e) {
          printWARN('⚠️ Failed to preload song metadata: ${song.title} - $e');
        }
      }
      
      printINFO('⬇️ HiveCacheRepository: Song preloading completed');
    } catch (error) {
      printERROR('❌ HiveCacheRepository.preloadSongs error: $error');
      // Don't throw for preloading failures
    }
  }

  @override
  Future<void> setCacheConfiguration({
    int? maxAudioCacheSize,
    int? maxImageCacheSize,
    Duration? defaultExpirationDuration,
  }) async {
    try {
      printINFO('⚙️ HiveCacheRepository: Setting cache configuration');
      
      final box = await Hive.openBox(_cacheConfigBox);
      final config = {
        'maxAudioCacheSize': maxAudioCacheSize ?? _defaultMaxAudioCacheSize,
        'maxImageCacheSize': maxImageCacheSize ?? _defaultMaxImageCacheSize,
        'defaultExpirationDuration': (defaultExpirationDuration ?? _defaultExpirationDuration).inMilliseconds,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      await box.put('config', config);
      await box.close();
      
      printINFO('⚙️ HiveCacheRepository: Cache configuration updated');
    } catch (error) {
      printERROR('❌ HiveCacheRepository.setCacheConfiguration error: $error');
      throw CacheException.configurationError('Failed to set cache configuration: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getCacheConfiguration() async {
    try {
      final box = await Hive.openBox(_cacheConfigBox);
      final config = box.get('config') as Map<String, dynamic>?;
      await box.close();
      
      return config ?? {
        'maxAudioCacheSize': _defaultMaxAudioCacheSize,
        'maxImageCacheSize': _defaultMaxImageCacheSize,
        'defaultExpirationDuration': _defaultExpirationDuration.inMilliseconds,
      };
    } catch (error) {
      printERROR('❌ HiveCacheRepository.getCacheConfiguration error: $error');
      throw CacheException.configurationError('Failed to get cache configuration: $error');
    }
  }

  // Helper methods

  String _generateImageCacheKey(String imageUrl) {
    return imageUrl.hashCode.toString();
  }

  Future<void> _cleanupCacheIfNeeded(CacheType type) async {
    final config = await getCacheConfiguration();
    final maxSize = type == CacheType.audio 
        ? config['maxAudioCacheSize'] as int
        : config['maxImageCacheSize'] as int;
    
    await optimizeCache(maxSizeBytes: maxSize);
  }

  Future<int> _clearExpiredFromBox(String boxName, DateTime now) async {
    try {
      final metadataBox = await Hive.openBox("${boxName}_metadata");
      final dataBox = await Hive.openBox(boxName);
      
      int removed = 0;
      final keysToRemove = <String>[];
      
      for (final key in metadataBox.keys) {
        final metadata = metadataBox.get(key);
        if (metadata != null) {
          final expiresAtStr = metadata['expiresAt'] as String?;
          if (expiresAtStr != null) {
            final expiresAt = DateTime.parse(expiresAtStr);
            if (now.isAfter(expiresAt)) {
              keysToRemove.add(key);
            }
          }
        }
      }
      
      for (final key in keysToRemove) {
        await metadataBox.delete(key);
        await dataBox.delete(key);
        removed++;
      }
      
      await metadataBox.close();
      await dataBox.close();
      
      return removed;
    } catch (error) {
      printERROR('❌ Error clearing expired from box $boxName: $error');
      return 0;
    }
  }

  Future<int> _clearBox(String boxName) async {
    try {
      final box = await Hive.openBox(boxName);
      final count = box.length;
      await box.clear();
      await box.close();
      return count;
    } catch (error) {
      printERROR('❌ Error clearing box $boxName: $error');
      return 0;
    }
  }

  Future<Map<String, int>> _getBoxStatistics(CacheType type, DateTime now) async {
    try {
      String boxName;
      switch (type) {
        case CacheType.audio:
          boxName = _audioCacheBox;
          break;
        case CacheType.image:
          boxName = _imageCacheBox;
          break;
        case CacheType.metadata:
        case CacheType.searchResults:
          boxName = "${_metadataCacheBox}_${type.name}";
          break;
      }
      
      final metadataBox = await Hive.openBox("${boxName}_metadata");
      
      int entries = 0;
      int size = 0;
      int expired = 0;
      
      for (final metadata in metadataBox.values) {
        if (metadata is Map) {
          entries++;
          size += (metadata['size'] as int? ?? 0);
          
          final expiresAtStr = metadata['expiresAt'] as String?;
          if (expiresAtStr != null) {
            final expiresAt = DateTime.parse(expiresAtStr);
            if (now.isAfter(expiresAt)) {
              expired++;
            }
          }
        }
      }
      
      await metadataBox.close();
      
      return {
        'entries': entries,
        'size': size,
        'expired': expired,
      };
    } catch (error) {
      printERROR('❌ Error getting box statistics for type $type: $error');
      return {'entries': 0, 'size': 0, 'expired': 0};
    }
  }

  Future<List<CacheEntry>> _getCacheEntriesForType(CacheType type) async {
    try {
      String boxName;
      switch (type) {
        case CacheType.audio:
          boxName = _audioCacheBox;
          break;
        case CacheType.image:
          boxName = _imageCacheBox;
          break;
        case CacheType.metadata:
        case CacheType.searchResults:
          boxName = "${_metadataCacheBox}_${type.name}";
          break;
      }
      
      final metadataBox = await Hive.openBox("${boxName}_metadata");
      final dataBox = await Hive.openBox(boxName);
      
      final entries = <CacheEntry>[];
      
      for (final key in metadataBox.keys) {
        final metadata = metadataBox.get(key);
        final data = dataBox.get(key);
        
        if (metadata != null && data != null) {
          try {
            final entry = CacheEntry(
              key: metadata['key'],
              data: data is Uint8List ? data : Uint8List.fromList(utf8.encode(data.toString())),
              createdAt: DateTime.parse(metadata['createdAt']),
              expiresAt: metadata['expiresAt'] != null ? DateTime.parse(metadata['expiresAt']) : null,
              type: type,
              size: metadata['size'],
              metadata: Map<String, dynamic>.from(metadata['metadata'] ?? {}),
            );
            entries.add(entry);
          } catch (e) {
            printWARN('⚠️ Failed to parse cache entry: $key - $e');
          }
        }
      }
      
      await metadataBox.close();
      await dataBox.close();
      
      return entries;
    } catch (error) {
      printERROR('❌ Error getting cache entries for type $type: $error');
      return [];
    }
  }

  Future<void> _removeCacheEntry(CacheEntry entry) async {
    switch (entry.type) {
      case CacheType.audio:
        await removeCachedSong(entry.key);
        break;
      case CacheType.image:
        final metadata = entry.metadata;
        final imageUrl = metadata?['url'] as String?;
        if (imageUrl != null) {
          await removeCachedImage(imageUrl);
        }
        break;
      case CacheType.metadata:
      case CacheType.searchResults:
        await _removeCachedMetadata(entry.key, entry.type);
        break;
    }
  }

  Future<void> _removeCachedMetadata(String key, CacheType type) async {
    try {
      final boxName = "${_metadataCacheBox}_${type.name}";
      final box = await Hive.openBox(boxName);
      final metadataBox = await Hive.openBox("${boxName}_metadata");
      
      await box.delete(key);
      await metadataBox.delete(key);
      
      await box.close();
      await metadataBox.close();
    } catch (error) {
      printERROR('❌ Error removing cached metadata: $key - $error');
    }
  }
}