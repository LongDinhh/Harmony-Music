import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';

/// Abstract repository interface for caching operations
abstract class CacheRepository {
  /// Cache song audio data
  Future<void> cacheSong(MediaItem song, Uint8List audioData);

  /// Get cached song audio data
  Future<Uint8List?> getCachedSong(String songId);

  /// Check if a song is cached
  Future<bool> isSongCached(String songId);

  /// Remove a specific song from cache
  Future<void> removeCachedSong(String songId);

  /// Clear all expired cache entries
  Future<void> clearExpiredCache();

  /// Clear all cache data
  Future<void> clearAllCache();

  /// Get cache size in bytes
  Future<int> getCacheSize();

  /// Get list of cached songs
  Future<List<String>> getCachedSongIds();

  /// Cache song metadata (without audio data)
  Future<void> cacheSongMetadata(String songId, Map<String, dynamic> metadata);

  /// Get cached song metadata
  Future<Map<String, dynamic>?> getCachedSongMetadata(String songId);

  /// Cache home screen data
  Future<void> cacheHomeScreenData(Map<String, dynamic> data);

  /// Get cached home screen data
  Future<Map<String, dynamic>?> getCachedHomeScreenData();

  /// Cache search results
  Future<void> cacheSearchResults(String query, Map<String, dynamic> results);

  /// Get cached search results
  Future<Map<String, dynamic>?> getCachedSearchResults(String query);

  /// Cache album data
  Future<void> cacheAlbumData(String albumId, Map<String, dynamic> albumData);

  /// Get cached album data
  Future<Map<String, dynamic>?> getCachedAlbumData(String albumId);

  /// Cache artist data
  Future<void> cacheArtistData(String artistId, Map<String, dynamic> artistData);

  /// Get cached artist data
  Future<Map<String, dynamic>?> getCachedArtistData(String artistId);

  /// Cache playlist data
  Future<void> cachePlaylistData(String playlistId, Map<String, dynamic> playlistData);

  /// Get cached playlist data
  Future<Map<String, dynamic>?> getCachedPlaylistData(String playlistId);

  /// Set cache expiration time for different data types
  void setCacheExpiration({
    Duration? audioCache,
    Duration? metadataCache,
    Duration? searchCache,
  });

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats();

  /// Optimize cache (remove least recently used items if size exceeds limit)
  Future<void> optimizeCache({int? maxSizeBytes});
}