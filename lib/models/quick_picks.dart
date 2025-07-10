import 'package:audio_service/audio_service.dart';
import 'media_Item_builder.dart';

class QuickPicks {
  QuickPicks(this.songList, {this.title = "Discover"});
  List<MediaItem> songList;
  final String title;

  Map<String, dynamic> toJson() => {
        "type": "QuickPicks",
        "title": title,
        "songList": songList.map((song) => MediaItemBuilder.toJson(song)).toList(),
      };

  factory QuickPicks.fromJson(Map<String, dynamic> json) => QuickPicks(
        (json["songList"] as List).map((song) => MediaItemBuilder.fromJson(song)).toList(),
        title: json["title"],
      );
}
