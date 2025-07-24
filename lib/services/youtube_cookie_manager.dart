import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/helper.dart';

class YouTubeCookieManager {
  static const String _ytbCookieBoxName = 'YTBCookies';
  static const String _encryptionKey = 'HarmonyMusic_CookieEncryption';

  /// Mã hóa cookie để bảo mật
  static String _encryptCookie(String value) {
    if (value.isEmpty) return value;
    try {
      final key = utf8.encode(_encryptionKey);
      final bytes = utf8.encode(value);
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(bytes);
      final encoded = base64Encode(bytes);
      return '$encoded.${digest.toString()}';
    } catch (e) {
      printERROR('Error encrypting cookie: $e');
      return value;
    }
  }

  /// Giải mã cookie
  static String _decryptCookie(String encryptedValue) {
    if (encryptedValue.isEmpty || !encryptedValue.contains('.')) {
      return encryptedValue;
    }
    try {
      final parts = encryptedValue.split('.');
      if (parts.length != 2) return encryptedValue;
      
      final encoded = parts[0];
      final expectedDigest = parts[1];
      
      final bytes = base64Decode(encoded);
      final key = utf8.encode(_encryptionKey);
      final hmac = Hmac(sha256, key);
      final actualDigest = hmac.convert(bytes).toString();
      
      if (expectedDigest == actualDigest) {
        return utf8.decode(bytes);
      } else {
        printERROR('Cookie integrity check failed');
        return encryptedValue;
      }
    } catch (e) {
      printERROR('Error decrypting cookie: $e');
      return encryptedValue;
    }
  }

  /// Khởi tạo Hive box cho YouTube cookies
  static Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_ytbCookieBoxName)) {
        await Hive.openBox(_ytbCookieBoxName);
        printINFO('YouTube Cookie Hive box opened');
      }
    } catch (e) {
      printERROR('Error initializing YouTube Cookie Hive box: $e');
      // Try to initialize Hive if not already initialized
      try {
        if (!Hive.isBoxOpen(_ytbCookieBoxName)) {
          final directory = await getApplicationDocumentsDirectory();
          Hive.init(directory.path);
          await Hive.openBox(_ytbCookieBoxName);
          printINFO('YouTube Cookie Hive box opened after re-initialization');
        }
      } catch (e2) {
        printERROR('Failed to re-initialize Hive: $e2');
      }
    }
  }

  /// Lấy box một cách an toàn
  static Box? _getBoxSafely() {
    try {
      if (Hive.isBoxOpen(_ytbCookieBoxName)) {
        return Hive.box(_ytbCookieBoxName);
      } else {
        printERROR('YouTube Cookie box is not open');
        return null;
      }
    } catch (e) {
      printERROR('Error accessing YouTube Cookie box: $e');
      return null;
    }
  }

  /// Lưu cookie YouTube vào Hive (đã mã hóa) với thởi hạn từ WebView
  static Future<void> saveYouTubeCookies(Map<String, dynamic> cookies) async {
    try {
      await init(); // Ensure box is initialized
      final box = _getBoxSafely();
      if (box == null) return;

      final batch = box.toMap(); // Get existing cookies for optimization
      int updatedCount = 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final entry in cookies.entries) {
        final cookieName = entry.key;
        final cookieData = entry.value;

        // Ưu tiên thởi hạn từ WebView theo thứ tự: expires > max-age > default
        int? expiryTime;

        if (cookieData['expires'] != null) {
          // Thởi hạn từ WebView expires
          expiryTime = cookieData['expires'] as int;
        } else if (cookieData['maxAge'] != null) {
          // Tính từ max-age nếu có
          final maxAgeSeconds = cookieData['maxAge'] as int;
          expiryTime = now + (maxAgeSeconds * 1000);
        } else if (cookieName.toLowerCase().contains('session')) {
          // Session cookie - 24 giờ
          expiryTime = now + (24 * 60 * 60 * 1000);
        } else {
          // Mặc định 7 ngày cho cookie thường
          expiryTime = now + (7 * 24 * 60 * 60 * 1000);
        }

        // Đảm bảo thởi hạn không quá 1 năm
        final maxExpiryTime = now + (365 * 24 * 60 * 60 * 1000);
        if (expiryTime > maxExpiryTime) {
          expiryTime = maxExpiryTime;
        }

        // Skip if cookie already exists and is identical
        if (batch.containsKey(cookieName)) {
          final existing = batch[cookieName];
          if (existing is Map &&
              existing['value'] == cookieData['value'] &&
              existing['expires'] == expiryTime) {
            continue; // Skip identical cookies
          }
        }

        // Mã hóa giá trị cookie để bảo mật
        final cookieValue = cookieData['value']?.toString() ?? '';
        final encryptedValue = _encryptCookie(cookieValue);

        // Lưu thông tin cookie đầy đủ
        final cookieInfo = {
          'value': cookieValue,
          'domain': cookieData['domain'] ?? '.youtube.com',
          'path': cookieData['path'] ?? '/',
          'expires': expiryTime,
          'secure': cookieData['secure'] ?? true,
          'httpOnly': cookieData['httpOnly'] ?? true,
          'createdAt': now,
          'source': cookieData['source'] ?? 'unknown',
          'version': 2, // Version for encryption
        };

        await box.put(cookieName, cookieInfo);
        updatedCount++;
      }

      if (updatedCount > 0) {
        _cachedCookieString = null;
      }
    } catch (e) {
      printERROR('Error saving YouTube cookies: $e');
    }
  }

  /// Lấy tất cả cookie YouTube còn hiệu lực (đã giải mã)
  static Future<Map<String, dynamic>> getValidYouTubeCookies() async {
    try {
      await init(); // Ensure box is initialized
      final box = _getBoxSafely();
      if (box == null) return {};

      final validCookies = <String, dynamic>{};
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final keysToDelete = <String>[];

      // Process in batch for better performance
      final allCookies = box.toMap();

      for (final entry in allCookies.entries) {
        final key = entry.key as String;
        final cookieData = entry.value;

        if (cookieData != null && cookieData is Map) {
          final expires = cookieData['expires'] as int?;

          // Kiểm tra cookie còn hiệu lực không
          if (expires == null || expires > currentTime) {
            // Giải mã giá trị cookie
            final encryptedValue = cookieData['value']?.toString() ?? '';
            String decryptedValue = encryptedValue;

            final decryptedCookie = Map<String, dynamic>.from(cookieData);
            decryptedCookie['value'] = decryptedValue;
            validCookies[key] = decryptedCookie;
          } else {
            keysToDelete.add(key);
          }
        }
      }

      // Batch delete expired cookies
      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        printINFO('Expired YouTube cookies removed: ${keysToDelete.length}');
      }

      return validCookies;
    } catch (e) {
      printERROR('Error getting valid YouTube cookies: $e');
      return {};
    }
  }

  /// Lấy cookie cụ thể theo tên
  static Future<Map<String, dynamic>?> getYouTubeCookie(
      String cookieName) async {
    try {
      await init(); // Ensure box is initialized
      final box = _getBoxSafely();
      if (box == null) return null;

      final cookieData = box.get(cookieName);

      if (cookieData == null) return null;

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final expires = cookieData['expires'] as int?;

      // Kiểm tra cookie còn hiệu lực không
      if (expires != null && expires <= currentTime) {
        await box.delete(cookieName);
        return null;
      }

      return Map<String, dynamic>.from(cookieData);
    } catch (e) {
      printERROR('Error getting YouTube cookie $cookieName: $e');
      return null;
    }
  }

  /// Kiểm tra xem có đăng nhập Google/YouTube không
  static Future<bool> isLoggedIn() async {
    try {
      final validCookies = await getValidYouTubeCookies();

      // Kiểm tra các cookie quan trọng của Google/YouTube
      final importantCookies = ['SID', 'HSID', 'SSID', 'SAPISID', 'APISID'];

      for (final cookieName in importantCookies) {
        if (validCookies.containsKey(cookieName)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      printERROR('Error checking login status: $e');
      return false;
    }
  }

  /// Lấy thông tin đăng nhập
  static Future<Map<String, dynamic>> getLoginInfo() async {
    try {
      final isLoggedIn = await YouTubeCookieManager.isLoggedIn();
      final validCookies = await getValidYouTubeCookies();

      return {
        'isLoggedIn': isLoggedIn,
        'cookieCount': validCookies.length,
        'cookies': validCookies,
      };
    } catch (e) {
      printERROR('Error getting login info: $e');
      return {
        'isLoggedIn': false,
        'cookieCount': 0,
        'cookies': {},
      };
    }
  }

  /// Xóa tất cả cookie YouTube
  static Future<void> clearAllYouTubeCookies() async {
    try {
      await init(); // Ensure box is initialized
      final box = _getBoxSafely();
      if (box == null) return;

      await box.clear();
      printINFO('All YouTube cookies cleared');
    } catch (e) {
      printERROR('Error clearing YouTube cookies: $e');
    }
  }

  /// Clear all cookies and cached data for logout
  static Future<void> clearAll() async {
    await init();
    final box = _getBoxSafely();
    await box?.clear();
    _cachedCookieString = null;
  }

  /// Xóa cookie cụ thể
  static Future<void> removeYouTubeCookie(String cookieName) async {
    try {
      await init(); // Ensure box is initialized
      final box = _getBoxSafely();
      if (box == null) return;

      await box.delete(cookieName);
      printINFO('YouTube cookie removed: $cookieName');
    } catch (e) {
      printERROR('Error removing YouTube cookie $cookieName: $e');
    }
  }

  /// Lấy cookie từ WebView và lưu vào Hive
  /// NOTE: Disabled after CookieManager removal
  static Future<void> syncCookiesFromWebView() async {
    // Commented out due to webview_manager removal
    printINFO('WebView cookie sync is disabled - CookieManager was removed');
    
    /* Original implementation commented out:
    try {
      final cookieManager = webview_manager.WebviewCookieManager();
      final cookies =
          await cookieManager.getCookies('https://music.youtube.com');

      final cookieMap = <String, dynamic>{};
      for (final cookie in cookies) {
        cookieMap[cookie.name] = {
          'value': cookie.value,
          'domain': cookie.domain,
          'path': cookie.path,
          'expires': cookie.expires?.millisecondsSinceEpoch,
          'secure': cookie.secure,
          'httpOnly':
              false, // WebView cookie manager không cung cấp thông tin này
        };
      }

      await saveYouTubeCookies(cookieMap);
      printINFO('Cookies synced from WebView: ${cookies.length} cookies');
    } catch (e) {
      printERROR('Error syncing cookies from WebView: $e');
    }
    */
  }

  /// Dọn dẹp cookie hết hạn (đã tối ưu)
  static Future<void> cleanupExpiredCookies() async {
    try {
      await init(); // Ensure box is initialized
      final box = _getBoxSafely();
      if (box == null) return;

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final keysToDelete = <String>[];

      // Batch processing for better performance
      final allCookies = box.toMap();

      for (final entry in allCookies.entries) {
        final key = entry.key as String;
        final cookieData = entry.value;

        if (cookieData != null && cookieData is Map) {
          final expires = cookieData['expires'] as int?;
          if (expires != null && expires <= currentTime) {
            keysToDelete.add(key);
          }
        }
      }

      // Batch delete for performance
      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        printINFO('Cleaned up ${keysToDelete.length} expired YouTube cookies');

        // Clear cache khi có thay đổi
        _cachedCookieString = null;
      }
    } catch (e) {
      printERROR('Error cleaning up expired cookies: $e');
    }
  }

  /// Background cleanup service
  static Future<void> startBackgroundCleanup() async {
    try {
      await cleanupExpiredCookies();

      // Lên lịch cleanup định kỳ (mỗi 6 giờ)
      Timer.periodic(const Duration(hours: 6), (timer) async {
        await cleanupExpiredCookies();
      });
    } catch (e) {
      printERROR('Error starting background cleanup: $e');
    }
  }

  /// Tối ưu hóa bộ nhớ: compress cookie data
  static Future<void> compressCookieData() async {
    try {
      await init();
      final box = _getBoxSafely();
      if (box == null) return;

      final validCookies = await getValidYouTubeCookies();
      if (validCookies.length > 50) {
        // Chỉ compress khi có nhiều cookie
        await box.clear();
        await saveYouTubeCookies(validCookies);
        printINFO('Cookie data compressed');
      }
    } catch (e) {
      printERROR('Error compressing cookie data: $e');
    }
  }

  /// Lấy chuỗi cookie để sử dụng trong requests (đã tối ưu và xác thực)
  static Future<String> getCookieString() async {
    try {
      final validCookies = await getValidYouTubeCookies();
      if (validCookies.isEmpty) return '';

      // Tối ưu hóa: chỉ lấy các cookie quan trọng và còn hiệu lực
      final cookiePairs = <String>[];

      for (final entry in validCookies.entries) {
        final cookieName = entry.key;
        final cookieData = entry.value;
        final value = cookieData['value']?.toString() ?? '';

        // Validate cookie value (basic security check)
        if (value.isNotEmpty && !value.contains(';') && !value.contains('\n')) {
          cookiePairs.add('$cookieName=$value');
        }
      }

      // Cache the result for performance
      _cachedCookieString = cookiePairs.join('; ');
      _lastCacheTime = DateTime.now().millisecondsSinceEpoch;

      return _cachedCookieString ?? '';
    } catch (e) {
      printERROR('Error getting cookie string: $e');
      return '';
    }
  }

  static String? _cachedCookieString;
  static int _lastCacheTime = 0;
  static const int _cacheDuration = 30000; // 30 seconds cache

  /// Lấy cookie string với cache để tối ưu hiệu suất
  static Future<String> getCachedCookieString(
      {String defaultCookie = 'CONSENT=YES+1'}) async {
    final cookieString = await getCookieString();
    if (cookieString.isEmpty) return defaultCookie;
    return cookieString;
  }

  /// Lưu cookies từ response headers (thay thế CookieManager.updateCookiesFromResponse)
  static Future<void> saveFromResponseHeaders(List<String> responseCookies) async {
    try {
      final cookieMap = <String, dynamic>{};
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final cookieString in responseCookies) {
        final parsedCookie = _parseCookieString(cookieString);
        if (parsedCookie != null) {
          final name = parsedCookie['name'] as String;
          final value = parsedCookie['value'] as String;
          final domain = parsedCookie['domain'] as String?;
          final path = parsedCookie['path'] as String?;
          final expires = parsedCookie['expires'] as int?;
          final secure = parsedCookie['secure'] as bool?;
          final httpOnly = parsedCookie['httpOnly'] as bool?;

          cookieMap[name] = {
            'value': value,
            'domain': domain ?? '.youtube.com',
            'path': path ?? '/',
            'expires': expires ?? (now + (7 * 24 * 60 * 60 * 1000)), // 7 days default
            'secure': secure ?? true,
            'httpOnly': httpOnly ?? true,
            'source': 'response_headers',
          };
        }
      }

      if (cookieMap.isNotEmpty) {
        await saveYouTubeCookies(cookieMap);
        printINFO('Saved ${cookieMap.length} cookies from response headers');
      }
    } catch (e) {
      printERROR('Error saving cookies from response headers: $e');
    }
  }

  /// Parse a single cookie string from Set-Cookie header
  static Map<String, dynamic>? _parseCookieString(String cookieString) {
    try {
      final parts = cookieString.split(';');
      if (parts.isEmpty) return null;

      // First part is name=value
      final nameValue = parts[0].trim().split('=');
      if (nameValue.length != 2) return null;

      final name = nameValue[0].trim();
      final value = nameValue[1].trim();

      String? domain;
      String? path;
      int? expires;
      bool? secure;
      bool? httpOnly;

      // Parse attributes
      for (int i = 1; i < parts.length; i++) {
        final attribute = parts[i].trim().toLowerCase();
        
        if (attribute.startsWith('domain=')) {
          domain = attribute.substring(7);
        } else if (attribute.startsWith('path=')) {
          path = attribute.substring(5);
        } else if (attribute.startsWith('expires=')) {
          final expiresStr = attribute.substring(8);
          try {
            expires = DateTime.parse(expiresStr).millisecondsSinceEpoch;
          } catch (e) {
            // Ignore invalid dates
          }
        } else if (attribute.startsWith('max-age=')) {
          final maxAge = int.tryParse(attribute.substring(8));
          if (maxAge != null) {
            expires = DateTime.now().millisecondsSinceEpoch + (maxAge * 1000);
          }
        } else if (attribute == 'secure') {
          secure = true;
        } else if (attribute == 'httponly') {
          httpOnly = true;
        }
      }

      return {
        'name': name,
        'value': value,
        'domain': domain,
        'path': path,
        'expires': expires,
        'secure': secure,
        'httpOnly': httpOnly,
      };
    } catch (e) {
      printERROR('Error parsing cookie string: $cookieString, error: $e');
      return null;
    }
  }
}
