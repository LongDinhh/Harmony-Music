import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';
import '../../widgets/mini_player_progress_bar.dart';
import '../../../utils/performance_testing.dart';

/// Granular reactive widget for mini player progress bar
/// Listens only to progressBarStatus reactive property from PlayerController
class MiniProgressBar extends StatelessWidget {
  const MiniProgressBar({
    super.key,
    this.height = 3,
    this.color,
  });

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final progressBarStatus = playerController.progressBarStatus.value;
      final progressBarColor = color ??
          Theme.of(context).progressIndicatorTheme.linearTrackColor ??
          Colors.white;

      return Container(
        height: height,
        color: Theme.of(context).progressIndicatorTheme.color,
        child: MiniPlayerProgressBar(
          progressBarStatus: progressBarStatus,
          progressBarColor: progressBarColor,
        ),
      );
    }).trackPerformance('MiniProgressBar_ObxWrapper');
  }
}
