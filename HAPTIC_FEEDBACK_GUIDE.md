# Hướng dẫn sử dụng Haptic Feedback trong Harmony Music

## Tổng quan

Ứng dụng Harmony Music đã được tích hợp haptic feedback để cải thiện trải nghiệm người dùng khi tương tác với các thành phần UI.

## Các loại Haptic Feedback

### 1. Navigation Haptic (`HapticUtils.navigationHaptic()`)
- **Mục đích**: Sử dụng khi chuyển đổi giữa các tab/menu chính
- **Loại**: `HapticFeedback.selectionClick()`
- **Ví dụ**: Chuyển từ Home sang Search, Library sang Settings

### 2. Screen Navigation Haptic (`HapticUtils.screenNavigationHaptic()`)
- **Mục đích**: Sử dụng khi mở màn hình mới
- **Loại**: `HapticFeedback.lightImpact()`
- **Ví dụ**: Mở album, playlist, artist screen

### 3. Back Navigation Haptic (`HapticUtils.backNavigationHaptic()`)
- **Mục đích**: Sử dụng khi đóng màn hình/quay lại
- **Loại**: `HapticFeedback.lightImpact()`
- **Ví dụ**: Quay lại màn hình trước đó

### 4. Action Haptic (`HapticUtils.actionHaptic()`)
- **Mục đích**: Sử dụng cho các hành động quan trọng
- **Loại**: `HapticFeedback.mediumImpact()`
- **Ví dụ**: Thêm/xóa bài hát khỏi playlist, tải xuống

### 5. Error Haptic (`HapticUtils.errorHaptic()`)
- **Mục đích**: Sử dụng khi có lỗi
- **Loại**: `HapticFeedback.heavyImpact()`
- **Ví dụ**: Lỗi mạng, lỗi tải dữ liệu

## Cách sử dụng

### Import utility
```dart
import '../../utils/haptic_utils.dart';
```

### Thêm haptic feedback vào navigation
```dart
onTap: () {
  HapticUtils.screenNavigationHaptic();
  Get.toNamed(ScreenNavigationSetup.albumScreen,
      id: ScreenNavigationSetup.id, arguments: (album, album.browseId));
},
```

### Thêm haptic feedback vào tab switching
```dart
void onTabSelected(int index) {
  HapticUtils.navigationHaptic();
  tabIndex.value = index;
}
```

## Các vị trí đã được thêm haptic feedback

### 1. Bottom Navigation Bar
- Chuyển đổi giữa Home, Search, Library, Settings

### 2. Side Navigation Bar
- Chuyển đổi giữa các tab trong sidebar

### 3. Search Navigation
- Tìm kiếm và mở kết quả tìm kiếm
- Desktop search bar

### 4. Song Info Navigation
- Mở album từ thông tin bài hát

### 5. Player Controls
- Play/Pause button (cả mini player và full player)
- Next/Previous buttons
- Shuffle mode toggle
- Loop mode toggle
- Gesture controls (swipe để next/prev, double tap để play/pause)
- Favorite toggle

## Lưu ý

- Haptic feedback chỉ hoạt động trên thiết bị có hỗ trợ rung
- Trên desktop, haptic feedback sẽ không có tác dụng
- Các loại haptic được chọn dựa trên mức độ quan trọng của hành động
- Không nên lạm dụng haptic feedback để tránh gây khó chịu cho người dùng

## Tương lai

Có thể mở rộng thêm haptic feedback cho:
- Thao tác với playlist (thêm/xóa bài hát)
- Các thao tác tải xuống
- Các thông báo lỗi
- Volume controls
- Seek controls
- Sleep timer controls 