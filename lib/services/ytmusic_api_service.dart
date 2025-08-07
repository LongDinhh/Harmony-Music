import 'dart:typed_data';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../utils/error_handler.dart';

/// Service wrapper cho dart_ytmusic_api package
class YTMusicAPIService {
  late final YTMusicAPI _ytMusic;
  bool _isInitialized = false;

  YTMusicAPIService();

  /// Initialize YT Music API
  Future<void> initialize() async {
    try {
      _ytMusic = YTMusicAPI();
      await _ytMusic.initialize();
      _isInitialized = true;
      AppErrorHandler.logInfo('YTMusicAPI initialized successfully', context: 'YTMusicAPIService');
    } catch (error) {
      AppErrorHandler.handleError(error, null, context: 'YTMusicAPI Init');
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('YTMusicAPI not initialized. Call initialize() first.');
    }
  }

  /// Get home screen data
  Future<dynamic> getHomeData({int limit = 4}) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getHome();
    } catch (error) {
      throw Exception('Failed to get home data: ${error.toString()}');
    }
  }

  /// Search for content
  Future<Map<String, dynamic>> search(String query, {
    String? filter,
    String? scope,
    int limit = 30,
    bool ignoreSpelling = false,
  }) async {
    _ensureInitialized();
    try {
      // dart_ytmusic_api search với filter options
      final results = await _ytMusic.search(
        query,
        filter: filter,
        limit: limit,
        ignoreSpelling: ignoreSpelling,
      );
      
      return {
        'contents': results,
        'query': query,
        'filter': filter,
      };
    } catch (error) {
      throw Exception('Failed to search: ${error.toString()}');
    }
  }

  /// Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    _ensureInitialized();
    try {
      final suggestions = await _ytMusic.getSearchSuggestions(query);
      return suggestions.cast<String>();
    } catch (error) {
      throw Exception('Failed to get search suggestions: ${error.toString()}');
    }
  }

  /// Get album information
  Future<Map<String, dynamic>> getAlbum(String browseId) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getAlbum(browseId);
    } catch (error) {
      throw Exception('Failed to get album: ${error.toString()}');
    }
  }

  /// Get artist information
  Future<Map<String, dynamic>> getArtist(String channelId) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getArtist(channelId);
    } catch (error) {
      throw Exception('Failed to get artist: ${error.toString()}');
    }
  }

  /// Get playlist or album songs
  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs({
    String? playlistId,
    String? albumId,
    int limit = 3000,
    bool related = false,
    int suggestionsLimit = 0,
  }) async {
    _ensureInitialized();
    try {
      if (playlistId != null) {
        return await _ytMusic.getPlaylist(playlistId, limit: limit);
      } else if (albumId != null) {
        return await _ytMusic.getAlbum(albumId);
      } else {
        throw Exception('Either playlistId or albumId must be provided');
      }
    } catch (error) {
      throw Exception('Failed to get playlist/album songs: ${error.toString()}');
    }
  }

  /// Get watch playlist
  Future<Map<String, dynamic>> getWatchPlaylist({
    String videoId = "",
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
    String? additionalParamsNext,
    bool onlyRelated = false,
  }) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getWatchPlaylist(
        videoId: videoId,
        playlistId: playlistId,
        limit: limit,
        radio: radio,
        shuffle: shuffle,
      );
    } catch (error) {
      throw Exception('Failed to get watch playlist: ${error.toString()}');
    }
  }

  /// Get song details
  Future<List> getSongWithId(String songId) async {
    _ensureInitialized();
    try {
      final song = await _ytMusic.getSong(songId);
      return [song];
    } catch (error) {
      throw Exception('Failed to get song details: ${error.toString()}');
    }
  }

  /// Get related content for a song
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode) async {
    _ensureInitialized();
    try {
      // YTMusic API có thể có method tương tự hoặc cần custom implementation
      final watchPlaylist = await _ytMusic.getWatchPlaylist(videoId: videoId, radio: true);
      return watchPlaylist['tracks'] ?? [];
    } catch (error) {
      throw Exception('Failed to get related content: ${error.toString()}');
    }
  }

  /// Get lyrics
  Future<dynamic> getLyrics(String browseId) async {
    _ensureInitialized();
    try {
      return await _ytMusic.getLyrics(browseId);
    } catch (error) {
      throw Exception('Failed to get lyrics: ${error.toString()}');
    }
  }

  /// Get charts
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"}) async {
    _ensureInitialized();
    try {
      final charts = await _ytMusic.getCharts(country: countryCode);
      return [charts];
    } catch (error) {
      throw Exception('Failed to get charts: ${error.toString()}');
    }
  }

  /// Get song year (may not be directly available in dart_ytmusic_api)
  Future<String?> getSongYear(String songId) async {
    _ensureInitialized();
    try {
      final song = await _ytMusic.getSong(songId);
      // Extract year from song data if available
      return song['year']?.toString();
    } catch (error) {
      return null; // Year not available
    }
  }

  /// Get album browse ID from audio playlist ID
  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    _ensureInitialized();
    try {
      // This might need custom implementation based on dart_ytmusic_api capabilities
      // For now, assume the audioPlaylistId is the browseId
      return audioPlaylistId;
    } catch (error) {
      throw Exception('Failed to get album browse ID: ${error.toString()}');
    }
  }

  /// Get artist related content
  Future<Map<String, dynamic>> getArtistRelatedContent(
    Map<String, dynamic> browseEndpoint,
    String category, {
    String additionalParams = "",
  }) async {
    _ensureInitialized();
    try {
      // This might need custom implementation
      final artistId = browseEndpoint['browseId'] as String?;
      if (artistId != null) {
        return await _ytMusic.getArtist(artistId);
      }
      throw Exception('Invalid browse endpoint');
    } catch (error) {
      throw Exception('Failed to get artist related content: ${error.toString()}');
    }
  }

  /// Get search continuation
  Future<Map<String, dynamic>> getSearchContinuation(
    Map additionalParamsNext, {
    int limit = 10,
  }) async {
    _ensureInitialized();
    try {
      // This might need custom implementation based on continuation tokens
      throw UnimplementedError('Search continuation not implemented yet');
    } catch (error) {
      throw Exception('Failed to get search continuation: ${error.toString()}');
    }
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}