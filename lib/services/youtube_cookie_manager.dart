import 'package:hive/hive.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart' as webview_manager;
import '../utils/helper.dart';

class YouTubeCookieManager {
  static const String _ytbCookieBoxName = 'YTBCookies';
  
  /// Khởi tạo Hive box cho YouTube cookies
  static Future<void> init() async {
    try {
      await Hive.openBox(_ytbCookieBoxName);
      printINFO('YouTube Cookie Hive box initialized');
    } catch (e) {
      printERROR('Error initializing YouTube Cookie Hive box: $e');
    }
  }

  /// Lưu cookie YouTube vào Hive
  static Future<void> saveYouTubeCookies(Map<String, dynamic> cookies) async {
    try {
      final box = Hive.box(_ytbCookieBoxName);
      
      for (final entry in cookies.entries) {
        final cookieName = entry.key;
        final cookieData = entry.value;
        
        // Lưu thông tin cookie đầy đủ
        final cookieInfo = {
          'value': cookieData['value'] ?? cookieData.toString(),
          'domain': cookieData['domain'] ?? '.youtube.com',
          'path': cookieData['path'] ?? '/',
          'expires': cookieData['expires'] ?? cookieData['expirationDate'],
          'secure': cookieData['secure'] ?? true,
          'httpOnly': cookieData['httpOnly'] ?? false,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        };
        
        await box.put(cookieName, cookieInfo);
      }
      
      printINFO('YouTube cookies saved successfully');
    } catch (e) {
      printERROR('Error saving YouTube cookies: $e');
    }
  }

  /// Lấy tất cả cookie YouTube còn hiệu lực
  static Future<Map<String, dynamic>> getValidYouTubeCookies() async {
    try {
      final box = Hive.box(_ytbCookieBoxName);
      final validCookies = <String, dynamic>{};
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      for (final key in box.keys) {
        final cookieData = box.get(key);
        if (cookieData != null && cookieData is Map) {
          final expires = cookieData['expires'] as int?;
          
          // Kiểm tra cookie còn hiệu lực không
          if (expires == null || expires > currentTime) {
            validCookies[key as String] = cookieData;
          } else {
            // Xóa cookie đã hết hạn
            await box.delete(key);
            printINFO('Expired YouTube cookie removed: $key');
          }
        }
      }
      
      return validCookies;
    } catch (e) {
      printERROR('Error getting valid YouTube cookies: $e');
      return {};
    }
  }

  /// Lấy cookie cụ thể theo tên
  static Future<Map<String, dynamic>?> getYouTubeCookie(String cookieName) async {
    try {
      final box = Hive.box(_ytbCookieBoxName);
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
      final box = Hive.box(_ytbCookieBoxName);
      await box.clear();
      printINFO('All YouTube cookies cleared');
    } catch (e) {
      printERROR('Error clearing YouTube cookies: $e');
    }
  }

  /// Xóa cookie cụ thể
  static Future<void> removeYouTubeCookie(String cookieName) async {
    try {
      final box = Hive.box(_ytbCookieBoxName);
      await box.delete(cookieName);
      printINFO('YouTube cookie removed: $cookieName');
    } catch (e) {
      printERROR('Error removing YouTube cookie $cookieName: $e');
    }
  }

  /// Lấy cookie từ WebView và lưu vào Hive
  static Future<void> syncCookiesFromWebView() async {
    try {
      final cookieManager = webview_manager.WebviewCookieManager();
      final cookies = await cookieManager.getCookies('https://youtube.com');
      
      final cookieMap = <String, dynamic>{};
      for (final cookie in cookies) {
        cookieMap[cookie.name] = {
          'value': cookie.value,
          'domain': cookie.domain,
          'path': cookie.path,
          'expires': cookie.expires?.millisecondsSinceEpoch,
          'secure': cookie.secure,
          'httpOnly': false, // WebView cookie manager không cung cấp thông tin này
        };
      }
      
      await saveYouTubeCookies(cookieMap);
      printINFO('Cookies synced from WebView: ${cookies.length} cookies');
    } catch (e) {
      printERROR('Error syncing cookies from WebView: $e');
    }
  }

  /// Dọn dẹp cookie hết hạn
  static Future<void> cleanupExpiredCookies() async {
    try {
      final box = Hive.box(_ytbCookieBoxName);
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      int removedCount = 0;
      
      for (final key in box.keys.toList()) {
        final cookieData = box.get(key);
        if (cookieData != null && cookieData is Map) {
          final expires = cookieData['expires'] as int?;
          if (expires != null && expires <= currentTime) {
            await box.delete(key);
            removedCount++;
          }
        }
      }
      
      if (removedCount > 0) {
        printINFO('Cleaned up $removedCount expired YouTube cookies');
      }
    } catch (e) {
      printERROR('Error cleaning up expired cookies: $e');
    }
  }

  /// Lấy chuỗi cookie để sử dụng trong requests
  static Future<String> getCookieString() async {
    try {
      final validCookies = await getValidYouTubeCookies();
      final cookiePairs = <String>[];
      
      for (final entry in validCookies.entries) {
        cookiePairs.add('${entry.key}=${entry.value['value']}');
      }
      
      return cookiePairs.join('; ');
    } catch (e) {
      printERROR('Error getting cookie string: $e');
      return '';
    }
  }
}