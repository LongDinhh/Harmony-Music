import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/player/player_controller.dart';

import 'image_widget.dart';
import 'snackbar.dart';
import 'songinfo_bottom_sheet.dart';

class UpNextQueue extends StatelessWidget {
  const UpNextQueue(
      {super.key,
      this.onReorderEnd,
      this.onReorderStart,
      this.isQueueInSlidePanel = true});
  final void Function(int)? onReorderStart;
  final void Function(int)? onReorderEnd;
  final bool isQueueInSlidePanel;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    return Container(
      key: const ValueKey('up_next_queue_container'),
      color: Theme.of(context).bottomSheetTheme.backgroundColor,
      child: Obx(() {
        final queueLength = playerController.currentQueue.length;
        return ReorderableListView.builder(
          key: ValueKey('queue_list_$queueLength'),
          footer: SizedBox(height: Get.mediaQuery.padding.bottom),
          scrollController:
              isQueueInSlidePanel ? playerController.scrollController : null,
          onReorder: (int oldIndex, int newIndex) {
            if (playerController.isShuffleModeEnabled.isTrue) {
              ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
                  Get.context!, "queuerearrangingDeniedMsg".tr,
                  size: SanckBarSize.BIG));
              return;
            }
            playerController.onReorder(oldIndex, newIndex);
          },
          onReorderStart: onReorderStart,
          onReorderEnd: onReorderEnd,
          itemCount: queueLength,
          padding: EdgeInsets.only(
              top: isQueueInSlidePanel ? 55 : 0,
              bottom: isQueueInSlidePanel ? 80 : 0),
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _QueueListItem(
              key: ValueKey(
                  'queue_item_${playerController.currentQueue[index].id}'),
              playerController: playerController,
              index: index,
              isQueueInSlidePanel: isQueueInSlidePanel,
            );
          },
        );
      }),
    );
  }
}

/// Optimized Queue List Item with granular rebuild
class _QueueListItem extends StatelessWidget {
  const _QueueListItem({
    super.key,
    required this.playerController,
    required this.index,
    required this.isQueueInSlidePanel,
  });

  final PlayerController playerController;
  final int index;
  final bool isQueueInSlidePanel;

  @override
  Widget build(BuildContext context) {
    final song = playerController.currentQueue[index];
    final homeScaffoldContext =
        playerController.homeScaffoldkey.currentContext!;

    return Material(
      key: Key('$index'),
      child: Obx(() {
        final isCurrentSong = playerController.currentSongIndex.value == index;
        return Dismissible(
          key: Key(song.id),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async => !isCurrentSong,
          onDismissed: (direction) {
            playerController.removeFromQueue(song);
          },
          child: ListTile(
            onTap: () {
              playerController.seekByIndex(index);
            },
            onLongPress: () {
              showModalBottomSheet(
                constraints: const BoxConstraints(maxWidth: 500),
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(10.0)),
                ),
                isScrollControlled: true,
                context: playerController.homeScaffoldkey.currentState!.context,
                barrierColor: Colors.transparent.withAlpha(100),
                builder: (context) => SongInfoBottomSheet(
                  song,
                  calledFromQueue: true,
                ),
              ).whenComplete(() => Get.delete<SongInfoController>());
            },
            contentPadding: EdgeInsets.only(
                top: 0,
                left: GetPlatform.isAndroid || GetPlatform.isIOS ? 30 : 0,
                right: 25),
            tileColor: isCurrentSong
                ? Theme.of(homeScaffoldContext).colorScheme.secondary
                : Theme.of(homeScaffoldContext)
                    .bottomSheetTheme
                    .backgroundColor,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (GetPlatform.isDesktop)
                  IconButton(
                      onPressed: () {
                        if (isCurrentSong) {
                          ScaffoldMessenger.of(context).showSnackBar(snackbar(
                              context, "songRemovedfromQueueCurrSong".tr,
                              size: SanckBarSize.BIG));
                        } else {
                          playerController.removeFromQueue(song);
                        }
                      },
                      icon: const Icon(Icons.close)),
                ImageWidget(
                  size: 50,
                  song: song,
                ),
              ],
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(homeScaffoldContext).textTheme.titleMedium,
            ),
            subtitle: Text(
              "${song.artist}",
              maxLines: 1,
              style: isCurrentSong
                  ? Theme.of(homeScaffoldContext)
                      .textTheme
                      .titleSmall!
                      .copyWith(
                          color: Theme.of(homeScaffoldContext)
                              .textTheme
                              .titleMedium!
                              .color!
                              .withValues(alpha: 0.35))
                  : Theme.of(homeScaffoldContext).textTheme.titleSmall,
            ),
            trailing: ReorderableDragStartListener(
              enabled: !GetPlatform.isDesktop,
              index: index,
              child: Container(
                padding: EdgeInsets.only(
                    right: (GetPlatform.isDesktop) ? 20 : 5, left: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!GetPlatform.isDesktop)
                      const Icon(
                        Icons.drag_handle,
                      ),
                    isCurrentSong
                        ? const Icon(
                            Icons.equalizer,
                            color: Colors.white,
                          )
                        : Text(
                            song.extras!['length'] ?? "",
                            style: Theme.of(homeScaffoldContext)
                                .textTheme
                                .titleSmall,
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
