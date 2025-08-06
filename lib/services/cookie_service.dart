import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart' as getx;
import '../utils/error_handler.dart';
import '../utils/helper.dart';
import 'youtube_cookie_manager.dart';
import 'youtube_config_service.dart';
import 'constant.dart';

/// Abstract interface cho Cookie Service
abstract class ICookieService {
  Future<void> initializeCookies();
  Future<String> getCookieString();
  Future<void> refreshCookies();
  Future<String?> generateSAPISIDHASH({String? datasyncId, String? origin});
  Future<void> handleResponseCookies(List<String> responseCookies);
  String mergeCookies(String existing, String newCookies);
}

/// Concrete implementation của Cookie Service
class CookieService extends getx.GetxService implements ICookieService {
  static CookieService? _instance;
  static CookieService get instance => _instance ??= CookieService._();

  CookieService._();

  @override
  void onInit() {
    super.onInit();
    initializeCookies();
  }

  @override
  Future<void> initializeCookies() async {
    try {
      // Khởi tạo cookie từ storage hoặc tạo mới
      final cookieString = await getCookieString();
      if (cookieString.isEmpty) {
        // Fallback cookie nếu không có cookie nào
        await _setFallbackCookie();
      }
      printINFO('Cookie service initialized successfully');
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Cookie initialization');
      await _setFallbackCookie();
    }
  }

  Future<void> _setFallbackCookie() async {
    try {
      // Sử dụng consent cookie cơ bản
      const fallbackCookie = 'CONSENT=YES+1';
      // Note: Trong thực tế, bạn có thể muốn lưu cookie này vào storage
      printINFO('Set fallback cookie: $fallbackCookie');
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Fallback cookie setup');
    }
  }

  @override
  Future<String> getCookieString() async {
    try {
      return await YouTubeCookieManager.getCachedCookieString();
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get cookie string');
      return 'CONSENT=YES+1'; // Fallback
    }
  }

  @override
  Future<void> refreshCookies() async {
    try {
      // Clear cache để force refresh
      await YouTubeCookieManager.cleanupExpiredCookies();

      final youtubeCookies = await getCookieString();
      if (youtubeCookies.isNotEmpty) {
        printINFO(
            'YouTube cookies refreshed (${youtubeCookies.split(';').length} cookies)');
      } else {
        printINFO('No YouTube cookies to refresh');
      }
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Cookie refresh');
    }
  }

  @override
  Future<String?> generateSAPISIDHASH(
      {String? datasyncId, String? origin}) async {
    try {
      // Lấy SAPISID cookie
      final sapisidCookie =
          await YouTubeCookieManager.getYouTubeCookie('SAPISID');
      if (sapisidCookie == null) {
        AppErrorHandler.logWarning(
            "No SAPISID cookie found for SAPISIDHASH generation",
            context: 'SAPISIDHASH');
        return null;
      }

      // Lấy datasyncId nếu không được truyền vào
      String? finalDatasyncId = datasyncId;
      if (finalDatasyncId == null) {
        finalDatasyncId = await YouTubeConfigService.getDatasyncId();
        if (finalDatasyncId == null) {
          AppErrorHandler.logWarning(
              "No datasyncId available for SAPISIDHASH generation",
              context: 'SAPISIDHASH');
          return null;
        }
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
      final finalOrigin = origin ?? domain;

      final inputString = [
        finalDatasyncId,
        timestamp,
        sapisidCookie['value'],
        finalOrigin
      ].join(' ');

      final digest = _sha1(inputString);
      final sapisidHash = '${timestamp}_${digest}_u';

      return sapisidHash;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'SAPISIDHASH generation');
      return null;
    }
  }

  @override
  Future<void> handleResponseCookies(List<String> responseCookies) async {
    try {
      if (responseCookies.isNotEmpty) {
        await YouTubeCookieManager.saveFromResponseHeaders(responseCookies);
        printINFO('Saved ${responseCookies.length} cookies from response');
      }
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Response cookie handling');
    }
  }

  @override
  String mergeCookies(String existing, String newCookies) {
    final cookieMap = <String, String>{};

    // Parse existing cookies
    for (final cookie in existing.split(';')) {
      final parts = cookie.trim().split('=');
      if (parts.length == 2) {
        cookieMap[parts[0]] = parts[1];
      }
    }

    // Parse và merge new cookies
    for (final cookie in newCookies.split(';')) {
      final parts = cookie.trim().split('=');
      if (parts.length == 2) {
        cookieMap[parts[0]] = parts[1]; // Override existing
      }
    }

    return cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// Helper method để tạo SHA1 hash
  String _sha1(String input) {
    var bytes = utf8.encode(input);
    var digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Kiểm tra xem có cookie authentication không
  Future<bool> hasAuthenticationCookies() async {
    try {
      final sapisid = await YouTubeCookieManager.getYouTubeCookie('SAPISID');
      final datasyncId = await YouTubeConfigService.getDatasyncId();
      return sapisid != null && datasyncId != null;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Authentication check');
      return false;
    }
  }

  /// Tạo authorization header nếu có credentials
  Future<Map<String, String>?> getAuthorizationHeaders() async {
    try {
      final sapisidHash = await generateSAPISIDHASH();
      if (sapisidHash != null) {
        return {'Authorization': 'SAPISIDHASH $sapisidHash'};
      }
      return null;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Authorization headers');
      return null;
    }
  }

  /// Clean up expired cookies
  Future<void> cleanupExpiredCookies() async {
    try {
      await YouTubeCookieManager.cleanupExpiredCookies();
      printINFO('Expired cookies cleaned up');
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Cookie cleanup');
    }
  }
}
