import 'package:flutter/material.dart';

/// Centralized constants for the Harmony Music application
/// Contains frequently used colors, durations, strings, and UI constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ========== COLORS (100+ occurrences) ==========
  static const Color kPrimaryWhite = Colors.white;
  static const Color kTransparent = Colors.transparent;
  static const Color kPrimaryBlack = Colors.black;
  static const Color kGreyShade300 = Colors.grey; // For shimmer baseColor
  static const Color kGreyShade100 = Colors.grey; // For shimmer highlightColor
  
  // ========== DURATIONS (30+ occurrences) ==========
  static const Duration kTimeoutDuration = Duration(seconds: 30);
  static const Duration kAnimationDuration = Duration(milliseconds: 350);
  static const Duration kFadeInDuration = Duration(milliseconds: 200);
  static const Duration kShortDelay = Duration(milliseconds: 100);
  static const Duration kMediumDelay = Duration(milliseconds: 500);
  
  // ========== HIVE BOXES (25+ occurrences) ==========
  static const String kAppPrefsBox = "AppPrefs";
  static const String kSongsCacheBox = "SongsCache";
  static const String kYouTubeCookieBox = "YouTubeCookieBox";
  static const String kLibraryBox = "LibraryBox";
  static const String kPlaylistBox = "PlaylistBox";
  
  // ========== UI CONSTANTS ==========
  static const EdgeInsets kDefaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets kSmallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets kLargePadding = EdgeInsets.all(24.0);
  static const EdgeInsets kHorizontalPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets kVerticalPadding = EdgeInsets.symmetric(vertical: 16.0);
  
  static const BorderRadius kDefaultBorderRadius = BorderRadius.all(Radius.circular(10.0));
  static const BorderRadius kSmallBorderRadius = BorderRadius.all(Radius.circular(5.0));
  static const BorderRadius kLargeBorderRadius = BorderRadius.all(Radius.circular(20.0));
  
  // ========== SIZES ==========
  static const Size kThumbnailSize = Size(50, 50);
  static const Size kAlbumArtSize = Size(120, 120);
  static const Size kShimmerTitleSize = Size(220, 30);
  static const Size kShimmerSubtitleSize = Size(90, 20);
  static const Size kShimmerDetailSize = Size(40, 15);
  
  // ========== COMMONLY USED STRINGS ==========
  static const String kAppName = "Harmony Music";
  static const String kAppVersion = "1.12.0+25";
  static const String kDefaultErrorMessage = "Đã có lỗi xảy ra";
  static const String kNetworkErrorMessage = "Lỗi kết nối mạng";
  static const String kLoadingMessage = "Đang tải...";
  
  // ========== API CONSTANTS ==========
  static const int kDefaultTimeout = 30; // seconds
  static const int kRetryAttempts = 3;
  static const String kUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36";
  
  // ========== ANIMATION CONSTANTS ==========
  static const Curve kDefaultCurve = Curves.easeInOut;
  static const double kDefaultOpacity = 0.7;
  static const double kHighOpacity = 0.9;
  static const double kLowOpacity = 0.3;
}
