import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class CookieYT extends YoutubeHttpClient {
  @override
  Map<String, String> get headers => {
        ...super.headers,
        'X-Goog-FieldMask':
            'playabilityStatus.status,playabilityStatus.reason,playerConfig.audioConfig,streamingData.adaptiveFormats,videoDetails.videoId',
      };
}

class StreamProvider {
  final bool playable;
  final List<Audio>? audioFormats;
  final List<Video>? videoFormats;
  final List<HLS>? hlsStreams;
  final String statusMSG;

  StreamProvider(
      {required this.playable,
      this.audioFormats,
      this.videoFormats,
      this.hlsStreams,
      this.statusMSG = ""});

  static Future<StreamProvider> fetch(String videoId) async {
    final yt = YoutubeExplode(CookieYT());

    try {
      final res = await yt.videos.streams.getManifest(videoId,
          ytClients: [YoutubeApiClient.androidVr]);
      final audio = res.audioOnly;
      final video = res.videoOnly;
      final muxed = res.muxed;

      print(video);
      print(audio);
      print(muxed);
      print(res.hls);

      // Tạo danh sách audio streams
      final audioFormats = audio
          .map((e) => Audio(
              itag: e.tag,
              audioCodec: e.audioCodec.contains('mp') ? Codec.mp4a : Codec.opus,
              bitrate: e.bitrate.bitsPerSecond,
              duration: e.duration ?? 0,
              loudnessDb: e.loudnessDb,
              url: e.url.toString(),
              size: e.size.totalBytes))
          .toList();

      // Tạo danh sách video streams
      final videoFormats = [
        ...video.map((e) => Video(
            itag: e.tag,
            videoCodec: e.videoCodec.contains('av01')
                ? VideoCodec.av01
                : e.videoCodec.contains('vp9')
                    ? VideoCodec.vp9
                    : VideoCodec.avc1,
            resolution: e.videoResolution.height,
            fps: e.framerate.framesPerSecond.toInt(),
            bitrate: e.bitrate.bitsPerSecond,
            duration: 0, // Video-only streams don't have duration
            url: e.url.toString(),
            size: e.size.totalBytes,
            qualityLabel: e.videoQualityLabel,
            container: e.container.name)),
        ...muxed.map((e) => Video(
            itag: e.tag,
            videoCodec: e.videoCodec.contains('av01')
                ? VideoCodec.av01
                : e.videoCodec.contains('vp9')
                    ? VideoCodec.vp9
                    : VideoCodec.avc1,
            resolution: e.videoResolution.height,
            fps: e.framerate.framesPerSecond.toInt(),
            bitrate: e.bitrate.bitsPerSecond,
            duration: 0, // Muxed streams duration can be retrieved from audio
            url: e.url.toString(),
            size: e.size.totalBytes,
            qualityLabel: e.qualityLabel,
            container: e.container.name,
            hasAudio: true))
      ];

      // Tạo HLS streams từ res.hls
      final hlsStreams = res.hls
          .map((e) => HLS(
              url: e.url.toString(),
              type: HLSType.variant,
              quality: "adaptive", // HLS streams are adaptive by nature
              resolution: 0, // Will be determined by the client
              framerate: 30))
          .toList();

      return StreamProvider(
        playable: true,
        statusMSG: "OK",
        audioFormats: audioFormats,
        videoFormats: videoFormats,
        hlsStreams: hlsStreams.isNotEmpty ? hlsStreams : null,
      );
    } catch (e) {
      if (e is SocketException) {
        return StreamProvider(
          playable: false,
          statusMSG: "networkError",
        );
      } else if (e is VideoUnplayableException) {
        print(e.message);
        return StreamProvider(
          playable: false,
          statusMSG: "Song is unplayable",
        );
      } else if (e is VideoRequiresPurchaseException) {
        return StreamProvider(
          playable: false,
          statusMSG: "Song requires purchase",
        );
      } else if (e is VideoUnavailableException) {
        return StreamProvider(
          playable: false,
          statusMSG: "Song is unavailable",
        );
      } else if (e is YoutubeExplodeException) {
        return StreamProvider(
          playable: false,
          statusMSG: e.message,
        );
      } else {
        return StreamProvider(
          playable: false,
          statusMSG: "Unknown error occurred",
        );
      }
    }
  }

  // Audio getters
  Audio? get highestQualityAudio =>
      audioFormats?.lastWhere((item) => item.itag == 251 || item.itag == 140,
          orElse: () => audioFormats!.first);

  Audio? get highestBitrateMp4aAudio =>
      audioFormats?.lastWhere((item) => item.itag == 140 || item.itag == 139,
          orElse: () => audioFormats!.first);

  Audio? get highestBitrateOpusAudio =>
      audioFormats?.lastWhere((item) => item.itag == 251 || item.itag == 250,
          orElse: () => audioFormats!.first);

  Audio? get lowQualityAudio =>
      audioFormats?.lastWhere((item) => item.itag == 249 || item.itag == 139,
          orElse: () => audioFormats!.first);

  // Audio extensions (theo API YouTube Explode)
  Audio? get withHighestBitrate =>
      audioFormats?.reduce((a, b) => a.bitrate > b.bitrate ? a : b);

  // Video getters
  Video? get highestQualityVideo =>
      videoFormats?.where((v) => v.resolution >= 1080).lastOrNull ??
      videoFormats?.lastOrNull;

  Video? get mediumQualityVideo =>
      videoFormats
          ?.where((v) => v.resolution >= 720 && v.resolution < 1080)
          .lastOrNull ??
      videoFormats?.where((v) => v.resolution >= 480).lastOrNull ??
      videoFormats?.lastOrNull;

  Video? get lowQualityVideo =>
      videoFormats?.where((v) => v.resolution <= 480).firstOrNull ??
      videoFormats?.firstOrNull;

  List<Video>? get muxedStreams =>
      videoFormats?.where((v) => v.hasAudio).toList();

  List<Video>? get videoOnlyStreams =>
      videoFormats?.where((v) => !v.hasAudio).toList();

  // Simplified getters để match với API example
  List<Audio>? get audioOnly => audioFormats;
  List<Video>? get videoOnly => videoOnlyStreams;
  List<Video>? get muxed => muxedStreams;
  List<HLS>? get hls => hlsStreams;

  // Video extensions (theo API YouTube Explode)
  Video? get withHighestVideoQuality =>
      muxedStreams?.reduce((a, b) => a.resolution > b.resolution ? a : b);

  // Filter video streams theo container
  List<Video> videoOnlyByContainer(String containerType) =>
      videoOnlyStreams?.where((v) => v.container == containerType).toList() ??
      [];

  List<Video> muxedByContainer(String containerType) =>
      muxedStreams?.where((v) => v.container == containerType).toList() ?? [];

  // HLS getters
  HLS? get masterHLSStream =>
      hlsStreams?.where((h) => h.type == HLSType.master).firstOrNull;

  Map<String, dynamic> get hmStreamingData {
    return {
      "playable": playable,
      "statusMSG": statusMSG,
      "lowQualityAudio": lowQualityAudio?.toJson(),
      "highQualityAudio": highestQualityAudio?.toJson(),
      "lowQualityVideo": lowQualityVideo?.toJson(),
      "mediumQualityVideo": mediumQualityVideo?.toJson(),
      "highQualityVideo": highestQualityVideo?.toJson(),
      "hlsMasterUrl": masterHLSStream?.url,
      "hasVideoFormats": videoFormats?.isNotEmpty ?? false,
      "hasHLSStreams": hlsStreams?.isNotEmpty ?? false,
      "videoFormats": videoFormats?.map((v) => v.toJson()).toList(),
      "hlsStreams": hlsStreams?.map((h) => h.toJson()).toList(),
    };
  }
}

class Audio {
  final int itag;
  final Codec audioCodec;
  final int bitrate;
  final int duration;
  final int size;
  final double loudnessDb;
  final String url;

  Audio(
      {required this.itag,
      required this.audioCodec,
      required this.bitrate,
      required this.duration,
      required this.loudnessDb,
      required this.url,
      required this.size});

  Map<String, dynamic> toJson() => {
        "itag": itag,
        "audioCodec": audioCodec.toString(),
        "bitrate": bitrate,
        "loudnessDb": loudnessDb,
        "url": url,
        "approxDurationMs": duration,
        "size": size
      };

  factory Audio.fromJson(json) => Audio(
      audioCodec: (json["audioCodec"] as String).contains("mp4a")
          ? Codec.mp4a
          : Codec.opus,
      itag: json['itag'],
      duration: json["approxDurationMs"] ?? 0,
      bitrate: json["bitrate"] ?? 0,
      loudnessDb: (json['loudnessDb'])?.toDouble() ?? 0.0,
      url: json['url'],
      size: json["size"] ?? 0);
}

class Video {
  final int itag;
  final VideoCodec videoCodec;
  final int resolution;
  final int fps;
  final int bitrate;
  final int duration;
  final int size;
  final String url;
  final String qualityLabel;
  final String container;
  final bool hasAudio;

  Video({
    required this.itag,
    required this.videoCodec,
    required this.resolution,
    required this.fps,
    required this.bitrate,
    required this.duration,
    required this.size,
    required this.url,
    required this.qualityLabel,
    required this.container,
    this.hasAudio = false,
  });

  Map<String, dynamic> toJson() => {
        "itag": itag,
        "videoCodec": videoCodec.toString(),
        "resolution": resolution,
        "fps": fps,
        "bitrate": bitrate,
        "url": url,
        "approxDurationMs": duration,
        "size": size,
        "qualityLabel": qualityLabel,
        "container": container,
        "hasAudio": hasAudio,
      };

  factory Video.fromJson(json) => Video(
      itag: json['itag'],
      videoCodec: VideoCodec.values.firstWhere(
          (codec) => codec.toString() == json["videoCodec"],
          orElse: () => VideoCodec.avc1),
      resolution: json["resolution"] ?? 0,
      fps: json["fps"] ?? 30,
      bitrate: json["bitrate"] ?? 0,
      duration: json["approxDurationMs"] ?? 0,
      size: json["size"] ?? 0,
      url: json['url'],
      qualityLabel: json["qualityLabel"] ?? "",
      container: json["container"] ?? "",
      hasAudio: json["hasAudio"] ?? false);
}

class HLS {
  final String url;
  final HLSType type;
  final String quality;
  final int resolution;
  final int framerate;

  HLS({
    required this.url,
    required this.type,
    required this.quality,
    this.resolution = 0,
    this.framerate = 30,
  });

  Map<String, dynamic> toJson() => {
        "url": url,
        "type": type.toString(),
        "quality": quality,
        "resolution": resolution,
        "framerate": framerate,
      };

  factory HLS.fromJson(json) => HLS(
      url: json['url'],
      type: HLSType.values.firstWhere((type) => type.toString() == json["type"],
          orElse: () => HLSType.master),
      quality: json["quality"] ?? "",
      resolution: json["resolution"] ?? 0,
      framerate: json["framerate"] ?? 30);
}

enum Codec { mp4a, opus }

enum VideoCodec { avc1, vp9, av01 }

enum HLSType { master, variant }

extension ListExtension<T> on List<T>? {
  T? get firstOrNull => this?.isNotEmpty == true ? this!.first : null;
  T? get lastOrNull => this?.isNotEmpty == true ? this!.last : null;
}
