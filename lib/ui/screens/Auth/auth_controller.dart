import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../services/cookie_manager.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final _isLoggedIn = false.obs;
  final _userEmail = ''.obs;
  final _userName = ''.obs;
  final _cookieCount = 0.obs;

  bool get isLoggedIn => _isLoggedIn.value;
  String get userEmail => _userEmail.value;
  String get userName => _userName.value;
  int get cookieCount => _cookieCount.value;

  late Box _authBox;

  @override
  void onInit() {
    super.onInit();
    _initHive();
  }

  Future<void> _initHive() async {
    _authBox = await Hive.openBox('auth_data');
    _loadAuthData();
  }

  void _loadAuthData() async {
    // Kiểm tra trạng thái đăng nhập dựa trên cookie SAPISID
    final isLoggedInFromCookie = await _checkLoginStatusFromCookie();
    _isLoggedIn.value = isLoggedInFromCookie;

    // Nếu có cookie hợp lệ, load thông tin user từ local storage
    if (isLoggedInFromCookie) {
      _userEmail.value = _authBox.get('userEmail', defaultValue: '');
      _userName.value = _authBox.get('userName', defaultValue: '');
    } else {
      _userEmail.value = '';
      _userName.value = '';
    }

    // Load cookie count from CookieManager
    await _updateCookieCount();
  }

  Future<void> _updateCookieCount() async {
    final cookieInfo = await CookieManager.getCookieInfo();
    print('AuthController - Cookie info: $cookieInfo');
    if (cookieInfo != null) {
      _cookieCount.value = cookieInfo['cookieCount'] ?? 0;
      print('AuthController - Cookie count: ${_cookieCount.value}');
    } else {
      _cookieCount.value = 0;
      print('AuthController - No cookie info found');
    }
  }

  Future<void> setLoginSuccess({
    required String email,
    required String name,
    String? cookiesString,
  }) async {
    _isLoggedIn.value = true;
    _userEmail.value = email;
    _userName.value = name;

    // Lưu cookies vào CookieManager nếu có
    if (cookiesString != null && cookiesString.isNotEmpty) {
      print('AuthController - Lưu cookies: $cookiesString');
      await _saveCookiesByKey(cookiesString);

      // Kiểm tra xem có lưu thành công không
      final savedCookies = await CookieManager.getAllValidCookiesString();
      print('AuthController - Cookies đã lưu: $savedCookies');
    }

    // Lưu vào local storage
    await _authBox.put('isLoggedIn', true);
    await _authBox.put('userEmail', email);
    await _authBox.put('userName', name);

    // Cập nhật số lượng cookies
    await _updateCookieCount();
  }

  Future<void> logout() async {
    _isLoggedIn.value = false;
    _userEmail.value = '';
    _userName.value = '';
    _cookieCount.value = 0;

    // Chỉ xóa cookie SAPISID để logout
    await CookieManager.removeCookieByKey('SAPISID');

    // Xóa dữ liệu local
    await _authBox.clear();

    print('AuthController - Đã đăng xuất và xóa cookie SAPISID');
  }

  void updateLoginStatus(bool status) {
    _isLoggedIn.value = status;
    _authBox.put('isLoggedIn', status);
  }

  // Lấy cookie cụ thể từ CookieManager
  Future<String?> getCookie(String name) async {
    return await CookieManager.getCookieByKey(name);
  }

  // Lấy tất cả cookies dưới dạng string cho HTTP request
  Future<String> getCookiesString() async {
    return await CookieManager.getAllValidCookiesString();
  }

  // Kiểm tra có cookie quan trọng không
  Future<bool> hasImportantCookies() async {
    final importantCookies = [
      'SID',
      'HSID',
      'SSID',
      'APISID',
      'SAPISID',
      '__Secure-3PAPISID'
    ];

    for (final cookie in importantCookies) {
      final value = await CookieManager.getCookieByKey(cookie);
      if (value != null && value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  // Lấy thông tin chi tiết về cookies
  Future<Map<String, dynamic>?> getCookieInfo() async {
    return await CookieManager.getCookieInfo();
  }

  // Lấy danh sách tất cả cookie keys
  Future<List<String>> getAllCookieKeys() async {
    return await CookieManager.getAllCookieKeys();
  }

  // Lấy thông tin cookie theo key
  Future<Map<String, dynamic>?> getCookieInfoByKey(String key) async {
    return await CookieManager.getCookieInfoByKey(key);
  }

  // Kiểm tra có cookies hợp lệ không
  Future<bool> hasValidCookies() async {
    return await CookieManager.hasValidCookies();
  }

  // Lấy thời gian còn lại của cookies
  Future<int?> getRemainingTime() async {
    return await CookieManager.getRemainingTime();
  }

  // Lưu cookies theo từng key
  Future<void> _saveCookiesByKey(String cookieString) async {
    try {
      // Parse cookie string thành các key-value pairs
      final cookies = cookieString.split('; ');
      for (final cookie in cookies) {
        final parts = cookie.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();

          // Lưu từng cookie theo key
          await CookieManager.saveCookieByKey(key, value);
        }
      }
    } catch (e) {
      print('Lỗi khi lưu cookies theo key: $e');
    }
  }

  // Kiểm tra trạng thái đăng nhập dựa trên cookie SAPISID
  Future<bool> _checkLoginStatusFromCookie() async {
    try {
      // Kiểm tra cookie SAPISID - đây là cookie quan trọng nhất
      final sapisid = await CookieManager.getCookieByKey('SAPISID');

      if (sapisid != null && sapisid.isNotEmpty) {
        print(
            'AuthController - Tìm thấy cookie SAPISID: ${sapisid.substring(0, 10)}...');
        return true;
      }

      // Nếu không có SAPISID, kiểm tra các cookie khác
      final importantCookies = [
        'SID',
        'HSID',
        'SSID',
        'APISID',
        '__Secure-3PAPISID'
      ];
      for (final cookieName in importantCookies) {
        final cookieValue = await CookieManager.getCookieByKey(cookieName);
        if (cookieValue != null && cookieValue.isNotEmpty) {
          print(
              'AuthController - Tìm thấy cookie $cookieName: ${cookieValue.substring(0, 10)}...');
          return true;
        }
      }

      print('AuthController - Không tìm thấy cookie đăng nhập nào');
      return false;
    } catch (e) {
      print('AuthController - Lỗi khi kiểm tra trạng thái đăng nhập: $e');
      return false;
    }
  }

  // Method public để kiểm tra trạng thái đăng nhập từ bên ngoài
  Future<bool> checkLoginStatus() async {
    final isLoggedIn = await _checkLoginStatusFromCookie();
    _isLoggedIn.value = isLoggedIn;
    return isLoggedIn;
  }

  // Kiểm tra cookie SAPISID cụ thể
  Future<String?> getSAPISID() async {
    return await CookieManager.getCookieByKey('SAPISID');
  }

  // Kiểm tra có cookie SAPISID không
  Future<bool> hasSAPISID() async {
    final sapisid = await getSAPISID();
    return sapisid != null && sapisid.isNotEmpty;
  }

  // Logout hoàn toàn (xóa tất cả cookies)
  Future<void> logoutCompletely() async {
    _isLoggedIn.value = false;
    _userEmail.value = '';
    _userName.value = '';
    _cookieCount.value = 0;

    // Xóa tất cả cookies
    await CookieManager.removeCookies();
    await CookieManager.clearAllCookiesByKey();

    // Xóa dữ liệu local
    await _authBox.clear();

    print('AuthController - Đã đăng xuất hoàn toàn và xóa tất cả cookies');
  }
}
