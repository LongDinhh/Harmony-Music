import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';
import '../../widgets/image_widget.dart';
import '../../../utils/performance_testing.dart';

/// Granular reactive widget for current song album artwork
/// Listens only to currentSong reactive property from PlayerController
class CurrentSongImage extends StatelessWidget {
  const CurrentSongImage({
    super.key,
    this.size = 50,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final currentSong = playerController.currentSong.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          currentSong != null
              ? ImageWidget(size: size, song: currentSong)
              : SizedBox(height: size, width: size),
        ],
      );
    }).trackPerformance('CurrentSongImage_ObxWrapper');
  }
}
