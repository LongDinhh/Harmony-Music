import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/Search/search_result_screen_controller.dart';
import '/ui/widgets/content_list_widget_item.dart';
import '/ui/widgets/quickpickswidget.dart';
import '/models/quick_picks.dart';

class ContentListWidget extends StatelessWidget {
  ///ContentListWidget is used to render a section of Content like a list of Albums, Playlists, or Songs in HomeScreen
  const ContentListWidget(
      {super.key,
      this.content,
      this.isHomeContent = true,
      this.scrollController});

  ///content will be of class Type AlbumContent, PlaylistContent, or QuickPicks
  final dynamic content;
  final bool isHomeContent;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final isAlbumContent = content.runtimeType.toString() == "AlbumContent";
    final isQuickPicks = content.runtimeType.toString() == "QuickPicks";
    
    // Nếu là QuickPicks, sử dụng QuickPicksWidget
    if (isQuickPicks) {
      return QuickPicksWidget(
        content: content as QuickPicks,
        scrollController: scrollController,
      );
    }
    
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    !isHomeContent && content.title.length > 12
                        ? "${content.title.substring(0, 12)}..."
                        : content.title,
                    //maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (!isHomeContent)
                  TextButton(
                      onPressed: () {
                        final scrresController =
                            Get.find<SearchResultScreenController>();
                        scrresController.viewAllCallback(content.title);
                      },
                      child: Text("viewAll".tr,
                          style: Theme.of(Get.context!).textTheme.titleSmall))
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 200,
            //color: Colors.blueAccent,
            child: Scrollbar(
              thickness: GetPlatform.isDesktop ? null : 0,
              controller: scrollController,
              child: ListView.separated(
                  controller: scrollController,
                  addAutomaticKeepAlives: false, //Testing going
                  addRepaintBoundaries: false, //on this
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (context, index) => const SizedBox(
                        width: 15,
                      ),
                  scrollDirection: Axis.horizontal,
                  itemCount: isAlbumContent
                      ? content.albumList.length
                      : content.playlistList.length,
                  itemBuilder: (_, index) {
                    if (isAlbumContent) {
                      return ContentListItem(content: content.albumList[index]);
                    }
                    return ContentListItem(
                        content: content.playlistList[index]);
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
