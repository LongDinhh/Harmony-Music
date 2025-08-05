import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen_controller.dart';

/// Pure content of bottom navigation bar without GlassWrapper
/// Used inside CombinedBottomContainer
class BottomNavBarContent extends StatelessWidget {
  const BottomNavBarContent({super.key});

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();

    // Danh sách các tab
    final List<BottomNavItem> tabs = [
      BottomNavItem(
        selectedIcon: Icons.music_note,
        unselectedIcon: Icons.music_note_outlined,
        label: modifyNgetlabel('music'.tr),
        index: 0,
      ),
      BottomNavItem(
        selectedIcon: Icons.search,
        unselectedIcon: Icons.search,
        label: modifyNgetlabel('search'.tr),
        index: 1,
      ),
      BottomNavItem(
        selectedIcon: Icons.library_music,
        unselectedIcon: Icons.library_music_outlined,
        label: modifyNgetlabel('library'.tr),
        index: 2,
      ),
      BottomNavItem(
        selectedIcon: Icons.settings,
        unselectedIcon: Icons.settings_outlined,
        label: modifyNgetlabel('settings'.tr),
        index: 3,
      ),
    ];

    return Obx(() => Container(
          height: 52.0 + MediaQuery.paddingOf(context).bottom,
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tabs.map((tab) {
                final isSelected =
                    homeScreenController.tabIndex.value == tab.index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        homeScreenController.onBottonBarTabSelected(tab.index),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Indicator
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isSelected
                                  ? tab.selectedIcon
                                  : tab.unselectedIcon,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Label
                          Text(
                            tab.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.color,
                                  decoration: TextDecoration.none,
                                  fontSize: 11,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ));
  }

  String modifyNgetlabel(String label) {
    if (label.length > 9) {
      return "${label.substring(0, 8)}..";
    }
    return label;
  }
}

class BottomNavItem {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  final int index;

  BottomNavItem({
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
    required this.index,
  });
}
