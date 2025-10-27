import 'package:audio_service/audio_service.dart';
import '../../models/playlist.dart';

/// Abstract repository interface for local library operations
abstract class LibraryRepository {
  /// Add a song to the user's library
  Future<void> addSongToLibrary(MediaItem song);

  /// Remove a song from the user's library by song ID
  Future<void> removeSongFromLibrary(String songId);

  /// Get all songs in the user's library
  Future<List<MediaItem>> getLibrarySongs();

  /// Get all playlists in the user's library
  Future<List<Playlist>> getPlaylists();

  /// Create a new playlist
  Future<Playlist> createPlaylist(String title, {String? description});

  /// Delete a playlist
  Future<void> deletePlaylist(String playlistId);

  /// Add a song to a specific playlist
  Future<void> addSongToPlaylist(String playlistId, MediaItem song);

  /// Remove a song from a specific playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId);

  /// Get songs from a specific playlist
  Future<List<MediaItem>> getPlaylistSongs(String playlistId);

  /// Update playlist metadata (title, description, thumbnail)
  Future<void> updatePlaylist(
    String playlistId, {
    String? title,
    String? description,
    String? thumbnailUrl,
  });

  /// Check if a song exists in the library
  Future<bool> isSongInLibrary(String songId);

  /// Check if a song exists in a specific playlist
  Future<bool> isSongInPlaylist(String playlistId, String songId);

  /// Get library statistics (song count, playlist count, etc.)
  Future<Map<String, int>> getLibraryStats();

  /// Search within the user's library
  Future<List<MediaItem>> searchLibrary(String query);

  /// Get recently added songs
  Future<List<MediaItem>> getRecentlyAdded({int limit = 50});

  /// Get most played songs
  Future<List<MediaItem>> getMostPlayed({int limit = 50});

  /// Update song play count
  Future<void> incrementPlayCount(String songId);

  /// Clear all library data
  Future<void> clearLibrary();

  /// Export library data
  Future<Map<String, dynamic>> exportLibrary();

  /// Import library data
  Future<void> importLibrary(Map<String, dynamic> data);
}