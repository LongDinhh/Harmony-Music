import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import '../../../services/youtube_cookie_manager.dart';
import '../../../utils/helper.dart';
import '../../widgets/snackbar.dart';

class GoogleLoginWebView extends StatefulWidget {
  const GoogleLoginWebView({super.key});

  @override
  State<GoogleLoginWebView> createState() => _GoogleLoginWebViewState();
}

class _GoogleLoginWebViewState extends State<GoogleLoginWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _loginCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });

            // Kiểm tra nếu đã chuyển đến m.youtube.com (đăng nhập thành công)
            if (url.contains('m.youtube.com') || url.contains('youtube.com')) {
              await _handleLoginSuccess(url);
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                snackbar(context, 'Error loading page: ${error.description ?? 'Unknown error'}'),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
        'https://accounts.google.com/ServiceLogin?continue=https://m.youtube.com',
      ));
  }

  Future<void> _handleLoginSuccess(String url) async {
    if (_loginCompleted) return;
    _loginCompleted = true;

    try {
      // Lấy tất cả cookie từ WebView
      final cookieManager = WebviewCookieManager();
      
      // Lấy cookie từ các domain quan trọng
      final youtubeCookies = await cookieManager.getCookies('https://youtube.com');
      final googleCookies = await cookieManager.getCookies('https://google.com');
      final accountsCookies = await cookieManager.getCookies('https://accounts.google.com');
      
      // Gộp tất cả cookie
      final allCookies = [...youtubeCookies, ...googleCookies, ...accountsCookies];
      
      if (allCookies.isNotEmpty) {
        // Chuyển đổi cookie sang format lưu trữ
        final cookieMap = <String, dynamic>{};
        
        for (final cookie in allCookies) {
          // Chỉ lấy cookie quan trọng của Google/YouTube
          if (_isImportantCookie(cookie.name, cookie.domain ?? '')) {
            cookieMap[cookie.name] = {
              'value': cookie.value,
              'domain': cookie.domain,
              'path': cookie.path,
              'expires': cookie.expires?.millisecondsSinceEpoch,
              'secure': cookie.secure,
              'httpOnly': true, // Giả định httpOnly cho cookie quan trọng
            };
          }
        }

        if (cookieMap.isNotEmpty) {
          // Lưu cookie vào Hive
          await YouTubeCookieManager.saveYouTubeCookies(cookieMap);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              snackbar(context, 'Đăng nhập Google thành công!'),
            );
          }
          
          // Đóng WebView và trở về màn hình cài đặt
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              snackbar(context, 'Không tìm thấy cookie đăng nhập'),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            snackbar(context, 'Không thể lấy cookie đăng nhập'),
          );
        }
      }
    } catch (e) {
      printERROR('Error handling login success: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snackbar(context, 'Lỗi khi lưu thông tin đăng nhập: $e'),
        );
      }
    }
  }

  bool _isImportantCookie(String name, String domain) {
    // Các cookie quan trọng của Google/YouTube
    final importantCookies = [
      'SID', 'HSID', 'SSID', 'APISID', 'SAPISID', 'LOGIN_INFO', 'PREF',
      'VISITOR_INFO1_LIVE', 'YSC', 'CONSENT', 'SOCS', '__Secure-3PAPISID',
      '__Secure-3PSID', '__Secure-3PSIDCC', 'NID', '1P_JAR', 'AEC'
    ];
    
    // Domain của Google/YouTube
    final importantDomains = [
      '.youtube.com', '.google.com', '.google.com.vn', '.accounts.google.com'
    ];
    
    return importantCookies.contains(name) && 
           importantDomains.any((d) => domain.contains(d));
  }

  Future<void> _closeWebView() async {
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập Google'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closeWebView,
        ),
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
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}