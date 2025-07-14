import 'package:hive/hive.dart';
import '../utils/helper.dart';

class CookieManager {
  static const String _cookieBoxName = 'CookieStorage';
  static const String _cookieKey = 'youtube_cookies';

  /// Lưu trữ cookie theo key riêng biệt
  static const String _cookieKeysBoxName = 'CookieKeysStorage';

  /// Lưu cookie với thời gian hết hạn
  /// [cookieString] - Chuỗi cookie
  /// [expiresIn] - Thời gian hết hạn tính bằng milliseconds (null = vĩnh viễn)
  static Future<void> saveCookies(String cookieString, {int? expiresIn}) async {
    try {
      final box = await Hive.openBox(_cookieBoxName);

      // Tính thời gian hết hạn
      int? expiresAt;
      if (expiresIn != null) {
        expiresAt = DateTime.now().millisecondsSinceEpoch + expiresIn;
      }
      // Nếu expiresIn = null thì cookie sẽ vĩnh viễn (expiresAt = null)

      final cookieData = {
        'cookies': cookieString,
        'expiresAt': expiresAt,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await box.put(_cookieKey, cookieData);
      await box.close();
    } catch (e) {
      printERROR('Error saving cookies: $e');
    }
  }

  /// Lấy cookie nếu chưa hết hạn
  static Future<String?> getValidCookies() async {
    try {
      final box = await Hive.openBox(_cookieBoxName);

      if (!box.containsKey(_cookieKey)) {
        await box.close();
        return null;
      }

      final cookieData = box.get(_cookieKey);
      await box.close();

      if (cookieData == null) return null;

      final expiresAt = cookieData['expiresAt'] as int?;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Nếu expiresAt = null thì cookie vĩnh viễn
      if (expiresAt == null) {
        printINFO('Valid permanent cookies found');
        return cookieData['cookies'] as String;
      }

      // Kiểm tra xem cookie có hết hạn chưa
      if (currentTime >= expiresAt) {
        printINFO('Cookies have expired, removing...');
        await removeCookies();
        return null;
      }

      printINFO(
          'Valid cookies found, expires at: ${DateTime.fromMillisecondsSinceEpoch(expiresAt)}');
      return cookieData['cookies'] as String;
    } catch (e) {
      printERROR('Error getting cookies: $e');
      return null;
    }
  }

  /// Xóa cookie
  static Future<void> removeCookies() async {
    try {
      final box = await Hive.openBox(_cookieBoxName);
      await box.delete(_cookieKey);
      await box.close();
      printINFO('Cookies removed successfully');
    } catch (e) {
      printERROR('Error removing cookies: $e');
    }
  }

  /// Kiểm tra xem cookie có tồn tại và còn hiệu lực không
  static Future<bool> hasValidCookies() async {
    final cookies = await getValidCookies();
    return cookies != null && cookies.isNotEmpty;
  }

  /// Lấy thời gian còn lại của cookie (tính bằng giây)
  /// Trả về null nếu cookie vĩnh viễn hoặc không tồn tại
  static Future<int?> getRemainingTime() async {
    try {
      final box = await Hive.openBox(_cookieBoxName);

      if (!box.containsKey(_cookieKey)) {
        await box.close();
        return null;
      }

      final cookieData = box.get(_cookieKey);
      await box.close();

      if (cookieData == null) return null;

      final expiresAt = cookieData['expiresAt'] as int?;

      // Nếu expiresAt = null thì cookie vĩnh viễn
      if (expiresAt == null) {
        return null; // Vĩnh viễn
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final remainingTime = (expiresAt - currentTime) ~/ 1000; // Chuyển về giây

      return remainingTime > 0 ? remainingTime : null;
    } catch (e) {
      printERROR('Error getting remaining time: $e');
      return null;
    }
  }

  /// Lấy thông tin chi tiết về cookie
  static Future<Map<String, dynamic>?> getCookieInfo() async {
    try {
      final box = await Hive.openBox(_cookieBoxName);

      if (!box.containsKey(_cookieKey)) {
        await box.close();
        return null;
      }

      final cookieData = box.get(_cookieKey);
      await box.close();

      if (cookieData == null) return null;

      final expiresAt = cookieData['expiresAt'] as int?;
      final createdAt = cookieData['createdAt'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Xử lý cookie vĩnh viễn
      if (expiresAt == null) {
        return {
          'createdAt': DateTime.fromMillisecondsSinceEpoch(createdAt),
          'expiresAt': null,
          'isExpired': false,
          'remainingTime': null, // Vĩnh viễn
          'cookieCount': _countCookies(cookieData['cookies'] as String),
          'isPermanent': true,
        };
      }

      return {
        'createdAt': DateTime.fromMillisecondsSinceEpoch(createdAt),
        'expiresAt': DateTime.fromMillisecondsSinceEpoch(expiresAt),
        'isExpired': currentTime >= expiresAt,
        'remainingTime': (expiresAt - currentTime) ~/ 1000,
        'cookieCount': _countCookies(cookieData['cookies'] as String),
        'isPermanent': false,
      };
    } catch (e) {
      printERROR('Error getting cookie info: $e');
      return null;
    }
  }

  /// Đếm số lượng cookie trong chuỗi
  static int _countCookies(String cookieString) {
    if (cookieString.isEmpty) return 0;
    return cookieString.split('; ').length;
  }

  /// Cập nhật cookie nếu cần thiết
  /// [newCookieString] - Chuỗi cookie mới
  /// [expiresIn] - Thời gian hết hạn (null = vĩnh viễn)
  static Future<void> updateCookiesIfNeeded(String newCookieString,
      {int? expiresIn}) async {
    try {
      final currentCookies = await getValidCookies();

      // Nếu không có cookie hiện tại hoặc cookie khác với cookie mới
      if (currentCookies == null || currentCookies != newCookieString) {
        await saveCookies(newCookieString, expiresIn: expiresIn);
        printINFO('Cookies updated successfully');
      }
    } catch (e) {
      printERROR('Error updating cookies: $e');
    }
  }

  /// Lưu cookie vĩnh viễn (không bao giờ hết hạn)
  static Future<void> savePermanentCookies(String cookieString) async {
    await saveCookies(cookieString, expiresIn: null);
  }

  /// Lưu cookie với thời gian hết hạn tính bằng ngày
  static Future<void> saveCookiesWithDays(String cookieString, int days) async {
    final expiresIn =
        days * 24 * 60 * 60 * 1000; // Chuyển ngày thành milliseconds
    await saveCookies(cookieString, expiresIn: expiresIn);
  }

  /// Lưu cookie với thời gian hết hạn tính bằng giờ
  static Future<void> saveCookiesWithHours(
      String cookieString, int hours) async {
    final expiresIn = hours * 60 * 60 * 1000; // Chuyển giờ thành milliseconds
    await saveCookies(cookieString, expiresIn: expiresIn);
  }

  /// Lưu cookie với thời gian hết hạn tính bằng phút
  static Future<void> saveCookiesWithMinutes(
      String cookieString, int minutes) async {
    final expiresIn = minutes * 60 * 1000; // Chuyển phút thành milliseconds
    await saveCookies(cookieString, expiresIn: expiresIn);
  }

  // ========== COOKIE THEO KEY ==========

  /// Lưu cookie theo key riêng biệt
  /// [key] - Tên cookie key (ví dụ: 'SAPISID', 'SID', 'HSID')
  /// [value] - Giá trị cookie
  /// [expiresIn] - Thời gian hết hạn (null = vĩnh viễn)
  static Future<void> saveCookieByKey(String key, String value,
      {int? expiresIn}) async {
    try {
      final box = await Hive.openBox(_cookieKeysBoxName);

      int? expiresAt;
      if (expiresIn != null) {
        expiresAt = DateTime.now().millisecondsSinceEpoch + expiresIn;
      }

      final cookieData = {
        'value': value,
        'expiresAt': expiresAt,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await box.put(key, cookieData);
      await box.close();
    } catch (e) {
      printERROR('Error saving cookie $key: $e');
    }
  }

  /// Lấy giá trị cookie theo key
  static Future<String?> getCookieByKey(String key) async {
    try {
      final box = await Hive.openBox(_cookieKeysBoxName);

      if (!box.containsKey(key)) {
        await box.close();
        return null;
      }

      final cookieData = box.get(key);
      await box.close();

      if (cookieData == null) return null;

      final expiresAt = cookieData['expiresAt'] as int?;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Nếu expiresAt = null thì cookie vĩnh viễn
      if (expiresAt == null) {
        return cookieData['value'] as String;
      }

      // Kiểm tra xem cookie có hết hạn chưa
      if (currentTime >= expiresAt) {
        printINFO('Cookie $key has expired, removing...');
        await removeCookieByKey(key);
        return null;
      }

      return cookieData['value'] as String;
    } catch (e) {
      printERROR('Error getting cookie $key: $e');
      return null;
    }
  }

  /// Xóa cookie theo key
  static Future<void> removeCookieByKey(String key) async {
    try {
      final box = await Hive.openBox(_cookieKeysBoxName);
      await box.delete(key);
      await box.close();
    } catch (e) {
      printERROR('Error removing cookie $key: $e');
    }
  }

  /// Lấy tất cả cookie keys hiện có
  static Future<List<String>> getAllCookieKeys() async {
    try {
      final box = await Hive.openBox(_cookieKeysBoxName);
      final keys = box.keys.whereType<String>().toList();
      await box.close();
      return keys;
    } catch (e) {
      printERROR('Error getting cookie keys: $e');
      return [];
    }
  }

  /// Lấy tất cả cookie hợp lệ dưới dạng chuỗi
  static Future<String> getAllValidCookiesString() async {
    try {
      final keys = await getAllCookieKeys();
      final validCookies = <String>[];
      print('Keys: $keys');

      for (final key in keys) {
        final value = await getCookieByKey(key);
        if (value != null) {
          validCookies.add('$key=$value');
        }
      }

      return validCookies.join('; ');
    } catch (e) {
      printERROR('Error getting all cookies string: $e');
      return '';
    }
  }

  /// Cập nhật cookie từ response headers
  /// [setCookieHeaders] - Danh sách Set-Cookie headers từ response
  static Future<void> updateCookiesFromResponse(
      List<String> setCookieHeaders) async {
    try {
      for (final header in setCookieHeaders) {
        await _parseAndSaveCookieFromHeader(header);
      }
    } catch (e) {
      printERROR('Error updating cookies from response: $e');
    }
  }

  /// Parse và lưu cookie từ Set-Cookie header
  static Future<void> _parseAndSaveCookieFromHeader(
      String setCookieHeader) async {
    try {
      // Parse Set-Cookie header: "name=value; expires=date; path=/; domain=..."
      final parts = setCookieHeader.split(';');
      if (parts.isEmpty) return;

      final nameValue = parts[0].trim();
      final nameValueParts = nameValue.split('=');
      if (nameValueParts.length < 2) return;

      final key = nameValueParts[0].trim();
      final value = nameValueParts.sublist(1).join('=').trim();

      // Tìm thời gian hết hạn
      int? expiresIn;
      for (final part in parts) {
        final trimmedPart = part.trim().toLowerCase();
        if (trimmedPart.startsWith('expires=')) {
          final expiresValue = trimmedPart.substring(8);
          final expiresDate = DateTime.tryParse(expiresValue);
          if (expiresDate != null) {
            expiresIn = expiresDate.millisecondsSinceEpoch -
                DateTime.now().millisecondsSinceEpoch;
            if (expiresIn < 0) expiresIn = null; // Cookie đã hết hạn
          }
          break;
        } else if (trimmedPart.startsWith('max-age=')) {
          final maxAgeValue = trimmedPart.substring(8);
          final maxAge = int.tryParse(maxAgeValue);
          if (maxAge != null) {
            expiresIn = maxAge * 1000; // Chuyển giây thành milliseconds
          }
          break;
        }
      }

      // Lưu cookie
      await saveCookieByKey(key, value, expiresIn: expiresIn);
    } catch (e) {
      printERROR('Error parsing cookie header: $e');
    }
  }

  /// Xóa tất cả cookie theo key
  static Future<void> clearAllCookiesByKey() async {
    try {
      final box = await Hive.openBox(_cookieKeysBoxName);
      await box.clear();
      await box.close();
      printINFO('All cookies by key cleared successfully');
    } catch (e) {
      printERROR('Error clearing cookies by key: $e');
    }
  }

  /// Lấy thông tin chi tiết về cookie theo key
  static Future<Map<String, dynamic>?> getCookieInfoByKey(String key) async {
    try {
      final box = await Hive.openBox(_cookieKeysBoxName);

      if (!box.containsKey(key)) {
        await box.close();
        return null;
      }

      final cookieData = box.get(key);
      await box.close();

      if (cookieData == null) return null;

      final expiresAt = cookieData['expiresAt'] as int?;
      final createdAt = cookieData['createdAt'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Xử lý cookie vĩnh viễn
      if (expiresAt == null) {
        return {
          'key': key,
          'value': cookieData['value'],
          'createdAt': DateTime.fromMillisecondsSinceEpoch(createdAt),
          'expiresAt': null,
          'isExpired': false,
          'remainingTime': null,
          'isPermanent': true,
        };
      }

      return {
        'key': key,
        'value': cookieData['value'],
        'createdAt': DateTime.fromMillisecondsSinceEpoch(createdAt),
        'expiresAt': DateTime.fromMillisecondsSinceEpoch(expiresAt),
        'isExpired': currentTime >= expiresAt,
        'remainingTime': (expiresAt - currentTime) ~/ 1000,
        'isPermanent': false,
      };
    } catch (e) {
      printERROR('Error getting cookie info for $key: $e');
      return null;
    }
  }

  // ========== DATASYNC ID & VISITOR ID ==========

  /// Lưu datasyncId
  /// [datasyncId] - ID datasync
  /// [expiresIn] - Thời gian hết hạn (null = vĩnh viễn)
  static Future<void> saveDatasyncId(String datasyncId,
      {int? expiresIn}) async {
    try {
      final box = await Hive.openBox(_cookieKeysBoxName);

      int? expiresAt;
      if (expiresIn != null) {
        expiresAt = DateTime.now().millisecondsSinceEpoch + expiresIn;
      }

      final data = {
        'value': datasyncId,
        'expiresAt': expiresAt,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await box.put('DATASYNC_ID', data);
      await box.close();
    } catch (e) {
      printERROR('Error saving datasyncId: $e');
    }
  }

  /// Lấy datasyncId
  static Future<String?> getDatasyncId() async {
    return await getCookieByKey('DATASYNC_ID');
  }

  /// Lưu visitorId
  /// [visitorId] - ID visitor
  /// [expiresIn] - Thời gian hết hạn (null = vĩnh viễn)
  static Future<void> saveVisitorId(String visitorId, {int? expiresIn}) async {
    try {
      final box = await Hive.openBox(_cookieKeysBoxName);

      int? expiresAt;
      if (expiresIn != null) {
        expiresAt = DateTime.now().millisecondsSinceEpoch + expiresIn;
      }

      final data = {
        'value': visitorId,
        'expiresAt': expiresAt,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await box.put('VISITOR_ID', data);
      await box.close();
    } catch (e) {
      printERROR('Error saving visitorId: $e');
    }
  }

  /// Lấy visitorId
  static Future<String?> getVisitorId() async {
    return await getCookieByKey('VISITOR_ID');
  }

  /// Lưu cả datasyncId và visitorId
  /// [datasyncId] - ID datasync
  /// [visitorId] - ID visitor
  /// [expiresIn] - Thời gian hết hạn (null = vĩnh viễn)
  static Future<void> saveIds(String datasyncId, String visitorId,
      {int? expiresIn}) async {
    await saveDatasyncId(datasyncId, expiresIn: expiresIn);
    await saveVisitorId(visitorId, expiresIn: expiresIn);
  }

  /// Lấy cả datasyncId và visitorId
  static Future<Map<String, String?>> getIds() async {
    final datasyncId = await getDatasyncId();
    final visitorId = await getVisitorId();
    return {
      'datasyncId': datasyncId,
      'visitorId': visitorId,
    };
  }

  /// Xóa cả datasyncId và visitorId
  static Future<void> removeIds() async {
    await removeCookieByKey('DATASYNC_ID');
    await removeCookieByKey('VISITOR_ID');
    printINFO('Both datasyncId and visitorId removed successfully');
  }
}
