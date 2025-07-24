import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../utils/helper.dart';
import 'youtube_cookie_manager.dart';

typedef Validator = bool Function(String? value);
typedef Processor = Future<void> Function(String value, Box prefsBox);

class ConfigExtractor {
  final List<String> keys;
  final Validator validator;
  final Processor processor;

  ConfigExtractor(
      {required this.keys, required this.validator, required this.processor});
}

class YouTubeConfigService {
  static const String _ytbPrefsBoxName = 'YTBPrefs';
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36';

  static final Dio _dio = Dio();
  static Box? _prefsBox;

  /// Collection of config extractors you can extend as needed.
  static final Map<String, ConfigExtractor> _extractors = {
    'DATASYNC_ID': ConfigExtractor(
      keys: ['USER_SESSION_ID', 'DATASYNC_ID', 'datasyncId'],
      validator: _validateDatasyncId,
      processor: _processSimpleValue('DATASYNC_ID'),
    ),
    'VISITOR_DATA': ConfigExtractor(
      keys: ['VISITOR_DATA'],
      validator: _validateVisitorData,
      processor: _processSimpleValue('VISITOR_DATA'),
    ),
    'SESSION_TOKEN': ConfigExtractor(
      keys: ['XSRF_TOKEN'],
      validator: _validateSessionToken,
      processor: _processSimpleValue('SESSION_TOKEN'),
    ),
    'INNERTUBE_API_KEY': ConfigExtractor(
      keys: ['INNERTUBE_API_KEY'],
      validator: _validateApiKey,
      processor: _processSimpleValue('INNERTUBE_API_KEY'),
    ),
    'CLIENT_VERSION': ConfigExtractor(
      keys: ['INNERTUBE_CLIENT_VERSION'],
      validator: _validateClientVersion,
      processor: _processSimpleValue('CLIENT_VERSION'),
    ),
    'LOGGED_IN': ConfigExtractor(
      keys: ['LOGGED_IN'],
      validator: _validateLoggedIn,
      processor: _processSimpleValue('LOGGED_IN'),
    ),
  };

  /// Initialize the service and Hive box.
  static Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_ytbPrefsBoxName)) {
        _prefsBox = await Hive.openBox(_ytbPrefsBoxName);
        printINFO('YouTube Prefs box opened');
      } else {
        _prefsBox = Hive.box(_ytbPrefsBoxName);
      }

      _dio.options = BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        followRedirects: true,
        maxRedirects: 5,
      );
    } catch (e) {
      printERROR('Error initializing YouTube Config Service: $e');
    }
  }

  /// Fetch the raw YouTube config from the music.youtube.com page.
  /// Will try with cookies first, then fallback to without cookies if needed.
  static Future<Map<String, dynamic>?> fetchYouTubeConfig() async {
    try {
      await init();

      final cookies = await YouTubeCookieManager.getCachedCookieString();
      final headers = {
        'User-Agent': _userAgent,
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      };

      // Add cookies if available
      if (cookies.isNotEmpty) {
        headers['Cookie'] = cookies;
        printINFO('Fetching YouTube config with cookies');
      } else {
        printWARN('Fetching YouTube config without cookies (limited data)');
      }

      final response = await _dio.get(
        'https://music.youtube.com',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final config = _extractYtcfg(response.data.toString());
        if (config != null) {
          printINFO('Successfully extracted YouTube config');
          return config;
        } else {
          printWARN('No ytcfg found in response');
        }
      } else {
        printERROR('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      printERROR('Error fetching YouTube config: $e');
    }
    return null;
  }

  /// Extract ytcfg JSON object from the response string.
  static Map<String, dynamic>? _extractYtcfg(String responseData) {
    try {
      final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
      final match = reg.firstMatch(responseData);
      if (match != null) {
        final jsonString = match.group(1);
        return json.decode(jsonString!);
      }
    } catch (e) {
      printERROR('Error parsing ytcfg JSON: $e');
    }
    return null;
  }

  /// Main extraction and processing method - processes all configured extractors.
  ///
  /// Returns a map of extracted keys and their values (or null if missing).
  static Future<Map<String, String?>> extractAndSaveConfig() async {
    try {
      final config = await fetchYouTubeConfig();
      if (config == null) {
        return {'error': 'Failed to fetch config'};
      }

      if (_prefsBox == null) {
        await init();
      }
      final Box prefsBox = _prefsBox!;

      final results = <String, String?>{};
      for (final entry in _extractors.entries) {
        final key = entry.key;
        final extractor = entry.value;
        String? extractedValue;

        for (final configKey in extractor.keys) {
          final rawValue = config[configKey]?.toString();
          if (rawValue != null && extractor.validator(rawValue)) {
            final cleanValue =
                rawValue.replaceAll('|', '').replaceAll('||', '').trim();
            await extractor.processor(cleanValue, prefsBox);
            extractedValue = cleanValue;
            printINFO("Extracted $key from key '${configKey}': $cleanValue");
            break;
          }
        }

        if (extractedValue == null) {
          printWARN(
              "No valid $key found in config keys: ${config.keys.toList()}");
        }
        results[key] = extractedValue;
      }
      return results;
    } catch (e) {
      printERROR('Error in extractAndSaveConfig: $e');
      return {'error': e.toString()};
    }
  }

  /// Simple processor that stores the value in Hive box with metadata.
  static Processor _processSimpleValue(String key) {
    return (String value, Box prefsBox) async {
      final data = {
        'value': value,
        'extractedAt': DateTime.now().millisecondsSinceEpoch,
        'source': 'youtube_config_service',
      };
      await prefsBox.put(key, data);
      printINFO('Saved $key to YTBPrefs box');
    };
  }

  /// Validator for DATASYNC_ID (no pipes, min length 10, valid chars).
  static bool _validateDatasyncId(String? val) {
    if (val == null || val.isEmpty) return false;
    if (val.contains('|') || val.length < 10) return false;
    final validPattern = RegExp(r'^[a-zA-Z0-9_\-\.\+\=]+$');
    return validPattern.hasMatch(val);
  }

  /// Validator for VISITOR_DATA (simple non-empty check and proper format).
  static bool _validateVisitorData(String? val) {
    if (val == null || val.isEmpty) return false;
    // VISITOR_DATA should be base64-like format, at least 10 characters
    return val.length >= 10 && RegExp(r'^[a-zA-Z0-9_\-\%\=]+$').hasMatch(val);
  }

  /// Validator for SESSION_TOKEN (XSRF token format).
  static bool _validateSessionToken(String? val) {
    if (val == null || val.isEmpty) return false;
    // Session tokens are usually base64 encoded, at least 20 characters
    return val.length >= 20 && RegExp(r'^[a-zA-Z0-9_\-\+\/\=]+$').hasMatch(val);
  }

  /// Validator for API KEY.
  static bool _validateApiKey(String? val) {
    if (val == null || val.isEmpty) return false;
    // YouTube/Google API keys typically start with 'AIza' and are 39 characters
    return val.startsWith('AIza') && val.length >= 35;
  }

  /// Validator for CLIENT_VERSION.
  static bool _validateClientVersion(String? val) {
    if (val == null || val.isEmpty) return false;
    // Client version should be in format like '1.20250716.03.00'
    return RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(val);
  }

  /// Validator for LOGGED_IN status.
  static bool _validateLoggedIn(String? val) {
    if (val == null) return false;
    // Should be boolean values
    return val == 'true' || val == 'false';
  }

  /// Retrieve saved config value by key.
  static Future<String?> getSavedConfigValue(String key) async {
    if (_prefsBox == null) {
      await init();
    }
    final data = _prefsBox!.get(key);
    if (data != null && data is Map) {
      return data['value']?.toString();
    }
    return null;
  }

  /// Clear all saved YouTube config keys.
  static Future<void> clearSavedConfig() async {
    try {
      if (_prefsBox == null) {
        await init();
      }
      await _prefsBox!.deleteAll(_extractors.keys.toList());
      printINFO('Cleared saved YouTube configuration');
    } catch (e) {
      printERROR('Error clearing saved config: $e');
    }
  }

  /// Check if saved config needs refresh based on age (default 24h).
  static Future<bool> needsRefresh(
      {Duration maxAge = const Duration(hours: 24)}) async {
    try {
      if (_prefsBox == null) {
        await init();
      }
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final key in _extractors.keys) {
        final data = _prefsBox!.get(key);
        if (data == null) {
          return true; // Missing config triggers refresh
        }
        if (data is Map) {
          final extractedAt = data['extractedAt'] as int?;
          if (extractedAt == null ||
              (now - extractedAt) > maxAge.inMilliseconds) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      printERROR('Error checking refresh need: $e');
      return true;
    }
  }

  /// Refresh configuration if needed. Returns current config values.
  static Future<Map<String, String?>> refreshIfNeeded(
      {Duration maxAge = const Duration(hours: 24)}) async {
    if (await needsRefresh(maxAge: maxAge)) {
      printINFO('Refreshing YouTube configuration...');
      return await extractAndSaveConfig();
    } else {
      printINFO('YouTube configuration is still fresh, no refresh needed');
      final results = <String, String?>{};
      for (final key in _extractors.keys) {
        results[key] = await getSavedConfigValue(key);
      }
      return results;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get DATASYNC_ID for authenticated requests
  static Future<String?> getDatasyncId() async {
    return await getSavedConfigValue('DATASYNC_ID');
  }

  /// Get VISITOR_DATA for visitor identification
  static Future<String?> getVisitorData() async {
    return await getSavedConfigValue('VISITOR_DATA');
  }

  /// Get SESSION_TOKEN for XSRF protection
  static Future<String?> getSessionToken() async {
    return await getSavedConfigValue('SESSION_TOKEN');
  }

  /// Get INNERTUBE_API_KEY for API requests
  static Future<String?> getApiKey() async {
    return await getSavedConfigValue('INNERTUBE_API_KEY');
  }

  /// Get CLIENT_VERSION for version headers
  static Future<String?> getClientVersion() async {
    return await getSavedConfigValue('CLIENT_VERSION');
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final loggedIn = await getSavedConfigValue('LOGGED_IN');
    return loggedIn == 'true';
  }

  /// Create common headers for YouTube Music API requests
  static Future<Map<String, String>> getApiHeaders() async {
    final headers = <String, String>{
      'User-Agent': _userAgent,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final apiKey = await getApiKey();
    final clientVersion = await getClientVersion();
    final sessionToken = await getSessionToken();

    if (apiKey != null) {
      headers['X-YouTube-Client-Version'] = clientVersion ?? '1.20250716.03.00';
    }

    if (sessionToken != null) {
      headers['X-XSRF-TOKEN'] = sessionToken;
    }

    return headers;
  }

  /// Create InnerTube context for API requests
  static Future<Map<String, dynamic>> getInnerTubeContext() async {
    final visitorData = await getVisitorData();
    final clientVersion = await getClientVersion();
    final isUserLoggedIn = await isLoggedIn();

    return {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': clientVersion ?? '1.20250716.03.00',
        'hl': 'vi',
        'gl': 'VN',
        'platform': 'DESKTOP',
        'userAgent': _userAgent,
        if (visitorData != null) 'visitorData': visitorData,
      },
      'user': {
        'lockedSafetyMode': false,
      },
      'request': {
        'useSsl': true,
        'internalExperimentFlags': [],
      },
    };
  }

  /// Get cookies string for direct HTTP requests
  static Future<String> getCookiesForRequest() async {
    return await YouTubeCookieManager.getCachedCookieString();
  }

  /// Create headers with datasync and visitor data for special requests
  static Future<Map<String, String>> getAuthenticatedHeaders() async {
    final headers = await getApiHeaders();
    final cookies = await getCookiesForRequest();
    final datasyncId = await getDatasyncId();

    if (cookies.isNotEmpty) {
      headers['Cookie'] = cookies;
    }

    if (datasyncId != null) {
      headers['X-Goog-Visitor-Id'] = datasyncId;
    }

    return headers;
  }
}
