import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../widgets/google_login_button.dart';

class LoginDemoScreen extends StatelessWidget {
  const LoginDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo AuthController
    Get.put(AuthController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Đăng nhập Google'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo hoặc icon
            const Icon(
              Icons.music_note,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),

            // Tiêu đề
            const Text(
              'Harmony Music',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'Đăng nhập để truy cập đầy đủ tính năng',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Nút đăng nhập Google
            GoogleLoginButton(
              onSuccess: () {
                print('Đăng nhập thành công!');
              },
              onError: () {
                print('Có lỗi xảy ra khi đăng nhập');
              },
            ),
            const SizedBox(height: 20),

            // Thông tin trạng thái đăng nhập
            Obx(() {
              final authController = Get.find<AuthController>();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Trạng thái: ${authController.isLoggedIn ? "Đã đăng nhập" : "Chưa đăng nhập"}',
                      style: TextStyle(
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
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 40),

            // Thông tin bổ sung
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'Lưu ý:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Đăng nhập để truy cập YouTube Music\n'
                      '• Dữ liệu được lưu cục bộ trên thiết bị\n'
                      '• Có thể đăng xuất bất cứ lúc nào',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
