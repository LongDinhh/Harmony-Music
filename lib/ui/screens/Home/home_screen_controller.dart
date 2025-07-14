import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/models/media_Item_builder.dart';
import '/ui/player/player_controller.dart';
import '../../../utils/update_check_flag_file.dart';
import '../../../utils/helper.dart';
import '/models/album.dart';
import '/models/playlist.dart';
import '/models/quick_picks.dart';
import '/services/music_service.dart';
import '../Settings/settings_screen_controller.dart';
import '/ui/widgets/new_version_dialog.dart';

class HomeScreenController extends GetxController {
  final MusicServices _musicServices = Get.find<MusicServices>();
  final isContentFetched = false.obs;
  final tabIndex = 0.obs;
  final networkError = false.obs;
  final quickPicks = QuickPicks([]).obs;
  final middleContent = [].obs;
  final fixedContent = [].obs;
  final showVersionDialog = true.obs;
  final isRefreshing = false.obs; // Thêm biến để track trạng thái refresh
  //isHomeScreenOnTop var only useful if bottom nav enabled
  final isHomeSreenOnTop = true.obs;
  final List<ScrollController> contentScrollControllers = [];
  bool reverseAnimationtransiton = false;
  bool _hasTriggeredRefreshHaptic =
      false; // Track haptic khi đủ điều kiện refresh

  @override
  onInit() {
    super.onInit();
    loadContent();
    if (updateCheckFlag) _checkNewVersion();
  }

  Future<void> loadContent() async {
    final box = Hive.box("AppPrefs");
    final isCachedHomeScreenDataEnabled =
        box.get("cacheHomeScreenData") ?? true;
    if (isCachedHomeScreenDataEnabled) {
      final loaded = await loadContentFromDb();

      if (loaded) {
        final currTimeSecsDiff = DateTime.now().millisecondsSinceEpoch -
            (box.get("homeScreenDataTime") ??
                DateTime.now().millisecondsSinceEpoch);
        if (currTimeSecsDiff / 1000 > 3600 * 8) {
          loadContentFromNetwork(silent: true);
        }
      } else {
        loadContentFromNetwork();
      }
    } else {
      loadContentFromNetwork();
    }
  }

  Future<bool> loadContentFromDb() async {
    final homeScreenData = await Hive.openBox("homeScreenData");
    if (homeScreenData.keys.isNotEmpty) {
      try {
        final String quickPicksType = homeScreenData.get("quickPicksType");
        final List quickPicksData = homeScreenData.get("quickPicks");
        final List middleContentData =
            homeScreenData.get("middleContent") ?? [];
        final List fixedContentData = homeScreenData.get("fixedContent") ?? [];
        quickPicks.value = QuickPicks(
            quickPicksData.map((e) => MediaItemBuilder.fromJson(e)).toList(),
            title: quickPicksType);
        middleContent.value = middleContentData.map((e) {
          final data = Map<String, dynamic>.from(e as Map);
          if (data["type"] == "Album Content") {
            return AlbumContent.fromJson(data);
          } else if (data["type"] == "QuickPicks") {
            return QuickPicks.fromJson(data);
          } else {
            return PlaylistContent.fromJson(data);
          }
        }).toList();
        fixedContent.value = fixedContentData.map((e) {
          final data = Map<String, dynamic>.from(e as Map);
          if (data["type"] == "Album Content") {
            return AlbumContent.fromJson(data);
          } else if (data["type"] == "QuickPicks") {
            return QuickPicks.fromJson(data);
          } else {
            return PlaylistContent.fromJson(data);
          }
        }).toList();
        isContentFetched.value = true;
        printINFO("Loaded from offline db");
        return true;
      } catch (e) {
        printERROR("Error loading cached data: $e");
        // Xóa cache cũ nếu có lỗi
        await homeScreenData.clear();
        await homeScreenData.close();
        return false;
      }
    } else {
      return false;
    }
  }

  Future<void> loadContentFromNetwork({bool silent = false}) async {
    final box = Hive.box("AppPrefs");
    String contentType = box.get("discoverContentType") ?? "QP";

    networkError.value = false;
    try {
      List middleContentTemp = [];
      final homeContentListMap = await _musicServices.getHome(
          limit:
              Get.find<SettingsScreenController>().noOfHomeScreenContent.value);
      if (contentType == "TR") {
        final index = homeContentListMap
            .indexWhere((element) => element['title'] == "Trending");
        if (index != -1 && index != 0) {
          quickPicks.value = QuickPicks(
              List<MediaItem>.from(homeContentListMap[index]["contents"]),
              title: "Trending");
        } else if (index == -1) {
          List charts = await _musicServices.getCharts();
          if (charts.isNotEmpty) {
            final con =
                charts.length == 4 ? charts.removeAt(3) : charts.removeAt(2);
            quickPicks.value = QuickPicks(List<MediaItem>.from(con["contents"]),
                title: con['title']);
            middleContentTemp.addAll(charts);
          }
        }
      } else if (contentType == "TMV") {
        final index = homeContentListMap
            .indexWhere((element) => element['title'] == "Top music videos");
        if (index != -1 && index != 0) {
          final con = homeContentListMap.removeAt(index);
          quickPicks.value = QuickPicks(List<MediaItem>.from(con["contents"]),
              title: con["title"]);
        } else if (index == -1) {
          List charts = await _musicServices.getCharts();
          if (charts.isNotEmpty) {
            quickPicks.value = QuickPicks(
                List<MediaItem>.from(charts[0]["contents"]),
                title: charts[0]["title"]);
            middleContentTemp.addAll(charts.sublist(1));
          }
        }
      } else if (contentType == "BOLI") {
        try {
          final songId = box.get("recentSongId");
          if (songId != null) {
            final rel = (await _musicServices.getContentRelatedToSong(
                songId, getContentHlCode()));
            if (rel.isNotEmpty) {
              final con = rel.removeAt(0);
              quickPicks.value =
                  QuickPicks(List<MediaItem>.from(con["contents"]));
              middleContentTemp.addAll(rel);
            }
          }
        } catch (e) {
          printERROR(
              "Seems Based on last interaction content currently not available!");
        }
      }

      if (quickPicks.value.songList.isEmpty) {
        final index = homeContentListMap
            .indexWhere((element) => element['title'] == "Quick picks");
        if (index != -1) {
          final con = homeContentListMap.removeAt(index);
          quickPicks.value = QuickPicks(List<MediaItem>.from(con["contents"]),
              title: "Quick picks");
        } else if (homeContentListMap.isNotEmpty) {
          // Fallback: use first available content if Quick picks not found
          final con = homeContentListMap.removeAt(0);
          quickPicks.value = QuickPicks(List<MediaItem>.from(con["contents"]),
              title: con["title"] ?? "Quick picks");
        }
      }

      middleContent.value = _setContentList(middleContentTemp);
      fixedContent.value = _setContentList(homeContentListMap);

      isContentFetched.value = true;

      // set home content last update time
      cachedHomeScreenData(updateAll: true);
      await Hive.box("AppPrefs")
          .put("homeScreenDataTime", DateTime.now().millisecondsSinceEpoch);
      // ignore: unused_catch_stack
    } on NetworkError catch (r, e) {
      printERROR("Home Content not loaded due to ${r.message}");
      await Future.delayed(const Duration(seconds: 1));
      networkError.value = !silent;
    } catch (e, stackTrace) {
      printERROR("Unexpected error loading home content: $e");
      printERROR("Stack trace: $stackTrace");
      networkError.value = !silent;
    }
  }

  /// Method để refresh lại data khi pull-to-refresh
  @override
  Future<void> refresh() async {
    if (isRefreshing.value) return; // Tránh multiple refresh cùng lúc

    try {
      isRefreshing.value = true;

      // Force load data từ network, bỏ qua cache
      await loadContentFromNetwork(silent: false);
    } catch (e) {
      printERROR("Error refreshing home screen data: $e");
    } finally {
      isRefreshing.value = false;
      _resetHapticState(); // Reset haptic state sau khi refresh
    }
  }

  /// Handle scroll notification để trigger haptic khi đủ điều kiện refresh
  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && !isRefreshing.value) {
      final pixels = notification.metrics.pixels;

      // Trigger haptic ở 140px
      if (pixels < -140 && !_hasTriggeredRefreshHaptic) {
        _hasTriggeredRefreshHaptic = true;
        HapticFeedback.lightImpact();
      }
      // Reset flag khi scroll về vị trí bình thường
      else if (pixels >= -40) {
        _hasTriggeredRefreshHaptic = false;
      }
    }
    // Reset flag khi bắt đầu và kết thúc scroll
    else if (notification is ScrollStartNotification) {
      if (notification.metrics.pixels <= 0) {
        _hasTriggeredRefreshHaptic = false;
      }
    } else if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels <= 0) {
        _hasTriggeredRefreshHaptic = false;
      }
    }
    return false; // Không consume notification
  }

  /// Reset haptic state
  void _resetHapticState() {
    _hasTriggeredRefreshHaptic = false;
  }

  List _setContentList(
    List<dynamic> contents,
  ) {
    List contentTemp = [];
    for (var content in contents) {
      // Safety check for content structure
      if (content == null ||
          content["contents"] == null ||
          (content["contents"] as List).isEmpty) {
        continue;
      }

      if ((content["contents"][0]).runtimeType == Playlist) {
        final tmp = PlaylistContent(
            playlistList: (content["contents"]).whereType<Playlist>().toList(),
            title: content["title"]);
        if (tmp.playlistList.length >= 2) {
          contentTemp.add(tmp);
        }
      } else if ((content["contents"][0]).runtimeType == Album) {
        final tmp = AlbumContent(
            albumList: (content["contents"]).whereType<Album>().toList(),
            title: content["title"]);
        if (tmp.albumList.length >= 2) {
          contentTemp.add(tmp);
        }
      } else if ((content["contents"][0]).runtimeType == MediaItem) {
        final songs = (content["contents"]).whereType<MediaItem>().toList();
        if (songs.length >= 2) {
          final tmp = QuickPicks(songs, title: content["title"]);
          contentTemp.add(tmp);
        }
      }
    }
    return contentTemp;
  }

  Future<void> changeDiscoverContent(dynamic val, {String? songId}) async {
    QuickPicks? quickPicks_;
    if (val == 'QP') {
      final homeContentListMap = await _musicServices.getHome(limit: 3);
      quickPicks_ = QuickPicks(
          List<MediaItem>.from(homeContentListMap[0]["contents"]),
          title: homeContentListMap[0]["title"]);
    } else if (val == "TMV" || val == 'TR') {
      try {
        final charts = await _musicServices.getCharts();
        if (charts.isNotEmpty) {
          final index = val == "TMV"
              ? 0
              : charts.length == 4
                  ? 3
                  : 2;
          if (index < charts.length) {
            quickPicks_ = QuickPicks(
                List<MediaItem>.from(charts[index]["contents"]),
                title: charts[index]["title"]);
          }
        }
      } catch (e) {
        printERROR(
            "Seems ${val == "TMV" ? "Top music videos" : "Trending songs"} currently not available!");
      }
    } else {
      songId ??= Hive.box("AppPrefs").get("recentSongId");
      if (songId != null) {
        try {
          final value = await _musicServices.getContentRelatedToSong(
              songId, getContentHlCode());
          middleContent.value = _setContentList(value);
          if (value.isNotEmpty &&
              value[0] != null &&
              value[0]['title'] != null &&
              (value[0]['title']).toString().contains("like")) {
            quickPicks_ =
                QuickPicks(List<MediaItem>.from(value[0]["contents"]));
            Hive.box("AppPrefs").put("recentSongId", songId);
          }
          // ignore: empty_catches
        } catch (e) {}
      }
    }
    if (quickPicks_ == null || quickPicks_.songList.isEmpty) return;

    quickPicks.value = quickPicks_;

    // set home content last update time
    cachedHomeScreenData(updateQuickPicksNMiddleContent: true);
    await Hive.box("AppPrefs")
        .put("homeScreenDataTime", DateTime.now().millisecondsSinceEpoch);
  }

  String getContentHlCode() {
    const List<String> unsupportedLangIds = ["ia", "ga", "fj", "eo"];
    final userLangId =
        Get.find<SettingsScreenController>().currentAppLanguageCode.value;
    return unsupportedLangIds.contains(userLangId) ? "vi" : userLangId;
  }

  void onSideBarTabSelected(int index) {
    reverseAnimationtransiton = index > tabIndex.value;
    tabIndex.value = index;
  }

  void onBottonBarTabSelected(int index) {
    reverseAnimationtransiton = index > tabIndex.value;
    tabIndex.value = index;
  }

  void _checkNewVersion() {
    showVersionDialog.value =
        Hive.box("AppPrefs").get("newVersionVisibility") ?? true;
    if (showVersionDialog.isTrue) {
      newVersionCheck(Get.find<SettingsScreenController>().currentVersion)
          .then((value) {
        if (value) {
          showDialog(
              context: Get.context!,
              builder: (context) => const NewVersionDialog());
        }
      });
    }
  }

  void onChangeVersionVisibility(bool val) {
    Hive.box("AppPrefs").put("newVersionVisibility", !val);
    showVersionDialog.value = !val;
  }

  ///This is used to minimized bottom navigation bar by setting [isHomeSreenOnTop.value] to `true` and set mini player height.
  ///
  ///and applicable/useful if bottom nav enabled
  void whenHomeScreenOnTop() {
    if (Get.find<SettingsScreenController>().isBottomNavBarEnabled.isTrue) {
      final currentRoute = getCurrentRouteName();
      final isHomeOnTop = currentRoute == '/homeScreen';
      final isResultScreenOnTop = currentRoute == '/searchResultScreen';
      final playerCon = Get.find<PlayerController>();

      isHomeSreenOnTop.value = isHomeOnTop;

      // Set miniplayer height accordingly
      if (!playerCon.initFlagForPlayer) {
        if (isHomeOnTop) {
          playerCon.playerPanelMinHeight.value = 65.0;
        } else {
          Future.delayed(
              isResultScreenOnTop
                  ? const Duration(milliseconds: 300)
                  : Duration.zero, () {
            playerCon.playerPanelMinHeight.value =
                65.0 + Get.mediaQuery.viewPadding.bottom;
          });
        }
      }
    }
  }

  Future<void> cachedHomeScreenData({
    bool updateAll = false,
    bool updateQuickPicksNMiddleContent = false,
  }) async {
    if (Get.find<SettingsScreenController>().cacheHomeScreenData.isFalse ||
        quickPicks.value.songList.isEmpty) {
      return;
    }

    final homeScreenData = Hive.box("homeScreenData");

    if (updateQuickPicksNMiddleContent) {
      await homeScreenData.putAll({
        "quickPicksType": quickPicks.value.title,
        "quickPicks": _getContentDataInJson(quickPicks.value.songList,
            isQuickPicks: true),
        "middleContent": _getContentDataInJson(middleContent.toList()),
      });
    } else if (updateAll) {
      await homeScreenData.putAll({
        "quickPicksType": quickPicks.value.title,
        "quickPicks": _getContentDataInJson(quickPicks.value.songList,
            isQuickPicks: true),
        "middleContent": _getContentDataInJson(middleContent.toList()),
        "fixedContent": _getContentDataInJson(fixedContent.toList())
      });
    }

    printINFO("Saved Homescreen data data");
  }

  List<Map<String, dynamic>> _getContentDataInJson(List content,
      {bool isQuickPicks = false}) {
    if (isQuickPicks) {
      return content.toList().map((e) => MediaItemBuilder.toJson(e)).toList();
    } else {
      return content.map((e) {
        if (e.runtimeType == AlbumContent) {
          return (e as AlbumContent).toJson();
        } else if (e.runtimeType == PlaylistContent) {
          return (e as PlaylistContent).toJson();
        } else if (e.runtimeType == QuickPicks) {
          return (e as QuickPicks).toJson();
        } else {
          return (e as PlaylistContent).toJson();
        }
      }).toList();
    }
  }

  void disposeDetachedScrollControllers({bool disposeAll = false}) {
    final scrollControllersCopy = contentScrollControllers.toList();
    for (final contoller in scrollControllersCopy) {
      if (!contoller.hasClients || disposeAll) {
        contentScrollControllers.remove(contoller);
        contoller.dispose();
      }
    }
  }

  @override
  void dispose() {
    disposeDetachedScrollControllers(disposeAll: true);
    super.dispose();
  }
}
