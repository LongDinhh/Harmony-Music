// ignore_for_file: constant_identifier_names

import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:hive/hive.dart';

import '../utils/helper.dart';
import '../utils/error_handler.dart';
import 'constant.dart';
import 'youtube_config_service.dart';

// Import các service mới
import 'network_service.dart';
import 'cookie_service.dart';
import 'api_service.dart';
import 'youtube_data_parser_service.dart';

enum AudioQuality {
  Low,
  High,
}

/// Refactored MusicServices - now delegates to specialized services
class MusicServices extends getx.GetxService {
  // Service dependencies - lazy initialization
  NetworkService? _networkService;
  CookieService? _cookieService;
  APIService? _apiService;
  YouTubeDataParserService? _parserService;

  // Legacy headers for backward compatibility
  final Map<String, String> _headers = {
    'user-agent': userAgent,
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    'origin': domain,
    'X-Goog-AuthUser': '0',
  };

  // Legacy context for backward compatibility
  final Map<String, dynamic> _context = {
    'context': {
      'client': {
        "acceptHeader":
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "browserName": "Chrome",
        "browserVersion": "140.0.0.0",
        "clientFormFactor": "UNKNOWN_FORM_FACTOR",
        "clientName": "WEB_REMIX",
        "clientVersion": "1.20250707.03.00",
        "deviceMake": "Apple",
        "userAgent":
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36,gzip(gfe)",
        "userInterfaceTheme": "USER_INTERFACE_THEME_DARK",
        "hl": "vi",
        "gl": "VN",
        "originalUrl": "https://music.youtube.com/",
      },
      'user': {}
    }
  };

  @override
  void onInit() {
    _initializeServices();
    init();
    super.onInit();
  }

  /// Initialize all service dependencies
  void _initializeServices() {
    try {
      _networkService = NetworkService.instance;
      _cookieService = CookieService.instance;
      _apiService = APIService.instance;
      _parserService = YouTubeDataParserService.instance;
    } catch (e) {
      // Services will be initialized lazily if not available
      printINFO(
          '⚠️ Some services not yet initialized, will initialize lazily: $e');
    }
  }

  // Lazy getters for services
  NetworkService get networkService {
    _networkService ??= NetworkService.instance;
    return _networkService!;
  }

  CookieService get cookieService {
    _cookieService ??= CookieService.instance;
    return _cookieService!;
  }

  APIService get apiService {
    _apiService ??= APIService.instance;
    return _apiService!;
  }

  YouTubeDataParserService get parserService {
    _parserService ??= YouTubeDataParserService.instance;
    return _parserService!;
  }

  // Legacy dio instance for backward compatibility
  final dio = Dio();

  /// Main initialization method - now delegates to services
  Future<void> init() async {
    try {
      printINFO('Initializing MusicServices with new architecture...');

      // Initialize services in order
      await cookieService.initializeCookies();
      networkService.configureSecurity();
      await _initializeAppData();
      await _setupVisitorId();

      printINFO('MusicServices initialization completed successfully');
    } catch (e) {
      AppErrorHandler.handleError(e, null,
          context: 'MusicServices initialization');
      rethrow;
    }
  }

  /// Sets up visitor ID from storage or uses fallback
  Future<void> _setupVisitorId() async {
    final appPrefsBox = Hive.box('AppPrefs');
    hlCode = appPrefsBox.get('contentLanguage') ?? "vi";

    final visitorData = await YouTubeConfigService.getVisitorData();
    if (visitorData != null) {
      _headers['X-Goog-Visitor-Id'] = visitorData;
      printINFO("Got Visitor id ($visitorData) from storage");
      return;
    }

    // Fallback visitor ID
    _headers['X-Goog-Visitor-Id'] =
        "CgttN24wcmd5UzNSWSi2lvq2BjIKCgJKUBIEGgAgYQ%3D%3D";
  }

  /// Flow khởi tạo app: call API domain, cập nhật cookie, lưu visitorId và datasyncId
  Future<void> _initializeAppData() async {
    try {
      printINFO("Initializing app data...");
      final response = await networkService.get(domain);

      await _processResponseData(response);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'App data initialization');
      _headers['X-Goog-Visitor-Id'] =
          "CgttN24wcmd5UzNSWSi2lvq2BjIKCgJKUBIEGgAgYQ%3D%3D";
    }
  }

  Future<void> _processResponseData(Response response) async {
    final responseCookies = response.headers.map['set-cookie'];
    if (responseCookies != null && responseCookies.isNotEmpty) {
      await cookieService.handleResponseCookies(responseCookies);
    }

    final config = parserService.extractYtcfg(response.data.toString());
    if (config != null) {
      await _saveVisitorData(config);
    }
  }

  Future<void> _saveVisitorData(Map<String, dynamic> config) async {
    final visitorId = config['VISITOR_DATA']?.toString();
    final datasyncId = _extractDatasyncId(config);

    // Use YouTubeConfigService to save extracted config values
    if (visitorId != null || datasyncId != null) {
      try {
        // Initialize YouTubeConfigService
        await YouTubeConfigService.init();

        // Save values using the extractAndSaveConfig method by temporarily modifying the config
        // This is a bit of a workaround since we already extracted the values
        if (visitorId != null) {
          _headers['X-Goog-Visitor-Id'] = visitorId;
          // Create temp config for visitor data
          // final tempConfig = {'VISITOR_DATA': visitorId};
          await _saveConfigValueDirectly('VISITOR_DATA', visitorId);
          printINFO('Saved VISITOR_DATA to YTBPrefs box: $visitorId');
        }

        if (datasyncId != null) {
          await _saveConfigValueDirectly('DATASYNC_ID', datasyncId);
          printINFO('Saved DATASYNC_ID to YTBPrefs box: $datasyncId');
        }
      } catch (e) {
        AppErrorHandler.handleError(e, null, context: 'Visitor data save');
      }
    }
  }

  /// Helper method to save config values directly to YTBPrefs box
  Future<void> _saveConfigValueDirectly(String key, String value) async {
    try {
      final box = Hive.box('YTBPrefs');
      final now = DateTime.now().millisecondsSinceEpoch;
      final data = {
        'value': value,
        'extractedAt': now,
        'source': 'music_service_ytcfg',
      };
      await box.put(key, data);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'YTBPrefs save - $key');
    }
  }

  /// Delegate to parser service
  String? _extractDatasyncId(Map<String, dynamic> config) {
    return parserService.extractDatasyncId(config);
  }

  set hlCode(String code) {
    _context['context']['client']['hl'] = code;
    // Also update APIService
    apiService.hlCode = code;
  }

  /// Generate visitor ID using NetworkService
  Future<String?> genrateVisitorId() async {
    try {
      final response = await networkService.get(domain);
      await _processResponseData(response);

      final config = parserService.extractYtcfg(response.data.toString());
      if (config != null) {
        await _saveVisitorData(config);
        return config['VISITOR_DATA']?.toString();
      }
      return null;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Visitor ID generation');
      return null;
    }
  }

  /// Delegate to APIService - backward compatible
  Future<dynamic> getHome({int limit = 4}) async {
    return await apiService.getHomeData(limit: limit);
  }

  /// Delegate to APIService - backward compatible
  Future<List<Map<String, dynamic>>> getCharts(
      {String? countryCode = "vi"}) async {
    return await apiService.getCharts(countryCode: countryCode);
  }

  /// Delegate to APIService - backward compatible
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

  /// Delegate to APIService - backward compatible
  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    return await apiService.getAlbumBrowseId(audioPlaylistId);
  }

  /// Delegate to APIService - backward compatible
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode) async {
    return await apiService.getContentRelatedToSong(videoId, hlCode);
  }

  /// Delegate to APIService - backward compatible
  Future<dynamic> getLyrics(String browseId) async {
    return await apiService.getLyrics(browseId);
  }

  /// Delegate to APIService - backward compatible
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

  /// Delegate to APIService - backward compatible
  Future<List<String>> getSearchSuggestion(String queryStr) async {
    return await apiService.getSearchSuggestion(queryStr);
  }

  /// Delegate to APIService - backward compatible
  Future<List> getSongWithId(String songId) async {
    return await apiService.getSongWithId(songId);
  }

  /// Delegate to APIService - backward compatible
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

  /// Delegate to APIService - backward compatible
  Future<Map<String, dynamic>> getSearchContinuation(Map additionalParamsNext,
      {int limit = 10}) async {
    return await apiService.getSearchContinuation(additionalParamsNext,
        limit: limit);
  }

  /// Delegate to APIService - backward compatible
  Future<Map<String, dynamic>> getArtist(String channelId) async {
    return await apiService.getArtist(channelId);
  }

  /// Delegate to APIService - backward compatible
  Future<Map<String, dynamic>> getArtistRealtedContent(
      Map<String, dynamic> browseEndpoint, String category,
      {String additionalParams = ""}) async {
    return await apiService.getArtistRealtedContent(browseEndpoint, category,
        additionalParams: additionalParams);
  }

  /// Delegate to APIService - backward compatible
  Future<String?> getSongYear(String songId) async {
    return await apiService.getSongYear(songId);
  }

  @override
  void onClose() {
    // Clean up legacy dio instance
    dio.close();

    // Services will clean up themselves through their own onClose methods
    super.onClose();
  }

  /// Delegate to CookieService - backward compatible
  Future<void> refreshYouTubeCookies() async {
    await cookieService.refreshCookies();
  }

  /// Delegate to CookieService - backward compatible
  Future<String?> getSApiSidHash(String? datasyncId, String sapisid,
      {String origin = "https://music.youtube.com"}) async {
    return await cookieService.generateSAPISIDHASH(
      datasyncId: datasyncId,
      origin: origin,
    );
  }
}

class NetworkError extends Error {
  final message = "Network Error !";
}
