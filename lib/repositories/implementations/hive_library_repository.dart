import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:get/get.dart';

import '../interfaces/library_repository.dart';
import '../exceptions/repository_exception.dart';
import '../../models/playlist.dart';
import '../../models/media_item_builder.dart';

/// Concrete implementation of LibraryRepository using Hive for local storage
class HiveLibraryRepository implements LibraryRepository {
  static const String _songsBoxName = 'library_songs';
  static const String _playlistsBoxName = 'library_playlists';
  static const String _playlistSongsPrefix = 'playlist_songs_';
  static const String _statsBoxName = 'library_stats';

  Box<Map>? _songsBox;
  Box<Map>? _playlistsBox;
  Box<Map>? _statsBox;

  Future<void> _ensureBoxesOpen() async {
    _songsBox ??= await Hive.openBox<Map>(_songsBoxName);
    _playlistsBox ??= await Hive.openBox<Map>(_playlistsBoxName);
    _statsBox ??= await Hive.openBox<Map>(_statsBoxName);
  }

  @override
  Future<void> addSongToLibrary(MediaItem song) async {
    try {
      await _ensureBoxesOpen();
      final songData = MediaItemBuilder.toJson(song);
      songData['addedAt'] = DateTime.now().millisecondsSinceEpoch;
      songData['playCount'] = 0;
      await _songsBox!.put(song.id, songData);
      
      // Update stats
      await _updateLibraryStats();
    } catch (error) {
      throw LibraryException.storageError('Failed to add song to library: ${error.toString()}');
    }
  }

  @override
  Future<void> removeSongFromLibrary(String songId) async {
    try {
      await _ensureBoxesOpen();
      
      if (!_songsBox!.containsKey(songId)) {
        throw LibraryException.songNotFound(songId);
      }
      
      await _songsBox!.delete(songId);
      
      // Remove from all playlists
      final playlists = await getPlaylists();
      for (final playlist in playlists) {
        await removeSongFromPlaylist(playlist.playlistId, songId);
      }
      
      // Update stats
      await _updateLibraryStats();
    } catch (error) {
      if (error is LibraryException) rethrow;
      throw LibraryException.storageError('Failed to remove song from library: ${error.toString()}');
    }
  }

  @override
  Future<List<MediaItem>> getLibrarySongs() async {
    try {
      await _ensureBoxesOpen();
      final songs = <MediaItem>[];
      
      for (final songData in _songsBox!.values) {
        try {
          final song = MediaItemBuilder.fromJson(songData);
          songs.add(song);
        } catch (e) {
          // Skip corrupted entries
          continue;
        }
      }
      
      // Sort by recently added
      songs.sort((a, b) {
        final aAddedAt = a.extras?['addedAt'] as int? ?? 0;
        final bAddedAt = b.extras?['addedAt'] as int? ?? 0;
        return bAddedAt.compareTo(aAddedAt);
      });
      
      return songs;
    } catch (error) {
      throw LibraryException.storageError('Failed to get library songs: ${error.toString()}');
    }
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    try {
      await _ensureBoxesOpen();
      final playlists = <Playlist>[];
      
      for (final playlistData in _playlistsBox!.values) {
        try {
          final playlist = Playlist.fromJson(playlistData);
          playlists.add(playlist);
        } catch (e) {
          // Skip corrupted entries
          continue;
        }
      }
      
      // Sort by title
      playlists.sort((a, b) => a.title.compareTo(b.title));
      
      return playlists;
    } catch (error) {
      throw LibraryException.storageError('Failed to get playlists: ${error.toString()}');
    }
  }

  @override
  Future<Playlist> createPlaylist(String title, {String? description}) async {
    try {
      await _ensureBoxesOpen();
      
      // Check if playlist with same title exists
      final existingPlaylists = await getPlaylists();
      if (existingPlaylists.any((p) => p.title.toLowerCase() == title.toLowerCase())) {
        throw LibraryException.playlistExists(title);
      }
      
      final playlistId = DateTime.now().millisecondsSinceEpoch.toString();
      final playlist = Playlist(
        title: title,
        playlistId: playlistId,
        description: description ?? 'Custom playlist',
        thumbnailUrl: Playlist.thumbPlaceholderUrl,
        songCount: '0',
        isPipedPlaylist: false,
        isCloudPlaylist: false,
      );
      
      await _playlistsBox!.put(playlistId, playlist.toJson());
      
      // Create empty songs box for this playlist
      final playlistSongsBox = await Hive.openBox<Map>('$_playlistSongsPrefix$playlistId');
      await playlistSongsBox.close();
      
      return playlist;
    } catch (error) {
      if (error is LibraryException) rethrow;
      throw LibraryException.storageError('Failed to create playlist: ${error.toString()}');
    }
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _ensureBoxesOpen();
      
      if (!_playlistsBox!.containsKey(playlistId)) {
        throw LibraryException.playlistNotFound(playlistId);
      }
      
      // Delete playlist
      await _playlistsBox!.delete(playlistId);
      
      // Delete playlist songs
      try {
        await Hive.deleteBoxFromDisk('$_playlistSongsPrefix$playlistId');
      } catch (e) {
        // Box might not exist, ignore
      }
    } catch (error) {
      if (error is LibraryException) rethrow;
      throw LibraryException.storageError('Failed to delete playlist: ${error.toString()}');
    }
  }

  @override
  Future<void> addSongToPlaylist(String playlistId, MediaItem song) async {
    try {
      await _ensureBoxesOpen();
      
      if (!_playlistsBox!.containsKey(playlistId)) {
        throw LibraryException.playlistNotFound(playlistId);
      }
      
      final playlistSongsBox = await Hive.openBox<Map>('$_playlistSongsPrefix$playlistId');
      final songData = MediaItemBuilder.toJson(song);
      songData['addedAt'] = DateTime.now().millisecondsSinceEpoch;
      await playlistSongsBox.put(song.id, songData);
      
      // Update playlist song count
      final playlistData = Map<String, dynamic>.from(_playlistsBox!.get(playlistId)!);
      playlistData['itemCount'] = playlistSongsBox.length.toString();
      await _playlistsBox!.put(playlistId, playlistData);
      
      await playlistSongsBox.close();
    } catch (error) {
      if (error is LibraryException) rethrow;
      throw LibraryException.storageError('Failed to add song to playlist: ${error.toString()}');
    }
  }

  @override
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _ensureBoxesOpen();
      
      if (!_playlistsBox!.containsKey(playlistId)) {
        throw LibraryException.playlistNotFound(playlistId);
      }
      
      final playlistSongsBox = await Hive.openBox<Map>('$_playlistSongsPrefix$playlistId');
      await playlistSongsBox.delete(songId);
      
      // Update playlist song count
      final playlistData = Map<String, dynamic>.from(_playlistsBox!.get(playlistId)!);
      playlistData['itemCount'] = playlistSongsBox.length.toString();
      await _playlistsBox!.put(playlistId, playlistData);
      
      await playlistSongsBox.close();
    } catch (error) {
      if (error is LibraryException) rethrow;
      throw LibraryException.storageError('Failed to remove song from playlist: ${error.toString()}');
    }
  }

  @override
  Future<List<MediaItem>> getPlaylistSongs(String playlistId) async {
    try {
      await _ensureBoxesOpen();
      
      if (!_playlistsBox!.containsKey(playlistId)) {
        throw LibraryException.playlistNotFound(playlistId);
      }
      
      final playlistSongsBox = await Hive.openBox<Map>('$_playlistSongsPrefix$playlistId');
      final songs = <MediaItem>[];
      
      for (final songData in playlistSongsBox.values) {
        try {
          final song = MediaItemBuilder.fromJson(songData);
          songs.add(song);
        } catch (e) {
          // Skip corrupted entries
          continue;
        }
      }
      
      await playlistSongsBox.close();
      
      // Sort by added date
      songs.sort((a, b) {
        final aAddedAt = a.extras?['addedAt'] as int? ?? 0;
        final bAddedAt = b.extras?['addedAt'] as int? ?? 0;
        return aAddedAt.compareTo(bAddedAt);
      });
      
      return songs;
    } catch (error) {
      if (error is LibraryException) rethrow;
      throw LibraryException.storageError('Failed to get playlist songs: ${error.toString()}');
    }
  }

  @override
  Future<void> updatePlaylist(
    String playlistId, {
    String? title,
    String? description,
    String? thumbnailUrl,
  }) async {
    try {
      await _ensureBoxesOpen();
      
      if (!_playlistsBox!.containsKey(playlistId)) {
        throw LibraryException.playlistNotFound(playlistId);
      }
      
      final playlistData = Map<String, dynamic>.from(_playlistsBox!.get(playlistId)!);
      
      if (title != null) playlistData['title'] = title;
      if (description != null) playlistData['description'] = description;
      if (thumbnailUrl != null) {
        playlistData['thumbnails'] = [{'url': thumbnailUrl}];
      }
      
      await _playlistsBox!.put(playlistId, playlistData);
    } catch (error) {
      if (error is LibraryException) rethrow;
      throw LibraryException.storageError('Failed to update playlist: ${error.toString()}');
    }
  }

  @override
  Future<bool> isSongInLibrary(String songId) async {
    try {
      await _ensureBoxesOpen();
      return _songsBox!.containsKey(songId);
    } catch (error) {
      throw LibraryException.storageError('Failed to check if song is in library: ${error.toString()}');
    }
  }

  @override
  Future<bool> isSongInPlaylist(String playlistId, String songId) async {
    try {
      await _ensureBoxesOpen();
      
      if (!_playlistsBox!.containsKey(playlistId)) {
        return false;
      }
      
      final playlistSongsBox = await Hive.openBox<Map>('$_playlistSongsPrefix$playlistId');
      final exists = playlistSongsBox.containsKey(songId);
      await playlistSongsBox.close();
      
      return exists;
    } catch (error) {
      throw LibraryException.storageError('Failed to check if song is in playlist: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, int>> getLibraryStats() async {
    try {
      await _ensureBoxesOpen();
      
      final songCount = _songsBox!.length;
      final playlistCount = _playlistsBox!.length;
      
      // Calculate total play count
      int totalPlayCount = 0;
      for (final songData in _songsBox!.values) {
        totalPlayCount += (songData['playCount'] as int? ?? 0);
      }
      
      return {
        'songCount': songCount,
        'playlistCount': playlistCount,
        'totalPlayCount': totalPlayCount,
      };
    } catch (error) {
      throw LibraryException.storageError('Failed to get library stats: ${error.toString()}');
    }
  }

  @override
  Future<List<MediaItem>> searchLibrary(String query) async {
    try {
      final allSongs = await getLibrarySongs();
      final lowerQuery = query.toLowerCase();
      
      return allSongs.where((song) {
        return song.title.toLowerCase().contains(lowerQuery) ||
               (song.artist?.toLowerCase().contains(lowerQuery) ?? false) ||
               (song.album?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (error) {
      throw LibraryException.storageError('Failed to search library: ${error.toString()}');
    }
  }

  @override
  Future<List<MediaItem>> getRecentlyAdded({int limit = 50}) async {
    try {
      final allSongs = await getLibrarySongs();
      return allSongs.take(limit).toList(); // Already sorted by addedAt in getLibrarySongs
    } catch (error) {
      throw LibraryException.storageError('Failed to get recently added songs: ${error.toString()}');
    }
  }

  @override
  Future<List<MediaItem>> getMostPlayed({int limit = 50}) async {
    try {
      final allSongs = await getLibrarySongs();
      
      // Sort by play count
      allSongs.sort((a, b) {
        final aPlayCount = a.extras?['playCount'] as int? ?? 0;
        final bPlayCount = b.extras?['playCount'] as int? ?? 0;
        return bPlayCount.compareTo(aPlayCount);
      });
      
      return allSongs.take(limit).toList();
    } catch (error) {
      throw LibraryException.storageError('Failed to get most played songs: ${error.toString()}');
    }
  }

  @override
  Future<void> incrementPlayCount(String songId) async {
    try {
      await _ensureBoxesOpen();
      
      if (_songsBox!.containsKey(songId)) {
        final songData = Map<String, dynamic>.from(_songsBox!.get(songId)!);
        songData['playCount'] = (songData['playCount'] as int? ?? 0) + 1;
        songData['lastPlayedAt'] = DateTime.now().millisecondsSinceEpoch;
        await _songsBox!.put(songId, songData);
      }
    } catch (error) {
      throw LibraryException.storageError('Failed to increment play count: ${error.toString()}');
    }
  }

  @override
  Future<void> clearLibrary() async {
    try {
      await _ensureBoxesOpen();
      
      // Clear all songs
      await _songsBox!.clear();
      
      // Clear all playlists and their songs
      final playlists = await getPlaylists();
      for (final playlist in playlists) {
        try {
          await Hive.deleteBoxFromDisk('$_playlistSongsPrefix${playlist.playlistId}');
        } catch (e) {
          // Box might not exist, ignore
        }
      }
      await _playlistsBox!.clear();
      
      // Clear stats
      await _statsBox!.clear();
    } catch (error) {
      throw LibraryException.storageError('Failed to clear library: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> exportLibrary() async {
    try {
      await _ensureBoxesOpen();
      
      final songs = await getLibrarySongs();
      final playlists = await getPlaylists();
      final stats = await getLibraryStats();
      
      final playlistsWithSongs = <Map<String, dynamic>>[];
      for (final playlist in playlists) {
        final playlistSongs = await getPlaylistSongs(playlist.playlistId);
        playlistsWithSongs.add({
          'playlist': playlist.toJson(),
          'songs': playlistSongs.map((s) => MediaItemBuilder.toJson(s)).toList(),
        });
      }
      
      return {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'songs': songs.map((s) => MediaItemBuilder.toJson(s)).toList(),
        'playlists': playlistsWithSongs,
        'stats': stats,
      };
    } catch (error) {
      throw LibraryException.exportError('Failed to export library: ${error.toString()}');
    }
  }

  @override
  Future<void> importLibrary(Map<String, dynamic> data) async {
    try {
      await _ensureBoxesOpen();
      
      // Validate data structure
      if (data['version'] == null || data['songs'] == null || data['playlists'] == null) {
        throw LibraryException.importError('Invalid library data format');
      }
      
      // Clear existing data
      await clearLibrary();
      
      // Import songs
      final songs = data['songs'] as List;
      for (final songData in songs) {
        try {
          final song = MediaItemBuilder.fromJson(songData);
          await addSongToLibrary(song);
        } catch (e) {
          // Skip invalid songs
          continue;
        }
      }
      
      // Import playlists
      final playlists = data['playlists'] as List;
      for (final playlistData in playlists) {
        try {
          final playlist = Playlist.fromJson(playlistData['playlist']);
          await _playlistsBox!.put(playlist.playlistId, playlist.toJson());
          
          // Import playlist songs
          final playlistSongs = playlistData['songs'] as List;
          final playlistSongsBox = await Hive.openBox<Map>('$_playlistSongsPrefix${playlist.playlistId}');
          
          for (final songData in playlistSongs) {
            try {
              final song = MediaItemBuilder.fromJson(songData);
              await playlistSongsBox.put(song.id, songData);
            } catch (e) {
              // Skip invalid songs
              continue;
            }
          }
          
          await playlistSongsBox.close();
        } catch (e) {
          // Skip invalid playlists
          continue;
        }
      }
      
      await _updateLibraryStats();
    } catch (error) {
      if (error is LibraryException) rethrow;
      throw LibraryException.importError('Failed to import library: ${error.toString()}');
    }
  }

  Future<void> _updateLibraryStats() async {
    try {
      final stats = await getLibraryStats();
      await _statsBox!.put('stats', {
        ...stats,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (error) {
      // Don't throw, just log
      print('Failed to update library stats: $error');
    }
  }
}