import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/ui/screens/Home/home_screen_controller.dart';
import '/ui/screens/Settings/settings_screen_controller.dart';
import '../utils/helper.dart';
import '../ui/navigator.dart';
import '../ui/player/player.dart';
import 'player/player_controller.dart';
import 'widgets/combined_bottom_container.dart';
import 'widgets/sliding_up_panel.dart';

class Home extends StatelessWidget {
  const Home({super.key});
  static const routeName = '/appHome';
  @override
  Widget build(BuildContext context) {
    printINFO("Home");
    // Initialize UI controllers only when Home widget is built
    final PlayerController playerController =
        Get.put(PlayerController(), permanent: true);
    Get.put(SettingsScreenController(), permanent: true);
    final homeScreenController =
        Get.put(HomeScreenController(), permanent: true);
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (playerController.playerPanelController.isPanelOpen) {
          playerController.playerPanelController.close();
        } else {
          if (Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.canPop()) {
            Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop();
          } else {
            if (homeScreenController.tabIndex.value != 0) {
              homeScreenController.onBottonBarTabSelected(0);
            } else if (playerController.buttonState.value ==
                PlayButtonState.playing) {
              SystemNavigator.pop();
            } else {
              await Get.find<AudioHandler>().customAction("saveSession");
              exit(0);
            }
          }
        }
      },
      child: CallbackShortcuts(
        bindings: {
          LogicalKeySet(LogicalKeyboardKey.space): playerController.playPause
        },
        child: Scaffold(
            key: playerController.homeScaffoldkey,
            body: Stack(
              children: [
                _buildSlidingPanel(context, playerController, size),
                // Combined bottom container with blur effect
                const CombinedBottomContainer(),
              ],
            )),
      ),
    );
  }

// All navigation logic now handled by CombinedBottomContainer (mobile-only)

  Widget _buildSlidingPanel(BuildContext context,
      PlayerController playerController, Size size) {
    return SlidingUpPanel(
      onPanelSlide: playerController.panellistener,
      controller: playerController.playerPanelController,
      minHeight: 0, // No minimum height since mini player is now separate
      maxHeight: size.height,
      isDraggable: true, // Always draggable on mobile
      onSwipeUp: () {
        playerController.queuePanelController.open();
      },
      panel: const Player(),
      body: const ScreenNavigation(),
      // No header anymore - handled by CombinedBottomContainer
    );
  }
}
