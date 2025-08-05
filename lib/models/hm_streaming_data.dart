import 'package:harmonymusic/services/stream_service.dart' show Audio;

class HMStreamingData {
  final bool playable;
  final String statusMSG;
  final Audio? lowQualityAudio;
  final Audio? highQualityAudio;
  int qualityIndex = 1;
  HMStreamingData({
    required this.playable,
    required this.statusMSG,
    this.lowQualityAudio,
    this.highQualityAudio,
  });

  void setQualityIndex(int index) {
    qualityIndex = index;
  }

  Audio? get audio => qualityIndex == 0 ? lowQualityAudio : highQualityAudio;

  factory HMStreamingData.fromJson(Map<String, dynamic> json) {
    if (!json['playable']) {
      return HMStreamingData(
        playable: false,
        statusMSG: json['statusMSG'],
      );
    }
    // Cast nested objects to Map<String, dynamic> to fix type errors from cache
    final lowQualityAudio = Audio.fromJson(Map<String, dynamic>.from(json['lowQualityAudio']));
    final highQualityAudio = Audio.fromJson(Map<String, dynamic>.from(json['highQualityAudio']));
    return HMStreamingData(
        playable: json['playable'],
        statusMSG: json['statusMSG'],
        lowQualityAudio: lowQualityAudio,
        highQualityAudio: highQualityAudio);
  }

  Map<String, dynamic> toJson() => {
        "playable": playable,
        "statusMSG": statusMSG,
        "lowQualityAudio": lowQualityAudio?.toJson(),
        "highQualityAudio": highQualityAudio?.toJson(),
      };
}
