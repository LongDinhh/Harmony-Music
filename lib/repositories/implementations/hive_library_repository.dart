import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import '../../models/album.dart';
import '../../models/playlist.dart';
import '../../models/media_Item_builder.dart';
import '../../ui/screens/Library/library_controller.dart';
import '../../services/piped_service.dart';
import '../../utils/helper.dart';
import '../repositories.dart';

/// Concrete implementation của LibraryRepository sử dụng Hive database
/// Maintains logic compatibility với existing library controllers
class HiveLibraryRepository implements LibraryRepository {
  // Hive box names used in the app
  static const String _libraryPlaylistsBox = "LibraryPlaylists";
  static const String _libraryAlbumsBox = "LibraryAlbums";
  static const String _favoritesBox = "LIBFAV";
  static const String _recentlyPlayedBox = "LIBRP";
  static const String _songsDownloadsBox = "SongDownloads";
  static const String _songsCacheBox = "SongsCache";

  final PipedServices? _pipedService;

  HiveLibraryRepository({PipedServices? pipedService})
      : _pipedService = pipedService;

  @override
  Future<void> addSongToLibrary(MediaItem song) async {
    try {
      printINFO('📚 HiveLibraryRepository: Adding song to favorites: ${song.title}');
      
      final box = await Hive.openBox(_favoritesBox);
      final songData = MediaItemBuilder.toJson(song);
      await box.put(song.id, songData);
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Song added to favorites successfully');
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.addSongToLibrary error: $error');
      throw LibraryException.addFailed('Failed to add song to library: $error');
    }
  }

  @override
  Future<void> removeSongFromLibrary(String songId) async {
    try {
      RepositoryUtils.validateNonEmpty(songId, 'songId');
      
      printINFO('📚 HiveLibraryRepository: Removing song from favorites: $songId');
      
      final box = await Hive.openBox(_favoritesBox);
      await box.delete(songId);
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Song removed from favorites successfully');
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.removeSongFromLibrary error: $error');
      throw LibraryException.removeFailed('Failed to remove song from library: $error');
    }
  }

  @override
  Future<List<MediaItem>> getLibrarySongs() async {
    try {
      printINFO('📚 HiveLibraryRepository: Getting all library songs');
      
      final box = await Hive.openBox(_favoritesBox);
      final songs = box.values.map((songData) {
        final song = MediaItemBuilder.fromJson(songData);
        return MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          artUri: song.artUri,
          extras: {"libraryId": _favoritesBox},
          playable: true,
        );
      }).toList();
      
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Got ${songs.length} library songs');
      return songs;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.getLibrarySongs error: $error');
      throw LibraryException.syncFailed('Failed to get library songs: $error');
    }
  }

  @override
  Future<bool> isSongInLibrary(String songId) async {
    try {
      RepositoryUtils.validateNonEmpty(songId, 'songId');
      
      final box = await Hive.openBox(_favoritesBox);
      final exists = box.containsKey(songId);
      await box.close();
      
      return exists;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.isSongInLibrary error: $error');
      return false;
    }
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    try {
      printINFO('📚 HiveLibraryRepository: Getting all playlists');
      
      final box = await Hive.openBox(_libraryPlaylistsBox);
      
      // Include default playlists + user created playlists
      final playlists = [
        ...LibraryPlaylistsController.initPlst,
        ...(box.values
            .map<Playlist?>((item) => Playlist.fromJson(item))
            .whereType<Playlist>()
            .toList())
      ];
      
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Got ${playlists.length} playlists');
      return playlists;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.getPlaylists error: $error');
      throw LibraryException.syncFailed('Failed to get playlists: $error');
    }
  }

  @override
  Future<bool> addOrRemoveAlbumFromLibrary(Album album, {required bool add}) async {
    try {
      printINFO('📚 HiveLibraryRepository: ${add ? 'Adding' : 'Removing'} album: ${album.title}');
      
      final box = await Hive.openBox(_libraryAlbumsBox);
      
      if (add) {
        await box.put(album.browseId, album.toJson());
      } else {
        await box.delete(album.browseId);
      }
      
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Album ${add ? 'added' : 'removed'} successfully');
      return true;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.addOrRemoveAlbumFromLibrary error: $error');
      throw LibraryException.addFailed('Failed to ${add ? 'add' : 'remove'} album: $error');
    }
  }

  @override
  Future<bool> isAlbumInLibrary(String albumId) async {
    try {
      RepositoryUtils.validateNonEmpty(albumId, 'albumId');
      
      final box = await Hive.openBox(_libraryAlbumsBox);
      final exists = box.containsKey(albumId);
      await box.close();
      
      return exists;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.isAlbumInLibrary error: $error');
      return false;
    }
  }

  @override
  Future<List<Album>> getLibraryAlbums() async {
    try {
      printINFO('📚 HiveLibraryRepository: Getting all library albums');
      
      final box = await Hive.openBox(_libraryAlbumsBox);
      final albums = box.values
          .map<Album?>((item) => Album.fromJson(item))
          .whereType<Album>()
          .toList();
      
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Got ${albums.length} library albums');
      return albums;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.getLibraryAlbums error: $error');
      throw LibraryException.syncFailed('Failed to get library albums: $error');
    }
  }

  @override
  Future<Playlist> createPlaylist(String playlistName, {String? description}) async {
    try {
      RepositoryUtils.validateNonEmpty(playlistName, 'playlistName');
      
      printINFO('📚 HiveLibraryRepository: Creating playlist: $playlistName');
      
      // Generate unique playlist ID
      final playlistId = 'PL_${DateTime.now().millisecondsSinceEpoch}';
      
      final playlist = Playlist(
        title: playlistName,
        playlistId: playlistId,
        description: description ?? "User created playlist",
        thumbnailUrl: Playlist.thumbPlaceholderUrl,
        isCloudPlaylist: false,
      );
      
      final box = await Hive.openBox(_libraryPlaylistsBox);
      await box.put(playlistId, playlist.toJson());
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Playlist created successfully: $playlistId');
      return playlist;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.createPlaylist error: $error');
      throw LibraryException.playlistCreateFailed('Failed to create playlist: $error');
    }
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    try {
      RepositoryUtils.validateNonEmpty(playlistId, 'playlistId');
      
      // Prevent deletion of default playlists
      if (_isDefaultPlaylist(playlistId)) {
        throw const LibraryException.removeFailed('Cannot delete default playlist');
      }
      
      printINFO('📚 HiveLibraryRepository: Deleting playlist: $playlistId');
      
      // Delete playlist metadata
      final playlistBox = await Hive.openBox(_libraryPlaylistsBox);
      await playlistBox.delete(playlistId);
      await playlistBox.close();
      
      // Delete playlist songs
      final songsBox = await Hive.openBox(playlistId);
      await songsBox.clear();
      await songsBox.close();
      
      printINFO('📚 HiveLibraryRepository: Playlist deleted successfully');
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.deletePlaylist error: $error');
      throw LibraryException.removeFailed('Failed to delete playlist: $error');
    }
  }

  @override
  Future<void> addSongToPlaylist(String playlistId, MediaItem song) async {
    try {
      RepositoryUtils.validateNonEmpty(playlistId, 'playlistId');
      
      printINFO('📚 HiveLibraryRepository: Adding song to playlist $playlistId: ${song.title}');
      
      final box = await Hive.openBox(playlistId);
      final songData = MediaItemBuilder.toJson(song);
      await box.put(song.id, songData);
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Song added to playlist successfully');
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.addSongToPlaylist error: $error');
      throw LibraryException.addFailed('Failed to add song to playlist: $error');
    }
  }

  @override
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      RepositoryUtils.validateNonEmpty(playlistId, 'playlistId');
      RepositoryUtils.validateNonEmpty(songId, 'songId');
      
      printINFO('📚 HiveLibraryRepository: Removing song from playlist $playlistId: $songId');
      
      final box = await Hive.openBox(playlistId);
      await box.delete(songId);
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Song removed from playlist successfully');
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.removeSongFromPlaylist error: $error');
      throw LibraryException.removeFailed('Failed to remove song from playlist: $error');
    }
  }

  @override
  Future<List<MediaItem>> getPlaylistSongs(String playlistId) async {
    try {
      RepositoryUtils.validateNonEmpty(playlistId, 'playlistId');
      
      printINFO('📚 HiveLibraryRepository: Getting songs from playlist: $playlistId');
      
      final box = await Hive.openBox(playlistId);
      final songs = box.values.map((songData) {
        final song = MediaItemBuilder.fromJson(songData);
        return MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          artUri: song.artUri,
          extras: {"libraryId": playlistId},
          playable: true,
        );
      }).toList();
      
      // For recently played, reverse the order (most recent first)
      if (playlistId == _recentlyPlayedBox) {
        songs.reversed.toList();
      }
      
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Got ${songs.length} songs from playlist');
      return songs;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.getPlaylistSongs error: $error');
      throw LibraryException.syncFailed('Failed to get playlist songs: $error');
    }
  }

  @override
  Future<void> updatePlaylist(
    String playlistId, {
    String? newName,
    String? newDescription,
  }) async {
    try {
      RepositoryUtils.validateNonEmpty(playlistId, 'playlistId');
      
      if (_isDefaultPlaylist(playlistId)) {
        throw const LibraryException.removeFailed('Cannot update default playlist');
      }
      
      printINFO('📚 HiveLibraryRepository: Updating playlist: $playlistId');
      
      final box = await Hive.openBox(_libraryPlaylistsBox);
      final playlistData = box.get(playlistId);
      
      if (playlistData == null) {
        throw LibraryException.playlistNotFound(playlistId);
      }
      
      final playlist = Playlist.fromJson(playlistData);
      final updatedPlaylist = Playlist(
        title: newName ?? playlist.title,
        playlistId: playlist.playlistId,
        description: newDescription ?? playlist.description,
        thumbnailUrl: playlist.thumbnailUrl,
        isCloudPlaylist: playlist.isCloudPlaylist,
      );
      
      await box.put(playlistId, updatedPlaylist.toJson());
      await box.close();
      
      printINFO('📚 HiveLibraryRepository: Playlist updated successfully');
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.updatePlaylist error: $error');
      throw LibraryException.removeFailed('Failed to update playlist: $error');
    }
  }

  @override
  Future<Map<String, int>> getLibraryStatistics() async {
    try {
      printINFO('📚 HiveLibraryRepository: Getting library statistics');
      
      final futures = [
        getLibrarySongs(),
        getPlaylists(),
        getLibraryAlbums(),
        _getDownloadedSongs(),
        _getCachedSongs(),
      ];
      
      final results = await Future.wait(futures);
      
      final stats = {
        'songs': (results[0] as List).length,
        'playlists': (results[1] as List).length - LibraryPlaylistsController.initPlst.length, // Exclude default playlists
        'albums': (results[2] as List).length,
        'downloads': (results[3] as List).length,
        'cached': (results[4] as List).length,
      };
      
      printINFO('📚 HiveLibraryRepository: Statistics - $stats');
      return stats;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.getLibraryStatistics error: $error');
      throw LibraryException.syncFailed('Failed to get library statistics: $error');
    }
  }

  @override
  Future<void> syncLibrary() async {
    try {
      printINFO('📚 HiveLibraryRepository: Syncing library with cloud');
      
      // Sync with Piped service if logged in
      if (_pipedService != null && _pipedService!.isLoggedIn) {
        // Implementation for Piped sync would go here
        printINFO('📚 HiveLibraryRepository: Syncing with Piped service');
        // For now, just log that sync would happen
      }
      
      printINFO('📚 HiveLibraryRepository: Library sync completed');
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.syncLibrary error: $error');
      throw LibraryException.syncFailed('Failed to sync library: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> exportLibraryData() async {
    try {
      printINFO('📚 HiveLibraryRepository: Exporting library data');
      
      final futures = [
        getLibrarySongs(),
        getPlaylists(),
        getLibraryAlbums(),
      ];
      
      final results = await Future.wait(futures);
      
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'songs': (results[0] as List<MediaItem>).map((song) => MediaItemBuilder.toJson(song)).toList(),
        'playlists': (results[1] as List<Playlist>).map((playlist) => playlist.toJson()).toList(),
        'albums': (results[2] as List<Album>).map((album) => album.toJson()).toList(),
      };
      
      printINFO('📚 HiveLibraryRepository: Library data exported successfully');
      return exportData;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.exportLibraryData error: $error');
      throw LibraryException.exportFailed('Failed to export library data: $error');
    }
  }

  @override
  Future<void> importLibraryData(Map<String, dynamic> data) async {
    try {
      printINFO('📚 HiveLibraryRepository: Importing library data');
      
      // Validate import data structure
      if (!data.containsKey('version') || !data.containsKey('songs')) {
        throw const LibraryException.importFailed('Invalid import data format');
      }
      
      // Import songs to favorites
      final songs = data['songs'] as List<dynamic>? ?? [];
      for (final songData in songs) {
        try {
          final song = MediaItemBuilder.fromJson(songData);
          await addSongToLibrary(song);
        } catch (e) {
          printWARN('⚠️ Failed to import song: $e');
        }
      }
      
      // Import playlists (excluding default ones)
      final playlists = data['playlists'] as List<dynamic>? ?? [];
      for (final playlistData in playlists) {
        try {
          final playlist = Playlist.fromJson(playlistData);
          if (!_isDefaultPlaylist(playlist.playlistId)) {
            final box = await Hive.openBox(_libraryPlaylistsBox);
            await box.put(playlist.playlistId, playlist.toJson());
            await box.close();
          }
        } catch (e) {
          printWARN('⚠️ Failed to import playlist: $e');
        }
      }
      
      // Import albums
      final albums = data['albums'] as List<dynamic>? ?? [];
      for (final albumData in albums) {
        try {
          final album = Album.fromJson(albumData);
          await addOrRemoveAlbumFromLibrary(album, add: true);
        } catch (e) {
          printWARN('⚠️ Failed to import album: $e');
        }
      }
      
      printINFO('📚 HiveLibraryRepository: Library data imported successfully');
    } catch (error) {
      printERROR('❌ HiveLibraryRepository.importLibraryData error: $error');
      throw LibraryException.importFailed('Failed to import library data: $error');
    }
  }

  /// Helper method to check if playlist is a default system playlist
  bool _isDefaultPlaylist(String playlistId) {
    final defaultIds = LibraryPlaylistsController.initPlst
        .map((playlist) => playlist.playlistId)
        .toList();
    return defaultIds.contains(playlistId);
  }

  /// Helper method to get downloaded songs
  Future<List<MediaItem>> _getDownloadedSongs() async {
    try {
      final box = await Hive.openBox(_songsDownloadsBox);
      final songs = box.values.map((songData) {
        final song = MediaItemBuilder.fromJson(songData);
        return MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          artUri: song.artUri,
          extras: {"libraryId": _songsDownloadsBox},
          playable: true,
        );
      }).toList();
      
      // Note: Don't close this box as it's used by downloader
      return songs;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository._getDownloadedSongs error: $error');
      return [];
    }
  }

  /// Helper method to get cached songs
  Future<List<MediaItem>> _getCachedSongs() async {
    try {
      final box = await Hive.openBox(_songsCacheBox);
      final songs = box.values.map((songData) {
        final song = MediaItemBuilder.fromJson(songData);
        return MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          artUri: song.artUri,
          extras: {"libraryId": _songsCacheBox},
          playable: true,
        );
      }).toList();
      
      await box.close();
      return songs;
    } catch (error) {
      printERROR('❌ HiveLibraryRepository._getCachedSongs error: $error');
      return [];
    }
  }
}