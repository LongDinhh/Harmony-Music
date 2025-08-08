import 'package:get/get.dart' as getx;
import '../utils/error_handler.dart';
import 'dart_ytmusic_adapter_service.dart';

/// Abstract interface cho API Service
abstract class IAPIService {
  Future<dynamic> getHomeData({int limit = 4});
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"});
  Future<Map<String, dynamic>> getWatchPlaylist(
      {String videoId = "",
      String? playlistId,
      int limit = 25,
      bool radio = false,
      bool shuffle = false,
      String? additionalParamsNext,
      bool onlyRelated = false});
  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs(
      {String? playlistId,
      String? albumId,
      int limit = 3000,
      bool related = false,
      int suggestionsLimit = 0});
  Future<List<String>> getSearchSuggestion(String queryStr);
  Future<Map<String, dynamic>> search(String query,
      {String? filter,
      String? scope,
      int limit = 30,
      bool ignoreSpelling = false});
  Future<Map<String, dynamic>> getArtist(String channelId);
  Future<String?> getSongYear(String songId);
  Future<List> getSongWithId(String songId);
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode);
  Future<dynamic> getLyrics(String browseId);
  Future<String> getAlbumBrowseId(String audioPlaylistId);
  Future<Map<String, dynamic>> getArtistRealtedContent(
      Map<String, dynamic> browseEndpoint, String category,
      {String additionalParams = ""});
  Future<Map<String, dynamic>> getSearchContinuation(Map additionalParamsNext,
      {int limit = 10});
}

/// Concrete implementation của API Service - now uses DartYTMusicAdapterService
class APIService extends getx.GetxService implements IAPIService {
  static APIService? _instance;
  static APIService get instance => _instance ??= APIService._();

  APIService._();

  late DartYTMusicAdapterService _adapterService;

  @override
  void onInit() {
    super.onInit();
    _adapterService = DartYTMusicAdapterService.instance;
  }

  @override
  Future<dynamic> getHomeData({int limit = 4}) async {
    try {
      return await _adapterService.getHomeData(limit: limit);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getHomeData');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"}) async {
    try {
      return await _adapterService.getCharts(countryCode: countryCode);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getCharts');
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
      return await _adapterService.getWatchPlaylist(
        videoId: videoId,
        playlistId: playlistId,
        limit: limit,
        radio: radio,
        shuffle: shuffle,
        additionalParamsNext: additionalParamsNext,
        onlyRelated: onlyRelated,
      );
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getWatchPlaylist');
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
      return await _adapterService.getPlaylistOrAlbumSongs(
        playlistId: playlistId,
        albumId: albumId,
        limit: limit,
        related: related,
        suggestionsLimit: suggestionsLimit,
      );
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getPlaylistOrAlbumSongs');
      return {};
    }
  }

  @override
  Future<List<String>> getSearchSuggestion(String queryStr) async {
    try {
      return await _adapterService.getSearchSuggestion(queryStr);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getSearchSuggestion');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> search(
    String query, {
    String? filter,
    String? scope,
    int limit = 30,
    bool ignoreSpelling = false
  }) async {
    try {
      return await _adapterService.search(
        query,
        filter: filter,
        scope: scope,
        limit: limit,
        ignoreSpelling: ignoreSpelling,
      );
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.search');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getArtist(String channelId) async {
    try {
      return await _adapterService.getArtist(channelId);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getArtist');
      return {};
    }
  }

  @override
  Future<String?> getSongYear(String songId) async {
    try {
      return await _adapterService.getSongYear(songId);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getSongYear');
      return null;
    }
  }

  @override
  Future<List> getSongWithId(String songId) async {
    try {
      return await _adapterService.getSongWithId(songId);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getSongWithId');
      return [false, null];
    }
  }

  @override
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode) async {
    try {
      return await _adapterService.getContentRelatedToSong(videoId, hlCode);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getContentRelatedToSong');
      return null;
    }
  }

  @override
  Future<dynamic> getLyrics(String browseId) async {
    try {
      return await _adapterService.getLyrics(browseId);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getLyrics');
      return null;
    }
  }

  @override
  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    try {
      return await _adapterService.getAlbumBrowseId(audioPlaylistId);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getAlbumBrowseId');
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
      return await _adapterService.getArtistRealtedContent(
        browseEndpoint,
        category,
        additionalParams: additionalParams,
      );
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getArtistRealtedContent');
      return {"results": []};
    }
  }

  @override
  Future<Map<String, dynamic>> getSearchContinuation(
    Map additionalParamsNext, {
    int limit = 10
  }) async {
    try {
      return await _adapterService.getSearchContinuation(
        additionalParamsNext,
        limit: limit,
      );
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'APIService.getSearchContinuation');
      return {};
    }
  }

  /// Update language code
  set hlCode(String code) {
    _adapterService.hlCode = code;
  }
}
