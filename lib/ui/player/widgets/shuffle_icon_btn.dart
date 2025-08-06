import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';

import '../player_controller.dart';
import '../../../utils/haptic_utils.dart';

/// Granular reactive widget for shuffle icon button
/// Listens only to isShuffleModeEnabled reactive property from PlayerController
class ShuffleIconBtn extends StatelessWidget {
  const ShuffleIconBtn({
    super.key,
    this.iconSize = 24.0,
    this.color,
    this.inactiveColor,
    this.onTap,
  });

  final double iconSize;
  final Color? color;
  final Color? inactiveColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final isShuffleEnabled = playerController.isShuffleModeEnabled.value;

      return IconButton(
        iconSize: iconSize,
        onPressed: () {
          HapticUtils.actionHaptic();
          if (onTap != null) {
            onTap!();
          } else {
            playerController.toggleShuffleMode();
          }
        },
        icon: Icon(
          Ionicons.shuffle,
          color: isShuffleEnabled
              ? (color ?? Theme.of(context).textTheme.titleLarge?.color)
              : (inactiveColor ??
                  Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.color
                      ?.withValues(alpha: 0.2)),
        ),
      );
    });
  }
}
