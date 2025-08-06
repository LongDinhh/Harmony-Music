import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';
import '../../../utils/haptic_utils.dart';

/// Granular reactive widget for previous button
/// Listens to currentQueue and currentSong
class PreviousButton extends StatelessWidget {
  const PreviousButton({
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

      final isFirstSong =
          currentQueue.isEmpty || (currentQueue.first.id == currentSong?.id);

      return SizedBox(
        width: 40,
        child: InkWell(
          onTap: isFirstSong
              ? null
              : () {
                  HapticUtils.actionHaptic();
                  if (onTap != null) {
                    onTap!();
                  } else {
                    playerController.prev();
                  }
                },
          child: Icon(
            Icons.skip_previous,
            color: color ?? Theme.of(context).textTheme.titleMedium?.color,
            size: iconSize,
          ),
        ),
      );
    });
  }
}
