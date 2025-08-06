import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';

/// Granular reactive widget that displays the current queue length
/// Listens only to currentQueue reactive property from PlayerController
class QueueLengthLabel extends StatelessWidget {
  const QueueLengthLabel({
    super.key,
    this.style,
    this.prefix = "",
    this.suffix = "",
    this.onTap,
  });

  final TextStyle? style;
  final String prefix;
  final String suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final queueLength = playerController.currentQueue.length;
      final displayText = "$prefix$queueLength$suffix";

      return GestureDetector(
        onTap: onTap,
        child: Text(
          displayText,
          style: style ?? Theme.of(context).textTheme.bodyMedium,
        ),
      );
    });
  }
}
