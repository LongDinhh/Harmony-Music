import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';
import '../../../utils/haptic_utils.dart';

/// Granular reactive widget for loop mode icon button
/// Listens only to isLoopModeEnabled reactive property from PlayerController
class LoopModeIconBtn extends StatelessWidget {
  const LoopModeIconBtn({
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
      final isLoopEnabled = playerController.isLoopModeEnabled.value;

      return IconButton(
        iconSize: iconSize,
        onPressed: () {
          HapticUtils.actionHaptic();
          if (onTap != null) {
            onTap!();
          } else {
            playerController.toggleLoopMode();
          }
        },
        icon: Icon(
          Icons.all_inclusive,
          color: isLoopEnabled
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
