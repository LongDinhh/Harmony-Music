// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:hive/hive.dart';

import '/models/album.dart';
import '/services/utils.dart';
import '../utils/helper.dart';
import 'constant.dart';
import 'continuations.dart';
import 'nav_parser.dart';
import 'package:crypto/crypto.dart';
import 'cookie_manager.dart';

enum AudioQuality {
  Low,
  High,
}

class MusicServices extends getx.GetxService {
  final Map<String, String> _headers = {
    'user-agent': userAgent,
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    'origin': domain,
    'X-Goog-AuthUser': '0',
  };

  final Map<String, dynamic> _context = {
    'context': {
      'client': {
        "clientName": "WEB_REMIX",
        "clientVersion": "1.20250707.03.00",
        "hl": "vi",
        "gl": "VN",
      },
      'user': {}
    }
  };

  @override
  void onInit() {
    init();
    super.onInit();
  }

  final dio = Dio();

  Future<void> init() async {
    //check visitor id in data base, if not generate one , set lang code
    final date = DateTime.now();
    _context['context']['client']['clientVersion'] =
        "1.${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.03.00";
    final signatureTimestamp = getDatestamp() - 1;
    _context['playbackContext'] = {
      'contentPlaybackContext': {'signatureTimestamp': signatureTimestamp},
    };

    // Khởi tạo cookie từ storage
    await _initializeCookies();

    // Thêm interceptor cho SAPISIDHASH
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Lấy tất cả cookie hợp lệ dưới dạng chuỗi
        final cookies = await CookieManager.getAllValidCookiesString();
        if (cookies.isNotEmpty) {
          options.headers['cookie'] = cookies;

          // Lấy SAPISID theo key
          final sapisid = await CookieManager.getCookieByKey('SAPISID');
          if (sapisid != null) {
            // Tạo SAPISIDHASH với datasyncId từ storage
            final sapisidHash =
                await getSApiSidHash(null, sapisid, origin: domain);
            if (sapisidHash != null) {
              options.headers['Authorization'] = 'SAPISIDHASH $sapisidHash';
            }
          }
        }

        handler.next(options);
      },
      onResponse: (response, handler) async {
        // Cập nhật cookie từ response headers nếu có
        final responseCookies = response.headers.map['set-cookie'];
        if (responseCookies != null && responseCookies.isNotEmpty) {
          await CookieManager.updateCookiesFromResponse(responseCookies);
        }
        handler.next(response);
      },
    ));

    // Flow khởi tạo app: call API domain, cập nhật cookie, lưu visitorId và datasyncId
    await _initializeAppData();

    final appPrefsBox = Hive.box('AppPrefs');
    hlCode = appPrefsBox.get('contentLanguage') ?? "vi";

    // Kiểm tra visitorId từ storage trước
    final storedIds = await CookieManager.getIds();
    if (storedIds['visitorId'] != null) {
      _headers['X-Goog-Visitor-Id'] = storedIds['visitorId']!;
      printINFO("Got Visitor id (${storedIds['visitorId']}) from storage");
      return;
    }

    // Fallback: sử dụng visitorId mặc định nếu không có trong storage
    _headers['X-Goog-Visitor-Id'] =
        "CgttN24wcmd5UzNSWSi2lvq2BjIKCgJKUBIEGgAgYQ%3D%3D";
  }

  /// Flow khởi tạo app: call API domain, cập nhật cookie, lưu visitorId và datasyncId
  Future<void> _initializeAppData() async {
    try {
      printINFO("Initializing app data...");

      // Call API domain để lấy cookie và visitor data
      final response =
          await dio.get(domain, options: Options(headers: _headers));

      // Cập nhật cookie từ response nếu có
      final responseCookies = response.headers.map['set-cookie'];
      if (responseCookies != null && responseCookies.isNotEmpty) {
        await CookieManager.updateCookiesFromResponse(responseCookies);
      }

      // Parse visitorId và datasyncId từ response
      final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
      final matches = reg.firstMatch(response.data.toString());

      if (matches != null) {
        final ytcfg = json.decode(matches.group(1).toString());
        final visitorId = ytcfg['VISITOR_DATA']?.toString();
        final datasyncId = ytcfg['USER_SESSION_ID']?.toString() ??
            ytcfg['datasyncId']?.toString().replaceAll('|', '') ??
            ytcfg['DATASYNC_ID']?.toString().replaceAll('|', '');

        // Lưu visitorId và datasyncId vào storage (vĩnh viễn)
        if (visitorId != null && datasyncId != null) {
          await CookieManager.saveIds(datasyncId, visitorId, expiresIn: null);

          // Cập nhật headers
          _headers['X-Goog-Visitor-Id'] = visitorId;
        } else if (visitorId != null) {
          await CookieManager.saveVisitorId(visitorId, expiresIn: null);
          _headers['X-Goog-Visitor-Id'] = visitorId;
        }
      }
    } catch (e) {
      printERROR("Error initializing app data: $e");
      // Fallback: sử dụng visitorId mặc định
      _headers['X-Goog-Visitor-Id'] =
          "CgttN24wcmd5UzNSWSi2lvq2BjIKCgJKUBIEGgAgYQ%3D%3D";
    }
  }

  set hlCode(String code) {
    _context['context']['client']['hl'] = code;
  }

  /// Khởi tạo cookie từ storage hoặc tạo mới
  Future<void> _initializeCookies() async {
    // Kiểm tra xem có cookie hợp lệ trong storage không
    final validCookies = await CookieManager.getAllValidCookiesString();
    if (validCookies.isNotEmpty) {
      _headers['cookie'] = validCookies;
      printINFO('Loaded cookies from storage');
      return;
    }

    // Nếu không có cookie hợp lệ, sử dụng cookie mặc định và lưu vào storage theo key
    await _initializeDefaultCookiesByKey();
    printINFO('Initialized with default cookies by key');
  }

  /// Khởi tạo cookie mặc định theo key
  Future<void> _initializeDefaultCookiesByKey() async {
    // Cookie mặc định được lưu theo key
    final defaultCookies = {
      'VISITOR_INFO1_LIVE': 'q-krUsDDf8U',
      'VISITOR_PRIVACY_METADATA': 'CgJWThIEGgAgFQ%3D%3D',
      '_gcl_au': '1.1.501670752.1749787964',
      'YSC': 'eusn3kpOLfs',
      '__Secure-ROLLOUT_TOKEN': 'CP_Pv52t5eyJaBD81La0zaaLAxioke269bGOAw%3D%3D',
      'HSID': 'A7pQpWgAW2F50KNH_',
      'SSID': 'AlIkzoKWvz032UgI-',
      'APISID': 'f4z2w7kNLEJ_dqSs/At57bYt0jIyRaqFM_',
      'SAPISID': '23BCIV3c09QiTMNc/Ay5Pl6vMnMoS8ccZB',
      '__Secure-1PAPISID': '23BCIV3c09QiTMNc/Ay5Pl6vMnMoS8ccZB',
      '__Secure-3PAPISID': '23BCIV3c09QiTMNc/Ay5Pl6vMnMoS8ccZB',
      'SID':
          'g.a000ywhZ840j5BNYqwIry9uq27YWivjaFcZVHAuMyiQhTFQkgIv6CugMmO8liIGkI-NsWg6C0wACgYKAaASARcSFQHGX2MiCdCkAawCZVJMiX3t5jmfPRoVAUF8yKprG9U94UR3koFOFiUfVi7G0076',
      '__Secure-1PSID':
          'g.a000ywhZ840j5BNYqwIry9uq27YWivjaFcZVHAuMyiQhTFQkgIv6c2-DIW1kOpYRMyXQl33IwgACgYKAZUSARcSFQHGX2MiQcM2U6p5qsAN4OMooFQFRRoVAUF8yKpdYrvYAqAEEGn4ry-cXLs00076',
      '__Secure-3PSID':
          'g.a000ywhZ840j5BNYqwIry9uq27YWivjaFcZVHAuMyiQhTFQkgIv678ydg2q4znw-PV2hmRGtYgACgYKAQ8SARcSFQHGX2MiWBqkTBpWZtSa8flyrhM8nRoVAUF8yKpDiGheBXXQz0c1fO-l8dFo0076',
      'LOGIN_INFO':
          'AFmmF2swRAIgTJKEUkwQxtdL_NstctthPi6sdsYegdOybb10zLFVrYYCIEn4zW1tmn3KujEdwq6boFuyxsb2k8ZkXW_rjD3D2q-d:QUQ3MjNmd255RTNRYW1VMW5hN2pFYmk5SHRBWHFnQ3o1TURjV3ZRNXhNbExIcTlXd0VHMkJJbjRweVlrdlV5QkpCLVlJcHg3WlFmZGl6Q28yMlZzUU9IZERQY0lDS2lnVUVKdkk3Ml9qNFRManVZelF1T0VvZ3c0NzNQOV91cHhyRnhqRmF1U3J2ZzMxTlI4Z0F1LWdEdENibUhoZ3BFM3Vn',
      'PREF': 'f6=40000080&f7=100&tz=Asia.Saigon&repeat=NONE&autoplay=true',
      '__Secure-1PSIDTS':
          'sidts-CjIB5H03Px4xGvNMZRBRF4gAGC3veODcLQrPo2rVeh_i5H94V5j7s8YWGG8ZScQ5bCJuBBAA',
      '__Secure-3PSIDTS':
          'sidts-CjIB5H03Px4xGvNMZRBRF4gAGC3veODcLQrPo2rVeh_i5H94V5j7s8YWGG8ZScQ5bCJuBBAA',
      'SIDCC':
          'AKEyXzWZuTBr_7tD7OzJpnu8RON5ZJJExChV75Lmw4Pm1YDq2czXJfaL3URhLsGzGBrqmTuyLQ',
      '__Secure-1PSIDCC':
          'AKEyXzVlFUN2gDeeSrM3FY4anqqsmu65BoOyyV2hgbCCgqGD-LIZN7iKgQ37mP0gdsGJCMcn-g',
      '__Secure-3PSIDCC':
          'AKEyXzVQGpE_QHnc72Js9lhxjzvdN5_6Nh153sajAs_CTgkxYpKslfEh19cvQl7029Js5rq6hds',
    };

    // Lưu từng cookie theo key (vĩnh viễn)
    for (final entry in defaultCookies.entries) {
      await CookieManager.saveCookieByKey(entry.key, entry.value,
          expiresIn: null);
    }

    // Cập nhật headers với cookie string
    _headers['cookie'] = await CookieManager.getAllValidCookiesString();
  }

  Future<String?> genrateVisitorId() async {
    try {
      final response =
          await dio.get(domain, options: Options(headers: _headers));

      // Lưu cookie mới từ response nếu có
      final responseCookies = response.headers.map['set-cookie'];
      if (responseCookies != null && responseCookies.isNotEmpty) {
        await CookieManager.updateCookiesFromResponse(responseCookies);
      }

      final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
      final matches = reg.firstMatch(response.data.toString());
      String? visitorId;
      if (matches != null) {
        final ytcfg = json.decode(matches.group(1).toString());
        visitorId = ytcfg['VISITOR_DATA']?.toString();
        final datasyncId = ytcfg['USER_SESSION_ID']?.toString() ??
            ytcfg['datasyncId']?.toString().replaceAll('|', '') ??
            ytcfg['DATASYNC_ID']?.toString().replaceAll('|', '');

        printINFO("=====datasyncId id: $datasyncId");

        // Lưu datasyncId và visitorId vào storage nếu có
        if (datasyncId != null && visitorId != null) {
          await CookieManager.saveIds(datasyncId, visitorId, expiresIn: null);
          printINFO("Saved datasyncId and visitorId from generateVisitorId");
        } else if (datasyncId != null) {
          await CookieManager.saveDatasyncId(datasyncId, expiresIn: null);
          printINFO("Saved datasyncId from generateVisitorId");
        } else if (visitorId != null) {
          await CookieManager.saveVisitorId(visitorId, expiresIn: null);
          printINFO("Saved visitorId from generateVisitorId");
        }
      }
      return visitorId;
    } catch (e) {
      printERROR("Error generating visitor ID: $e");
      return null;
    }
  }

  Future<Response> _sendRequest(String action, Map<dynamic, dynamic> data,
      {additionalParams = ""}) async {
    try {
      final response =
          await dio.post("$baseUrl$action$fixedParms$additionalParams",
              options: Options(
                headers: _headers,
              ),
              data: data);

      if (response.statusCode == 200) {
        return response;
      } else {
        return _sendRequest(action, data, additionalParams: additionalParams);
      }
    } on DioException catch (e) {
      printINFO("Error $e");
      throw NetworkError();
    }
  }

  // Future<List<Map<String, dynamic>>>
  Future<dynamic> getHome({int limit = 4}) async {
    final data = Map.from(_context);
    data["browseId"] = "FEmusic_home";
    final response = await _sendRequest("browse", data);
    final results = nav(response.data, single_column_tab + section_list);
    final home = [...parseMixedContent(results)];

    final sectionList =
        nav(response.data, single_column_tab + ['sectionListRenderer']);
    //print(sectionList.containsKey('continuations'));
    if (sectionList.containsKey('continuations')) {
      requestFunc(additionalParams) async {
        return (await _sendRequest("browse", data,
                additionalParams: additionalParams))
            .data;
      }

      parseFunc(contents) => parseMixedContent(contents);
      final x = (await getContinuations(sectionList, 'sectionListContinuation',
          limit - home.length, requestFunc, parseFunc));
      // inspect(x);
      home.addAll([...x]);
    }

    return home;
  }

  Future<List<Map<String, dynamic>>> getCharts(
      {String? countryCode = "vi"}) async {
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
      charts.add(parseChartsItem(result));
    }

    return charts;
  }

  Future<Map<String, dynamic>> getWatchPlaylist(
      {String videoId = "",
      String? playlistId,
      int limit = 25,
      bool radio = false,
      bool shuffle = false,
      String? additionalParamsNext,
      bool onlyRelated = false}) async {
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
      tracks.addAll(parseWatchPlaylist(results['contents']));
    }

    dynamic additionalParamsForNext;
    if (results.containsKey('continuations') || additionalParamsNext != null) {
      requestFunc(additionalParams) async =>
          (await _sendRequest("next", data, additionalParams: additionalParams))
              .data;
      parseFunc(contents) => parseWatchPlaylist(contents);
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
  }

  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    final response = await dio.get("${domain}playlist",
        options: Options(headers: _headers),
        queryParameters: {"list": audioPlaylistId});
    final reg = RegExp(r'\"MPRE.+?\"');
    final matchs = reg.firstMatch(response.data.toString());
    if (matchs != null) {
      final x = (matchs[0])!;
      final res = (x.substring(1)).split("\\")[0];
      return res;
    }
    return audioPlaylistId;
  }

  dynamic getContentRelatedToSong(String videoId, String hlCode) async {
    final params = await getWatchPlaylist(videoId: videoId, onlyRelated: true);
    final data = Map.from(_context);
    data['browseId'] = params['related'];
    data['context']['client']['hl'] = hlCode;
    final response = (await _sendRequest('browse', data)).data;
    final sections = nav(response, ['contents'] + section_list);
    final x = parseMixedContent(sections);
    return x;
  }

  dynamic getLyrics(String browseId) async {
    final data = Map.from(_context);
    data['browseId'] = browseId;
    final response = (await _sendRequest('browse', data)).data;
    return nav(
      response,
      ['contents', ...section_list_item, ...description_shelf, ...description],
    );
  }

  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs(
      {String? playlistId,
      String? albumId,
      int limit = 3000,
      bool related = false,
      int suggestionsLimit = 0}) async {
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
      final Map<String, dynamic> header =
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

      final Map<String, dynamic> results =
          nav(response, musicPlaylistShelfRenderer) ??
              nav(
                response,
                [
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
                ],
              );
      final Map<String, dynamic> playlist = {'id': results['playlistId']};

      playlist['title'] = nav(header, title_text);
      playlist['thumbnails'] = nav(header, thumnail_cropped) ??
          nav(header, [
            "thumbnail",
            "musicThumbnailRenderer",
            "thumbnail",
            "thumbnails"
          ]);
      playlist["description"] = nav(header, description);
      final int runCount = header['subtitle']['runs'].length;
      if (runCount > 1) {
        playlist['author'] = {
          'name': nav(header, subtitle2),
          'id': nav(header, ['subtitle', 'runs', 2] + navigation_browse_id)
        };
        if (runCount == 5) {
          playlist['year'] = nav(header, subtitle3);
        }
      }

      final int secondSubtitleRunCount =
          header['secondSubtitle']['runs'].length;
      final String count = (((header['secondSubtitle']['runs']
                      [secondSubtitleRunCount % 3]['text'])
                  .split(' ')[0])
              .split(',') as List)
          .join();
      final int songCount = int.parse(count);
      if (header['secondSubtitle']['runs'].length > 1) {
        playlist['duration'] = header['secondSubtitle']['runs']
            [(secondSubtitleRunCount % 3) + 2]['text'];
      }
      playlist['trackCount'] = songCount;

      // requestFunc(additionalParams) async => (await _sendRequest("browse", data,
      //         additionalParams: additionalParams))
      //     .data;

      requestFuncCountinuation(cont) async =>
          (await _sendRequest("browse", {...data, ...cont})).data;

      if (songCount > 0) {
        playlist['tracks'] = parsePlaylistItems(results['contents']);
        limit = songCount;

        List<dynamic> parseFunc(contents) => parsePlaylistItems(contents);

        playlist['tracks'] = [
          ...(playlist['tracks']),
          ...(await getContinuationsPlaylist(
              results, limit, requestFuncCountinuation, parseFunc))
        ];
      }
      playlist['duration_seconds'] = sumTotalDuration(playlist);
      return playlist;
    }

    //album content
    final album = parseAlbumHeader(response);
    dynamic results = nav(
          response,
          [
            'contents',
            "twoColumnBrowseResultsRenderer",
            "secondaryContents",
            'sectionListRenderer',
            'contents',
            0,
            'musicShelfRenderer'
          ],
        ) ??
        nav(
          response,
          [
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
          ],
        );

    album['tracks'] = parsePlaylistItems(results['contents'],
        artistsM: album['artists'],
        thumbnailsM: album["thumbnails"],
        albumIdName: {"id": albumId, 'name': album['title']},
        albumYear: album['year'],
        isAlbum: true);
    results = nav(
      response,
      [...single_column_tab, ...section_list, 1, 'musicCarouselShelfRenderer'],
    );
    if (results != null) {
      List contents = [];
      if (results.runtimeType.toString().contains("Iterable") ||
          results.runtimeType.toString().contains("List")) {
        for (dynamic result in results) {
          contents.add(parseAlbum(result['musicTwoRowItemRenderer']));
        }
      } else {
        contents
            .add(parseAlbum(results['contents'][0]['musicTwoRowItemRenderer']));
      }
      album['other_versions'] = contents;
    }
    album['duration_seconds'] = sumTotalDuration(album);

    return album;
  }

  Future<List<String>> getSearchSuggestion(String queryStr) async {
    final data = Map.from(_context);
    data['input'] = queryStr;
    final res = nav(
            (await _sendRequest("music/get_search_suggestions", data)).data,
            ['contents', 0, 'searchSuggestionsSectionRenderer', 'contents']) ??
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
  }

  ///Specially created for deep-links
  Future<List> getSongWithId(String songId) async {
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
  }

  Future<Map<String, dynamic>> search(String query,
      {String? filter,
      String? scope,
      int limit = 30,
      bool ignoreSpelling = false}) async {
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
        //final topResult = parseTopResult(res['musicCardShelfRenderer'], ['artist', 'playlist', 'song', 'video', 'station']);
        //searchResults.add(topResult);
        results = nav(res, ['musicCardShelfRenderer', 'contents']);
        if (results != null) {
          if ((results[0]).containsKey("messageRenderer")) {
            category = nav(results[0], ['messageRenderer', ...text_run_text]);
            results = results.sublist(1);
          }
          //type = null;
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

      searchResults[category] = parseSearchResults(results,
          ['artist', 'playlist', 'song', 'video', 'station'], type, category);

      if (filter != null) {
        requestFunc(additionalParams) async =>
            (await _sendRequest("search", data,
                    additionalParams: additionalParams))
                .data;
        parseFunc(contents) => parseSearchResults(contents,
            ['artist', 'playlist', 'song', 'video', 'station'], type, category);

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
  }

  Future<Map<String, dynamic>> getSearchContinuation(Map additionalParamsNext,
      {int limit = 10}) async {
    final data = additionalParamsNext['data'];
    final type = additionalParamsNext['type'];
    final category = additionalParamsNext['category'];
    final Map<String, dynamic> searchResults = {};

    requestFunc(additionalParams) async =>
        (await _sendRequest("search", data, additionalParams: additionalParams))
            .data;

    parseFunc(contents) => parseSearchResults(contents,
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
  }

  Future<Map<String, dynamic>> getArtist(String channelId) async {
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

    artist.addAll(parseArtistContents(results));
    return artist;
  }

  Future<Map<String, dynamic>> getArtistRealtedContent(
      Map<String, dynamic> browseEndpoint, String category,
      {String additionalParams = ""}) async {
    final Map<String, dynamic> result = {
      "results": [],
    };
    final data = Map.of(_context);
    browseEndpoint.remove("content");
    if (browseEndpoint.isEmpty) return result;
    data.addAll(browseEndpoint);
    final response =
        (await _sendRequest("browse", data, additionalParams: additionalParams))
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
        final x = parsePlaylistItems(contentList);
        result['results'] = x;
        result['additionalParams'] = "&ctoken=${null}&continuation=${null}";
      } else if (contents.containsKey("gridRenderer")) {
        result['results'] = (contents['gridRenderer']['items'])
            .map((video) => parseVideo(video['musicTwoRowItemRenderer']))
            .toList();
        result['additionalParams'] = "&ctoken=${null}&continuation=${null}";
      } else {
        final collapseContent =
            nav(contents, ['musicPlaylistShelfRenderer', "collapsedItemCount"]);
        if (collapseContent != null) {
          final contentlist =
              contents['musicPlaylistShelfRenderer']['contents'];
          if (contentlist.length.toString() != collapseContent.toString()) {
            final continuationItem = contentlist.removeAt(100);
            result['results'] = parsePlaylistItems(contentlist);
            final continuationKey = nav(continuationItem, [
              "continuationItemRenderer",
              "continuationEndpoint",
              "continuationCommand",
              "token"
            ]);
            result['additionalParams'] =
                "&ctoken=$continuationKey&continuation=$continuationKey";
          } else {
            result['results'] = parsePlaylistItems(contentlist);
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
  }

  Future<String?> getSongYear(String songId) async {
    final data = Map.from(_context);
    data['browseId'] = "MPTC$songId";
    try {
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
      rethrow;
    }
  }

  @override
  void onClose() {
    dio.close();
    super.onClose();
  }

  String _sha1(String input) {
    var bytes = utf8.encode(input);
    var digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Tạo SAPISIDHASH cho YouTube API
  ///
  /// [datasyncId] - ID datasync (nếu null sẽ lấy từ storage)
  /// [cookieString] - Chuỗi cookie chứa SAPISID
  /// [origin] - Origin URL (mặc định là https://www.youtube.com)
  Future<String?> getSApiSidHash(String? datasyncId, String sapisid,
      {String origin = "https://music.youtube.com"}) async {
    try {
      // Nếu datasyncId không được truyền vào, lấy từ storage
      String? finalDatasyncId = datasyncId;
      if (finalDatasyncId == null) {
        finalDatasyncId = await CookieManager.getDatasyncId();
        if (finalDatasyncId == null) {
          printERROR("No datasyncId available for SAPISIDHASH generation");
          return null;
        }
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      final inputString =
          [finalDatasyncId, timestamp, sapisid, origin].join(' ');
      final digest = _sha1(inputString);

      final sapisidHash = '${timestamp}_${digest}_u';

      return sapisidHash;
    } catch (e) {
      printERROR("Error generating SAPISIDHASH: $e");
      return null;
    }
  }
}

class NetworkError extends Error {
  final message = "Network Error !";
}
