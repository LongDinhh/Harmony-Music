import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';
import '../../../utils/haptic_utils.dart';

/// Granular reactive widget for next button
/// Listens to currentQueue, currentSong, isShuffleModeEnabled, and isQueueLoopModeEnabled
class NextButton extends StatelessWidget {
  const NextButton({
    super.key,
    this.iconSize = 35,
    this.color,
    this.onTap,
  });

  final double iconSize;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final currentQueue = playerController.currentQueue;
      final currentSong = playerController.currentSong.value;
      final isShuffleEnabled = playerController.isShuffleModeEnabled.value;
      final isQueueLoopEnabled = playerController.isQueueLoopModeEnabled.value;

      final isLastSong = currentQueue.isEmpty ||
          (!(isShuffleEnabled || isQueueLoopEnabled) &&
              (currentQueue.last.id == currentSong?.id));

      return SizedBox(
        width: 40,
        child: InkWell(
          onTap: isLastSong
              ? null
              : () {
                  HapticUtils.actionHaptic();
                  if (onTap != null) {
                    onTap!();
                  } else {
                    playerController.next();
                  }
                },
          child: Icon(
            Icons.skip_next,
            color: isLastSong
                ? (color ?? Theme.of(context).textTheme.titleLarge?.color)
                    ?.withValues(alpha: 0.2)
                : color ?? Theme.of(context).textTheme.titleMedium?.color,
            size: iconSize,
          ),
        ),
      );
    });
  }
}
