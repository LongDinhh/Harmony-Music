// ignore_for_file: constant_identifier_names

import 'package:get/get.dart' as getx;

import '../utils/helper.dart';
import 'api_service.dart';

// Import các service mới
enum AudioQuality {
  Low,
  High,
}

class MusicServices extends getx.GetxService {
  APIService? _apiService;

  @override
  void onInit() {
    _initializeServices();
    super.onInit();
  }

  void _initializeServices() {
    try {
      _apiService = APIService.instance;
    } catch (e) {
      printINFO(
          '⚠️ Some services not yet initialized, will initialize lazily: $e');
    }
  }

  APIService get apiService {
    _apiService ??= APIService.instance;
    return _apiService!;
  }

  Future<dynamic> getHome({int limit = 4}) async {
    final response = await apiService.getHomeData(limit: limit);
    printINFO("BOLI - getHome response: $response");
    return response;
  }

  Future<List<Map<String, dynamic>>> getCharts(
      {String? countryCode = "vi"}) async {
    return await apiService.getCharts(countryCode: countryCode);
  }

  Future<Map<String, dynamic>> getWatchPlaylist(
      {String videoId = "",
      String? playlistId,
      int limit = 25,
      bool radio = false,
      bool shuffle = false,
      String? additionalParamsNext,
      bool onlyRelated = false}) async {
    return await apiService.getWatchPlaylist(
      videoId: videoId,
      playlistId: playlistId,
      limit: limit,
      radio: radio,
      shuffle: shuffle,
      additionalParamsNext: additionalParamsNext,
      onlyRelated: onlyRelated,
    );
  }

  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    return await apiService.getAlbumBrowseId(audioPlaylistId);
  }

  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode) async {
    return await apiService.getContentRelatedToSong(videoId, hlCode);
  }

  Future<dynamic> getLyrics(String browseId) async {
    return await apiService.getLyrics(browseId);
  }

  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs(
      {String? playlistId,
      String? albumId,
      int limit = 3000,
      bool related = false,
      int suggestionsLimit = 0}) async {
    return await apiService.getPlaylistOrAlbumSongs(
      playlistId: playlistId,
      albumId: albumId,
      limit: limit,
      related: related,
      suggestionsLimit: suggestionsLimit,
    );
  }

  Future<List<String>> getSearchSuggestion(String queryStr) async {
    return await apiService.getSearchSuggestion(queryStr);
  }

  Future<List> getSongWithId(String songId) async {
    return await apiService.getSongWithId(songId);
  }

  Future<Map<String, dynamic>> search(String query,
      {String? filter,
      String? scope,
      int limit = 30,
      bool ignoreSpelling = false}) async {
    return await apiService.search(
      query,
      filter: filter,
      scope: scope,
      limit: limit,
      ignoreSpelling: ignoreSpelling,
    );
  }

  Future<Map<String, dynamic>> getSearchContinuation(Map additionalParamsNext,
      {int limit = 10}) async {
    return await apiService.getSearchContinuation(additionalParamsNext,
        limit: limit);
  }

  Future<Map<String, dynamic>> getArtist(String channelId) async {
    return await apiService.getArtist(channelId);
  }

  Future<Map<String, dynamic>> getArtistRealtedContent(
      Map<String, dynamic> browseEndpoint, String category,
      {String additionalParams = ""}) async {
    return await apiService.getArtistRealtedContent(browseEndpoint, category,
        additionalParams: additionalParams);
  }

  Future<String?> getSongYear(String songId) async {
    return await apiService.getSongYear(songId);
  }
}

