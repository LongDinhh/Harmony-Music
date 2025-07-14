# Tính năng Đăng nhập Google

## Mô tả
Tính năng đăng nhập Google sử dụng WebView để truy cập YouTube Music thông qua tài khoản Google.

## Các file chính

### 1. `google_login_screen.dart`
- Màn hình WebView để hiển thị trang đăng nhập Google
- Xử lý navigation và phát hiện đăng nhập thành công
- URL đăng nhập: Google Sign-in cho YouTube Music

### 2. `auth_controller.dart`
- Controller quản lý trạng thái đăng nhập
- Lưu trữ thông tin người dùng bằng Hive
- Cung cấp các method để đăng nhập/đăng xuất

### 3. `google_login_button.dart`
- Widget nút đăng nhập có thể tái sử dụng
- Hiển thị trạng thái đăng nhập
- Tích hợp sẵn chức năng đăng xuất

### 4. `login_demo_screen.dart`
- Màn hình demo để test tính năng
- Hiển thị trạng thái đăng nhập
- Cung cấp giao diện test

## Cách sử dụng

### 1. Thêm dependency
```yaml
dependencies:
  webview_flutter: ^4.7.0
```

### 2. Khởi tạo AuthController
```dart
// Trong main.dart hoặc màn hình chính
Get.put(AuthController());
```

### 3. Sử dụng GoogleLoginButton
```dart
GoogleLoginButton(
  onSuccess: () {
    print('Đăng nhập thành công!');
  },
  onError: () {
    print('Có lỗi xảy ra');
  },
)
```

### 4. Kiểm tra trạng thái đăng nhập
```dart
final authController = Get.find<AuthController>();
if (authController.isLoggedIn) {
  // Người dùng đã đăng nhập
  print('Email: ${authController.userEmail}');
  print('Tên: ${authController.userName}');
}
```

### 5. Đăng xuất
```dart
final authController = Get.find<AuthController>();
await authController.logout();
```

## Cấu hình Android

### AndroidManifest.xml
Đã thêm các quyền cần thiết:
- `INTERNET`
- `ACCESS_NETWORK_STATE`

### Cấu hình WebView
- JavaScript được bật
- Cho phép tất cả navigation
- Tự động phát hiện đăng nhập thành công

## Lưu ý

1. **Bảo mật**: Thông tin đăng nhập được lưu cục bộ trên thiết bị
2. **Network**: Cần kết nối internet để đăng nhập
3. **Platform**: Chỉ hỗ trợ Android và iOS
4. **Testing**: Sử dụng `LoginDemoScreen` để test tính năng

## Troubleshooting

### Lỗi WebView không tải
- Kiểm tra kết nối internet
- Đảm bảo đã thêm quyền INTERNET
- Kiểm tra URL đăng nhập có hợp lệ

### Lỗi đăng nhập không thành công
- Kiểm tra URL redirect sau đăng nhập
- Đảm bảo tài khoản Google hợp lệ
- Kiểm tra cấu hình YouTube Music

### Lỗi lưu trữ dữ liệu
- Kiểm tra quyền ghi file
- Đảm bảo Hive được khởi tạo đúng cách
- Kiểm tra dung lượng lưu trữ 