import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import '../../../services/youtube_cookie_manager.dart';
import '../../../services/youtube_config_service.dart';
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

            // Kiểm tra nếu đã chuyển đến music.youtube.com (đăng nhập thành công)
            if (url.contains('music.youtube.com')) {
              await _handleLoginSuccess(url);
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                snackbar(context, 'Error loading page: ${error.description}'),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
        'https://accounts.google.com/ServiceLogin?continue=https://music.youtube.com',
      ));
  }

  Future<void> _handleLoginSuccess(String url) async {
    if (_loginCompleted) return;
    _loginCompleted = true;

    try {
      // Lấy tất cả cookie từ WebView
      final cookieManager = WebviewCookieManager();

      // Lấy cookie từ các domain quan trọng
      final youtubeCookies =
          await cookieManager.getCookies('https://music.youtube.com');

      // Gộp tất cả cookie
      final allCookies = [...youtubeCookies];

      if (allCookies.isNotEmpty) {
        // Chuyển đổi cookie sang format lưu trữ với thởi hạn chính xác
        final cookieMap = <String, dynamic>{};

        for (final cookie in allCookies) {
          // Chỉ lấy tất cả cookie từ domain .youtube.com
          if (_isImportantCookie(cookie.name, cookie.domain ?? '')) {
            // Lấy thởi hạn thực tế từ WebView
            int? expiryTime;
            if (cookie.expires != null) {
              expiryTime = cookie.expires!.millisecondsSinceEpoch;
            } else {
              // Mặc định 30 ngày nếu không có expires
              expiryTime = DateTime.now()
                  .add(const Duration(days: 30))
                  .millisecondsSinceEpoch;
            }

            cookieMap[cookie.name] = {
              'value': cookie.value,
              'domain': cookie.domain,
              'path': cookie.path,
              'expires': expiryTime,
              'secure': cookie.secure,
              'httpOnly': true,
              'maxAge': cookie.maxAge, // Thêm max-age nếu có
              'source': 'webview', // Đánh dấu nguồn để debug
            };
          }
        }

        if (cookieMap.isNotEmpty) {
          // Lưu cookie vào Hive
          await YouTubeCookieManager.saveYouTubeCookies(cookieMap);

          // Log thông tin chi tiết
          final cookieCount = cookieMap.length;
          final expiryInfo = cookieMap.entries
              .where((e) => e.value['expires'] != null)
              .map((e) =>
                  '${e.key}: ${DateTime.fromMillisecondsSinceEpoch(e.value['expires']).toString()}');

          printINFO(
              'Đã lưu $cookieCount cookies với thởi hạn: ${expiryInfo.join(', ')}');

          // Sau khi lưu cookies thành công, extract YouTube config
          await _extractYouTubeConfig();

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
    // Chỉ chấp nhận cookie từ domain .youtube.com
    return domain.endsWith('.youtube.com');
  }

  Future<void> _closeWebView() async {
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _extractYouTubeConfig() async {
    try {
      final results = await YouTubeConfigService.extractAndSaveConfig();
      printINFO('Extracted YouTube config: $results');

      final datasyncId = results['DATASYNC_ID'];
      final visitorData = results['VISITOR_DATA'];

      // Sử dụng DATASYNC_ID và VISITOR_DATA cho việc của bạn ở đây
      if (datasyncId != null) {
        printINFO('DATASYNC_ID: $datasyncId');
      }

      if (visitorData != null) {
        printINFO('VISITOR_DATA: $visitorData');
      }
    } catch (e) {
      printERROR('Error extracting YouTube config: $e');
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
