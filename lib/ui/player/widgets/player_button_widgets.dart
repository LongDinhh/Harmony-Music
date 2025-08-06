import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';

import '../player_controller.dart';

/// Optimized favorite button widget with granular reactivity
/// Listens only to isCurrentSongFav reactive property from PlayerController
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    this.iconSize = 20,
    this.color,
  });

  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() => Icon(
          playerController.isCurrentSongFav.isFalse
              ? Icons.favorite_border
              : Icons.favorite,
          size: iconSize,
          color: color ?? Theme.of(context).textTheme.titleMedium!.color,
        ));
  }
}

/// Optimized loop button widget with granular reactivity
/// Listens only to isLoopModeEnabled reactive property from PlayerController
class LoopButton extends StatelessWidget {
  const LoopButton({
    super.key,
    this.iconSize = 18,
    this.activeColor,
    this.inactiveColor,
  });

  final double iconSize;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() => Icon(
          Icons.all_inclusive,
          size: iconSize,
          color: playerController.isLoopModeEnabled.value
              ? activeColor ?? Theme.of(context).textTheme.titleLarge!.color
              : inactiveColor ??
                  Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .color!
                      .withValues(alpha: 0.2),
        ));
  }
}

/// Optimized shuffle button widget with granular reactivity
/// Listens only to isShuffleModeEnabled reactive property from PlayerController
class ShuffleButton extends StatelessWidget {
  const ShuffleButton({
    super.key,
    this.iconSize = 18,
    this.activeColor,
    this.inactiveColor,
  });

  final double iconSize;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() => Icon(
          Ionicons.shuffle,
          size: iconSize,
          color: playerController.isShuffleModeEnabled.value
              ? activeColor ?? Theme.of(context).textTheme.titleLarge!.color
              : inactiveColor ??
                  Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .color!
                      .withValues(alpha: 0.2),
        ));
  }
}
