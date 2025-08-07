import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/utils/app_link_controller.dart' show ProcessLink;
import '/services/music_service.dart';
import '/repositories/interfaces/music_repository.dart';
import '/utils/helper.dart';

class SearchScreenController extends GetxController with ProcessLink {
  final textInputController = TextEditingController();
  final musicServices = Get.find<MusicServices>();
  MusicRepository? _musicRepository;
  final suggestionList = [].obs;
  final historyQuerylist = [].obs;
  late Box<dynamic> queryBox;
  final urlPasted = false.obs;

  // Desktop search bar related
  final focusNode = FocusNode();
  final isSearchBarInFocus = false.obs;

  @override
  onInit() {
    _init();
    super.onInit();
  }

  Future<void> _init() async {
    if (GetPlatform.isDesktop) {
      focusNode.addListener(() {
        isSearchBarInFocus.value = focusNode.hasFocus;
      });
    }
    
    // Try to get repository, fallback to direct service calls if not available
    try {
      _musicRepository = Get.find<MusicRepository>();
    } catch (e) {
      printWARNING('MusicRepository not available, using direct service calls');
    }
    
    queryBox = await Hive.openBox("searchQuery");
    historyQuerylist.value = queryBox.values.toList().reversed.toList();
  }

  Future<void> onChanged(String text) async {
    if (text.contains("https://")) {
      urlPasted.value = true;
      return;
    }
    urlPasted.value = false;

    // Kiểm tra input có rỗng không
    if (text.trim().isEmpty) {
      suggestionList.clear();
      return;
    }

    // Use repository if available, fallback to direct service call
    suggestionList.value = _musicRepository != null
        ? await _musicRepository!.getSearchSuggestions(text)
        : await musicServices.getSearchSuggestion(text);
  }

  Future<void> suggestionInput(String txt) async {
    // Kiểm tra input có rỗng không
    if (txt.trim().isEmpty) {
      return;
    }

    textInputController.text = txt;
    textInputController.selection =
        TextSelection.collapsed(offset: textInputController.text.length);
    await onChanged(txt);
  }

  Future<void> addToHistryQueryList(String txt) async {
    // Kiểm tra input có rỗng không
    if (txt.trim().isEmpty) {
      return;
    }

    if (historyQuerylist.length > 9) {
      final queryForRemoval = queryBox.getAt(0);
      await queryBox.deleteAt(0);
      historyQuerylist.removeWhere((element) => element == queryForRemoval);
    }
    if (!historyQuerylist.contains(txt)) {
      await queryBox.add(txt);
      historyQuerylist.insert(0, txt);
    }

    //reset current query and suggestionlist
    reset();
  }

  void reset() {
    urlPasted.value = false;
    textInputController.text = "";
    suggestionList.clear();
  }

  Future<void> removeQueryFromHistory(String txt) async {
    final index = queryBox.values.toList().indexOf(txt);
    await queryBox.deleteAt(index);
    historyQuerylist.remove(txt);
  }

  @override
  void dispose() {
    focusNode.dispose();
    textInputController.dispose();
    queryBox.close();
    super.dispose();
  }
}
