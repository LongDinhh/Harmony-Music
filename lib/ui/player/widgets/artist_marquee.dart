import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '../player_controller.dart';
import '../../../utils/performance_testing.dart';

/// Granular reactive widget that displays current song artist with marquee effect
/// Listens only to currentSong reactive property from PlayerController
class ArtistMarquee extends StatelessWidget {
  const ArtistMarquee({
    super.key,
    this.style,
    this.maxLines = 1,
    this.onTap,
  });

  final TextStyle? style;
  final int maxLines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final currentSong = playerController.currentSong.value;
      final artist = currentSong?.artist ?? "";

      return GestureDetector(
        onTap: onTap,
        child: Marquee(
          id: "${currentSong?.id}_artist",
          delay: const Duration(milliseconds: 300),
          duration: const Duration(seconds: 5),
          child: Text(
            artist,
            maxLines: maxLines,
            style: style ?? Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );
    }).trackPerformance('ArtistMarquee_ObxWrapper');
  }
}
