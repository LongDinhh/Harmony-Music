import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../utils/error_handler.dart';

/// Service wrapper for dart_ytmusic_api package
class YTMusicAPIService {
  late final YTMusic _ytMusic;
  bool _isInitialized = false;

  /// Initialize the YTMusic API
  Future<void> initialize({
    String? cookies,
    String gl = 'VN', // Vietnam
    String hl = 'vi', // Vietnamese
  }) async {
    try {
      _ytMusic = YTMusic();
      await _ytMusic.initialize(
        cookies: cookies,
        gl: gl,
        hl: hl,
      );
      _isInitialized = true;
    } catch (error) {
      throw Exception('Failed to initialize YTMusic API: $error');
    }
  }

  /// Ensure the service is initialized before use
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('YTMusicAPIService not initialized. Call initialize() first.');
    }
  }

  /// Get home data/sections
  Future<dynamic> getHomeData({int limit = 4}) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getHomeSections();
    } catch (error) {
      ErrorHandler.handleError('Failed to get home data', error);
      rethrow;
    }
  }

  /// Search for music content
  Future<Map<String, dynamic>> search(
    String query, {
    String? type, // 'songs', 'videos', 'artists', 'albums', 'playlists'
    int limit = 20,
  }) async {
    _ensureInitialized();
    try {
      dynamic result;
      
      switch (type?.toLowerCase()) {
        case 'songs':
          result = await _ytMusic.searchSongs(query);
          break;
        case 'videos':
          result = await _ytMusic.searchVideos(query);
          break;
        case 'artists':
          result = await _ytMusic.searchArtists(query);
          break;
        case 'albums':
          result = await _ytMusic.searchAlbums(query);
          break;
        case 'playlists':
          result = await _ytMusic.searchPlaylists(query);
          break;
        default:
          result = await _ytMusic.search(query);
      }
      
      return {'results': result, 'query': query, 'type': type};
    } catch (error) {
      ErrorHandler.handleError('Failed to search', error);
      rethrow;
    }
  }

  /// Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    _ensureInitialized();
    try {
      final suggestions = await _ytMusic.getSearchSuggestions(query);
      if (suggestions is List) {
        return suggestions.cast<String>();
      }
      return [];
    } catch (error) {
      ErrorHandler.handleError('Failed to get search suggestions', error);
      return [];
    }
  }

  /// Get album details
  Future<dynamic> getAlbum(String albumId) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getAlbum(albumId);
    } catch (error) {
      ErrorHandler.handleError('Failed to get album', error);
      rethrow;
    }
  }

  /// Get artist details
  Future<dynamic> getArtist(String artistId) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getArtist(artistId);
    } catch (error) {
      ErrorHandler.handleError('Failed to get artist', error);
      rethrow;
    }
  }

  /// Get playlist details and songs
  Future<dynamic> getPlaylistOrAlbumSongs(String playlistId) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getPlaylist(playlistId);
    } catch (error) {
      ErrorHandler.handleError('Failed to get playlist', error);
      rethrow;
    }
  }

  /// Get watch playlist (radio/mix)
  Future<dynamic> getWatchPlaylist(String videoId, String? playlistId) async {
    _ensureInitialized();
    try {
      // Note: dart_ytmusic_api might not have direct watch playlist support
      // For now, we'll return related content or similar functionality
      return await _ytMusic.getSong(videoId);
    } catch (error) {
      ErrorHandler.handleError('Failed to get watch playlist', error);
      rethrow;
    }
  }

  /// Get song details
  Future<dynamic> getSongWithId(String videoId) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getSong(videoId);
    } catch (error) {
      ErrorHandler.handleError('Failed to get song', error);
      rethrow;
    }
  }

  /// Get content related to a song
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode) async {
    _ensureInitialized();
    try {
      // Since dart_ytmusic_api might not have direct "related content" method,
      // we'll use artist information or similar songs approach
      final song = await _ytMusic.getSong(videoId);
      
      // If song has artist info, get artist's songs
      if (song != null && song['artists'] != null && (song['artists'] as List).isNotEmpty) {
        final artistId = song['artists'][0]['id'];
        if (artistId != null) {
          return await _ytMusic.getArtistSongs(artistId);
        }
      }
      
      return [];
    } catch (error) {
      ErrorHandler.handleError('Failed to get related content', error);
      rethrow;
    }
  }

  /// Get song lyrics
  Future<dynamic> getLyrics(String videoId) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getLyrics(videoId);
    } catch (error) {
      ErrorHandler.handleError('Failed to get lyrics', error);
      rethrow;
    }
  }

  /// Get charts data
  Future<dynamic> getCharts(String country) async {
    _ensureInitialized();
    try {
      // dart_ytmusic_api might not have charts method
      // For now, we'll return empty or use home sections as fallback
      return await getHomeData();
    } catch (error) {
      ErrorHandler.handleError('Failed to get charts', error);
      rethrow;
    }
  }

  /// Get song year (metadata)
  Future<dynamic> getSongYear(String videoId) async {
    _ensureInitialized();
    try {
      final song = await _ytMusic.getSong(videoId);
      return song?['year'] ?? song?['release_date'];
    } catch (error) {
      ErrorHandler.handleError('Failed to get song year', error);
      rethrow;
    }
  }

  /// Get album browse ID
  Future<String?> getAlbumBrowseId(String albumName) async {
    _ensureInitialized();
    try {
      final searchResults = await _ytMusic.searchAlbums(albumName);
      if (searchResults is List && searchResults.isNotEmpty) {
        return searchResults.first['id'] ?? searchResults.first['browseId'];
      }
      return null;
    } catch (error) {
      ErrorHandler.handleError('Failed to get album browse ID', error);
      return null;
    }
  }

  /// Get artist related content
  Future<dynamic> getArtistRelatedContent(String artistId) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getArtistSongs(artistId);
    } catch (error) {
      ErrorHandler.handleError('Failed to get artist related content', error);
      rethrow;
    }
  }

  /// Get search continuation (pagination)
  Future<dynamic> getSearchContinuation(String continuationToken) async {
    _ensureInitialized();
    try {
      // dart_ytmusic_api might not support continuation tokens
      // Return empty for now
      return [];
    } catch (error) {
      ErrorHandler.handleError('Failed to get search continuation', error);
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
    // No specific disposal needed for dart_ytmusic_api
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}