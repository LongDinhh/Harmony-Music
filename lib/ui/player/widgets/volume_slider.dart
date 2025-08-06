import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';

/// Granular reactive widget for volume slider
/// Listens only to volume reactive property from PlayerController
class VolumeSlider extends StatelessWidget {
  const VolumeSlider({
    super.key,
    this.width = 220,
    this.iconSize = 20,
  });

  final double width;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final volume = playerController.volume.value;

      return Container(
        padding: const EdgeInsets.only(right: 20, left: 10),
        height: 20,
        width: width,
        child: Row(
          children: [
            SizedBox(
              width: iconSize,
              child: InkWell(
                onTap: playerController.mute,
                child: Icon(
                  volume == 0
                      ? Icons.volume_off
                      : volume > 0 && volume < 50
                          ? Icons.volume_down
                          : Icons.volume_up,
                  size: iconSize,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 10.0,
                  ),
                ),
                child: Slider(
                  value: volume / 100,
                  onChanged: (value) {
                    playerController.setVolume((value * 100).toInt());
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
