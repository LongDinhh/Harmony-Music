/// Base exception class for repository operations
abstract class RepositoryException implements Exception {
  const RepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'RepositoryException: $message';
}

/// Exception thrown when music operations fail
class MusicException extends RepositoryException {
  const MusicException(super.message, [super.cause]);

  const MusicException.searchFailed(String message) : super(message);
  const MusicException.albumNotFound(String albumId) : super('Album not found: $albumId');
  const MusicException.artistNotFound(String artistId) : super('Artist not found: $artistId');
  const MusicException.networkError(String message) : super(message);
  const MusicException.parseError(String message) : super(message);

  @override
  String toString() => 'MusicException: $message';
}

/// Exception thrown when library operations fail
class LibraryException extends RepositoryException {
  const LibraryException(super.message, [super.cause]);

  const LibraryException.songNotFound(String songId) : super('Song not found in library: $songId');
  const LibraryException.playlistNotFound(String playlistId) : super('Playlist not found: $playlistId');
  const LibraryException.playlistExists(String title) : super('Playlist already exists: $title');
  const LibraryException.storageError(String message) : super(message);
  const LibraryException.importError(String message) : super('Import failed: $message');
  const LibraryException.exportError(String message) : super('Export failed: $message');

  @override
  String toString() => 'LibraryException: $message';
}

/// Exception thrown when cache operations fail
class CacheException extends RepositoryException {
  const CacheException(super.message, [super.cause]);

  const CacheException.storageError(String message) : super(message);
  const CacheException.corruptedData(String message) : super('Corrupted cache data: $message');
  const CacheException.insufficientSpace(String message) : super('Insufficient storage space: $message');
  const CacheException.cacheNotFound(String key) : super('Cache not found: $key');

  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when user preference operations fail
class UserException extends RepositoryException {
  const UserException(super.message, [super.cause]);

  const UserException.preferenceNotFound(String key) : super('Preference not found: $key');
  const UserException.invalidValue(String key, String value) : super('Invalid value for $key: $value');
  const UserException.storageError(String message) : super(message);

  @override
  String toString() => 'UserException: $message';
}