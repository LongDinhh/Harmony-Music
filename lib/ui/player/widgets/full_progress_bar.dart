import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import '../player_controller.dart';

/// Granular reactive widget for full progress bar with labels and seek functionality
/// Listens only to progressBarStatus reactive property from PlayerController
class FullProgressBar extends StatelessWidget {
  const FullProgressBar({
    super.key,
    this.padding =
        const EdgeInsets.only(left: 15.0, top: 8, right: 15, bottom: 0),
    this.timeLabelLocation = TimeLabelLocation.sides,
    this.thumbRadius = 7,
    this.barHeight = 4,
    this.thumbGlowRadius = 15,
  });

  final EdgeInsets padding;
  final TimeLabelLocation timeLabelLocation;
  final double thumbRadius;
  final double barHeight;
  final double thumbGlowRadius;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final progressBarStatus = playerController.progressBarStatus.value;

      return Padding(
        padding: padding,
        child: ProgressBar(
          timeLabelLocation: timeLabelLocation,
          thumbRadius: thumbRadius,
          barHeight: barHeight,
          thumbGlowRadius: thumbGlowRadius,
          baseBarColor: Theme.of(context).sliderTheme.inactiveTrackColor,
          bufferedBarColor: Theme.of(context).sliderTheme.valueIndicatorColor,
          progressBarColor: Theme.of(context).sliderTheme.activeTrackColor,
          thumbColor: Theme.of(context).sliderTheme.thumbColor,
          timeLabelTextStyle: Theme.of(context).textTheme.titleMedium,
          progress: progressBarStatus.current,
          total: progressBarStatus.total,
          buffered: progressBarStatus.buffered,
          onSeek: playerController.seek,
        ),
      );
    });
  }
}
