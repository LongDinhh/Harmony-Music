import 'dart:convert';
import 'package:get/get.dart' as getx;
import '../utils/error_handler.dart';
import '../utils/helper.dart';
import 'nav_parser.dart' as nav_parser;

/// Abstract interface cho YouTube Data Parser Service
abstract class IYouTubeDataParserService {
  Map<String, dynamic>? extractYtcfg(String responseData);
  String? extractDatasyncId(Map<String, dynamic> config);
  bool isValidDatasyncId(String? datasyncId);

  // Parsing methods for different data types
  List<dynamic> parseMixedContent(List<dynamic> results);
  List<dynamic> parseSearchResults(List<dynamic> results,
      List<String> resultTypes, String? type, String category);
  List<dynamic> parsePlaylistItems(List<dynamic> results,
      {List<dynamic>? artistsM,
      List<dynamic>? thumbnailsM,
      Map<String, dynamic>? albumIdName,
      String? albumYear,
      bool isAlbum = false});
  Map<String, dynamic> parseAlbumHeader(Map<String, dynamic> response);
  Map<String, dynamic> parseChartsItem(dynamic result);
  List<dynamic> parseWatchPlaylist(List<dynamic> contents);
  Map<String, dynamic> parseArtistContents(List<dynamic> results);
}

/// Concrete implementation của YouTube Data Parser Service
class YouTubeDataParserService extends getx.GetxService
    implements IYouTubeDataParserService {
  static YouTubeDataParserService? _instance;
  static YouTubeDataParserService get instance =>
      _instance ??= YouTubeDataParserService._();

  YouTubeDataParserService._();

  @override
  Map<String, dynamic>? extractYtcfg(String responseData) {
    try {
      final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
      final matches = reg.firstMatch(responseData);
      if (matches != null) {
        return json.decode(matches.group(1).toString());
      }
      return null;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'YTCFG extraction');
      return null;
    }
  }

  @override
  String? extractDatasyncId(Map<String, dynamic> config) {
    try {
      // Thử các key có thể chứa datasyncId theo thứ tự ưu tiên
      final possibleKeys = ['USER_SESSION_ID', 'DATASYNC_ID', 'datasyncId'];

      for (final key in possibleKeys) {
        final value = config[key]?.toString();
        if (value != null && value.isNotEmpty) {
          // Xóa ký tự | và validate format
          final cleanValue =
              value.replaceAll('|', '').replaceAll('||', '').trim();
          if (isValidDatasyncId(cleanValue)) {
            printINFO("Extracted datasyncId from key '$key': $cleanValue");
            return cleanValue;
          }
        }
      }

      printWARN("No valid datasyncId found in config: ${config.keys.toList()}");
      return null;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'DatasyncId extraction');
      return null;
    }
  }

  @override
  bool isValidDatasyncId(String? datasyncId) {
    if (datasyncId == null || datasyncId.isEmpty) return false;

    // Basic validation: should not contain pipes, should have reasonable length
    if (datasyncId.contains('|') || datasyncId.length < 10) {
      return false;
    }

    // Should contain alphanumeric characters and common special chars
    final validPattern = RegExp(r'^[a-zA-Z0-9_\-\.\+\=]+$');
    return validPattern.hasMatch(datasyncId);
  }

  @override
  List<dynamic> parseMixedContent(List<dynamic> results) {
    try {
      // Import the function from nav_parser.dart and call it directly
      return nav_parser.parseMixedContent(results);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Mixed content parsing');
      return [];
    }
  }

  @override
  List<dynamic> parseSearchResults(List<dynamic> results,
      List<String> resultTypes, String? type, String category) {
    try {
      // Delegate to existing parseSearchResults function from nav_parser.dart
      return nav_parser.parseSearchResults(
          results, resultTypes, type, category);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Search results parsing');
      return [];
    }
  }

  @override
  List<dynamic> parsePlaylistItems(List<dynamic> results,
      {List<dynamic>? artistsM,
      List<dynamic>? thumbnailsM,
      Map<String, dynamic>? albumIdName,
      String? albumYear,
      bool isAlbum = false}) {
    try {
      // Delegate to existing parsePlaylistItems function from nav_parser.dart
      return nav_parser.parsePlaylistItems(results,
          artistsM: artistsM,
          thumbnailsM: thumbnailsM,
          albumIdName: albumIdName,
          albumYear: albumYear,
          isAlbum: isAlbum);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Playlist items parsing');
      return [];
    }
  }

  @override
  Map<String, dynamic> parseAlbumHeader(Map<String, dynamic> response) {
    try {
      // Delegate to existing parseAlbumHeader function from nav_parser.dart
      return nav_parser.parseAlbumHeader(response);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Album header parsing');
      return {};
    }
  }

  @override
  Map<String, dynamic> parseChartsItem(dynamic result) {
    try {
      // Delegate to existing parseChartsItem function from nav_parser.dart
      return nav_parser.parseChartsItem(result);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Charts item parsing');
      return {};
    }
  }

  @override
  List<dynamic> parseWatchPlaylist(List<dynamic> contents) {
    try {
      // Delegate to existing parseWatchPlaylist function from nav_parser.dart
      return nav_parser.parseWatchPlaylist(contents);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Watch playlist parsing');
      return [];
    }
  }

  @override
  Map<String, dynamic> parseArtistContents(List<dynamic> results) {
    try {
      // Delegate to existing parseArtistContents function from nav_parser.dart
      return nav_parser.parseArtistContents(results);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Artist contents parsing');
      return {};
    }
  }

  /// Parse visitor data from config response
  String? parseVisitorData(Map<String, dynamic> config) {
    try {
      return config['VISITOR_DATA']?.toString();
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Visitor data parsing');
      return null;
    }
  }

  /// Parse API key from config response
  String? parseApiKey(Map<String, dynamic> config) {
    try {
      return config['INNERTUBE_API_KEY']?.toString();
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'API key parsing');
      return null;
    }
  }

  /// Parse client version from config response
  String? parseClientVersion(Map<String, dynamic> config) {
    try {
      return config['INNERTUBE_CLIENT_VERSION']?.toString();
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Client version parsing');
      return null;
    }
  }

  /// Parse session token from config response
  String? parseSessionToken(Map<String, dynamic> config) {
    try {
      return config['XSRF_TOKEN']?.toString();
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Session token parsing');
      return null;
    }
  }

  /// Generic method to safely extract nested data using navigation path
  dynamic safeNavigation(dynamic data, List<dynamic> path) {
    try {
      return nav_parser.nav(data, path);
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Safe navigation');
      return null;
    }
  }

  /// Parse duration from text string (e.g., "3:45" -> seconds)
  int? parseDurationToSeconds(String? durationText) {
    try {
      if (durationText == null || durationText.isEmpty) return null;

      final parts = durationText.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return (minutes * 60) + seconds;
      } else if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        return (hours * 3600) + (minutes * 60) + seconds;
      }
      return null;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Duration parsing');
      return null;
    }
  }

  /// Parse view count from text (e.g., "1.2M views" -> 1200000)
  int? parseViewCount(String? viewText) {
    try {
      if (viewText == null || viewText.isEmpty) return null;

      // Remove "views" and other text, keep only numbers and multipliers
      final cleanText = viewText
          .toLowerCase()
          .replaceAll('views', '')
          .replaceAll('view', '')
          .replaceAll(',', '')
          .trim();

      if (cleanText.contains('k')) {
        final number = double.tryParse(cleanText.replaceAll('k', ''));
        return ((number ?? 0) * 1000).toInt();
      } else if (cleanText.contains('m')) {
        final number = double.tryParse(cleanText.replaceAll('m', ''));
        return ((number ?? 0) * 1000000).toInt();
      } else if (cleanText.contains('b')) {
        final number = double.tryParse(cleanText.replaceAll('b', ''));
        return ((number ?? 0) * 1000000000).toInt();
      } else {
        return int.tryParse(cleanText);
      }
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'View count parsing');
      return null;
    }
  }

  /// Validate parsed data structure
  bool validateParsedData(dynamic data, List<String> requiredFields) {
    try {
      if (data == null || data is! Map<String, dynamic>) return false;

      final dataMap = data;
      for (final field in requiredFields) {
        if (!dataMap.containsKey(field) || dataMap[field] == null) {
          return false;
        }
      }
      return true;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Data validation');
      return false;
    }
  }
}
