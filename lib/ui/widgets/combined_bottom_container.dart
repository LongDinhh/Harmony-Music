import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen_controller.dart';
import 'package:harmonymusic/ui/screens/Settings/settings_screen_controller.dart';
import 'package:harmonymusic/ui/player/player_controller.dart';
// import 'package:harmonymusic/utils/helper.dart'; // Không còn cần thiết
import 'glass_wrapper.dart';
import 'bottom_nav_bar_content.dart';
import '../player/components/mini_player_content.dart';

/// Combined container that holds both MiniPlayer and BottomNavBar
/// with shared glass blur effect
class CombinedBottomContainer extends StatelessWidget {
  const CombinedBottomContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();
    final homeController = Get.find<HomeScreenController>();
    final playerController = Get.find<PlayerController>();

    return _CombinedBottomContainerContent(
      key: const ValueKey('combined_bottom_container_content'),
      settingsController: settingsController,
      homeController: homeController,
      playerController: playerController,
    );
  }
}

/// Optimized Content widget with granular state management
class _CombinedBottomContainerContent extends StatelessWidget {
  const _CombinedBottomContainerContent({
    super.key,
    required this.settingsController,
    required this.homeController,
    required this.playerController,
  });

  final SettingsScreenController settingsController;
  final HomeScreenController homeController;
  final PlayerController playerController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Check if keyboard is open using KeyboardVisibilityController from PlayerController
      final isKeyboardOpen = playerController.isKeyboardVisible.value;

      // Check current route to hide nav bar in album/playlist screens (reactive!)
      final currentRoute = homeController.currentRoute.value;
      final isInHomeScreenContext = currentRoute == '/homeScreen';

      // Check if we should show the container at all
      final shouldShowMiniPlayer = playerController
              .isPlayerpanelTopVisible.value &&
          !isKeyboardOpen; // Ẩn mini player khi keyboard mở để tránh che khuất nội dung

      final shouldShowBottomNav = settingsController
              .isBottomNavBarEnabled.isTrue &&
          isInHomeScreenContext && // Chỉ hiện khi ở trong HomeScreen context (không phải album/playlist)
          homeController.tabIndex.value !=
              1 && // Ẩn nav bar ở tab Search (index 1)
          playerController.isPanelGTHOpened.isFalse &&
          !isKeyboardOpen; // Ẩn nav bar khi keyboard mở

      // If neither should show, return empty
      if (!shouldShowMiniPlayer && !shouldShowBottomNav) {
        return const SizedBox.shrink();
      }

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        left: 0,
        right: 0,
        bottom: shouldShowBottomNav
            ? 0
            : -80, // Slide down when bottom nav hidden (bottom nav height ~80px)
        child: _OpacityWrapper(
          playerController: playerController,
          child: GlassWrapper(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            backgroundColor:
                Theme.of(context).bottomSheetTheme.backgroundColor ??
                    Theme.of(context).primaryColor,
            opacity: 0.15,
            blurIntensity: 20,
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mini Player (no need for separate animation now)
                  if (shouldShowMiniPlayer) const MiniPlayerContent(),

                  // Bottom Nav Bar with fade animation only (container handles positioning)
                  _BottomNavWrapper(
                    shouldShowBottomNav: shouldShowBottomNav,
                    settingsController: settingsController,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Separate opacity wrapper to minimize rebuilds
class _OpacityWrapper extends StatelessWidget {
  const _OpacityWrapper({
    required this.playerController,
    required this.child,
  });

  final PlayerController playerController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedOpacity(
          opacity: playerController.playerPaneOpacity.value,
          duration: Duration.zero,
          child: child,
        ));
  }
}

/// Separate bottom nav wrapper to minimize rebuilds
class _BottomNavWrapper extends StatelessWidget {
  const _BottomNavWrapper({
    required this.shouldShowBottomNav,
    required this.settingsController,
  });

  final bool shouldShowBottomNav;
  final SettingsScreenController settingsController;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: shouldShowBottomNav ? 1.0 : 0.0,
      child:
          shouldShowBottomNav || settingsController.isBottomNavBarEnabled.isTrue
              ? const BottomNavBarContent()
              : const SizedBox.shrink(),
    );
  }
}
