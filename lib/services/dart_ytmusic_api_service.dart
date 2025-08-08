import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:get/get.dart' as getx;
import '../utils/error_handler.dart';
import 'api_service.dart'; // Import interface IAPIService

/// Service wrapper sử dụng dart_ytmusic_api package
class DartYTMusicAPIService extends getx.GetxService implements IAPIService {
  static DartYTMusicAPIService? _instance;
  static DartYTMusicAPIService get instance => _instance ??= DartYTMusicAPIService._();

  DartYTMusicAPIService._();

  YTMusic? _ytMusic;

  @override
  void onInit() {
    super.onInit();
    _initializeYTMusic();
  }

  Future<void> _initializeYTMusic() async {
    try {
      // Initialize YTMusic instance - có thể cần config thêm
      _ytMusic = YTMusic();
      await _ytMusic!.initialize();
      print('✅ DartYTMusicAPIService initialized successfully');
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'YTMusic initialization');
      print('❌ Error initializing YTMusic: $e');
    }
  }

  YTMusic get ytMusic {
    if (_ytMusic == null) {
      throw Exception('YTMusic not initialized yet');
    }
    return _ytMusic!;
  }

  @override
  Future<dynamic> getHomeData({int limit = 4}) async {
    try {
      final result = await ytMusic.getHome();
      // Transform result to match expected format
      return _transformHomeData(result, limit);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get home data');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"}) async {
    try {
      final result = await ytMusic.getCharts(country: countryCode ?? "vi");
      return _transformChartsData(result);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get charts');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getWatchPlaylist({
    String videoId = "",
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
    String? additionalParamsNext,
    bool onlyRelated = false
  }) async {
    try {
      final result = await ytMusic.getWatchPlaylist(
        videoId: videoId.isNotEmpty ? videoId : null,
        playlistId: playlistId,
        limit: limit,
        radio: radio,
        shuffle: shuffle,
      );
      return _transformWatchPlaylistData(result);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get watch playlist');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs({
    String? playlistId,
    String? albumId,
    int limit = 3000,
    bool related = false,
    int suggestionsLimit = 0
  }) async {
    try {
      if (playlistId != null) {
        final result = await ytMusic.getPlaylist(playlistId, limit: limit);
        return _transformPlaylistData(result);
      } else if (albumId != null) {
        final result = await ytMusic.getAlbum(albumId);
        return _transformAlbumData(result);
      }
      return {};
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get playlist/album songs');
      return {};
    }
  }

  @override
  Future<List<String>> getSearchSuggestion(String queryStr) async {
    try {
      final result = await ytMusic.getSearchSuggestions(queryStr);
      return result.map((suggestion) => suggestion.toString()).toList();
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get search suggestions');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> search(String query, {
    String? filter,
    String? scope,
    int limit = 30,
    bool ignoreSpelling = false
  }) async {
    try {
      final result = await ytMusic.search(
        query,
        filter: filter,
        limit: limit,
        ignoreSpelling: ignoreSpelling,
      );
      return _transformSearchData(result);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Search');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getArtist(String channelId) async {
    try {
      final result = await ytMusic.getArtist(channelId);
      return _transformArtistData(result);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get artist');
      return {};
    }
  }

  @override
  Future<String?> getSongYear(String songId) async {
    try {
      final result = await ytMusic.getSong(songId);
      // Extract year from song data
      return _extractYearFromSongData(result);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get song year');
      return null;
    }
  }

  @override
  Future<List> getSongWithId(String songId) async {
    try {
      final result = await ytMusic.getSong(songId);
      return [true, result];
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get song with ID');
      return [false, null];
    }
  }

  @override
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode) async {
    try {
      final result = await ytMusic.getSongRelated(videoId);
      return _transformRelatedContent(result);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get content related to song');
      return null;
    }
  }

  @override
  Future<dynamic> getLyrics(String browseId) async {
    try {
      final result = await ytMusic.getLyrics(browseId);
      return result;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get lyrics');
      return null;
    }
  }

  @override
  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    try {
      final result = await ytMusic.getAlbumBrowseId(audioPlaylistId);
      return result ?? audioPlaylistId;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get album browse ID');
      return audioPlaylistId;
    }
  }

  @override
  Future<Map<String, dynamic>> getArtistRealtedContent(
    Map<String, dynamic> browseEndpoint, 
    String category, {
    String additionalParams = ""
  }) async {
    try {
      // This might need to be implemented based on the specific API
      // For now, return empty result
      return {"results": []};
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get artist related content');
      return {"results": []};
    }
  }

  @override
  Future<Map<String, dynamic>> getSearchContinuation(
    Map additionalParamsNext, {
    int limit = 10
  }) async {
    try {
      // Implementation depends on how dart_ytmusic_api handles continuations
      return {};
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Search continuation');
      return {};
    }
  }

  // Helper methods để transform data format
  dynamic _transformHomeData(dynamic result, int limit) {
    // Transform the result to match the expected format
    // This will depend on the actual structure returned by dart_ytmusic_api
    return result;
  }

  List<Map<String, dynamic>> _transformChartsData(dynamic result) {
    // Transform charts data
    if (result is List) {
      return result.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Map<String, dynamic> _transformWatchPlaylistData(dynamic result) {
    // Transform watch playlist data
    if (result is Map<String, dynamic>) {
      return result;
    }
    return {};
  }

  Map<String, dynamic> _transformPlaylistData(dynamic result) {
    // Transform playlist data
    if (result is Map<String, dynamic>) {
      return result;
    }
    return {};
  }

  Map<String, dynamic> _transformAlbumData(dynamic result) {
    // Transform album data
    if (result is Map<String, dynamic>) {
      return result;
    }
    return {};
  }

  Map<String, dynamic> _transformSearchData(dynamic result) {
    // Transform search data
    if (result is Map<String, dynamic>) {
      return result;
    }
    return {};
  }

  Map<String, dynamic> _transformArtistData(dynamic result) {
    // Transform artist data
    if (result is Map<String, dynamic>) {
      return result;
    }
    return {};
  }

  dynamic _transformRelatedContent(dynamic result) {
    // Transform related content
    return result;
  }

  String? _extractYearFromSongData(dynamic songData) {
    // Extract year from song data
    // This depends on the structure of the song data
    if (songData is Map<String, dynamic>) {
      return songData['year']?.toString();
    }
    return null;
  }
}