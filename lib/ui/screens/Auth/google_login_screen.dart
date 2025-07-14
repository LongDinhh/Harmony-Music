import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../../services/cookie_manager.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  late final WebViewController _controller;
  bool isLoading = true;
  String? currentUrl;
  final AuthController _authController = Get.put(AuthController());
  final WebviewCookieManager _webviewCookieManager = WebviewCookieManager();
  static const String _url = 'https://m.youtube.com';
  static const String _youtubeDomain = '.youtube.com';

  @override
  void initState() {
    super.initState();
    const String loginUrl =
        'https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fm.youtube.com';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              currentUrl = url;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              isLoading = false;
              currentUrl = url;
            });
            // Chỉ lấy cookie khi đã vào đúng trang music.youtube.com
            if (url.contains('m.youtube.com')) {
              await _handleSuccessfulLogin(url);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(loginUrl));
  }

  Future<void> _handleSuccessfulLogin(String url) async {
    print('Đăng nhập thành công: $url');
    // Lấy cookie của trang music.youtube.com
    final cookiesString = await _extractCookies();
    await _authController.setLoginSuccess(
      email: 'user@example.com',
      name: 'Người dùng Google',
      cookiesString: cookiesString,
    );
    Get.snackbar(
      'Thành công',
      'Đăng nhập Google thành công! Đã lấy được cookies',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    Future.delayed(const Duration(seconds: 3), () {
      Get.back(result: true);
    });
  }

  Future<String> _extractCookies() async {
    try {
      // Lấy tất cả cookies từ domain .youtube.com
      final gotCookies = await _webviewCookieManager.getCookies(_youtubeDomain);
      print('Tất cả cookies từ domain .youtube.com:');

      if (gotCookies.isEmpty) {
        print('Không có cookies nào từ domain .youtube.com');
        // Thử lấy từ music.youtube.com nếu không có cookies từ .youtube.com
        final musicCookies = await _webviewCookieManager.getCookies(_url);
        if (musicCookies.isNotEmpty) {
          print('Tìm thấy cookies từ music.youtube.com, chuyển sang lấy từ đó');
          return await _processCookies(musicCookies);
        }
        return '';
      }

      return await _processCookies(gotCookies);
    } catch (e) {
      print('Lỗi khi lấy cookie: $e');
      return '';
    }
  }

  Future<String> _processCookies(List<dynamic> cookies) async {
    // Tạo chuỗi cookie từ danh sách cookies
    final cookieStrings = <String>[];
    final allCookieStrings = <String>[];

    print('Tổng số cookies: ${cookies.length}');

    for (var cookie in cookies) {
      print('Cookie: ${cookie.name} = ${cookie.value}');
      print('Domain: ${cookie.domain}');
      print('Path: ${cookie.path}');
      print('Secure: ${cookie.secure}');
      print('HttpOnly: ${cookie.httpOnly}');
      print('---');

      // Lưu tất cả cookies
      allCookieStrings.add('${cookie.name}=${cookie.value}');

      // Chỉ lấy cookies quan trọng cho việc lưu trữ
      if (_isImportantCookie(cookie.name)) {
        cookieStrings.add('${cookie.name}=${cookie.value}');
      }
    }

    final cookieString = cookieStrings.join('; ');
    final allCookieString = allCookieStrings.join('; ');

    print('Cookie string quan trọng: $cookieString');
    print('Tất cả cookie string: $allCookieString');

    if (cookieString.isNotEmpty) {
      // Lưu vào CookieManager theo từng key
      await _saveCookiesByKey(cookieString);
      print('Đã lưu cookie vào CookieManager');

      // Kiểm tra xem có lưu thành công không
      final savedCookies = await CookieManager.getAllValidCookiesString();
      print('Cookie đã lưu: $savedCookies');

      // Kiểm tra cookie info
      final cookieInfo = await CookieManager.getCookieInfo();
      print('Cookie info: $cookieInfo');

      final cookiesString = await CookieManager.getAllValidCookiesString();
      print('Cookies string: $cookiesString');
    }

    return cookieString;
  }

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

  // Kiểm tra xem cookie có quan trọng không
  bool _isImportantCookie(String cookieName) {
    const importantCookies = [
      // Authentication cookies
      'SID',
      'HSID',
      'SSID',
      'APISID',
      'SAPISID',
      '__Secure-1PAPISID',
      '__Secure-3PAPISID',
      'SIDCC',

      // Session cookies
      'OTZ',
      'VISITOR_INFO1_LIVE',
      'LOGIN_INFO',
      'PREF',

      // Analytics cookies
      '_gcl_au',
      '_ga',
      '_gid',

      // YouTube specific cookies
      'YSC',
      'yt-remote-cast-available',
      'yt-remote-cast-installed',
      'yt-remote-fast-check-period',
      'yt-remote-session-app',
      'yt-remote-session-name',

      // Music specific cookies
      'music_theme',
      'music_theme_auto',
      'music_theme_dark',
      'music_theme_light',

      // Other important cookies
      'CONSENT',
      'NID',
      '1P_JAR',
      'AEC',
      'SEARCH_SAMESITE',
      'SIDCC',
      'SSID',
      'HSID',
      'APISID',
      'SAPISID',
      '__Secure-1PAPISID',
      '__Secure-3PAPISID',
      '__Secure-1PSID',
      '__Secure-3PSID',
      '__Secure-1PSIDCC',
      '__Secure-3PSIDCC',
    ];
    return importantCookies.contains(cookieName);
  }

  // Lấy tất cả cookies từ webview_cookie_manager
  Future<void> _getAllCookies() async {
    try {
      // Lấy cookies từ domain .youtube.com
      final gotCookies = await _webviewCookieManager.getCookies(_youtubeDomain);
      print('Tất cả cookies từ domain .youtube.com:');

      if (gotCookies.isEmpty) {
        print('Không có cookies từ domain .youtube.com');
        // Thử lấy từ music.youtube.com
        final musicCookies = await _webviewCookieManager.getCookies(_url);
        print('Tất cả cookies từ music.youtube.com:');
        for (var cookie in musicCookies) {
          print('Cookie: ${cookie.name} = ${cookie.value}');
          print('Domain: ${cookie.domain}');
          print('Path: ${cookie.path}');
          print('Secure: ${cookie.secure}');
          print('HttpOnly: ${cookie.httpOnly}');
          print('---');
        }
      } else {
        for (var cookie in gotCookies) {
          print('Cookie: ${cookie.name} = ${cookie.value}');
          print('Domain: ${cookie.domain}');
          print('Path: ${cookie.path}');
          print('Secure: ${cookie.secure}');
          print('HttpOnly: ${cookie.httpOnly}');
          print('---');
        }
      }
    } catch (e) {
      print('Lỗi khi lấy cookies: $e');
    }
  }

  // Lấy tất cả cookies và lưu vào CookieManager
  Future<String> _getAllCookiesAndSave() async {
    try {
      // Lấy cookies từ domain .youtube.com
      final gotCookies = await _webviewCookieManager.getCookies(_youtubeDomain);
      print('Lấy tất cả cookies từ domain .youtube.com:');

      if (gotCookies.isEmpty) {
        print('Không có cookies từ domain .youtube.com');
        // Thử lấy từ music.youtube.com
        final musicCookies = await _webviewCookieManager.getCookies(_url);
        if (musicCookies.isNotEmpty) {
          print('Tìm thấy cookies từ music.youtube.com');
          return await _processAllCookies(musicCookies);
        }
        return '';
      }

      return await _processAllCookies(gotCookies);
    } catch (e) {
      print('Lỗi khi lấy tất cả cookies: $e');
      return '';
    }
  }

  Future<String> _processAllCookies(List<dynamic> cookies) async {
    final cookieStrings = <String>[];

    print('Tổng số cookies: ${cookies.length}');

    for (var cookie in cookies) {
      print('Cookie: ${cookie.name} = ${cookie.value}');
      print('Domain: ${cookie.domain}');
      print('Path: ${cookie.path}');
      print('Secure: ${cookie.secure}');
      print('HttpOnly: ${cookie.httpOnly}');
      print('---');

      // Lưu tất cả cookies
      cookieStrings.add('${cookie.name}=${cookie.value}');

      // Lưu từng cookie vào CookieManager
      await CookieManager.saveCookieByKey(cookie.name, cookie.value);
    }

    final cookieString = cookieStrings.join('; ');
    print('Tất cả cookie string: $cookieString');

    return cookieString;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập Google'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải trang đăng nhập...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
