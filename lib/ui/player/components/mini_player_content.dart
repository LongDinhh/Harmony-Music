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

/// Container widget that manages the mini player height reactively
class _MiniPlayerContainer extends StatelessWidget {
  const _MiniPlayerContainer({
    required this.child,
    required this.width,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() => Container(
          height: playerController.playerPanelMinHeight.value,
          width: width,
          color: Colors.transparent,
          child: child,
        ));
  }
}

/// Granular reactive widget for progress bar
class _MiniProgressBarWidget extends StatelessWidget {
  const _MiniProgressBarWidget({
    required this.isWideScreen,
    required this.bottomNavEnabled,
    required this.hasBottomNav,
    required this.isTop,
  });

  final bool isWideScreen;
  final bool bottomNavEnabled;
  final bool hasBottomNav;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return RepaintBoundary(
      child: !isWideScreen || bottomNavEnabled
          ? Obx(() => Container(
                height: 2,
                margin: EdgeInsets.only(
                  top: isTop ? 0 : 0,
                  bottom: isTop ? 0 : 0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: isTop ? const Radius.circular(16) : Radius.zero,
                    bottom: !isTop ? const Radius.circular(16) : Radius.zero,
                  ),
                  color: Theme.of(context).progressIndicatorTheme.color,
                ),
                clipBehavior: Clip.antiAlias,
                child: MiniPlayerProgressBar(
                  progressBarStatus: playerController.progressBarStatus.value,
                  progressBarColor: Theme.of(context)
                          .progressIndicatorTheme
                          .linearTrackColor ??
                      Colors.white,
                ),
              ))
          : Obx(() => Container(
                height: 2,
                margin: EdgeInsets.only(
                  top: isTop ? 0 : 0,
                  bottom: isTop ? 0 : 0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: isTop ? const Radius.circular(16) : Radius.zero,
                    bottom: !isTop ? const Radius.circular(16) : Radius.zero,
                  ),
                  color: Theme.of(context).sliderTheme.inactiveTrackColor,
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: ProgressBar(
                  timeLabelLocation: TimeLabelLocation.none,
                  thumbRadius: 3,
                  barHeight: 2,
                  thumbGlowRadius: 6,
                  baseBarColor: Colors.transparent,
                  bufferedBarColor:
                      Theme.of(context).sliderTheme.valueIndicatorColor,
                  progressBarColor:
                      Theme.of(context).sliderTheme.activeTrackColor,
                  thumbColor: Theme.of(context).sliderTheme.thumbColor,
                  progress: playerController.progressBarStatus.value.current,
                  total: playerController.progressBarStatus.value.total,
                  buffered: playerController.progressBarStatus.value.buffered,
                  onSeek: playerController.seek,
                ),
              )),
    );
  }
}

/// Granular reactive widget for song info
class _SongInfoWidget extends StatelessWidget {
  const _SongInfoWidget();

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Expanded(
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
          child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                    child: Text(
                      playerController.currentSong.value != null
                          ? playerController.currentSong.value!.title
                          : "",
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium,
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
                            ? playerController.currentSong.value!.artist!
                            : "",
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}

/// Granular reactive widget for next button
class _NextButtonWidget extends StatelessWidget {
  const _NextButtonWidget();

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return SizedBox(
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
    );
  }
}

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

    // Get bottom nav state without wrapping in Obx at top level
    final homeController = Get.find<HomeScreenController>();

    return Obx(() {
      final currentRoute = homeController.currentRoute.value;
      final isInHomeScreenContext = currentRoute == '/homeScreen';
      final hasBottomNav = bottomNavEnabled && isInHomeScreenContext;

      return _MiniPlayerContainer(
        width: size.width,
        child: Column(
          mainAxisAlignment: hasBottomNav
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.start,
          children: [
            // Progress Bar - top position when no bottom nav
            if (!hasBottomNav)
              _MiniProgressBarWidget(
                isWideScreen: isWideScreen,
                bottomNavEnabled: bottomNavEnabled,
                hasBottomNav: hasBottomNav,
                isTop: true,
              ),

            // Main Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 17.0, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Album Art with RepaintBoundary
                    RepaintBoundary(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Obx(() => playerController.currentSong.value != null
                              ? ImageWidget(
                                  size: 50,
                                  song: playerController.currentSong.value!,
                                )
                              : const SizedBox(height: 50, width: 50)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Song Info - now using granular widget
                    const _SongInfoWidget(),

                    // Player Controls - now using granular widgets
                    _buildPlayerControls(context, isWideScreen,
                        bottomNavEnabled, playerController, size),
                  ],
                ),
              ),
            ),

            // Progress Bar - bottom position when has bottom nav
            if (hasBottomNav)
              _MiniProgressBarWidget(
                isWideScreen: isWideScreen,
                bottomNavEnabled: bottomNavEnabled,
                hasBottomNav: hasBottomNav,
                isTop: false,
              ),
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
                  icon: const _FavoriteIcon(),
                ),
                IconButton(
                  iconSize: 20,
                  onPressed: () {
                    HapticUtils.actionHaptic();
                    playerController.toggleShuffleMode();
                  },
                  icon: const _ShuffleIcon(),
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

          // Next button - now using granular widget
          const _NextButtonWidget(),

          // Desktop controls (right side)
          if (isWideScreen && !bottomNavEnabled) ...[
            Row(
              children: [
                IconButton(
                  iconSize: 20,
                  onPressed: playerController.toggleLoopMode,
                  icon: const _LoopIcon(),
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

/// Optimized favorite icon widget with granular reactivity
class _FavoriteIcon extends StatelessWidget {
  const _FavoriteIcon();

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() => Icon(
          playerController.isCurrentSongFav.isFalse
              ? Icons.favorite_border
              : Icons.favorite,
          color: Theme.of(context).textTheme.titleMedium!.color,
        ));
  }
}

/// Optimized shuffle icon widget with granular reactivity
class _ShuffleIcon extends StatelessWidget {
  const _ShuffleIcon();

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() => Icon(
          Ionicons.shuffle,
          color: playerController.isShuffleModeEnabled.value
              ? Theme.of(context).textTheme.titleLarge!.color
              : Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .color!
                  .withValues(alpha: 0.2),
        ));
  }
}

/// Optimized loop icon widget with granular reactivity
class _LoopIcon extends StatelessWidget {
  const _LoopIcon();

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() => Icon(
          Icons.all_inclusive,
          color: playerController.isLoopModeEnabled.value
              ? Theme.of(context).textTheme.titleLarge!.color
              : Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .color!
                  .withValues(alpha: 0.2),
        ));
  }
}
