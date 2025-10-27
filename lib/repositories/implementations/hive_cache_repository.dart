import 'dart:typed_data';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../interfaces/cache_repository.dart';
import '../exceptions/repository_exception.dart';
import '../../models/media_item_builder.dart';

/// Concrete implementation of CacheRepository using Hive for local caching
class HiveCacheRepository implements CacheRepository {
  static const String _audioCacheBoxName = 'audio_cache';
  static const String _metadataCacheBoxName = 'metadata_cache';
  static const String _searchCacheBoxName = 'search_cache';
  static const String _homeScreenCacheBoxName = 'home_screen_cache';
  static const String _albumCacheBoxName = 'album_cache';
  static const String _artistCacheBoxName = 'artist_cache';
  static const String _playlistCacheBoxName = 'playlist_cache';
  static const String _cacheStatsBoxName = 'cache_stats';

  Box<Uint8List>? _audioCacheBox;
  Box<Map>? _metadataCacheBox;
  Box<Map>? _searchCacheBox;
  Box<Map>? _homeScreenCacheBox;
  Box<Map>? _albumCacheBox;
  Box<Map>? _artistCacheBox;
  Box<Map>? _playlistCacheBox;
  Box<Map>? _cacheStatsBox;

  // Cache expiration settings
  Duration _audioExpiration = const Duration(days: 30);
  Duration _metadataExpiration = const Duration(days: 7);
  Duration _searchExpiration = const Duration(hours: 6);

  // Maximum cache size in bytes (default 1GB)
  int _maxCacheSize = 1024 * 1024 * 1024;

  Future<void> _ensureBoxesOpen() async {
    _audioCacheBox ??= await Hive.openBox<Uint8List>(_audioCacheBoxName);
    _metadataCacheBox ??= await Hive.openBox<Map>(_metadataCacheBoxName);
    _searchCacheBox ??= await Hive.openBox<Map>(_searchCacheBoxName);
    _homeScreenCacheBox ??= await Hive.openBox<Map>(_homeScreenCacheBoxName);
    _albumCacheBox ??= await Hive.openBox<Map>(_albumCacheBoxName);
    _artistCacheBox ??= await Hive.openBox<Map>(_artistCacheBoxName);
    _playlistCacheBox ??= await Hive.openBox<Map>(_playlistCacheBoxName);
    _cacheStatsBox ??= await Hive.openBox<Map>(_cacheStatsBoxName);
  }

  @override
  Future<void> cacheSong(MediaItem song, Uint8List audioData) async {
    try {
      await _ensureBoxesOpen();
      
      final cacheEntry = {
        'data': audioData,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'size': audioData.length,
        'songTitle': song.title,
        'artist': song.artist ?? 'Unknown',
      };
      
      await _audioCacheBox!.put(song.id, audioData);
      await _metadataCacheBox!.put('audio_${song.id}', cacheEntry);
      
      // Update cache stats
      await _updateCacheStats();
      
      // Check if cache size exceeds limit
      await optimizeCache();
    } catch (error) {
      throw CacheException.storageError('Failed to cache song: ${error.toString()}');
    }
  }

  @override
  Future<Uint8List?> getCachedSong(String songId) async {
    try {
      await _ensureBoxesOpen();
      
      // Check if cached and not expired
      final metadata = _metadataCacheBox!.get('audio_$songId');
      if (metadata == null) return null;
      
      final cachedAt = metadata['cachedAt'] as int;
      final expirationTime = cachedAt + _audioExpiration.inMilliseconds;
      
      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        // Expired, remove from cache
        await removeCachedSong(songId);
        return null;
      }
      
      // Update last accessed time
      metadata['lastAccessedAt'] = DateTime.now().millisecondsSinceEpoch;
      await _metadataCacheBox!.put('audio_$songId', metadata);
      
      return _audioCacheBox!.get(songId);
    } catch (error) {
      throw CacheException.storageError('Failed to get cached song: ${error.toString()}');
    }
  }

  @override
  Future<bool> isSongCached(String songId) async {
    try {
      await _ensureBoxesOpen();
      
      if (!_audioCacheBox!.containsKey(songId)) return false;
      
      // Check if expired
      final metadata = _metadataCacheBox!.get('audio_$songId');
      if (metadata == null) return false;
      
      final cachedAt = metadata['cachedAt'] as int;
      final expirationTime = cachedAt + _audioExpiration.inMilliseconds;
      
      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        await removeCachedSong(songId);
        return false;
      }
      
      return true;
    } catch (error) {
      return false;
    }
  }

  @override
  Future<void> removeCachedSong(String songId) async {
    try {
      await _ensureBoxesOpen();
      
      await _audioCacheBox!.delete(songId);
      await _metadataCacheBox!.delete('audio_$songId');
      
      await _updateCacheStats();
    } catch (error) {
      throw CacheException.storageError('Failed to remove cached song: ${error.toString()}');
    }
  }

  @override
  Future<void> clearExpiredCache() async {
    try {
      await _ensureBoxesOpen();
      
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final expiredKeys = <String>[];
      
      // Check audio cache
      for (final key in _metadataCacheBox!.keys) {
        if (key.toString().startsWith('audio_')) {
          final metadata = _metadataCacheBox!.get(key);
          if (metadata != null) {
            final cachedAt = metadata['cachedAt'] as int;
            final expirationTime = cachedAt + _audioExpiration.inMilliseconds;
            
            if (currentTime > expirationTime) {
              final songId = key.toString().substring(6); // Remove 'audio_' prefix
              expiredKeys.add(songId);
            }
          }
        }
      }
      
      // Remove expired audio cache
      for (final songId in expiredKeys) {
        await removeCachedSong(songId);
      }
      
      // Check search cache
      final expiredSearchKeys = <String>[];
      for (final key in _searchCacheBox!.keys) {
        final searchData = _searchCacheBox!.get(key);
        if (searchData != null) {
          final cachedAt = searchData['cachedAt'] as int? ?? 0;
          final expirationTime = cachedAt + _searchExpiration.inMilliseconds;
          
          if (currentTime > expirationTime) {
            expiredSearchKeys.add(key.toString());
          }
        }
      }
      
      for (final key in expiredSearchKeys) {
        await _searchCacheBox!.delete(key);
      }
      
      // Check metadata cache
      final expiredMetadataKeys = <String>[];
      for (final key in _metadataCacheBox!.keys) {
        if (!key.toString().startsWith('audio_')) {
          final metadata = _metadataCacheBox!.get(key);
          if (metadata != null) {
            final cachedAt = metadata['cachedAt'] as int? ?? 0;
            final expirationTime = cachedAt + _metadataExpiration.inMilliseconds;
            
            if (currentTime > expirationTime) {
              expiredMetadataKeys.add(key.toString());
            }
          }
        }
      }
      
      for (final key in expiredMetadataKeys) {
        await _metadataCacheBox!.delete(key);
      }
      
      await _updateCacheStats();
    } catch (error) {
      throw CacheException.storageError('Failed to clear expired cache: ${error.toString()}');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      await _ensureBoxesOpen();
      
      await _audioCacheBox!.clear();
      await _metadataCacheBox!.clear();
      await _searchCacheBox!.clear();
      await _homeScreenCacheBox!.clear();
      await _albumCacheBox!.clear();
      await _artistCacheBox!.clear();
      await _playlistCacheBox!.clear();
      
      await _updateCacheStats();
    } catch (error) {
      throw CacheException.storageError('Failed to clear all cache: ${error.toString()}');
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      await _ensureBoxesOpen();
      
      int totalSize = 0;
      
      // Audio cache size
      for (final metadata in _metadataCacheBox!.values) {
        if (metadata['size'] != null) {
          totalSize += metadata['size'] as int;
        }
      }
      
      // Estimate other cache sizes (rough approximation)
      totalSize += _searchCacheBox!.length * 1024; // ~1KB per search result
      totalSize += _homeScreenCacheBox!.length * 5120; // ~5KB per home screen data
      totalSize += _albumCacheBox!.length * 2048; // ~2KB per album
      totalSize += _artistCacheBox!.length * 1024; // ~1KB per artist
      totalSize += _playlistCacheBox!.length * 3072; // ~3KB per playlist
      
      return totalSize;
    } catch (error) {
      return 0;
    }
  }

  @override
  Future<List<String>> getCachedSongIds() async {
    try {
      await _ensureBoxesOpen();
      return _audioCacheBox!.keys.cast<String>().toList();
    } catch (error) {
      return [];
    }
  }

  @override
  Future<void> cacheSongMetadata(String songId, Map<String, dynamic> metadata) async {
    try {
      await _ensureBoxesOpen();
      
      final cacheEntry = {
        ...metadata,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _metadataCacheBox!.put('metadata_$songId', cacheEntry);
    } catch (error) {
      throw CacheException.storageError('Failed to cache song metadata: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedSongMetadata(String songId) async {
    try {
      await _ensureBoxesOpen();
      
      final metadata = _metadataCacheBox!.get('metadata_$songId');
      if (metadata == null) return null;
      
      final cachedAt = metadata['cachedAt'] as int;
      final expirationTime = cachedAt + _metadataExpiration.inMilliseconds;
      
      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        await _metadataCacheBox!.delete('metadata_$songId');
        return null;
      }
      
      return Map<String, dynamic>.from(metadata);
    } catch (error) {
      return null;
    }
  }

  @override
  Future<void> cacheHomeScreenData(Map<String, dynamic> data) async {
    try {
      await _ensureBoxesOpen();
      
      final cacheEntry = {
        ...data,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _homeScreenCacheBox!.put('home_data', cacheEntry);
    } catch (error) {
      throw CacheException.storageError('Failed to cache home screen data: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedHomeScreenData() async {
    try {
      await _ensureBoxesOpen();
      
      final data = _homeScreenCacheBox!.get('home_data');
      if (data == null) return null;
      
      final cachedAt = data['cachedAt'] as int;
      final expirationTime = cachedAt + _metadataExpiration.inMilliseconds;
      
      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        await _homeScreenCacheBox!.delete('home_data');
        return null;
      }
      
      return Map<String, dynamic>.from(data);
    } catch (error) {
      return null;
    }
  }

  @override
  Future<void> cacheSearchResults(String query, Map<String, dynamic> results) async {
    try {
      await _ensureBoxesOpen();
      
      final cacheEntry = {
        ...results,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _searchCacheBox!.put(query.toLowerCase(), cacheEntry);
    } catch (error) {
      throw CacheException.storageError('Failed to cache search results: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedSearchResults(String query) async {
    try {
      await _ensureBoxesOpen();
      
      final results = _searchCacheBox!.get(query.toLowerCase());
      if (results == null) return null;
      
      final cachedAt = results['cachedAt'] as int;
      final expirationTime = cachedAt + _searchExpiration.inMilliseconds;
      
      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        await _searchCacheBox!.delete(query.toLowerCase());
        return null;
      }
      
      return Map<String, dynamic>.from(results);
    } catch (error) {
      return null;
    }
  }

  @override
  Future<void> cacheAlbumData(String albumId, Map<String, dynamic> albumData) async {
    try {
      await _ensureBoxesOpen();
      
      final cacheEntry = {
        ...albumData,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _albumCacheBox!.put(albumId, cacheEntry);
    } catch (error) {
      throw CacheException.storageError('Failed to cache album data: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedAlbumData(String albumId) async {
    try {
      await _ensureBoxesOpen();
      
      final data = _albumCacheBox!.get(albumId);
      if (data == null) return null;
      
      final cachedAt = data['cachedAt'] as int;
      final expirationTime = cachedAt + _metadataExpiration.inMilliseconds;
      
      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        await _albumCacheBox!.delete(albumId);
        return null;
      }
      
      return Map<String, dynamic>.from(data);
    } catch (error) {
      return null;
    }
  }

  @override
  Future<void> cacheArtistData(String artistId, Map<String, dynamic> artistData) async {
    try {
      await _ensureBoxesOpen();
      
      final cacheEntry = {
        ...artistData,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _artistCacheBox!.put(artistId, cacheEntry);
    } catch (error) {
      throw CacheException.storageError('Failed to cache artist data: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedArtistData(String artistId) async {
    try {
      await _ensureBoxesOpen();
      
      final data = _artistCacheBox!.get(artistId);
      if (data == null) return null;
      
      final cachedAt = data['cachedAt'] as int;
      final expirationTime = cachedAt + _metadataExpiration.inMilliseconds;
      
      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        await _artistCacheBox!.delete(artistId);
        return null;
      }
      
      return Map<String, dynamic>.from(data);
    } catch (error) {
      return null;
    }
  }

  @override
  Future<void> cachePlaylistData(String playlistId, Map<String, dynamic> playlistData) async {
    try {
      await _ensureBoxesOpen();
      
      final cacheEntry = {
        ...playlistData,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _playlistCacheBox!.put(playlistId, cacheEntry);
    } catch (error) {
      throw CacheException.storageError('Failed to cache playlist data: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedPlaylistData(String playlistId) async {
    try {
      await _ensureBoxesOpen();
      
      final data = _playlistCacheBox!.get(playlistId);
      if (data == null) return null;
      
      final cachedAt = data['cachedAt'] as int;
      final expirationTime = cachedAt + _metadataExpiration.inMilliseconds;
      
      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        await _playlistCacheBox!.delete(playlistId);
        return null;
      }
      
      return Map<String, dynamic>.from(data);
    } catch (error) {
      return null;
    }
  }

  @override
  void setCacheExpiration({
    Duration? audioCache,
    Duration? metadataCache,
    Duration? searchCache,
  }) {
    if (audioCache != null) _audioExpiration = audioCache;
    if (metadataCache != null) _metadataExpiration = metadataCache;
    if (searchCache != null) _searchExpiration = searchCache;
  }

  @override
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      await _ensureBoxesOpen();
      
      final totalSize = await getCacheSize();
      final songCount = _audioCacheBox!.length;
      final searchResultsCount = _searchCacheBox!.length;
      final albumCount = _albumCacheBox!.length;
      final artistCount = _artistCacheBox!.length;
      final playlistCount = _playlistCacheBox!.length;
      
      return {
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).round(),
        'cachedSongs': songCount,
        'cachedSearchResults': searchResultsCount,
        'cachedAlbums': albumCount,
        'cachedArtists': artistCount,
        'cachedPlaylists': playlistCount,
        'maxSizeBytes': _maxCacheSize,
        'maxSizeMB': (_maxCacheSize / (1024 * 1024)).round(),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (error) {
      return {};
    }
  }

  @override
  Future<void> optimizeCache({int? maxSizeBytes}) async {
    try {
      await _ensureBoxesOpen();
      
      final maxSize = maxSizeBytes ?? _maxCacheSize;
      final currentSize = await getCacheSize();
      
      if (currentSize <= maxSize) return;
      
      // Get all cached items with their access times
      final cacheItems = <Map<String, dynamic>>[];
      
      for (final key in _metadataCacheBox!.keys) {
        if (key.toString().startsWith('audio_')) {
          final metadata = _metadataCacheBox!.get(key);
          if (metadata != null) {
            final lastAccessed = metadata['lastAccessedAt'] as int? ?? 
                                metadata['cachedAt'] as int? ?? 0;
            cacheItems.add({
              'key': key.toString().substring(6), // Remove 'audio_' prefix
              'lastAccessed': lastAccessed,
              'size': metadata['size'] as int? ?? 0,
            });
          }
        }
      }
      
      // Sort by least recently used
      cacheItems.sort((a, b) => (a['lastAccessed'] as int).compareTo(b['lastAccessed'] as int));
      
      // Remove items until we're under the size limit
      int sizeToRemove = currentSize - maxSize;
      int removedSize = 0;
      
      for (final item in cacheItems) {
        if (removedSize >= sizeToRemove) break;
        
        final songId = item['key'] as String;
        await removeCachedSong(songId);
        removedSize += item['size'] as int;
      }
      
      await _updateCacheStats();
    } catch (error) {
      throw CacheException.storageError('Failed to optimize cache: ${error.toString()}');
    }
  }

  Future<void> _updateCacheStats() async {
    try {
      final stats = await getCacheStats();
      await _cacheStatsBox!.put('stats', stats);
    } catch (error) {
      // Don't throw, just log
      print('Failed to update cache stats: $error');
    }
  }
}