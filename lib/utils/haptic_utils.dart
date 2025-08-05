import 'package:flutter/services.dart';

/// Utility class để quản lý haptic feedback trong ứng dụng
class HapticUtils {
  /// Thêm haptic feedback khi chuyển menu/tab
  static void navigationHaptic() {
    HapticFeedback.selectionClick();
  }

  /// Thêm haptic feedback khi mở màn hình mới
  static void screenNavigationHaptic() {
    HapticFeedback.lightImpact();
  }

  /// Thêm haptic feedback khi đóng màn hình
  static void backNavigationHaptic() {
    HapticFeedback.lightImpact();
  }

  /// Thêm haptic feedback khi thực hiện action quan trọng
  static void actionHaptic() {
    HapticFeedback.selectionClick();
  }

  /// Thêm haptic feedback khi có lỗi
  static void errorHaptic() {
    HapticFeedback.heavyImpact();
  }
}
