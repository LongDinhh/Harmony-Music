import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import 'google_login_screen.dart';
import '../../widgets/google_login_button.dart';
import '../../../services/cookie_manager.dart';

class AuthDemo extends StatelessWidget {
  const AuthDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Đảm bảo AuthController đã được khởi tạo
    Get.put(AuthController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Đăng nhập Google'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Get.find<AuthController>().updateLoginStatus(false);
            },
            tooltip: 'Reset trạng thái',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.music_note,
                    size: 60,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Harmony Music',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đăng nhập để truy cập đầy đủ tính năng YouTube Music',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Nút đăng nhập
            GoogleLoginButton(
              text: 'Đăng nhập bằng Google',
              height: 56,
              borderRadius: 12,
              onSuccess: () {
                print('Đăng nhập thành công!');
              },
              onError: () {
                print('Có lỗi xảy ra khi đăng nhập');
              },
            ),

            const SizedBox(height: 30),

            // Thông tin trạng thái
            Obx(() {
              final authController = Get.find<AuthController>();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: authController.isLoggedIn
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: authController.isLoggedIn
                        ? Colors.green.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          authController.isLoggedIn
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: authController.isLoggedIn
                              ? Colors.green
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trạng thái đăng nhập',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: authController.isLoggedIn
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authController.isLoggedIn
                          ? 'Đã đăng nhập'
                          : 'Chưa đăng nhập',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: authController.isLoggedIn
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    if (authController.isLoggedIn) ...[
                      const SizedBox(height: 8),
                      Text('Email: ${authController.userEmail}'),
                      Text('Tên: ${authController.userName}'),
                      Text('Số lượng cookies: ${authController.cookieCount}'),
                      FutureBuilder<bool>(
                        future: authController.hasSAPISID(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (snapshot.data == true) {
                            return const Text(
                              '✅ Có cookie SAPISID (Đã đăng nhập)',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return const Text(
                            '❌ Không có cookie SAPISID (Chưa đăng nhập)',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<String>>(
                        future: authController.getAllCookieKeys(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }

                          final keys = snapshot.data ?? [];
                          final importantKeys = keys
                              .where((key) => [
                                    'SID',
                                    'HSID',
                                    'SSID',
                                    'APISID',
                                    'SAPISID',
                                    '__Secure-3PAPISID'
                                  ].contains(key))
                              .take(3)
                              .toList();

                          if (importantKeys.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cookies quan trọng:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              ...importantKeys
                                  .map((key) => FutureBuilder<String?>(
                                        future: authController.getCookie(key),
                                        builder: (context, cookieSnapshot) {
                                          if (cookieSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox.shrink();
                                          }
                                          final value =
                                              cookieSnapshot.data ?? '';
                                          return Text(
                                            '$key: ${value.length > 10 ? '${value.substring(0, 10)}...' : value}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'monospace'),
                                          );
                                        },
                                      )),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 30),

            // Các nút chức năng
            if (Get.find<AuthController>().isLoggedIn) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.to(() => const GoogleLoginScreen());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Làm mới đăng nhập'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Get.find<AuthController>().logout();
                        Get.snackbar(
                          'Đã đăng xuất',
                          'Đã xóa cookie SAPISID',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await Get.find<AuthController>().logoutCompletely();
                  Get.snackbar(
                    'Đã đăng xuất hoàn toàn',
                    'Đã xóa tất cả cookies',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Đăng xuất hoàn toàn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _showCookiesDialog();
                },
                icon: const Icon(Icons.cookie),
                label: const Text('Xem tất cả Cookies'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await _testCookieManager();
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Test CookieManager'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await _checkLoginStatus();
                },
                icon: const Icon(Icons.security),
                label: const Text('Kiểm tra trạng thái đăng nhập'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await _testWebviewCookies();
                },
                icon: const Icon(Icons.web),
                label: const Text('Test WebView Cookies'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await _testAllCookies();
                },
                icon: const Icon(Icons.cookie),
                label: const Text('Lấy tất cả Cookies'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],

            const Spacer(),

            // Thông tin bổ sung
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(height: 8),
                  const Text(
                    'Lưu ý:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Đăng nhập để truy cập YouTube Music\n'
                    '• Dữ liệu được lưu cục bộ trên thiết bị\n'
                    '• Có thể đăng xuất bất cứ lúc nào\n'
                    '• Chỉ hỗ trợ Android và iOS',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCookiesDialog() {
    final authController = Get.find<AuthController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Tất cả Cookies'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text('Tổng số cookies: ${authController.cookieCount}'),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: authController.getAllCookieKeys(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final keys = snapshot.data ?? [];
                    if (keys.isEmpty) {
                      return const Center(child: Text('Không có cookies'));
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: keys.map((key) {
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: authController.getCookieInfoByKey(key),
                            builder: (context, cookieSnapshot) {
                              if (cookieSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }

                              final cookieInfo = cookieSnapshot.data;
                              if (cookieInfo == null) {
                                return const SizedBox.shrink();
                              }

                              final isImportant = [
                                'SID',
                                'HSID',
                                'SSID',
                                'APISID',
                                'SAPISID',
                                '__Secure-3PAPISID'
                              ].contains(key);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isImportant
                                      ? Colors.green.shade50
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isImportant
                                        ? Colors.green.shade200
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          key,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isImportant
                                                ? Colors.green
                                                : Colors.black,
                                          ),
                                        ),
                                        if (isImportant) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.star,
                                              color: Colors.green, size: 16),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cookieInfo['value'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () async {
              final cookiesString = await authController.getCookiesString();
              Get.snackbar(
                'Đã copy',
                'Cookies string đã được copy',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _testCookieManager() async {
    print('=== TEST COOKIE MANAGER ===');

    // Test 1: Lấy cookies hiện tại
    final currentCookies = await CookieManager.getAllValidCookiesString();
    print('1. Current cookies: $currentCookies');

    // Test 2: Lấy cookie info
    final cookieInfo = await CookieManager.getCookieInfo();
    print('2. Cookie info: $cookieInfo');

    // Test 3: Lấy tất cả cookie keys
    final keys = await CookieManager.getAllCookieKeys();
    print('3. All cookie keys: $keys');

    // Test 4: Lấy cookies string
    final cookiesString = await CookieManager.getAllValidCookiesString();
    print('4. Cookies string: $cookiesString');

    // Test 5: Kiểm tra có cookies hợp lệ không
    final hasValid = await CookieManager.hasValidCookies();
    print('5. Has valid cookies: $hasValid');

    // Test 6: Lấy thời gian còn lại
    final remainingTime = await CookieManager.getRemainingTime();
    print('6. Remaining time: $remainingTime');

    // Test 7: Lấy cookie cụ thể
    for (final key in [
      'SID',
      'HSID',
      'SSID',
      'APISID',
      'SAPISID',
      '__Secure-3PAPISID'
    ]) {
      final value = await CookieManager.getCookieByKey(key);
      print('7. $key: $value');
    }

    print('=== END TEST ===');

    Get.snackbar(
      'Test hoàn thành',
      'Xem log để biết kết quả',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _checkLoginStatus() async {
    print('=== KIỂM TRA TRẠNG THÁI ĐĂNG NHẬP ===');

    final authController = Get.find<AuthController>();

    // Test 1: Kiểm tra cookie SAPISID
    final sapisid = await authController.getSAPISID();
    print('1. SAPISID: ${sapisid ?? 'Không có'}');

    // Test 2: Kiểm tra có SAPISID không
    final hasSAPISID = await authController.hasSAPISID();
    print('2. Có SAPISID: $hasSAPISID');

    // Test 3: Kiểm tra trạng thái đăng nhập tổng thể
    final isLoggedIn = await authController.checkLoginStatus();
    print('3. Trạng thái đăng nhập: $isLoggedIn');

    // Test 4: Lấy tất cả cookie keys
    final keys = await authController.getAllCookieKeys();
    print('4. Tất cả cookie keys: $keys');

    // Test 5: Kiểm tra các cookie quan trọng
    final importantCookies = [
      'SID',
      'HSID',
      'SSID',
      'APISID',
      'SAPISID',
      '__Secure-3PAPISID'
    ];
    for (final cookieName in importantCookies) {
      final value = await authController.getCookie(cookieName);
      print(
          '5. $cookieName: ${value != null ? '${value.substring(0, 10)}...' : 'Không có'}');
    }

    print('=== KẾT QUẢ ===');
    if (hasSAPISID) {
      print('✅ ĐÃ ĐĂNG NHẬP - Có cookie SAPISID');
      Get.snackbar(
        'Đã đăng nhập',
        'Tìm thấy cookie SAPISID - Trạng thái đăng nhập hợp lệ',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      print('❌ CHƯA ĐĂNG NHẬP - Không có cookie SAPISID');
      Get.snackbar(
        'Chưa đăng nhập',
        'Không tìm thấy cookie SAPISID - Cần đăng nhập lại',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _testWebviewCookies() async {
    print('=== TEST WEBVIEW COOKIES ===');

    try {
      // Mở GoogleLoginScreen để test webview cookies
      final result = await Get.to(() => const GoogleLoginScreen());

      if (result == true) {
        print('✅ Đăng nhập thành công qua WebView');
        Get.snackbar(
          'Thành công',
          'Đã lấy cookies từ WebView',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        print('❌ Đăng nhập không thành công');
        Get.snackbar(
          'Thất bại',
          'Không thể lấy cookies từ WebView',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Lỗi khi test WebView cookies: $e');
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _testAllCookies() async {
    print('=== TEST LẤY TẤT CẢ COOKIES ===');
    
    try {
      // Mở GoogleLoginScreen để test lấy tất cả cookies
      final result = await Get.to(() => const GoogleLoginScreen());
      
      if (result == true) {
        print('✅ Lấy cookies thành công');
        Get.snackbar(
          'Thành công',
          'Đã lấy tất cả cookies từ domain .youtube.com',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        print('❌ Lấy cookies không thành công');
        Get.snackbar(
          'Thất bại',
          'Không thể lấy cookies từ domain .youtube.com',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Lỗi khi test lấy tất cả cookies: $e');
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
