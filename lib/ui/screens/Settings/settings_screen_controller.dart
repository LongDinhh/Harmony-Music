import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/services/permission_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../utils/update_check_flag_file.dart';
import '/services/piped_service.dart';
import '../Library/library_controller.dart';
import '../../widgets/snackbar.dart';
import '../../../utils/helper.dart';
import '/services/music_service.dart';
import '/ui/player/player_controller.dart';
import '../Home/home_screen_controller.dart';
import '/ui/utils/theme_controller.dart';
import '/services/cookie_manager.dart';
import '/services/youtube_cookie_manager.dart';
import 'google_login_webview.dart';

class SettingsScreenController extends GetxController {
  late String _supportDir;
  final cacheSongs = false.obs;
  final setBox = Hive.box("AppPrefs");
  final themeModetype = ThemeType.dynamic.obs;
  final skipSilenceEnabled = false.obs;
  final loudnessNormalizationEnabled = false.obs;
  final noOfHomeScreenContent = 7.obs;
  final streamingQuality = AudioQuality.High.obs;
  final playerUi = 0.obs;
  final slidableActionEnabled = true.obs;
  final isIgnoringBatteryOptimizations = false.obs;
  final autoOpenPlayer = true.obs;
  final discoverContentType = "QP".obs;
  final isNewVersionAvailable = false.obs;
  final isLinkedWithPiped = false.obs;
  final stopPlyabackOnSwipeAway = false.obs;
  final currentAppLanguageCode = "vi".obs;
  final downloadLocationPath = "".obs;
  final exportLocationPath = "".obs;
  final downloadingFormat = "".obs;
  final hideDloc = true.obs;
  final autoDownloadFavoriteSongEnabled = false.obs;
  final isTransitionAnimationDisabled = false.obs;
  final isBottomNavBarEnabled = false.obs;
  final backgroundPlayEnabled = true.obs;
  final restorePlaybackSession = false.obs;
  final cacheHomeScreenData = true.obs;
  final currentVersion = "V1.12.0";

  @override
  void onInit() {
    _setInitValue();
    if (updateCheckFlag) _checkNewVersion();
    _createInAppSongDownDir();
    _loadCookieInfo();
    super.onInit();
  }

  get currentVision => currentVersion;
  get isCurrentPathsupportDownDir =>
      "$_supportDir/Music" == downloadLocationPath.toString();
  String get supportDirPath => _supportDir;

  _checkNewVersion() {
    newVersionCheck(currentVersion)
        .then((value) => isNewVersionAvailable.value = value);
  }

  Future<String> _createInAppSongDownDir() async {
    _supportDir = (await getApplicationSupportDirectory()).path;
    final directory = Directory("$_supportDir/Music/");
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return "$_supportDir/Music";
  }

  Future<void> _setInitValue() async {
    final isDesktop = GetPlatform.isDesktop;
    final appLang = setBox.get('currentAppLanguageCode') ?? "vi";
    currentAppLanguageCode.value = appLang == "zh_Hant"
        ? "zh-TW"
        : appLang == "zh_Hans"
            ? "zh-CN"
            : appLang;
    isBottomNavBarEnabled.value =
        isDesktop ? false : (setBox.get("isBottomNavBarEnabled") ?? true);
    noOfHomeScreenContent.value = setBox.get("noOfHomeScreenContent") ?? 7;
    isTransitionAnimationDisabled.value =
        setBox.get("isTransitionAnimationDisabled") ?? false;
    cacheSongs.value = setBox.get('cacheSongs') ?? false;
    themeModetype.value = ThemeType.values[setBox.get('themeModeType') ?? 0];
    skipSilenceEnabled.value =
        isDesktop ? false : setBox.get("skipSilenceEnabled");
    loudnessNormalizationEnabled.value = isDesktop
        ? false
        : (setBox.get("loudnessNormalizationEnabled") ?? false);
    autoOpenPlayer.value = (setBox.get("autoOpenPlayer") ?? true);
    restorePlaybackSession.value =
        setBox.get("restrorePlaybackSession") ?? true;
    cacheHomeScreenData.value = setBox.get("cacheHomeScreenData") ?? true;
    streamingQuality.value =
        AudioQuality.values[setBox.get('streamingQuality')];
    playerUi.value = isDesktop ? 0 : (setBox.get('playerUi') ?? 0);
    backgroundPlayEnabled.value = setBox.get("backgroundPlayEnabled") ?? true;
    final downloadPath =
        setBox.get('downloadLocationPath') ?? await _createInAppSongDownDir();
    downloadLocationPath.value =
        (isDesktop && downloadPath.contains("emulated"))
            ? await _createInAppSongDownDir()
            : downloadPath;

    exportLocationPath.value =
        setBox.get("exportLocationPath") ?? "/storage/emulated/0/Music";
    downloadingFormat.value = setBox.get('downloadingFormat') ?? "m4a";
    discoverContentType.value = setBox.get('discoverContentType') ?? "QP";
    slidableActionEnabled.value = setBox.get('slidableActionEnabled') ?? true;
    if (setBox.containsKey("piped")) {
      isLinkedWithPiped.value = setBox.get("piped")['isLoggedIn'];
    }
    stopPlyabackOnSwipeAway.value =
        setBox.get('stopPlyabackOnSwipeAway') ?? false;
    if (GetPlatform.isAndroid) {
      isIgnoringBatteryOptimizations.value =
          (await Permission.ignoreBatteryOptimizations.isGranted);
    }
    autoDownloadFavoriteSongEnabled.value =
        setBox.get("autoDownloadFavoriteSongEnabled") ?? false;
  }

  void setAppLanguage(String? val) {
    Get.updateLocale(Locale(val!));
    Get.find<MusicServices>().hlCode = val;
    Get.find<HomeScreenController>().loadContentFromNetwork(silent: true);
    currentAppLanguageCode.value = val;
    setBox.put('currentAppLanguageCode', val);
  }

  void setContentNumber(int? no) {
    noOfHomeScreenContent.value = no!;
    setBox.put("noOfHomeScreenContent", no);
  }

  void setStreamingQuality(dynamic val) {
    setBox.put("streamingQuality", AudioQuality.values.indexOf(val));
    streamingQuality.value = val;
  }

  void setPlayerUi(dynamic val) {
    final playerCon = Get.find<PlayerController>();
    setBox.put("playerUi", val);
    if (val == 1 && playerCon.gesturePlayerStateAnimationController == null) {
      playerCon.initGesturePlayerStateAnimationController();
    }

    playerUi.value = val;
  }

  void enableBottomNavBar(bool val) {
    final homeScrCon = Get.find<HomeScreenController>();
    final playerCon = Get.find<PlayerController>();
    if (val) {
      homeScrCon.onSideBarTabSelected(3);
      isBottomNavBarEnabled.value = true;
    } else {
      isBottomNavBarEnabled.value = false;
      homeScrCon.onSideBarTabSelected(5);
    }
    if (!Get.find<PlayerController>().initFlagForPlayer) {
      playerCon.playerPanelMinHeight.value =
          val ? 65.0 : 65.0 + Get.mediaQuery.viewPadding.bottom;
    }
    setBox.put("isBottomNavBarEnabled", val);
  }

  void toggleSlidableAction(bool val) {
    setBox.put("slidableActionEnabled", val);
    slidableActionEnabled.value = val;
  }

  void changeDownloadingFormat(String? val) {
    setBox.put("downloadingFormat", val);
    downloadingFormat.value = val!;
  }

  Future<void> setExportedLocation() async {
    if (!await PermissionService.getExtStoragePermission()) {
      return;
    }

    final String? pickedFolderPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: "Select export file folder");
    if (pickedFolderPath == '/' || pickedFolderPath == null) {
      return;
    }

    setBox.put("exportLocationPath", pickedFolderPath);
    exportLocationPath.value = pickedFolderPath;
  }

  Future<void> setDownloadLocation() async {
    if (!await PermissionService.getExtStoragePermission()) {
      return;
    }

    final String? pickedFolderPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: "Select downloads folder");
    if (pickedFolderPath == '/' || pickedFolderPath == null) {
      return;
    }

    setBox.put("downloadLocationPath", pickedFolderPath);
    downloadLocationPath.value = pickedFolderPath;
  }

  void showDownLoc() {
    hideDloc.value = false;
  }

  void disableTransitionAnimation(bool val) {
    setBox.put('isTransitionAnimationDisabled', val);
    isTransitionAnimationDisabled.value = val;
  }

  Future<void> clearImagesCache() async {
    final tempImgDirPath =
        "${(await getApplicationCacheDirectory()).path}/libCachedImageData";
    final tempImgDir = Directory(tempImgDirPath);
    try {
      if (await tempImgDir.exists()) {
        await tempImgDir.delete(recursive: true);
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  void resetDownloadLocation() {
    final defaultPath = "$_supportDir/Music";
    setBox.put("downloadLocationPath", defaultPath);
    downloadLocationPath.value = defaultPath;
  }

  void onThemeChange(dynamic val) {
    setBox.put('themeModeType', ThemeType.values.indexOf(val));
    themeModetype.value = val;
    Get.find<ThemeController>().changeThemeModeType(val);
  }

  void onContentChange(dynamic value) {
    setBox.put('discoverContentType', value);
    discoverContentType.value = value;
    Get.find<HomeScreenController>().changeDiscoverContent(value);
  }

  void toggleCachingSongsValue(bool value) {
    setBox.put("cacheSongs", value);
    cacheSongs.value = value;
  }

  void toggleSkipSilence(bool val) {
    Get.find<PlayerController>().toggleSkipSilence(val);
    setBox.put('skipSilenceEnabled', val);
    skipSilenceEnabled.value = val;
  }

  void toggleLoudnessNormalization(bool val) {
    Get.find<PlayerController>().toggleLoudnessNormalization(val);
    setBox.put("loudnessNormalizationEnabled", val);
    loudnessNormalizationEnabled.value = val;
  }

  void toggleRestorePlaybackSession(bool val) {
    setBox.put("restrorePlaybackSession", val);
    restorePlaybackSession.value = val;
  }

  Future<void> toggleCacheHomeScreenData(bool val) async {
    setBox.put("cacheHomeScreenData", val);
    cacheHomeScreenData.value = val;
    if (!val) {
      Hive.openBox("homeScreenData").then((box) async {
        await box.clear();
        await box.close();
      });
    } else {
      await Hive.openBox("homeScreenData");
      Get.find<HomeScreenController>().cachedHomeScreenData(updateAll: true);
    }
  }

  void toggleAutoDownloadFavoriteSong(bool val) {
    setBox.put("autoDownloadFavoriteSongEnabled", val);
    autoDownloadFavoriteSongEnabled.value = val;
  }

  void toggleBackgroundPlay(bool val) {
    setBox.put('backgroundPlayEnabled', val);
    backgroundPlayEnabled.value = val;
  }

  Future<void> enableIgnoringBatteryOptimizations() async {
    await Permission.ignoreBatteryOptimizations.request();
    isIgnoringBatteryOptimizations.value =
        await Permission.ignoreBatteryOptimizations.isGranted;
  }

  void toggleAutoOpenPlayer(bool val) {
    setBox.put('autoOpenPlayer', val);
    autoOpenPlayer.value = val;
  }

  Future<void> unlinkPiped() async {
    Get.find<PipedServices>().logout();
    isLinkedWithPiped.value = false;
    Get.find<LibraryPlaylistsController>().removePipedPlaylists();
    final box = await Hive.openBox('blacklistedPlaylist');
    box.clear();
    ScaffoldMessenger.of(Get.context!).showSnackBar(
        snackbar(Get.context!, "unlinkAlert".tr, size: SanckBarSize.MEDIUM));
    box.close();
  }

  Future<void> resetAppSettingsToDefault() async {
    await setBox.clear();
  }

  void toggleStopPlyabackOnSwipeAway(bool val) {
    setBox.put('stopPlyabackOnSwipeAway', val);
    stopPlyabackOnSwipeAway.value = val;
  }

  Future<void> closeAllDatabases() async {
    await Hive.close();
  }

  Future<String> get dbDir async {
    if (GetPlatform.isDesktop) {
      return "$supportDirPath/db";
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  // Cookie management methods
  final cookieInfo = Rxn<Map<String, dynamic>>();
  final hasValidCookies = false.obs;
  final isGoogleLoggedIn = false.obs;
  final googleLoginInfo = Rxn<Map<String, dynamic>>();

  Future<void> _loadCookieInfo() async {
    final info = await CookieManager.getCookieInfo();
    cookieInfo.value = info;
    hasValidCookies.value = await CookieManager.hasValidCookies();
    
    // Cleanup expired cookies
    await YouTubeCookieManager.cleanupExpiredCookies();
    
    // Load Google/YouTube login info
    await refreshGoogleLoginStatus();
  }

  Future<void> refreshCookieInfo() async {
    await _loadCookieInfo();
  }

  Future<void> clearCookies() async {
    await CookieManager.removeCookies();
    await _loadCookieInfo();
    ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
        Get.context!, "Cookies cleared successfully",
        size: SanckBarSize.MEDIUM));
  }

  Future<void> updateCookies(String newCookieString) async {
    await CookieManager.saveCookies(newCookieString);
    await _loadCookieInfo();
    ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
        Get.context!, "Cookies updated successfully",
        size: SanckBarSize.MEDIUM));
  }

  // Google/YouTube login methods
  Future<void> refreshGoogleLoginStatus() async {
    try {
      final loginInfo = await YouTubeCookieManager.getLoginInfo();
      googleLoginInfo.value = loginInfo;
      isGoogleLoggedIn.value = loginInfo['isLoggedIn'] as bool;
    } catch (e) {
      printERROR('Error refreshing Google login status: $e');
      isGoogleLoggedIn.value = false;
      googleLoginInfo.value = {'isLoggedIn': false, 'cookieCount': 0, 'cookies': {}};
    }
  }

  Future<void> logoutGoogle() async {
    try {
      await YouTubeCookieManager.clearAllYouTubeCookies();
      await refreshGoogleLoginStatus();
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
          Get.context!, "Đã đăng xuất Google", size: SanckBarSize.MEDIUM));
    } catch (e) {
      printERROR('Error logging out Google: $e');
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
          Get.context!, "Lỗi khi đăng xuất: $e", size: SanckBarSize.MEDIUM));
    }
  }

  Future<void> openGoogleLoginWebView() async {
    try {
      final result = await Get.to(() => const GoogleLoginWebView());
      if (result == true) {
        await refreshGoogleLoginStatus();
      }
    } catch (e) {
      printERROR('Error opening Google login WebView: $e');
    }
  }

  Future<void> cleanupExpiredCookies() async {
    try {
      await YouTubeCookieManager.cleanupExpiredCookies();
      await refreshGoogleLoginStatus();
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
          Get.context!, "Đã dọn dẹp cookie hết hạn", size: SanckBarSize.MEDIUM));
    } catch (e) {
      printERROR('Error cleaning up expired cookies: $e');
    }
  }
}
