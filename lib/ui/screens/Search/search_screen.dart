import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'components/search_item.dart';
import '/ui/screens/Settings/settings_screen_controller.dart';
import '../../widgets/modified_text_field.dart';
import '/ui/navigator.dart';
import 'search_screen_controller.dart';
import '../../../utils/haptic_utils.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchScreenController =
        Get.put(SearchScreenController(), permanent: true);
    final settingsScreenController =
        Get.put(SettingsScreenController(), permanent: true);
    final topPadding = context.isLandscape ? 50.0 : 60.0;

    // Kiểm tra xem có cần focus vào input không
    final arguments = Get.arguments;
    final shouldFocus =
        arguments is Map<String, dynamic> && arguments['focus'] == true;
    final category = arguments is Map<String, dynamic>
        ? arguments['category'] as String?
        : null;

    // Focus vào input nếu cần và set category nếu có
    if (shouldFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        searchScreenController.focusNode.requestFocus();
        if (category != null) {
          searchScreenController.textInputController.text = category;
          searchScreenController.onChanged(category);
        }
      });
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Obx(
        () => Padding(
          padding: EdgeInsets.only(top: topPadding, left: 5, right: 5),
          child: Column(
            children: [
              // Header với nút back và title cùng dòng
              Row(
                children: [
                  // Nút back cho mobile
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Theme.of(context).textTheme.titleMedium!.color,
                    ),
                    onPressed: () {
                      Get.nestedKey(ScreenNavigationSetup.id)!
                          .currentState!
                          .pop();
                    },
                  ),
                  Expanded(
                    child: Text(
                      "search".tr,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              ModifiedTextField(
                textCapitalization: TextCapitalization.sentences,
                controller: searchScreenController.textInputController,
                focusNode: searchScreenController.focusNode,
                textInputAction: TextInputAction.search,
                onChanged: searchScreenController.onChanged,
                onSubmitted: (val) {
                  // Kiểm tra input có rỗng không
                  if (val.trim().isEmpty) {
                    // Giữ nguyên focus và không làm gì cả
                    searchScreenController.focusNode.requestFocus();
                    return;
                  }

                  if (val.contains("https://")) {
                    searchScreenController.filterLinks(Uri.parse(val));
                    searchScreenController.reset();
                    return;
                  }
                  HapticUtils.screenNavigationHaptic();
                  Get.toNamed(ScreenNavigationSetup.searchResultScreen,
                      id: ScreenNavigationSetup.id, arguments: val);
                  searchScreenController.addToHistryQueryList(val);
                },
                autofocus:
                    settingsScreenController.isBottomNavBarEnabled.isFalse,
                cursorColor: Theme.of(context).textTheme.bodySmall!.color,
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 15),
                    focusColor: Colors.white,
                    hintText: "searchDes".tr,
                    suffix: IconButton(
                      onPressed: searchScreenController.reset,
                      icon: const Icon(Icons.close),
                      splashRadius: 16,
                      iconSize: 19,
                    )),
              ),
              Expanded(
                child: Obx(() {
                  final isEmpty =
                      searchScreenController.suggestionList.isEmpty ||
                          searchScreenController.textInputController.text == "";
                  final list = isEmpty
                      ? searchScreenController.historyQuerylist.toList()
                      : searchScreenController.suggestionList.toList();
                  return ListView(
                      padding: const EdgeInsets.only(top: 5, bottom: 400),
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      children: searchScreenController.urlPasted.isTrue
                          ? [
                              InkWell(
                                onTap: () {
                                  searchScreenController.filterLinks(Uri.parse(
                                      searchScreenController
                                          .textInputController.text));
                                  searchScreenController.reset();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: SizedBox(
                                    width: double.maxFinite,
                                    height: 60,
                                    child: Center(
                                        child: Text(
                                      "urlSearchDes".tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    )),
                                  ),
                                ),
                              )
                            ]
                          : list
                              .map((item) => SearchItem(
                                  queryString: item, isHistoryString: isEmpty))
                              .toList());
                }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
