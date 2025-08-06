import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';

/// Granular reactive widget for queue loop button
/// Listens only to isQueueLoopModeEnabled reactive property from PlayerController
class QueueLoopBtn extends StatelessWidget {
  const QueueLoopBtn({
    super.key,
    this.height = 30,
    this.padding = const EdgeInsets.symmetric(horizontal: 15),
    this.borderRadius = 20,
    this.activeColor,
    this.inactiveColor,
    this.textStyle,
    this.onTap,
  });

  final double height;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? activeColor;
  final Color? inactiveColor;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return InkWell(
      onTap: onTap ?? () => playerController.toggleQueueLoopMode(),
      child: Obx(() {
        final isQueueLoopEnabled =
            playerController.isQueueLoopModeEnabled.value;

        return Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: isQueueLoopEnabled
                ? (activeColor ?? Colors.white.withValues(alpha: 0.8))
                : (inactiveColor ?? Colors.white24),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Center(
            child: Text(
              "queueLoop".tr,
              style: textStyle,
            ),
          ),
        );
      }),
    );
  }
}
