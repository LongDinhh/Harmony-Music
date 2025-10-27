// Repositories barrel file - exports all repository interfaces
// This file provides a single import point for all repository interfaces

import 'dart:convert' show json;

// Export all repository interfaces
export 'music_repository.dart';
export 'library_repository.dart';
export 'cache_repository.dart';

// Export all concrete implementations
export 'implementations/youtube_music_repository.dart';
export 'implementations/hive_library_repository.dart';
export 'implementations/hive_cache_repository.dart';

// Repository-specific exceptions
class RepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const RepositoryException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'RepositoryException: $message';
}

class MusicException extends RepositoryException {
  const MusicException(super.message, {super.code, super.originalError});

  const MusicException.searchFailed(String message)
      : super(message, code: 'SEARCH_FAILED');

  const MusicException.albumNotFound(String albumId)
      : super('Album not found: $albumId', code: 'ALBUM_NOT_FOUND');

  const MusicException.artistNotFound(String artistId)
      : super('Artist not found: $artistId', code: 'ARTIST_NOT_FOUND');

  const MusicException.networkError(String message)
      : super('Network error: $message', code: 'NETWORK_ERROR');

  const MusicException.parseError(String message)
      : super('Parse error: $message', code: 'PARSE_ERROR');
}

class LibraryException extends RepositoryException {
  const LibraryException(super.message, {super.code, super.originalError});

  const LibraryException.addFailed(String message)
      : super('Failed to add to library: $message', code: 'ADD_FAILED');

  const LibraryException.removeFailed(String message)
      : super('Failed to remove from library: $message', code: 'REMOVE_FAILED');

  const LibraryException.playlistNotFound(String playlistId)
      : super('Playlist not found: $playlistId', code: 'PLAYLIST_NOT_FOUND');

  const LibraryException.playlistCreateFailed(String message)
      : super('Failed to create playlist: $message', code: 'CREATE_FAILED');

  const LibraryException.syncFailed(String message)
      : super('Sync failed: $message', code: 'SYNC_FAILED');

  const LibraryException.importFailed(String message)
      : super('Import failed: $message', code: 'IMPORT_FAILED');

  const LibraryException.exportFailed(String message)
      : super('Export failed: $message', code: 'EXPORT_FAILED');
}

class CacheException extends RepositoryException {
  const CacheException(super.message, {super.code, super.originalError});

  const CacheException.writeFailed(String message)
      : super('Cache write failed: $message', code: 'WRITE_FAILED');

  const CacheException.readFailed(String message)
      : super('Cache read failed: $message', code: 'READ_FAILED');

  const CacheException.deleteFailed(String message)
      : super('Cache delete failed: $message', code: 'DELETE_FAILED');

  const CacheException.insufficientSpace(String message)
      : super('Insufficient cache space: $message', code: 'INSUFFICIENT_SPACE');

  const CacheException.corruptedData(String message)
      : super('Corrupted cache data: $message', code: 'CORRUPTED_DATA');

  const CacheException.configurationError(String message)
      : super('Cache configuration error: $message', code: 'CONFIG_ERROR');
}

// Repository configuration class
class RepositoryConfig {
  static const Duration defaultCacheExpiration = Duration(hours: 24);
  static const int defaultMaxCacheSizeBytes = 100 * 1024 * 1024; // 100MB
  static const int defaultMaxCacheEntries = 1000;
  static const int defaultSearchLimit = 30;
  static const Duration defaultNetworkTimeout = Duration(seconds: 30);
}

// Repository utilities
class RepositoryUtils {
  /// Generate unique cache key từ multiple parameters
  static String generateCacheKey(List<String> parts) {
    return parts.join('_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  /// Validate repository input parameters
  static void validateNonEmpty(String value, String paramName) {
    if (value.trim().isEmpty) {
      throw RepositoryException('$paramName cannot be empty');
    }
  }

  /// Validate list not empty
  static void validateListNotEmpty<T>(List<T> list, String paramName) {
    if (list.isEmpty) {
      throw RepositoryException('$paramName cannot be empty');
    }
  }

  /// Safe JSON conversion with error handling
  static Map<String, dynamic>? safeJsonDecode(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}