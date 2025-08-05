import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Settings/settings_screen_controller.dart';
import 'package:ionicons/ionicons.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '/ui/widgets/lyrics_dialog.dart';
import '/ui/player/player_controller.dart';
import '../../widgets/image_widget.dart';
import '../../widgets/mini_player_progress_bar.dart';
import 'animated_play_button.dart';
import '../../../utils/haptic_utils.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen_controller.dart';

/// Pure content of mini player without GlassWrapper
/// Used inside CombinedBottomContainer
class MiniPlayerContent extends StatelessWidget {
  const MiniPlayerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final size = MediaQuery.sizeOf(context);
    final isWideScreen = size.width > 800;
    final bottomNavEnabled =
        Get.find<SettingsScreenController>().isBottomNavBarEnabled.isTrue;

    return Obx(() {
      // Kiểm tra xem có đang ở màn hình có bottom nav bar không
      final homeController = Get.find<HomeScreenController>();
      final currentRoute = homeController.currentRoute.value;
      final isInHomeScreenContext = currentRoute == '/homeScreen';
      final hasBottomNav = bottomNavEnabled && isInHomeScreenContext;

      return Container(
        height: playerController.playerPanelMinHeight.value,
        width: size.width,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: hasBottomNav
              ? MainAxisAlignment
                  .spaceBetween // Progress bar ở bottom khi có bottom nav
              : MainAxisAlignment
                  .start, // Progress bar ở top khi không có bottom nav
          children: [
            // Progress Bar - đặt ở top khi không có bottom nav
            if (!hasBottomNav) ...[
              !isWideScreen || bottomNavEnabled
                  ? GetX<PlayerController>(
                      builder: (controller) => Container(
                          height: 2,
                          margin: const EdgeInsets.only(top: 0),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            color:
                                Theme.of(context).progressIndicatorTheme.color,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: MiniPlayerProgressBar(
                              progressBarStatus:
                                  controller.progressBarStatus.value,
                              progressBarColor: Theme.of(context)
                                      .progressIndicatorTheme
                                      .linearTrackColor ??
                                  Colors.white)),
                    )
                  : GetX<PlayerController>(builder: (controller) {
                      return Container(
                        height: 2,
                        margin: const EdgeInsets.only(top: 0),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          color:
                              Theme.of(context).sliderTheme.inactiveTrackColor,
                        ),
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: ProgressBar(
                          timeLabelLocation: TimeLabelLocation.none,
                          thumbRadius: 3,
                          barHeight: 2,
                          thumbGlowRadius: 6,
                          baseBarColor: Colors
                              .transparent, // Để tránh xung đột với container color
                          bufferedBarColor:
                              Theme.of(context).sliderTheme.valueIndicatorColor,
                          progressBarColor:
                              Theme.of(context).sliderTheme.activeTrackColor,
                          thumbColor: Theme.of(context).sliderTheme.thumbColor,
                          progress: controller.progressBarStatus.value.current,
                          total: controller.progressBarStatus.value.total,
                          buffered: controller.progressBarStatus.value.buffered,
                          onSeek: controller.seek,
                        ),
                      );
                    }),
            ],

            // Main Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 17.0, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Album Art
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        playerController.currentSong.value != null
                            ? ImageWidget(
                                size: 50,
                                song: playerController.currentSong.value!,
                              )
                            : const SizedBox(height: 50, width: 50),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Song Info
                    Expanded(
                      child: GestureDetector(
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
                                child: Text(
                                  playerController.currentSong.value != null
                                      ? playerController
                                          .currentSong.value!.title
                                      : "",
                                  maxLines: 1,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                                child: Marquee(
                                  id: "${playerController.currentSong.value}_mini",
                                  delay: const Duration(milliseconds: 300),
                                  duration: const Duration(seconds: 5),
                                  child: Text(
                                    playerController.currentSong.value != null
                                        ? playerController
                                            .currentSong.value!.artist!
                                        : "",
                                    maxLines: 1,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Player Controls
                    _buildPlayerControls(context, isWideScreen,
                        bottomNavEnabled, playerController, size),
                  ],
                ),
              ),
            ),

            // Progress Bar - đặt ở bottom khi có bottom nav
            if (hasBottomNav) ...[
              !isWideScreen || bottomNavEnabled
                  ? GetX<PlayerController>(
                      builder: (controller) => Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 0),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                            color:
                                Theme.of(context).progressIndicatorTheme.color,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: MiniPlayerProgressBar(
                              progressBarStatus:
                                  controller.progressBarStatus.value,
                              progressBarColor: Theme.of(context)
                                      .progressIndicatorTheme
                                      .linearTrackColor ??
                                  Colors.white)),
                    )
                  : GetX<PlayerController>(builder: (controller) {
                      return Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 0),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                          color:
                              Theme.of(context).sliderTheme.inactiveTrackColor,
                        ),
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: ProgressBar(
                          timeLabelLocation: TimeLabelLocation.none,
                          thumbRadius: 3,
                          barHeight: 2,
                          thumbGlowRadius: 6,
                          baseBarColor: Colors
                              .transparent, // Để tránh xung đột với container color
                          bufferedBarColor:
                              Theme.of(context).sliderTheme.valueIndicatorColor,
                          progressBarColor:
                              Theme.of(context).sliderTheme.activeTrackColor,
                          thumbColor: Theme.of(context).sliderTheme.thumbColor,
                          progress: controller.progressBarStatus.value.current,
                          total: controller.progressBarStatus.value.total,
                          buffered: controller.progressBarStatus.value.buffered,
                          onSeek: controller.seek,
                        ),
                      );
                    }),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildPlayerControls(BuildContext context, bool isWideScreen,
      bool bottomNavEnabled, PlayerController playerController, Size size) {
    return Container(
      width: isWideScreen && !bottomNavEnabled ? 450 : 90,
      constraints: BoxConstraints(
        maxWidth: isWideScreen && !bottomNavEnabled ? 450 : 90,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Desktop controls (left side)
          if (isWideScreen && !bottomNavEnabled) ...[
            Row(
              children: [
                IconButton(
                  iconSize: 20,
                  onPressed: () {
                    HapticUtils.actionHaptic();
                    playerController.toggleFavourite();
                  },
                  icon: Obx(() => Icon(
                        playerController.isCurrentSongFav.isFalse
                            ? Icons.favorite_border
                            : Icons.favorite,
                        color: Theme.of(context).textTheme.titleMedium!.color,
                      )),
                ),
                IconButton(
                  iconSize: 20,
                  onPressed: () {
                    HapticUtils.actionHaptic();
                    playerController.toggleShuffleMode();
                  },
                  icon: Obx(() => Icon(
                        Ionicons.shuffle,
                        color: playerController.isShuffleModeEnabled.value
                            ? Theme.of(context).textTheme.titleLarge!.color
                            : Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .color!
                                .withValues(alpha: 0.2),
                      )),
                ),
              ],
            ),

            // Previous button
            SizedBox(
              width: 40,
              child: InkWell(
                onTap: (playerController.currentQueue.isEmpty ||
                        (playerController.currentQueue.first.id ==
                            playerController.currentSong.value?.id))
                    ? null
                    : () {
                        HapticUtils.actionHaptic();
                        playerController.prev();
                      },
                child: Icon(
                  Icons.skip_previous,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                  size: 35,
                ),
              ),
            ),
          ],

          // Play/Pause button
          isWideScreen && !bottomNavEnabled
              ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: 58,
                  height: 58,
                  child: Center(
                    child: AnimatedPlayButton(iconSize: isWideScreen ? 43 : 35),
                  ),
                )
              : SizedBox.square(
                  dimension: 50,
                  child: Center(
                    child: AnimatedPlayButton(iconSize: isWideScreen ? 43 : 35),
                  ),
                ),

          // Next button
          SizedBox(
            width: 40,
            child: Obx(() {
              final isLastSong = playerController.currentQueue.isEmpty ||
                  (!(playerController.isShuffleModeEnabled.isTrue ||
                          playerController.isQueueLoopModeEnabled.isTrue) &&
                      (playerController.currentQueue.last.id ==
                          playerController.currentSong.value?.id));
              return InkWell(
                onTap: isLastSong
                    ? null
                    : () {
                        HapticUtils.actionHaptic();
                        playerController.next();
                      },
                child: Icon(
                  Icons.skip_next,
                  color: isLastSong
                      ? Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .color!
                          .withValues(alpha: 0.2)
                      : Theme.of(context).textTheme.titleMedium!.color,
                  size: 35,
                ),
              );
            }),
          ),

          // Desktop controls (right side)
          if (isWideScreen && !bottomNavEnabled) ...[
            Row(
              children: [
                IconButton(
                  iconSize: 20,
                  onPressed: playerController.toggleLoopMode,
                  icon: Icon(
                    Icons.all_inclusive,
                    color: playerController.isLoopModeEnabled.value
                        ? Theme.of(context).textTheme.titleLarge!.color
                        : Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .color!
                            .withValues(alpha: 0.2),
                  ),
                ),
                IconButton(
                  iconSize: 20,
                  onPressed: () {
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
                    color: Theme.of(context).textTheme.titleLarge!.color,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
          ],
        ],
      ),
    );
  }
}
