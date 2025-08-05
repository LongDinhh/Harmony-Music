import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/services/permission_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/youtube_cookie_manager.dart';
import 'google_login_webview.dart';

import '../../../utils/update_check_flag_file.dart';
import '/services/piped_service.dart';
import '../Library/library_controller.dart';
import '../../widgets/snackbar.dart';
import '../../../utils/helper.dart';
import '/services/music_service.dart';
import '/ui/player/player_controller.dart';
import '../Home/home_screen_controller.dart';
import '/ui/utils/theme_controller.dart';

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
  final autoOpenPlayer = false.obs;
  final discoverContentType = "BOLI".obs;
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
  final isBottomNavBarEnabled = true.obs;
  final backgroundPlayEnabled = true.obs;
  final restorePlaybackSession = true.obs;
  final cacheHomeScreenData = true.obs;
  final currentVersion = "V1.12.0";
  final RxBool isGoogleLoggedIn = false.obs;

  @override
  void onInit() {
    _setInitValue();
    _checkGoogleLogin();
    if (updateCheckFlag) _checkNewVersion();
    _createInAppSongDownDir();
    super.onInit();
  }

  String get currentVision => currentVersion;
  bool get isCurrentPathsupportDownDir =>
      "$_supportDir/Music" == downloadLocationPath.toString();
  String get supportDirPath => _supportDir;

  void _checkNewVersion() {
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
    // Set default app language if not exists
    if (!setBox.containsKey('currentAppLanguageCode')) {
      await setBox.put('currentAppLanguageCode', 'vi');
    }
    final appLang = setBox.get('currentAppLanguageCode') ?? "vi";
    currentAppLanguageCode.value = appLang == "zh_Hant"
        ? "zh-TW"
        : appLang == "zh_Hans"
            ? "zh-CN"
            : appLang;

    // Set default bottom nav bar enabled
    if (!setBox.containsKey('isBottomNavBarEnabled')) {
      await setBox.put('isBottomNavBarEnabled', true);
    }
    isBottomNavBarEnabled.value = true;

    // Set default home screen content count
    if (!setBox.containsKey('noOfHomeScreenContent')) {
      await setBox.put('noOfHomeScreenContent', 7);
    }
    noOfHomeScreenContent.value = setBox.get("noOfHomeScreenContent") ?? 7;

    // Set default transition animation
    if (!setBox.containsKey('isTransitionAnimationDisabled')) {
      await setBox.put('isTransitionAnimationDisabled', false);
    }
    isTransitionAnimationDisabled.value =
        setBox.get("isTransitionAnimationDisabled") ?? false;

    // Set default cache songs
    if (!setBox.containsKey('cacheSongs')) {
      await setBox.put('cacheSongs', false);
    }
    cacheSongs.value = setBox.get('cacheSongs') ?? false;

    // Set default theme mode
    if (!setBox.containsKey('themeModeType')) {
      await setBox.put('themeModeType', 0);
    }
    themeModetype.value = ThemeType.values[setBox.get('themeModeType') ?? 0];

    // Set default skip silence and loudness normalization
    skipSilenceEnabled.value = false;
    loudnessNormalizationEnabled.value = false;

    // Set default auto open player
    if (!setBox.containsKey('autoOpenPlayer')) {
      await setBox.put('autoOpenPlayer', false);
    }
    autoOpenPlayer.value = (setBox.get("autoOpenPlayer") ?? false);

    // Set default restore playback session
    if (!setBox.containsKey('restrorePlaybackSession')) {
      await setBox.put('restrorePlaybackSession', true);
    }
    restorePlaybackSession.value =
        setBox.get("restrorePlaybackSession") ?? true;

    // Set default cache home screen data
    if (!setBox.containsKey('cacheHomeScreenData')) {
      await setBox.put('cacheHomeScreenData', true);
    }
    cacheHomeScreenData.value = setBox.get("cacheHomeScreenData") ?? true;

    // Set default streaming quality
    if (!setBox.containsKey('streamingQuality')) {
      await setBox.put('streamingQuality', AudioQuality.High.index);
    }
    streamingQuality.value =
        AudioQuality.values[setBox.get('streamingQuality')];

    // Set default player UI
    if (!setBox.containsKey('playerUi')) {
      await setBox.put('playerUi', 0);
    }
    playerUi.value = setBox.get('playerUi') ?? 0;

    // Set default background play
    if (!setBox.containsKey('backgroundPlayEnabled')) {
      await setBox.put('backgroundPlayEnabled', true);
    }
    backgroundPlayEnabled.value = setBox.get("backgroundPlayEnabled") ?? true;

    // Set default download location
    final downloadPath =
        setBox.get('downloadLocationPath') ?? await _createInAppSongDownDir();
    if (!setBox.containsKey('downloadLocationPath')) {
      await setBox.put('downloadLocationPath', downloadPath);
    }
    downloadLocationPath.value = downloadPath;

    // Set default export location
    if (!setBox.containsKey('exportLocationPath')) {
      await setBox.put('exportLocationPath', "/storage/emulated/0/Music");
    }
    exportLocationPath.value =
        setBox.get("exportLocationPath") ?? "/storage/emulated/0/Music";

    // Set default downloading format
    if (!setBox.containsKey('downloadingFormat')) {
      await setBox.put('downloadingFormat', "m4a");
    }
    downloadingFormat.value = setBox.get('downloadingFormat') ?? "m4a";

    // Set default discover content type
    if (!setBox.containsKey('discoverContentType')) {
      await setBox.put('discoverContentType', "BOLI");
    }
    discoverContentType.value = setBox.get('discoverContentType') ?? "BOLI";

    // Set default slidable action
    if (!setBox.containsKey('slidableActionEnabled')) {
      await setBox.put('slidableActionEnabled', true);
    }
    slidableActionEnabled.value = setBox.get('slidableActionEnabled') ?? true;

    // Piped login status (không set default vì liên quan đến login)
    if (setBox.containsKey("piped")) {
      isLinkedWithPiped.value = setBox.get("piped")['isLoggedIn'];
    }

    // Set default stop playback on swipe away
    if (!setBox.containsKey('stopPlyabackOnSwipeAway')) {
      await setBox.put('stopPlyabackOnSwipeAway', false);
    }
    stopPlyabackOnSwipeAway.value =
        setBox.get('stopPlyabackOnSwipeAway') ?? false;

    // Check battery optimization (Android only)
    if (GetPlatform.isAndroid) {
      isIgnoringBatteryOptimizations.value =
          (await Permission.ignoreBatteryOptimizations.isGranted);
    }

    // Set default auto download favorite songs
    if (!setBox.containsKey('autoDownloadFavoriteSongEnabled')) {
      await setBox.put('autoDownloadFavoriteSongEnabled', false);
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
    return (await getApplicationDocumentsDirectory()).path;
  }

  /// Check if Google is logged in by querying YouTube cookies
  Future<void> _checkGoogleLogin() async {
    try {
      final validCookies = await YouTubeCookieManager.getValidYouTubeCookies();
      isGoogleLoggedIn.value = validCookies.isNotEmpty;
    } catch (e) {
      printERROR('Error checking Google login status: $e');
      isGoogleLoggedIn.value = false;
    }
  }

  /// Login with Google using WebView
  Future<void> loginWithGoogle(BuildContext ctx) async {
    try {
      final result = await Get.to(() => const GoogleLoginWebView());
      if (result == true) {
        isGoogleLoggedIn.value = true;
      }
    } catch (e) {
      printERROR('Error during Google login: $e');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          snackbar(ctx, 'Error during Google login: $e'),
        );
      }
    }
  }

  /// Logout from Google by clearing YouTube cookies
  Future<void> logoutGoogle() async {
    try {
      await YouTubeCookieManager.clearAll();
      isGoogleLoggedIn.value = false;
    } catch (e) {
      printERROR('Error during Google logout: $e');
    }
  }
}
