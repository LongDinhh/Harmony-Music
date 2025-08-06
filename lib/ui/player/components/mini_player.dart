import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Settings/settings_screen_controller.dart';

import '/ui/widgets/lyrics_dialog.dart';
import '/ui/widgets/song_info_dialog.dart';
import '/ui/player/player_controller.dart';
import '../../widgets/add_to_playlist.dart';
import '../../widgets/sleep_timer_bottom_sheet.dart';
import '../../widgets/song_download_btn.dart';
import '../../widgets/glass_wrapper.dart';
import '../widgets/widgets.dart';
import '../../../utils/performance_testing.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWideScreen = size.width > 800;
    final bottomNavEnabled =
        Get.find<SettingsScreenController>().isBottomNavBarEnabled.isTrue;

    // Tiny Obx that only listens to visibility and opacity
    return Obx(() {
      final playerController = Get.find<PlayerController>();
      return Visibility(
        key: const ValueKey('mini_player_visibility'),
        visible: playerController.isPlayerpanelTopVisible.value,
        child: AnimatedOpacity(
          key: const ValueKey('mini_player_opacity'),
          opacity: playerController.playerPaneOpacity.value,
          duration: Duration.zero,
          child: _MiniPlayerContent(
            isWideScreen: isWideScreen,
            bottomNavEnabled: bottomNavEnabled,
            size: size,
          ).trackPerformance('MiniPlayer_MainContainer'),
        ),
      );
    }).trackPerformance('MiniPlayer_ObxWrapper');
  }
}

/// Non-reactive content widget - all dynamic elements are now granular reactive children
class _MiniPlayerContent extends StatelessWidget {
  const _MiniPlayerContent({
    required this.isWideScreen,
    required this.bottomNavEnabled,
    required this.size,
  });

  final bool isWideScreen;
  final bool bottomNavEnabled;
  final Size size;

  @override
  Widget build(BuildContext context) {
      return GlassWrapper(
        blurIntensity: 20,
        backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        opacity: 0.15,
        child: Obx(() {
          final playerController = Get.find<PlayerController>();
          final height = playerController.playerPanelMinHeight.value;

          return Container(
            height: height,
            width: size.width,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Progress bar section - granular reactive
                _buildProgressBar().trackPerformance('MiniPlayer_ProgressBar'),
                // Main content section
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 17.0, vertical: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Album artwork - granular reactive
                        _buildAlbumArt().trackPerformance('MiniPlayer_AlbumArt'),
                        const SizedBox(width: 10),
                        // Song info section - granular reactive
                        Expanded(child: _buildSongInfo(context).trackPerformance('MiniPlayer_SongInfo')),
                        // Player controls - granular reactive
                        _buildPlayerControls(context).trackPerformance('MiniPlayer_Controls'),
                        // Volume and extra controls for widescreen
                        if (isWideScreen && !bottomNavEnabled)
                          _buildWideScreenControls(context).trackPerformance('MiniPlayer_WideScreenControls'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).trackPerformance('MiniPlayer_ContentObx'),
      );
  }

  Widget _buildProgressBar() {
    return !isWideScreen || bottomNavEnabled
        ? const MiniProgressBar(height: 3)
        : const FullProgressBar();
  }

  Widget _buildAlbumArt() {
    return const CurrentSongImage(size: 50);
  }

  Widget _buildSongInfo(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! < 0) {
          playerController.next();
        } else if (details.primaryVelocity! > 0) {
          playerController.prev();
        }
      },
      onTap: () {
        playerController.playerPanelController.open();
      },
      child: ColoredBox(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              child: SongTitleMarquee(
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 20,
              child: ArtistMarquee(
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerControls(BuildContext context) {
    return Container(
      width: isWideScreen && !bottomNavEnabled ? 450 : 90,
      constraints: BoxConstraints(
        maxWidth: isWideScreen && !bottomNavEnabled ? 450 : 90,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWideScreen && !bottomNavEnabled)
            Row(
              children: [
                FavoriteIconBtn(
                  iconSize: 20,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
                ShuffleIconBtn(
                  iconSize: 20,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  inactiveColor: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.color
                      ?.withValues(alpha: 0.2),
                ),
              ],
            ),
          if (isWideScreen && !bottomNavEnabled) const PreviousButton(),
          // Play/pause button
          isWideScreen && !bottomNavEnabled
              ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: 58,
                  height: 58,
                  child: Center(
                    child: MiniPlayPauseBtn(
                      iconSize: isWideScreen ? 43 : 35,
                      showBackground: false,
                    ),
                  ),
                )
              : SizedBox.square(
                  dimension: 50,
                  child: Center(
                    child: MiniPlayPauseBtn(
                      iconSize: isWideScreen ? 43 : 35,
                    ),
                  ),
                ),
          const NextButton(),
          if (isWideScreen && !bottomNavEnabled)
            Row(
              children: [
                LoopModeIconBtn(
                  iconSize: 20,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  inactiveColor: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.color
                      ?.withValues(alpha: 0.2),
                ),
                IconButton(
                  iconSize: 20,
                  onPressed: () {
                    final playerController = Get.find<PlayerController>();
                    playerController.showLyrics();
                    showDialog(
                      builder: (context) => const LyricsDialog(),
                      context: context,
                    ).whenComplete(() {
                      playerController.isDesktopLyricsDialogOpen = false;
                      playerController.showLyricsflag.value = false;
                    });
                    playerController.isDesktopLyricsDialogOpen = true;
                  },
                  icon: Icon(
                    Icons.lyrics_outlined,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
          if (isWideScreen && !bottomNavEnabled) const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildWideScreenControls(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: size.width < 1004 ? 0 : 30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VolumeSlider(
              width: (size.width > 860) ? 220 : 180,
            ),
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      playerController.homeScaffoldkey.currentState!
                          .openEndDrawer();
                    },
                    icon: const Icon(Icons.queue_music),
                  ),
                  if (size.width > 860)
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Obx(() {
                        final isSleepTimerActive =
                            playerController.isSleepTimerActive.value;
                        return IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              constraints: const BoxConstraints(maxWidth: 500),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(10.0),
                                ),
                              ),
                              isScrollControlled: true,
                              context: playerController
                                  .homeScaffoldkey.currentState!.context,
                              barrierColor: Colors.transparent.withAlpha(100),
                              builder: (context) =>
                                  const SleepTimerBottomSheet(),
                            );
                          },
                          icon: Icon(
                            isSleepTimerActive
                                ? Icons.timer
                                : Icons.timer_outlined,
                          ),
                        );
                      }),
                    ),
                  const SizedBox(width: 10),
                  const SongDownloadButton(calledFromPlayer: true),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      final currentSong = playerController.currentSong.value;
                      if (currentSong != null) {
                        showDialog(
                          context: context,
                          builder: (context) => AddToPlaylist([currentSong]),
                        ).whenComplete(
                            () => Get.delete<AddToPlaylistController>());
                      }
                    },
                    icon: const Icon(Icons.playlist_add),
                  ),
                  if (size.width > 965)
                    IconButton(
                      onPressed: () {
                        final currentSong = playerController.currentSong.value;
                        if (currentSong != null) {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                SongInfoDialog(song: currentSong),
                          );
                        }
                      },
                      icon: const Icon(Icons.info, size: 22),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
