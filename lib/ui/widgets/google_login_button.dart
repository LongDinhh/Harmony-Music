import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/Auth/google_login_screen.dart';
import '../screens/Auth/auth_controller.dart';

class GoogleLoginButton extends StatelessWidget {
  final String? text;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const GoogleLoginButton({
    super.key,
    this.text,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.onSuccess,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Obx(() {
      if (authController.isLoggedIn) {
        return _buildLoggedInState(authController);
      } else {
        return _buildLoginButton();
      }
    });
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: () => _navigateToLogin(),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: textColor ?? Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          elevation: 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/google_logo.png',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.login,
                  size: 24,
                  color: Colors.blue,
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              text ?? 'Đăng nhập bằng Google',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInState(AuthController authController) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 70, // Tăng chiều cao để hiển thị thêm thông tin
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã đăng nhập: ${authController.userEmail}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                  onPressed: () => _logout(),
                  tooltip: 'Đăng xuất',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Cookies: ${authController.cookieCount}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                FutureBuilder<bool>(
                  future: authController.hasImportantCookies(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (snapshot.data == true) {
                      return const Text(
                        '✅ Quan trọng',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLogin() async {
    try {
      final result = await Get.to(() => const GoogleLoginScreen());
      if (result == true) {
        onSuccess?.call();
      }
    } catch (e) {
      print('Lỗi khi đăng nhập: $e');
      onError?.call();
    }
  }

  void _logout() async {
    final AuthController authController = Get.find<AuthController>();
    await authController.logout();

    Get.snackbar(
      'Đã đăng xuất',
      'Bạn đã đăng xuất thành công',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
