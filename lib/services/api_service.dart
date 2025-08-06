import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../utils/error_handler.dart';
import 'network_service.dart';
import '/models/album.dart';
import 'cookie_service.dart';
import 'youtube_data_parser_service.dart';
import 'youtube_config_service.dart';
import 'constant.dart';
import 'nav_parser.dart';
import 'utils.dart';
import 'continuations.dart';

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

/// Concrete implementation của API Service
class APIService extends getx.GetxService implements IAPIService {
  static APIService? _instance;
  static APIService get instance => _instance ??= APIService._();

  APIService._();

  NetworkService? _networkService;
  CookieService? _cookieService;
  YouTubeDataParserService? _parserService;

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
    super.onInit();
    _initializeServices();
    _setupContext();
  }

  void _initializeServices() {
    try {
      _networkService = NetworkService.instance;
      _cookieService = CookieService.instance;
      _parserService = YouTubeDataParserService.instance;
    } catch (e) {
      // Services will be initialized lazily if not available
      print('⚠️ Some services not yet initialized, will initialize lazily: $e');
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

  YouTubeDataParserService get parserService {
    _parserService ??= YouTubeDataParserService.instance;
    return _parserService!;
  }

  Future<void> _setupContext() async {
    final date = DateTime.now();
    _context['context']['client']['clientVersion'] =
        "1.${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.03.00";

    final signatureTimestamp = getDatestamp() - 1;
    _context['playbackContext'] = {
      'contentPlaybackContext': {'signatureTimestamp': signatureTimestamp},
    };
  }

  /// Send request với YouTube API endpoint
  Future<Response> _sendRequest(String action, Map<dynamic, dynamic> data,
      {String additionalParams = ""}) async {
    try {
      // Chuẩn bị headers
      final headers = <String, String>{};

      // Thêm cookies
      final cookieString = await cookieService.getCookieString();
      if (cookieString.isNotEmpty) {
        headers['cookie'] = cookieString;
      }

      // Thêm authorization headers nếu có
      final authHeaders = await cookieService.getAuthorizationHeaders();
      if (authHeaders != null) {
        headers.addAll(authHeaders);
      }

      // Thêm visitor ID
      final visitorData = await YouTubeConfigService.getVisitorData();
      if (visitorData != null) {
        headers['X-Goog-Visitor-Id'] = visitorData;
      }

      final response = await networkService.sendRequest(
        "$baseUrl$action$fixedParms$additionalParams",
        method: 'POST',
        headers: headers,
        data: data,
      );

      // Xử lý cookies từ response
      final responseCookies = response.headers.map['set-cookie'];
      if (responseCookies != null && responseCookies.isNotEmpty) {
        await cookieService.handleResponseCookies(responseCookies);
      }

      return response;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'API request - $action');
      rethrow;
    }
  }

  @override
  Future<dynamic> getHomeData({int limit = 4}) async {
    try {
      final data = Map.from(_context);
      data["browseId"] = "FEmusic_home";
      final response = await _sendRequest("browse", data);
      final results = nav(response.data, single_column_tab + section_list);
      final home = [...parserService.parseMixedContent(results)];

      final sectionList =
          nav(response.data, single_column_tab + ['sectionListRenderer']);

      if (sectionList.containsKey('continuations')) {
        requestFunc(additionalParams) async {
          return (await _sendRequest("browse", data,
                  additionalParams: additionalParams))
              .data;
        }

        parseFunc(contents) => parserService.parseMixedContent(contents);
        final x = (await getContinuations(
            sectionList,
            'sectionListContinuation',
            limit - home.length,
            requestFunc,
            parseFunc));
        home.addAll([...x]);
      }

      return home;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get home data');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCharts(
      {String? countryCode = "vi"}) async {
    try {
      final List<Map<String, dynamic>> charts = [];
      final data = Map.from(_context);

      data['browseId'] = 'FEmusic_charts';
      if (countryCode != null) {
        data['formData'] = {
          'selectedValues': [countryCode]
        };
      }
      final response = (await _sendRequest('browse', data)).data;
      final results = nav(response, single_column_tab + section_list);
      results.removeAt(0);
      for (dynamic result in results) {
        charts.add(parserService.parseChartsItem(result));
      }

      return charts;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get charts');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getWatchPlaylist(
      {String videoId = "",
      String? playlistId,
      int limit = 25,
      bool radio = false,
      bool shuffle = false,
      String? additionalParamsNext,
      bool onlyRelated = false}) async {
    try {
      if (videoId.isNotEmpty && videoId.substring(0, 4) == "MPED") {
        videoId = videoId.substring(4);
      }

      final data = Map.from(_context);
      data['enablePersistentPlaylistPanel'] = true;
      data['isAudioOnly'] = true;
      data['tunerSettingValue'] = 'AUTOMIX_SETTING_NORMAL';

      if (videoId == "" && playlistId == null) {
        throw Exception(
            "You must provide either a video id, a playlist id, or both");
      }

      if (videoId != "") {
        data['videoId'] = videoId;
        playlistId ??= "RDAMVM$videoId";

        if (!(radio || shuffle)) {
          data['watchEndpointMusicSupportedConfigs'] = {
            'watchEndpointMusicConfig': {
              'hasPersistentPlaylistPanel': true,
              'musicVideoType': "MUSIC_VIDEO_TYPE_ATV",
            }
          };
        }
      }

      playlistId = validatePlaylistId(playlistId!);
      data['playlistId'] = playlistId;

      final isPlaylist =
          playlistId.startsWith('PL') || playlistId.startsWith('OLA');
      if (shuffle) {
        data['params'] = "wAEB8gECKAE%3D";
      }
      if (radio) {
        data['params'] = "wAEB";
      }

      final List<dynamic> tracks = [];
      dynamic lyricsBrowseId, relatedBrowseId, playlist;
      final results = {};

      if (additionalParamsNext == null) {
        final response = (await _sendRequest("next", data)).data;
        final watchNextRenderer = nav(response, [
          'contents',
          'singleColumnMusicWatchNextResultsRenderer',
          'tabbedRenderer',
          'watchNextTabbedResultsRenderer'
        ]);

        lyricsBrowseId = getTabBrowseId(watchNextRenderer, 1);
        relatedBrowseId = getTabBrowseId(watchNextRenderer, 2);

        if (onlyRelated) {
          return {
            'lyrics': lyricsBrowseId,
            'related': relatedBrowseId,
          };
        }

        results.addAll(nav(watchNextRenderer, [
          ...tab_content,
          'musicQueueRenderer',
          'content',
          'playlistPanelRenderer'
        ]));

        playlist = results['contents']
            .map((content) => nav(content,
                ['playlistPanelVideoRenderer', ...navigation_playlist_id]))
            .where((e) => e != null)
            .toList()
            .first;
        tracks.addAll(parserService.parseWatchPlaylist(results['contents']));
      }

      dynamic additionalParamsForNext;
      if (results.containsKey('continuations') ||
          additionalParamsNext != null) {
        requestFunc(additionalParams) async => (await _sendRequest("next", data,
                additionalParams: additionalParams))
            .data;
        parseFunc(contents) => parserService.parseWatchPlaylist(contents);
        final x = await getContinuations(results, 'playlistPanelContinuation',
            limit - tracks.length, requestFunc, parseFunc,
            ctokenPath: isPlaylist ? '' : 'Radio',
            isAdditionparamReturnReq: true,
            additionalParams_: additionalParamsNext);
        additionalParamsForNext = x[1];
        tracks.addAll(List<dynamic>.from(x[0]));
      }

      return {
        'tracks': tracks,
        'playlistId': playlist,
        'lyrics': lyricsBrowseId,
        'related': relatedBrowseId,
        'additionalParamsForNext': additionalParamsForNext
      };
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get watch playlist');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs(
      {String? playlistId,
      String? albumId,
      int limit = 3000,
      bool related = false,
      int suggestionsLimit = 0}) async {
    try {
      String browseId = playlistId != null
          ? (playlistId.startsWith("VL") ? playlistId : "VL$playlistId")
          : albumId!;

      if (albumId != null && albumId.contains("OLAK5uy")) {
        browseId = await getAlbumBrowseId(browseId);
      }

      final data = Map.from(_context);
      data['browseId'] = browseId;
      final Map<String, dynamic> response =
          (await _sendRequest('browse', data)).data;

      if (playlistId != null) {
        // Handle playlist parsing
        final dynamic headerData =
            nav(response, ['header', "musicDetailHeaderRenderer"]) ??
                nav(response, [
                  'contents',
                  "twoColumnBrowseResultsRenderer",
                  'tabs',
                  0,
                  "tabRenderer",
                  "content",
                  "sectionListRenderer",
                  "contents",
                  0,
                  "musicResponsiveHeaderRenderer"
                ]);

        final dynamic resultsData = nav(response, musicPlaylistShelfRenderer) ??
            nav(response, [
              'contents',
              "singleColumnBrowseResultsRenderer",
              "tabs",
              0,
              "tabRenderer",
              "content",
              'sectionListRenderer',
              'contents',
              0,
              "musicPlaylistShelfRenderer"
            ]);

        // Return empty playlist if essential data is missing
        if (headerData == null || resultsData == null) {
          return {
            'id': playlistId,
            'title': 'Unknown Playlist',
            'tracks': <dynamic>[],
            'trackCount': 0,
            'duration_seconds': 0,
          };
        }

        final Map<String, dynamic> header = headerData as Map<String, dynamic>;
        final Map<String, dynamic> results =
            resultsData as Map<String, dynamic>;
        final Map<String, dynamic> playlist = {
          'id': results['playlistId'] ?? playlistId
        };

        playlist['title'] = nav(header, title_text) ?? 'Unknown Playlist';
        playlist['thumbnails'] = nav(header, thumnail_cropped) ??
            nav(header, [
              "thumbnail",
              "musicThumbnailRenderer",
              "thumbnail",
              "thumbnails"
            ]);
        playlist["description"] = nav(header, description);

        // Safely check subtitle data
        int runCount = 0;
        if (header['subtitle'] != null && header['subtitle']['runs'] != null) {
          runCount = header['subtitle']['runs'].length;
          if (runCount > 1) {
            playlist['author'] = {
              'name': nav(header, subtitle2),
              'id': nav(header, ['subtitle', 'runs', 2] + navigation_browse_id)
            };
            if (runCount == 5) {
              playlist['year'] = nav(header, subtitle3);
            }
          }
        }

        int songCount = 0;
        if (header['secondSubtitle'] != null &&
            header['secondSubtitle']['runs'] != null) {
          final int secondSubtitleRunCount =
              header['secondSubtitle']['runs'].length;
          final String count = (((header['secondSubtitle']['runs']
                          [secondSubtitleRunCount % 3]['text'])
                      .split(' ')[0])
                  .split(',') as List)
              .join();
          songCount = int.parse(count);
          if (header['secondSubtitle']['runs'].length > 1) {
            playlist['duration'] = header['secondSubtitle']['runs']
                [(secondSubtitleRunCount % 3) + 2]['text'];
          }
        }
        playlist['trackCount'] = songCount;

        requestFuncCountinuation(cont) async =>
            (await _sendRequest("browse", {...data, ...cont})).data;

        if (songCount > 0) {
          playlist['tracks'] =
              parserService.parsePlaylistItems(results['contents']);
          limit = songCount;

          List<dynamic> parseFunc(contents) =>
              parserService.parsePlaylistItems(contents);

          playlist['tracks'] = [
            ...(playlist['tracks']),
            ...(await getContinuationsPlaylist(
                results, limit, requestFuncCountinuation, parseFunc))
          ];
        } else {
          playlist['tracks'] = <dynamic>[];
        }
        playlist['duration_seconds'] = sumTotalDuration(playlist);
        return playlist;
      }

      // Album content
      final album = parserService.parseAlbumHeader(response);
      dynamic results = nav(response, [
            'contents',
            "twoColumnBrowseResultsRenderer",
            "secondaryContents",
            'sectionListRenderer',
            'contents',
            0,
            'musicShelfRenderer'
          ]) ??
          nav(response, [
            'contents',
            "singleColumnBrowseResultsRenderer",
            "tabs",
            0,
            "tabRenderer",
            "content",
            'sectionListRenderer',
            'contents',
            0,
            'musicShelfRenderer'
          ]);

      album['tracks'] = parserService.parsePlaylistItems(results['contents'],
          artistsM: album['artists'],
          thumbnailsM: album["thumbnails"],
          albumIdName: {"id": albumId, 'name': album['title']},
          albumYear: album['year'],
          isAlbum: true);

      results = nav(response, [
        ...single_column_tab,
        ...section_list,
        1,
        'musicCarouselShelfRenderer'
      ]);
      if (results != null) {
        List contents = [];
        if (results.runtimeType.toString().contains("Iterable") ||
            results.runtimeType.toString().contains("List")) {
          for (dynamic result in results) {
            contents.add(parseAlbum(result['musicTwoRowItemRenderer']));
          }
        } else {
          contents.add(
              parseAlbum(results['contents'][0]['musicTwoRowItemRenderer']));
        }
        album['other_versions'] = contents;
      }
      album['duration_seconds'] = sumTotalDuration(album);

      return album;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get playlist/album songs');
      return {};
    }
  }

  @override
  Future<List<String>> getSearchSuggestion(String queryStr) async {
    try {
      final data = Map.from(_context);
      data['input'] = queryStr;
      final res = nav(
              (await _sendRequest("music/get_search_suggestions", data)).data, [
            'contents',
            0,
            'searchSuggestionsSectionRenderer',
            'contents'
          ]) ??
          [];
      return res
          .map<String?>((item) {
            return (nav(item, [
              'searchSuggestionRenderer',
              'navigationEndpoint',
              'searchEndpoint',
              'query'
            ])).toString();
          })
          .whereType<String>()
          .toList();
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get search suggestions');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> search(String query,
      {String? filter,
      String? scope,
      int limit = 30,
      bool ignoreSpelling = false}) async {
    try {
      final data = Map.of(_context);
      data['context']['client']["hl"] = 'en';
      data['query'] = query;

      final Map<String, dynamic> searchResults = {};
      final filters = [
        'albums',
        'artists',
        'playlists',
        'community_playlists',
        'featured_playlists',
        'songs',
        'videos'
      ];

      if (filter != null && !filters.contains(filter)) {
        throw Exception(
            'Invalid filter provided. Please use one of the following filters or leave out the parameter: ${filters.join(', ')}');
      }

      final scopes = ['library', 'uploads'];

      if (scope != null && !scopes.contains(scope)) {
        throw Exception(
            'Invalid scope provided. Please use one of the following scopes or leave out the parameter: ${scopes.join(', ')}');
      }

      if (scope == scopes[1] && filter != null) {
        throw Exception(
            'No filter can be set when searching uploads. Please unset the filter parameter when scope is set to uploads.');
      }

      final params = getSearchParams(filter, scope, ignoreSpelling);

      if (params != null) {
        data['params'] = params;
      }

      final response = (await _sendRequest("search", data)).data;

      if (response['contents'] == null) {
        return searchResults;
      }

      dynamic results;

      if ((response['contents']).containsKey('tabbedSearchResultsRenderer')) {
        final tabIndex =
            scope == null || filter != null ? 0 : scopes.indexOf(scope) + 1;
        results = response['contents']['tabbedSearchResultsRenderer']['tabs']
            [tabIndex]['tabRenderer']['content'];
      } else {
        results = response['contents'];
      }

      results = nav(results, ['sectionListRenderer', 'contents']);

      if (results.length == 1 && results[0]['itemSectionRenderer'] != null) {
        return searchResults;
      }

      String? type;

      for (var res in results) {
        String category;
        if (res.containsKey('musicCardShelfRenderer')) {
          results = nav(res, ['musicCardShelfRenderer', 'contents']);
          if (results != null) {
            if ((results[0]).containsKey("messageRenderer")) {
              category = nav(results[0], ['messageRenderer', ...text_run_text]);
              results = results.sublist(1);
            }
          } else {
            continue;
          }
          continue;
        } else if (res['musicShelfRenderer'] != null) {
          results = res['musicShelfRenderer']['contents'];
          String? typeFilter = filter;

          category = nav(res, ['musicShelfRenderer', ...title_text]);

          if (typeFilter == null && scope == scopes[0]) {
            typeFilter = category;
          }

          type = typeFilter?.substring(0, typeFilter.length - 1).toLowerCase();
        } else {
          continue;
        }

        searchResults[category] = parserService.parseSearchResults(results,
            ['artist', 'playlist', 'song', 'video', 'station'], type, category);

        if (filter != null) {
          requestFunc(additionalParams) async =>
              (await _sendRequest("search", data,
                      additionalParams: additionalParams))
                  .data;
          parseFunc(contents) => parserService.parseSearchResults(
              contents,
              ['artist', 'playlist', 'song', 'video', 'station'],
              type,
              category);

          if (searchResults.containsKey(category)) {
            final x = await getContinuations(
                res['musicShelfRenderer'],
                'musicShelfContinuation',
                limit - ((searchResults[category] as List).length),
                requestFunc,
                parseFunc,
                isAdditionparamReturnReq: true);

            searchResults["params"] = {
              'data': data,
              "type": type,
              "category": category,
              'additionalParams': x[1],
            };

            searchResults[category] = [
              ...(searchResults[category] as List),
              ...(x[0])
            ];
          }
        }
      }

      return searchResults;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Search');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getSearchContinuation(Map additionalParamsNext,
      {int limit = 10}) async {
    try {
      final data = additionalParamsNext['data'];
      final type = additionalParamsNext['type'];
      final category = additionalParamsNext['category'];
      final Map<String, dynamic> searchResults = {};

      requestFunc(additionalParams) async => (await _sendRequest("search", data,
              additionalParams: additionalParams))
          .data;

      parseFunc(contents) => parserService.parseSearchResults(contents,
          ['artist', 'playlist', 'song', 'video', 'station'], type, category);

      final x = await getContinuations(
          {}, 'musicShelfContinuation', limit, requestFunc, parseFunc,
          isAdditionparamReturnReq: true,
          additionalParams_: additionalParamsNext['additionalParams']);

      searchResults["params"] = {
        "data": data,
        "type": type,
        "category": category,
        'additionalParams': x[1],
      };

      searchResults[category] = x[0];

      return searchResults;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Search continuation');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getArtist(String channelId) async {
    try {
      if (channelId.startsWith("MPLA")) {
        channelId = channelId.substring(4);
      }
      final data = Map.from(_context);
      data['context']['client']["hl"] = 'en';
      data['browseId'] = channelId;
      final response = (await _sendRequest("browse", data)).data;
      final results = nav(response, [...single_column_tab, ...section_list]);

      final Map<String, dynamic> artist = {'description': null, 'views': null};
      final Map<String, dynamic> header = (response['header']
              ['musicImmersiveHeaderRenderer']) ??
          response['header']['musicVisualHeaderRenderer'];
      artist['name'] = nav(header, title_text);
      final descriptionShelf =
          findObjectByKey(results, description_shelf[0], isKey: true);
      if (descriptionShelf != null) {
        artist['description'] = nav(descriptionShelf, description);
        artist['views'] = descriptionShelf['subheader'] == null
            ? null
            : descriptionShelf['subheader']['runs'][0]['text'];
      }
      final dynamic subscriptionButton = header['subscriptionButton'] != null
          ? header['subscriptionButton']['subscribeButtonRenderer']
          : null;
      artist['channelId'] = channelId;
      artist['shuffleId'] = nav(header,
          ['playButton', 'buttonRenderer', ...navigation_watch_playlist_id]);
      artist['radioId'] = nav(
        header,
        ['startRadioButton', 'buttonRenderer'] + navigation_playlist_id,
      );
      artist['subscribers'] = subscriptionButton != null
          ? nav(
              subscriptionButton,
              ['subscriberCountText', 'runs', 0, 'text'],
            )
          : null;

      artist['thumbnails'] = nav(header, thumbnails);

      artist.addAll(parserService.parseArtistContents(results));
      return artist;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get artist');
      return {};
    }
  }

  @override
  Future<String?> getSongYear(String songId) async {
    try {
      final data = Map.from(_context);
      data['browseId'] = "MPTC$songId";
      final response = (await _sendRequest('browse', data)).data;
      String? year = nav(response, [
        "onResponseReceivedActions",
        0,
        "openPopupAction",
        "popup",
        "dismissableDialogRenderer",
        "metadata",
        "musicMultiRowListItemRenderer",
        "secondTitle",
        "runs",
        2,
        "text"
      ]);
      return year;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get song year');
      return null;
    }
  }

  @override
  Future<List> getSongWithId(String songId) async {
    try {
      final data = Map.of(_context);
      data['videoId'] = songId;
      final response = (await _sendRequest("player", data)).data;
      final category =
          nav(response, ["microformat", "microformatDataRenderer", "category"]);
      if (category == "Music" ||
          (response["videoDetails"]).containsKey("musicVideoType")) {
        final list = await getWatchPlaylist(videoId: songId);
        return [true, list['tracks']];
      }
      return [false, null];
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get song with ID');
      return [false, null];
    }
  }

  @override
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode) async {
    try {
      final params =
          await getWatchPlaylist(videoId: videoId, onlyRelated: true);
      final data = Map.from(_context);
      data['browseId'] = params['related'];
      data['context']['client']['hl'] = hlCode;
      final response = (await _sendRequest('browse', data)).data;
      final sections = nav(response, ['contents'] + section_list);
      final x = parserService.parseMixedContent(sections);
      return x;
    } catch (e) {
      AppErrorHandler.handleError(e, null,
          context: 'Get content related to song');
      return null;
    }
  }

  @override
  Future<dynamic> getLyrics(String browseId) async {
    try {
      final data = Map.from(_context);
      data['browseId'] = browseId;
      final response = (await _sendRequest('browse', data)).data;
      return nav(
        response,
        [
          'contents',
          ...section_list_item,
          ...description_shelf,
          ...description
        ],
      );
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get lyrics');
      return null;
    }
  }

  @override
  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    try {
      final response = await networkService.sendRequest(
        "${domain}playlist",
        method: 'GET',
        queryParameters: {'list': audioPlaylistId},
      );
      final reg = RegExp(r'\"MPRE.+?\"');
      final matchs = reg.firstMatch(response.data.toString());
      if (matchs != null) {
        final x = (matchs[0])!;
        final res = (x.substring(1)).split("\\")[0];
        return res;
      }
      return audioPlaylistId;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get album browse ID');
      return audioPlaylistId;
    }
  }

  @override
  Future<Map<String, dynamic>> getArtistRealtedContent(
      Map<String, dynamic> browseEndpoint, String category,
      {String additionalParams = ""}) async {
    try {
      final Map<String, dynamic> result = {
        "results": [],
      };
      final data = Map.of(_context);
      browseEndpoint.remove("content");
      if (browseEndpoint.isEmpty) return result;
      data.addAll(browseEndpoint);
      final response = (await _sendRequest("browse", data,
              additionalParams: additionalParams))
          .data;
      final contents = nav(response, [
        'contents',
        'singleColumnBrowseResultsRenderer',
        'tabs',
        0,
        'tabRenderer',
        'content',
        'sectionListRenderer',
        'contents',
        0,
      ]);

      if (category == "Songs" || category == "Videos") {
        if (additionalParams != "") {
          final contentList = nav(response, [
            "onResponseReceivedActions",
            0,
            "appendContinuationItemsAction",
            "continuationItems"
          ]);
          final x = parserService.parsePlaylistItems(contentList);
          result['results'] = x;
          result['additionalParams'] = "&ctoken=${null}&continuation=${null}";
        } else if (contents.containsKey("gridRenderer")) {
          result['results'] = (contents['gridRenderer']['items'])
              .map((video) => parseVideo(video['musicTwoRowItemRenderer']))
              .toList();
          result['additionalParams'] = "&ctoken=${null}&continuation=${null}";
        } else {
          final collapseContent = nav(
              contents, ['musicPlaylistShelfRenderer', "collapsedItemCount"]);
          if (collapseContent != null) {
            final contentlist =
                contents['musicPlaylistShelfRenderer']['contents'];
            if (contentlist.length.toString() != collapseContent.toString()) {
              final continuationItem = contentlist.removeAt(100);
              result['results'] = parserService.parsePlaylistItems(contentlist);
              final continuationKey = nav(continuationItem, [
                "continuationItemRenderer",
                "continuationEndpoint",
                "continuationCommand",
                "token"
              ]);
              result['additionalParams'] =
                  "&ctoken=$continuationKey&continuation=$continuationKey";
            } else {
              result['results'] = parserService.parsePlaylistItems(contentlist);
              result['additionalParams'] = "&ctoken=null&continuation=null";
            }
          }
          return result;
        }
      } else if (category == 'Albums' || category == 'Singles') {
        List contentlist;

        /// in continuation
        if (additionalParams != "") {
          contentlist =
              response['continuationContents']['gridContinuation']['items'];
          final continuationKey = nav(response, [
            'continuationContents',
            'gridContinuation',
            'continuations',
            0,
            'nextContinuationData',
            'continuation'
          ]);
          result['additionalParams'] =
              "&ctoken=$continuationKey&continuation=$continuationKey";
        } else {
          /// in first request
          contentlist = contents['gridRenderer']['items'];

          final continuationKey = nav(contents, [
            'gridRenderer',
            'continuations',
            0,
            'nextContinuationData',
            'continuation'
          ]);
          result['additionalParams'] =
              "&ctoken=$continuationKey&continuation=$continuationKey";
        }

        result['results'] = category == 'Albums'
            ? contentlist
                .map((item) => parseAlbum(item['musicTwoRowItemRenderer']))
                .whereType<Album>()
                .toList()
            : contentlist
                .map((item) => parseSingle(item['musicTwoRowItemRenderer']))
                .whereType<Album>()
                .toList();
      }
      return result;
    } catch (e) {
      AppErrorHandler.handleError(e, null,
          context: 'Get artist related content');
      return {"results": []};
    }
  }

  /// Update language code trong context
  set hlCode(String code) {
    _context['context']['client']['hl'] = code;
  }
}
