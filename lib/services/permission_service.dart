import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '/native_bindings/andrid_utils.dart' show SDKInt;

class PermissionService {
  static Future<bool> getExtStoragePermission() async {
    if (GetPlatform.isDesktop) {
      return Future.value(true);
    }

    // iOS permission handling
    if (GetPlatform.isIOS) {
      return await _getIOSStoragePermission();
    }

    // Android permission handling
    if ((SDKInt.Companion.getSDKInt()) < 30) {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        await [
          Permission.storage,
          Permission.accessMediaLocation,
          Permission.mediaLibrary,
        ].request();
      }

      if (await Permission.storage.isPermanentlyDenied) {
        await openAppSettings();
      }

      return (await Permission.storage.status).isGranted;
    } else {
      if (!await Permission.manageExternalStorage.isGranted) {
        final permission = await Permission.manageExternalStorage.request();
        return permission.isGranted;
      }
      return true;
    }
  }

  // iOS-specific storage permission
  static Future<bool> _getIOSStoragePermission() async {
    try {
      // iOS uses photo library access for music files export
      var status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }

      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    } catch (e) {
      print('Error getting iOS storage permission: $e');
      return true; // Allow access if permission check fails
    }
  }

  // iOS-specific media library permission
  static Future<bool> getIOSMediaLibraryPermission() async {
    if (!GetPlatform.isIOS) {
      return true;
    }

    try {
      var status = await Permission.mediaLibrary.status;
      if (status.isDenied) {
        status = await Permission.mediaLibrary.request();
      }

      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    } catch (e) {
      print('Error getting iOS media library permission: $e');
      return true;
    }
  }

  // Check notification permission for both platforms
  static Future<bool> getNotificationPermission() async {
    if (GetPlatform.isDesktop) {
      return true;
    }

    try {
      var status = await Permission.notification.status;
      if (status.isDenied) {
        status = await Permission.notification.request();
      }

      return status.isGranted;
    } catch (e) {
      print('Error getting notification permission: $e');
      return false;
    }
  }
}
