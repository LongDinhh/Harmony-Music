import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';
import '../../../utils/haptic_utils.dart';

/// Granular reactive widget for favorite icon button
/// Listens only to isCurrentSongFav reactive property from PlayerController
class FavoriteIconBtn extends StatelessWidget {
  const FavoriteIconBtn({
    super.key,
    this.iconSize = 24.0,
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
      final isFavorite = playerController.isCurrentSongFav.value;

      return IconButton(
        iconSize: iconSize,
        onPressed: () {
          HapticUtils.actionHaptic();
          if (onTap != null) {
            onTap!();
          } else {
            playerController.toggleFavourite();
          }
        },
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: color ?? Theme.of(context).textTheme.titleMedium?.color,
        ),
      );
    });
  }
}
