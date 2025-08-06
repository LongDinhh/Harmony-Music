import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';
import '../../../utils/haptic_utils.dart';

/// Granular reactive widget for mini play/pause button
/// Listens only to buttonState reactive property from PlayerController
class MiniPlayPauseBtn extends StatelessWidget {
  const MiniPlayPauseBtn({
    super.key,
    this.iconSize = 35.0,
    this.color,
    this.backgroundColor,
    this.onTap,
    this.showBackground = false,
    this.borderRadius = 10.0,
  });

  final double iconSize;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBackground;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final buttonState = playerController.buttonState.value;

      Widget iconWidget;
      switch (buttonState) {
        case PlayButtonState.loading:
          iconWidget = SizedBox(
            width: iconSize * 0.6,
            height: iconSize * 0.6,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color ?? Theme.of(context).textTheme.titleMedium?.color,
            ),
          );
          break;
        case PlayButtonState.playing:
          iconWidget = Icon(
            Icons.pause,
            size: iconSize,
            color: color ?? Theme.of(context).textTheme.titleMedium?.color,
          );
          break;
        case PlayButtonState.paused:
          iconWidget = Icon(
            Icons.play_arrow,
            size: iconSize,
            color: color ?? Theme.of(context).textTheme.titleMedium?.color,
          );
          break;
      }

      final button = IconButton(
        onPressed: buttonState == PlayButtonState.loading
            ? null
            : () {
                HapticUtils.actionHaptic();
                if (onTap != null) {
                  onTap!();
                } else {
                  playerController.playPause();
                }
              },
        icon: iconWidget,
      );

      if (showBackground) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: button,
        );
      }

      return button;
    });
  }
}
