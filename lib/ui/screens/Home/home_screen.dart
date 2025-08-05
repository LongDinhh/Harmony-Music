import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/widgets/animated_screen_transition.dart';
import '../Library/library_combined.dart';
import '../Search/search_screen.dart';
import '../Settings/settings_screen_controller.dart';
import '/ui/player/player_controller.dart';
import '/ui/widgets/create_playlist_dialog.dart';
import '../../navigator.dart';
import '../../widgets/content_list_widget.dart';
import '../../widgets/quickpickswidget.dart';
import '../../widgets/shimmer_widgets/home_shimmer.dart';
import '../../widgets/home_search_bar.dart';
import '../../widgets/category_buttons.dart';
import 'home_screen_controller.dart';
import '../Settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    final HomeScreenController homeScreenController =
        Get.find<HomeScreenController>();
    final SettingsScreenController settingsScreenController =
        Get.find<SettingsScreenController>();

    return Scaffold(
        floatingActionButton: _buildFloatingActionButton(context,
            homeScreenController, settingsScreenController, playerController),
        body: _buildBody(settingsScreenController, homeScreenController));
  }
}

Widget _buildFloatingActionButton(
    BuildContext context,
    HomeScreenController homeScreenController,
    SettingsScreenController settingsScreenController,
    PlayerController playerController) {
  return Obx(() {
    final showFAB = (homeScreenController.tabIndex.value == 0 ||
            homeScreenController.tabIndex.value == 2) &&
        false;

    if (!showFAB) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
          bottom: playerController.playerPanelMinHeight.value >
                  MediaQuery.paddingOf(context).bottom
              ? playerController.playerPanelMinHeight.value -
                  MediaQuery.paddingOf(context).bottom
              : playerController.playerPanelMinHeight.value),
      child: SizedBox(
        height: 60,
        width: 60,
        child: FittedBox(
          child: FloatingActionButton(
              focusElevation: 0,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14))),
              elevation: 0,
              onPressed: () async {
                if (homeScreenController.tabIndex.value == 2) {
                  showDialog(
                      context: Get.context!,
                      builder: (context) => const CreateNRenamePlaylistPopup());
                } else {
                  Get.toNamed(ScreenNavigationSetup.searchScreen,
                      id: ScreenNavigationSetup.id);
                }
              },
              child: Icon(homeScreenController.tabIndex.value == 2
                  ? Icons.add
                  : Icons.search)),
        ),
      ),
    );
  });
}

Widget _buildBody(SettingsScreenController settingsScreenController,
    HomeScreenController homeScreenController) {
  return Obx(() => AnimatedScreenTransition(
        enabled: settingsScreenController.isTransitionAnimationDisabled.isFalse,
        resverse: homeScreenController.reverseAnimationtransiton,
        horizontalTransition:
            true,
        child: Center(
          key: ValueKey<int>(homeScreenController.tabIndex.value),
          child: const Body(),
        ),
      ));
}

List<Widget> getWidgetList(
    dynamic list, HomeScreenController homeScreenController) {
  return list
      .map((content) {
        final scrollController =
            homeScreenController.getOrCreateScrollController(
                'content_${content.runtimeType}_${content.hashCode}');
        return ContentListWidget(
            content: content, scrollController: scrollController);
      })
      .whereType<Widget>()
      .toList();
}

class Body extends StatelessWidget {
  const Body({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    final topPadding = context.isLandscape ? 50.0 : 15.0;
    final leftPadding = 20.0;
    // Calculate bottom padding based on what's showing in combined container
    final playerController = Get.find<PlayerController>();
    final hasActiveSong = playerController.currentSong.value != null;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final miniPlayerHeight =
        hasActiveSong ? (screenWidth > 800 ? 105.0 : 75.0) : 0.0;
    final navBarHeight = 52.0;
    final bottomPadding = 200.0 + miniPlayerHeight + navBarHeight;
    if (homeScreenController.tabIndex.value == 0) {
      return Padding(
        padding: EdgeInsets.only(left: leftPadding),
        child: Column(
          children: [
            const CategoryButtons(), // Fixed top CategoryButtons
            Expanded(
              child: GestureDetector(
                child: Obx(
                  () => homeScreenController.networkError.isTrue
                      ? SizedBox(
                          height: MediaQuery.sizeOf(context).height - 180,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  "music".tr,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "networkError1".tr,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 10),
                                          decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge!
                                                  .color,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: InkWell(
                                            onTap: () {
                                              homeScreenController
                                                  .loadContentFromNetwork();
                                            },
                                            child: Text(
                                              "retry".tr,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .canvasColor),
                                            ),
                                          ),
                                        ),
                                      ]),
                                ),
                              )
                            ],
                          ),
                        )
                      : Obx(() {
                          final List<Widget> items = [];
                          // Thêm HomeSearchBar vào đầu danh sách
                          items.add(const HomeSearchBar());

                          if (homeScreenController.isContentFetched.value) {
                            // Chỉ thêm QuickPicksWidget nếu có dữ liệu
                            if (homeScreenController
                                .quickPicks.value.songList.isNotEmpty) {
                              final scrollController = homeScreenController
                                  .getOrCreateScrollController('quick_picks');
                              items.add(QuickPicksWidget(
                                  content:
                                      homeScreenController.quickPicks.value,
                                  scrollController: scrollController));
                            }

                            // Thêm các widget khác
                            items.addAll(getWidgetList(
                                homeScreenController.middleContent,
                                homeScreenController));
                            items.addAll(getWidgetList(
                                homeScreenController.fixedContent,
                                homeScreenController));
                          } else {
                            items.add(const HomeShimmer());
                          }
                          return NotificationListener<ScrollNotification>(
                            onNotification:
                                homeScreenController.handleScrollNotification,
                            child: RefreshIndicator(
                              onRefresh: homeScreenController.refresh,
                              color:
                                  Colors.white, // Icon loading màu trắng sáng
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withValues(
                                      alpha: 0.8), // Background có màu primary
                              strokeWidth: 3.0, // Làm dày icon để dễ nhìn hơn
                              child: ListView.builder(
                                padding: EdgeInsets.only(
                                  bottom: bottomPadding,
                                  top: topPadding,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) => items[index],
                              ),
                            ),
                          );
                        }),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (homeScreenController.tabIndex.value == 1) {
      // Search screen - không có nav bar, chỉ có mini player padding
      return _wrapWithBottomPaddingForMiniPlayerOnly(
          const SearchScreen(), context);
    } else if (homeScreenController.tabIndex.value == 2) {
      // Library screen - có nav bar từ CombinedBottomContainer
      return _wrapWithBottomPaddingForMiniPlayerOnly(
          const CombinedLibrary(), context);
    } else if (homeScreenController.tabIndex.value == 3) {
      // Settings screen - có nav bar từ CombinedBottomContainer
      return _wrapWithBottomPaddingForMiniPlayerOnly(
          const SettingsScreen(isBottomNavActive: true), context);
    } else {
      return Center(
        child: Text("${homeScreenController.tabIndex.value}"),
      );
    }
  }

  List<Widget> getWidgetList(
      dynamic list, HomeScreenController homeScreenController) {
    return list
        .map((content) {
          final scrollController =
              homeScreenController.getOrCreateScrollController(
                  'content_${content.runtimeType}_${content.hashCode}');
          return ContentListWidget(
              content: content, scrollController: scrollController);
        })
        .whereType<Widget>()
        .toList();
  }

  Widget _wrapWithBottomPaddingForMiniPlayerOnly(
      Widget child, BuildContext context) {
    // Calculate padding chỉ cho mini player, không có nav bar
    final playerController = Get.find<PlayerController>();
    final hasActiveSong = playerController.currentSong.value != null;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final miniPlayerHeight =
        hasActiveSong ? (screenWidth > 800 ? 105.0 : 75.0) : 0.0;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        bottom: miniPlayerHeight,
      ),
      child: child,
    );
  }
}
