import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';

/// Enum định nghĩa các loại cache khác nhau
enum CacheType {
  /// Cache cho audio files
  audio,
  /// Cache cho thumbnails/images
  image,
  /// Cache cho metadata (song info, playlists, etc.)
  metadata,
  /// Cache cho search results
  searchResults,
}

/// Model cho cache entry với metadata
class CacheEntry {
  final String key;
  final Uint8List data;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final CacheType type;
  final int size;
  final Map<String, dynamic>? metadata;

  CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    this.expiresAt,
    required this.type,
    required this.size,
    this.metadata,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// Model cho cache statistics
class CacheStatistics {
  final int totalEntries;
  final int totalSizeBytes;
  final Map<CacheType, int> entriesByType;
  final Map<CacheType, int> sizeByType;
  final int expiredEntries;

  CacheStatistics({
    required this.totalEntries,
    required this.totalSizeBytes,
    required this.entriesByType,
    required this.sizeByType,
    required this.expiredEntries,
  });
}

/// Abstract repository interface cho caching operations
/// Quản lý cache cho audio files, images, metadata
abstract class CacheRepository {
  /// Cache audio data cho một bài hát
  /// 
  /// [song] - MediaItem của bài hát
  /// [audioData] - binary data của audio file
  /// [expirationDuration] - thời gian cache sẽ expire (optional)
  /// Returns Future<void> - completed when audio is cached
  /// Throws CacheException if operation fails
  Future<void> cacheAudio(
    MediaItem song, 
    Uint8List audioData, {
    Duration? expirationDuration,
  });

  /// Lấy cached audio data
  /// 
  /// [songId] - ID của bài hát
  /// Returns Uint8List? - audio data nếu có, null nếu không có cache
  Future<Uint8List?> getCachedAudio(String songId);

  /// Kiểm tra bài hát có được cache không
  /// 
  /// [songId] - ID của bài hát
  /// Returns bool - true nếu audio đã được cache và chưa expire
  Future<bool> isAudioCached(String songId);

  /// Cache image/thumbnail data
  /// 
  /// [imageUrl] - URL của image
  /// [imageData] - binary data của image
  /// [expirationDuration] - thời gian cache sẽ expire (optional)
  /// Returns Future<void> - completed when image is cached
  Future<void> cacheImage(
    String imageUrl, 
    Uint8List imageData, {
    Duration? expirationDuration,
  });

  /// Lấy cached image data
  /// 
  /// [imageUrl] - URL của image
  /// Returns Uint8List? - image data nếu có, null nếu không có cache
  Future<Uint8List?> getCachedImage(String imageUrl);

  /// Cache metadata (search results, playlists, etc.)
  /// 
  /// [key] - unique key cho metadata
  /// [data] - metadata dưới dạng Map
  /// [type] - loại cache
  /// [expirationDuration] - thời gian cache sẽ expire (optional)
  /// Returns Future<void> - completed when metadata is cached
  Future<void> cacheMetadata(
    String key, 
    Map<String, dynamic> data, 
    CacheType type, {
    Duration? expirationDuration,
  });

  /// Lấy cached metadata
  /// 
  /// [key] - unique key cho metadata
  /// [type] - loại cache
  /// Returns Map<String, dynamic>? - metadata nếu có, null nếu không có cache
  Future<Map<String, dynamic>?> getCachedMetadata(String key, CacheType type);

  /// Xóa cache của một bài hát specific
  /// 
  /// [songId] - ID của bài hát
  /// Returns Future<void> - completed when cache is removed
  Future<void> removeCachedSong(String songId);

  /// Xóa cache của một image specific
  /// 
  /// [imageUrl] - URL của image
  /// Returns Future<void> - completed when cache is removed
  Future<void> removeCachedImage(String imageUrl);

  /// Xóa tất cả cache đã expire
  /// 
  /// Returns Future<int> - số lượng entries đã được xóa
  Future<int> clearExpiredCache();

  /// Xóa tất cả cache theo loại
  /// 
  /// [type] - loại cache cần xóa
  /// Returns Future<int> - số lượng entries đã được xóa
  Future<int> clearCacheByType(CacheType type);

  /// Xóa toàn bộ cache
  /// 
  /// Returns Future<void> - completed when all cache is cleared
  Future<void> clearAllCache();

  /// Lấy thống kê cache
  /// 
  /// Returns CacheStatistics - thông tin về cache usage
  Future<CacheStatistics> getCacheStatistics();

  /// Lấy danh sách cache entries
  /// 
  /// [type] - loại cache (optional, null để lấy tất cả)
  /// [limit] - giới hạn số entries (optional)
  /// Returns List<CacheEntry> - danh sách cache entries
  Future<List<CacheEntry>> getCacheEntries({
    CacheType? type,
    int? limit,
  });

  /// Optimize cache bằng cách xóa cache cũ nhất khi vượt quá limit
  /// 
  /// [maxSizeBytes] - kích thước tối đa của cache (bytes)
  /// [maxEntries] - số lượng entries tối đa
  /// Returns Future<int> - số lượng entries đã được xóa
  Future<int> optimizeCache({
    int? maxSizeBytes,
    int? maxEntries,
  });

  /// Preload cache cho danh sách bài hát
  /// 
  /// [songs] - danh sách bài hát cần preload
  /// [priority] - độ ưu tiên (1-10, 10 là cao nhất)
  /// Returns Future<void> - completed when preloading is done
  Future<void> preloadSongs(List<MediaItem> songs, {int priority = 5});

  /// Set cache configuration
  /// 
  /// [maxAudioCacheSize] - max size cho audio cache (bytes)
  /// [maxImageCacheSize] - max size cho image cache (bytes)
  /// [defaultExpirationDuration] - thời gian expire mặc định
  /// Returns Future<void> - completed when config is updated
  Future<void> setCacheConfiguration({
    int? maxAudioCacheSize,
    int? maxImageCacheSize,
    Duration? defaultExpirationDuration,
  });

  /// Lấy cache configuration hiện tại
  /// 
  /// Returns Map<String, dynamic> - cache configuration
  Future<Map<String, dynamic>> getCacheConfiguration();
}