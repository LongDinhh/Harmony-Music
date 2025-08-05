import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../utils/haptic_utils.dart';
import '../../../utils/scroll_controller_manager.dart';

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

class HomeScreenController extends GetxController
    with ScrollControllerManagerMixin {
  final MusicServices _musicServices = Get.find<MusicServices>();
  final isContentFetched = false.obs;
  final tabIndex = 0.obs;
  final networkError = false.obs;
  final quickPicks = QuickPicks([]).obs;
  final middleContent = [].obs;
  final fixedContent = [].obs;
  final showVersionDialog = true.obs;
  final isRefreshing = false.obs; // Thêm biến để track trạng thái refresh
  //Track current route để CombinedBottomContainer có thể reactive
  final currentRoute = '/homeScreen'.obs;
  bool reverseAnimationtransiton = false;
  bool _hasTriggeredRefreshHaptic =
      false; // Track haptic khi đủ điều kiện refresh

  @override
  onInit() {
    super.onInit();
    // Initialize current route
    currentRoute.value = getCurrentRouteName() ?? '/homeScreen';
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

    // Clean up idle scroll controllers when loading new content
    cleanupIdleScrollControllers();

    networkError.value = false;
    try {
      List middleContentTemp = [];
      final limitContent =
          Get.find<SettingsScreenController>().noOfHomeScreenContent.value;
      final homeContentListMap =
          await _musicServices.getHome(limit: limitContent);

      try {
        final songId = box.get("recentSongId");
        if (songId != null) {
          final rel = (await _musicServices.getContentRelatedToSong(
              songId, getContentHlCode()));
          final con = rel.removeAt(0);
          quickPicks.value = QuickPicks(List<MediaItem>.from(con["contents"]));
          middleContentTemp.addAll(rel);
          printINFO("BOLI - Successfully loaded content for songId: $songId");
        } else {
          printERROR("BOLI - recentSongId is null, cannot load BOLI content");
        }
      } catch (e) {
        printERROR(
            "Seems Based on last interaction content currently not available! Error: $e");
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

    songId ??= Hive.box("AppPrefs").get("recentSongId");
    if (songId != null) {
      try {
        final value = await _musicServices.getContentRelatedToSong(
            songId, getContentHlCode());
        middleContent.value = _setContentList(value);
        if (value.isNotEmpty && (value[0]['title']).contains("like")) {
          quickPicks_ = QuickPicks(List<MediaItem>.from(value[0]["contents"]));
          Hive.box("AppPrefs").put("recentSongId", songId);
        }
      } catch (e) {
        printERROR("Error loading content related to song: $e");
      }
    }
    if (quickPicks_ == null) return;

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
    // Thêm haptic feedback khi chuyển menu
    HapticUtils.navigationHaptic();
    reverseAnimationtransiton = index > tabIndex.value;
    tabIndex.value = index;
  }

  void onBottonBarTabSelected(int index) {
    // Thêm haptic feedback khi chuyển menu
    HapticUtils.navigationHaptic();
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

  ///This is used to set mini player height based on current route.
  ///
  ///and applicable/useful if bottom nav enabled
  void whenHomeScreenOnTop() {
    if (Get.find<SettingsScreenController>().isBottomNavBarEnabled.isTrue) {
      final currentRoute = getCurrentRouteName();
      final isHomeOnTop = currentRoute == '/homeScreen';
      final isResultScreenOnTop = currentRoute == '/searchResultScreen';
      final playerCon = Get.find<PlayerController>();

      // Update observable current route để trigger CombinedBottomContainer rebuild
      this.currentRoute.value = currentRoute ?? '/homeScreen';

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

  // ScrollController management is now handled by ScrollControllerManagerMixin
  // All scroll controllers are automatically managed with proper cleanup
}
