import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class CookieYT extends YoutubeHttpClient {
  @override
  Map<String, String> get headers => {
        ...super.headers,
        'cookie':
            'VISITOR_INFO1_LIVE=q-krUsDDf8U; VISITOR_PRIVACY_METADATA=CgJWThIEGgAgFQ%3D%3D; LOGIN_INFO=AFmmF2swRgIhAIEdaLSu-B1LuE1uO39zo0o5_YwpaodP5_LofVdBXUDoAiEA01UylY7oM5B8SxRYKZxnI4P7brXoiKMlTmWz0up8KpU:QUQ3MjNmemNBZEFUMzhaUzlJVHEwSkF2cTlQaEZwcUNETUJzQy1RQlViWWpYNHhVLXlOUlozeVhQWVB1bHk5R1U1U0JSMEdvcTNLQTZ3bXRvR2ZsSk5URDlMWVFOa2JGZXRHbm9teEpYdDMyNUluZG5RazlBVXppOWNMdFlpNUxBN3pTeHhRV0x1dVU2ZkQ3aTdGRV95c0xUN19LdWhrUkdn; HSID=ASObiPAEosdn_4ihM; SSID=A-w15U2mdiOCPZb0c; APISID=W_0vAqTWVwuih7zB/Achkh4moi0UtgeJU4; SAPISID=FNNH5xHSo5EP7GV6/AnPGVLTSE_mlXLpEk; __Secure-1PAPISID=FNNH5xHSo5EP7GV6/AnPGVLTSE_mlXLpEk; __Secure-3PAPISID=FNNH5xHSo5EP7GV6/AnPGVLTSE_mlXLpEk; _gcl_au=1.1.501670752.1749787964; PREF=f6=40000080&f7=100&tz=Asia.Saigon&repeat=NONE; SID=g.a000ywi5nQobEs5lc-kj8Ej3I_DgUk-ceJVb-L33v46HTTsW8ofwRD3qmrCDwLjOL-RCX83p5QACgYKATESARMSFQHGX2Mih_3ta-ZQ3FWF5P1fkc0duxoVAUF8yKrus1KZcbJQeaj5WKkBpmqf0076; __Secure-1PSID=g.a000ywi5nQobEs5lc-kj8Ej3I_DgUk-ceJVb-L33v46HTTsW8ofwqUTRNCqUqToyRrxVvu2HkgACgYKAWISARMSFQHGX2Miri3THEBnFT__dNFeF0PawBoVAUF8yKofvQ2IbKtdk1OCPcsRTYAV0076; __Secure-3PSID=g.a000ywi5nQobEs5lc-kj8Ej3I_DgUk-ceJVb-L33v46HTTsW8ofwPBx2Rz5WfdDFiks40XS-kAACgYKAUYSARMSFQHGX2MiwWoT0nKFyTiTX2F5dUGw4xoVAUF8yKpDEKuwI6bU77-6Q0pbzHrO0076; YSC=_Bax-w1wU4g; __Secure-ROLLOUT_TOKEN=CP_Pv52t5eyJaBD81La0zaaLAxj2yfP85qmOAw%3D%3D; __Secure-1PSIDTS=sidts-CjEB5H03P-OLcno-IfIUUklUD1_1bQi-_UfH8C-WLSjG5PlnMbwj9JyBCtcE4xXhGh3BEAA; __Secure-3PSIDTS=sidts-CjEB5H03P-OLcno-IfIUUklUD1_1bQi-_UfH8C-WLSjG5PlnMbwj9JyBCtcE4xXhGh3BEAA; SIDCC=AKEyXzUf68QlNd0zrfTeYXwcE9DYBgv7HYZ_fFAzVeyqK_CY1j2-bx-7Vpw4EsBzf82k7e5uOQ; __Secure-1PSIDCC=AKEyXzWE6UeW6Iw9PXzAUVu_eqPH21at2rT91MCsCGL4CkxWxk1bYSafMSKhqkBN-aUarhpBsu4; __Secure-3PSIDCC=AKEyXzXD5rj2-0uKgWVRnueIOwhpcCEPZFCnYTQz3YSmJu5Nqd1go2E5l70zGz--AlsBPZc2VwU; ST-o95pvo=itct=CNYEEKQwGAEiEwjViZiBzKqOAxXHWPUFHWi3JGQyB3JlbGF0ZWRItsKX86rckqtDmgEFCAEQ-B0%3D&csn=stDi9e23q3kG1Nm9&session_logininfo=AFmmF2swRgIhAIEdaLSu-B1LuE1uO39zo0o5_YwpaodP5_LofVdBXUDoAiEA01UylY7oM5B8SxRYKZxnI4P7brXoiKMlTmWz0up8KpU%3AQUQ3MjNmemNBZEFUMzhaUzlJVHEwSkF2cTlQaEZwcUNETUJzQy1RQlViWWpYNHhVLXlOUlozeVhQWVB1bHk5R1U1U0JSMEdvcTNLQTZ3bXRvR2ZsSk5URDlMWVFOa2JGZXRHbm9teEpYdDMyNUluZG5RazlBVXppOWNMdFlpNUxBN3pTeHhRV0x1dVU2ZkQ3aTdGRV95c0xUN19LdWhrUkdn&endpoint=%7B%22clickTrackingParams%22%3A%22CNYEEKQwGAEiEwjViZiBzKqOAxXHWPUFHWi3JGQyB3JlbGF0ZWRItsKX86rckqtDmgEFCAEQ-B0%3D%22%2C%22commandMetadata%22%3A%7B%22webCommandMetadata%22%3A%7B%22url%22%3A%22%2Fwatch%3Fv%3DA8C71-mSkAk%26list%3DRDA8C71-mSkAk%26start_radio%3D1%26pp%3DoAcB0gcJCcEJAYcqIYzv%22%2C%22webPageType%22%3A%22WEB_PAGE_TYPE_WATCH%22%2C%22rootVe%22%3A3832%7D%7D%2C%22watchEndpoint%22%3A%7B%22videoId%22%3A%22A8C71-mSkAk%22%2C%22playlistId%22%3A%22RDA8C71-mSkAk%22%2C%22params%22%3A%22OAHAAQG4BQE%253D%22%2C%22playerParams%22%3A%22oAcB0gcJCcEJAYcqIYzv%22%2C%22nofollow%22%3Atrue%2C%22loggingContext%22%3A%7B%22vssLoggingContext%22%3A%7B%22serializedContextData%22%3A%22Gg1SREE4QzcxLW1Ta0Fr%22%7D%7D%2C%22watchEndpointSupportedOnesieConfig%22%3A%7B%22html5PlaybackOnesieConfig%22%3A%7B%22commonConfig%22%3A%7B%22url%22%3A%22https%3A%2F%2Frr6---sn-hvcp4vox8o-i5oz.googlevideo.com%2Finitplayback%3Fsource%3Dyoutube%26oeis%3D1%26c%3DWEB%26oad%3D3200%26ovd%3D3200%26oaad%3D11000%26oavd%3D11000%26ocs%3D700%26oewis%3D1%26oputc%3D1%26ofpcc%3D1%26siu%3D1%26msp%3D1%26odepv%3D1%26onvi%3D1%26id%3D03c0bbd7e9929009%26ip%3D2402%253A9d80%253A858%253A27a0%253A10b3%253A27a%253Ae252%253Ae211%26initcwndbps%3D1398750%26mt%3D1751885571%26oweuc%3D%22%7D%7D%7D%7D%7D',
      };
}

class StreamProvider {
  final bool playable;
  final List<Audio>? audioFormats;
  final String statusMSG;
  StreamProvider(
      {required this.playable, this.audioFormats, this.statusMSG = ""});

  static Future<StreamProvider> fetch(String videoId) async {
    final yt = YoutubeExplode(CookieYT());

    try {
      final res = await yt.videos.streamsClient.getManifest(videoId);
      final audio = res.audioOnly;
      return StreamProvider(
        playable: true,
        statusMSG: "OK",
        audioFormats: audio
          .map((e) => Audio(
            itag: e.tag,
            audioCodec:
                e.audioCodec.contains('mp') ? Codec.mp4a : Codec.opus,
            bitrate: e.bitrate.bitsPerSecond,
            duration: e.duration ?? 0,
            loudnessDb: e.loudnessDb,
            url: e.url.toString(),
            size: e.size.totalBytes))
          .toList());
    } catch (e) {
      if (e is SocketException) {
        return StreamProvider(
          playable: false,
          statusMSG: "networkError",
        );
      } else if (e is VideoUnplayableException) {
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

  Map<String, dynamic> get hmStreamingData {
    return {
      "playable": playable,
      "statusMSG": statusMSG,
      "lowQualityAudio": lowQualityAudio?.toJson(),
      "highQualityAudio": highestQualityAudio?.toJson()
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

enum Codec { mp4a, opus }
