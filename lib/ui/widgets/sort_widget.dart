// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Library/library_controller.dart';

import 'additional_operation_dialog.dart';
import 'modified_text_field.dart';

enum OperationMode { arrange, delete, addToPlaylist, none }

enum SortType {
  Name,
  Date,
  Duration,
  RecentlyPlayed,
}

Set<SortType> buildSortTypeSet(
    [bool dateRequired = false,
    bool durationRequired = false,
    bool recentlyPlayedRequired = false]) {
  Set<SortType> requiredSortTypes = {};
  if (dateRequired) {
    requiredSortTypes.add(SortType.Date);
  }
  if (durationRequired) {
    requiredSortTypes.add(SortType.Duration);
  }
  if (recentlyPlayedRequired) {
    requiredSortTypes.add(SortType.RecentlyPlayed);
  }
  return requiredSortTypes;
}

class SortWidget extends StatelessWidget {
  /// Additional operations - Delete Multiple songs, Rearrage offline playlist, Add Multiple songs to playlist
  const SortWidget({
    super.key,
    required this.tag,
    this.itemCountTitle = '',
    this.titleLeftPadding = 18,
    this.isAdditionalOperationRequired = true,
    this.requiredSortTypes = const <SortType>{SortType.Name},
    this.isSearchFeatureRequired = false,
    this.isPlaylistRearrageFeatureRequired = false,
    this.isSongDeletetioFeatureRequired = false,
    required this.screenController,
    this.onSearchStart,
    this.onSearch,
    this.onSearchClose,
    this.itemIcon,
    this.startAdditionalOperation,
    this.selectAll,
    this.performAdditionalOperation,
    this.cancelAdditionalOperation,
    this.isImportFeatureRequired = false,
    required this.onSort,
  });

  /// unique identifier for each sortwidget
  final String tag;
  final String itemCountTitle;
  final IconData? itemIcon;
  final bool isAdditionalOperationRequired;
  final double titleLeftPadding;
  final Set<SortType> requiredSortTypes;
  final bool isSearchFeatureRequired;
  final bool isSongDeletetioFeatureRequired;
  final bool isPlaylistRearrageFeatureRequired;
  final dynamic screenController;
  final Function(SortWidgetController, OperationMode)? startAdditionalOperation;
  final Function(bool)? selectAll;
  final Function()? performAdditionalOperation;
  final Function()? cancelAdditionalOperation;
  final Function(String?)? onSearchStart;
  final Function(String, String?)? onSearch;
  final Function(String?)? onSearchClose;
  final Function(SortType, bool) onSort;
  final bool isImportFeatureRequired;

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "importPlaylist".tr,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "importPlaylistDesc".tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              "importLargeFileNote".tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.file_open),
                label: Text("selectFile".tr),
                onPressed: () {
                  Get.find<LibraryPlaylistsController>()
                      .importPlaylistFromJson(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text("close".tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SortWidgetController(), tag: tag);
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: SizedBox(
        height: 40,
        child: _SortWidgetContent(
          key: ValueKey('sort_widget_$tag'),
          controller: controller,
          tag: tag,
          itemCountTitle: itemCountTitle,
          titleLeftPadding: titleLeftPadding,
          itemIcon: itemIcon,
          requiredSortTypes: requiredSortTypes,
          isImportFeatureRequired: isImportFeatureRequired,
          isSearchFeatureRequired: isSearchFeatureRequired,
          isAdditionalOperationRequired: isAdditionalOperationRequired,
          isPlaylistRearrageFeatureRequired: isPlaylistRearrageFeatureRequired,
          isSongDeletetioFeatureRequired: isSongDeletetioFeatureRequired,
          screenController: screenController,
          onSort: onSort,
          onSearchStart: onSearchStart,
          onSearch: onSearch,
          onSearchClose: onSearchClose,
          startAdditionalOperation: startAdditionalOperation,
          showImportDialog: () => _showImportDialog(context),
        ),
      ),
    );
  }
}

/// Optimized Sort Widget Content with granular state management
class _SortWidgetContent extends StatelessWidget {
  const _SortWidgetContent({
    super.key,
    required this.controller,
    required this.tag,
    required this.itemCountTitle,
    required this.titleLeftPadding,
    required this.itemIcon,
    required this.requiredSortTypes,
    required this.isImportFeatureRequired,
    required this.isSearchFeatureRequired,
    required this.isAdditionalOperationRequired,
    required this.isPlaylistRearrageFeatureRequired,
    required this.isSongDeletetioFeatureRequired,
    required this.screenController,
    required this.onSort,
    required this.onSearchStart,
    required this.onSearch,
    required this.onSearchClose,
    required this.startAdditionalOperation,
    required this.showImportDialog,
  });

  final SortWidgetController controller;
  final String tag;
  final String itemCountTitle;
  final double titleLeftPadding;
  final IconData? itemIcon;
  final Set<SortType> requiredSortTypes;
  final bool isImportFeatureRequired;
  final bool isSearchFeatureRequired;
  final bool isAdditionalOperationRequired;
  final bool isPlaylistRearrageFeatureRequired;
  final bool isSongDeletetioFeatureRequired;
  final dynamic screenController;
  final Function(SortType, bool) onSort;
  final Function(String?)? onSearchStart;
  final Function(String, String?)? onSearch;
  final Function(String?)? onSearchClose;
  final Function(SortWidgetController, OperationMode)? startAdditionalOperation;
  final VoidCallback showImportDialog;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSearching = controller.isSearchingEnabled.value;

      return Stack(
        children: [
          if (!isSearching)
            _SortButtonsRow(
              controller: controller,
              itemCountTitle: itemCountTitle,
              titleLeftPadding: titleLeftPadding,
              itemIcon: itemIcon,
              requiredSortTypes: requiredSortTypes,
              isImportFeatureRequired: isImportFeatureRequired,
              isSearchFeatureRequired: isSearchFeatureRequired,
              isAdditionalOperationRequired: isAdditionalOperationRequired,
              isPlaylistRearrageFeatureRequired:
                  isPlaylistRearrageFeatureRequired,
              isSongDeletetioFeatureRequired: isSongDeletetioFeatureRequired,
              screenController: screenController,
              onSort: onSort,
              onSearchStart: onSearchStart,
              tag: tag,
              startAdditionalOperation: startAdditionalOperation,
              showImportDialog: showImportDialog,
            ),
          if (isSearching)
            _SearchField(
              controller: controller,
              tag: tag,
              onSearch: onSearch,
              onSearchClose: onSearchClose,
            ),
        ],
      );
    });
  }
}

/// Separated Sort Buttons Row for better performance
class _SortButtonsRow extends StatelessWidget {
  const _SortButtonsRow({
    required this.controller,
    required this.itemCountTitle,
    required this.titleLeftPadding,
    required this.itemIcon,
    required this.requiredSortTypes,
    required this.isImportFeatureRequired,
    required this.isSearchFeatureRequired,
    required this.isAdditionalOperationRequired,
    required this.isPlaylistRearrageFeatureRequired,
    required this.isSongDeletetioFeatureRequired,
    required this.screenController,
    required this.onSort,
    required this.onSearchStart,
    required this.tag,
    required this.startAdditionalOperation,
    required this.showImportDialog,
  });

  final SortWidgetController controller;
  final String itemCountTitle;
  final double titleLeftPadding;
  final IconData? itemIcon;
  final Set<SortType> requiredSortTypes;
  final bool isImportFeatureRequired;
  final bool isSearchFeatureRequired;
  final bool isAdditionalOperationRequired;
  final bool isPlaylistRearrageFeatureRequired;
  final bool isSongDeletetioFeatureRequired;
  final dynamic screenController;
  final Function(SortType, bool) onSort;
  final Function(String?)? onSearchStart;
  final String tag;
  final Function(SortWidgetController, OperationMode)? startAdditionalOperation;
  final VoidCallback showImportDialog;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(left: titleLeftPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(itemCountTitle),
              if (itemIcon != null)
                Icon(
                  Icons.music_note,
                  size: 15,
                  color: Theme.of(context).colorScheme.secondary,
                )
            ],
          ),
        ),
        _SortIconButton(
          controller: controller,
          sortType: SortType.Name,
          icon: Icons.sort_by_alpha,
          tooltip: "sortByName".tr,
          onPressed: () => controller.onSortByName(onSort),
        ),
        if (requiredSortTypes.contains(SortType.Date))
          _SortIconButton(
            controller: controller,
            sortType: SortType.Date,
            icon: Icons.calendar_month,
            tooltip: "sortByDate".tr,
            onPressed: () => controller.onSortByDate(onSort),
          ),
        if (requiredSortTypes.contains(SortType.Duration))
          _SortIconButton(
            controller: controller,
            sortType: SortType.Duration,
            icon: Icons.timer,
            tooltip: "sortByDuration".tr,
            onPressed: () => controller.onSortByDuration(onSort),
          ),
        const Expanded(child: SizedBox()),
        _AscendingIconButton(
          controller: controller,
          onSort: onSort,
        ),
        if (isImportFeatureRequired)
          _StaticIconButton(
            icon: Icons.import_contacts,
            tooltip: "importPlaylist".tr,
            onPressed: showImportDialog,
          ),
        if (isSearchFeatureRequired)
          _StaticIconButton(
            icon: Icons.search,
            tooltip: "search".tr,
            onPressed: () {
              onSearchStart!(tag);
              controller.toggleSearch();
            },
          ),
        if (isAdditionalOperationRequired)
          PopupMenuButton(
            child: const Icon(
              Icons.more_vert,
              size: 20,
            ),
            onSelected: (mode) {
              showDialog(
                  context: context,
                  builder: (context) => AdditionalOperationDialog(
                        operationMode: mode,
                        screenController: screenController,
                        controller: controller,
                      ));

              controller.setActiveMode(mode);
              startAdditionalOperation!(controller, mode);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              if (isPlaylistRearrageFeatureRequired)
                PopupMenuItem(
                  value: OperationMode.arrange,
                  child: Text("reArrangePlaylist".tr),
                ),
              if (isSongDeletetioFeatureRequired)
                PopupMenuItem(
                  value: OperationMode.delete,
                  child: Text("removeMultiple".tr),
                ),
              PopupMenuItem(
                value: OperationMode.addToPlaylist,
                child: Text("addMultipleSongs".tr),
              ),
            ],
          ),
        const SizedBox(width: 15),
      ],
    );
  }
}

/// Reactive Sort Icon Button
class _SortIconButton extends StatelessWidget {
  const _SortIconButton({
    required this.controller,
    required this.sortType,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final SortWidgetController controller;
  final SortType sortType;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _customIconButton(
          isSelected: controller.sortType.value == sortType,
          icon: icon,
          tooltip: tooltip,
          onPressed: onPressed,
        ));
  }
}

/// Reactive Ascending Icon Button
class _AscendingIconButton extends StatelessWidget {
  const _AscendingIconButton({
    required this.controller,
    required this.onSort,
  });

  final SortWidgetController controller;
  final Function(SortType, bool) onSort;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _customIconButton(
          icon: controller.isAscending.value
              ? Icons.arrow_downward
              : Icons.arrow_upward,
          tooltip: "sortAscendNDescend".tr,
          onPressed: () => controller.onAscendNDescend(onSort),
        ));
  }
}

/// Static Icon Button (no reactivity needed)
class _StaticIconButton extends StatelessWidget {
  const _StaticIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _customIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

/// Search Field Component
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.tag,
    required this.onSearch,
    required this.onSearchClose,
  });

  final SortWidgetController controller;
  final String tag;
  final Function(String, String?)? onSearch;
  final Function(String?)? onSearchClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 5, right: 20),
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor.withAlpha(125),
        child: ModifiedTextField(
          controller: controller.textEditingController,
          textAlignVertical: TextAlignVertical.center,
          autofocus: true,
          onChanged: (value) {
            onSearch!(value, tag);
          },
          cursorColor: Theme.of(context).textTheme.titleSmall!.color,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(8),
            filled: true,
            border: const OutlineInputBorder(),
            hintText: "search".tr,
            suffixIconColor: Theme.of(context).colorScheme.secondary,
            suffixIcon: IconButton(
              splashRadius: 10,
              iconSize: 20,
              icon: const Icon(Icons.cancel),
              onPressed: () {
                controller.toggleSearch();
                onSearchClose!(tag);
              },
            ),
          ),
        ),
      ),
    );
  }
}

Widget _customIconButton({
  required IconData icon,
  required String tooltip,
  bool? isSelected,
  Function()? onPressed,
}) {
  return IconButton(
    icon: Icon(icon),
    padding: const EdgeInsets.all(0),
    color: isSelected == null || isSelected == true
        ? Theme.of(Get.context!).textTheme.bodySmall!.color
        : Theme.of(Get.context!).colorScheme.secondary,
    iconSize: 20,
    splashRadius: 20,
    visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
    onPressed: onPressed,
    tooltip: tooltip,
  );
}

class SortWidgetController extends GetxController {
  final Rx<SortType> sortType = SortType.Name.obs;
  final isAscending = true.obs;
  final isSearchingEnabled = false.obs;
  final isRearraningEnabled = false.obs;
  final isDeletionEnabled = false.obs;
  final isAddtoPlaylistEnabled = false.obs;
  final isAllSelected = false.obs;
  TextEditingController textEditingController = TextEditingController();

  void setActiveMode(OperationMode mode) {
    isAddtoPlaylistEnabled.value = OperationMode.addToPlaylist == mode;
    isDeletionEnabled.value = OperationMode.delete == mode;
    isRearraningEnabled.value = OperationMode.arrange == mode;
  }

  void toggleSelectAll(bool val) {
    isAllSelected.value = val;
  }

  void onSortByName(Function onSort) {
    sortType.value = SortType.Name;
    onSort(sortType.value, isAscending.value);
  }

  void onSortByDuration(Function onSort) {
    sortType.value = SortType.Duration;
    onSort(sortType.value, isAscending.value);
  }

  void onSortByDate(Function onSort) {
    sortType.value = SortType.Date;
    onSort(sortType.value, isAscending.value);
  }

  void onAscendNDescend(Function onSort) {
    isAscending.value = !isAscending.value;
    onSort(sortType.value, isAscending.value);
  }

  void toggleSearch() {
    isSearchingEnabled.value = !isSearchingEnabled.value;
  }
}
