import 'package:audio_service/audio_service.dart';
import '../models/playlist.dart';
import '../models/album.dart';

/// Abstract repository interface cho library-related operations
/// Quản lý thư viện cá nhân của user (songs, playlists, albums)
abstract class LibraryRepository {
  /// Thêm bài hát vào thư viện cá nhân
  /// 
  /// [song] - MediaItem của bài hát cần thêm
  /// Returns Future<void> - completed when song is added
  /// Throws LibraryException if operation fails
  Future<void> addSongToLibrary(MediaItem song);

  /// Xóa bài hát khỏi thư viện cá nhân
  /// 
  /// [songId] - ID của bài hát cần xóa
  /// Returns Future<void> - completed when song is removed
  /// Throws LibraryException if operation fails
  Future<void> removeSongFromLibrary(String songId);

  /// Lấy tất cả bài hát trong thư viện cá nhân
  /// 
  /// Returns List<MediaItem> - danh sách bài hát trong library
  Future<List<MediaItem>> getLibrarySongs();

  /// Kiểm tra bài hát có trong thư viện không
  /// 
  /// [songId] - ID của bài hát cần kiểm tra
  /// Returns bool - true nếu bài hát có trong library
  Future<bool> isSongInLibrary(String songId);

  /// Lấy tất cả playlists trong thư viện
  /// 
  /// Returns List<Playlist> - danh sách playlists
  Future<List<Playlist>> getPlaylists();

  /// Thêm album vào thư viện cá nhân
  /// 
  /// [album] - Album object cần thêm
  /// [add] - true để thêm, false để xóa
  /// Returns Future<bool> - true if operation successful
  Future<bool> addOrRemoveAlbumFromLibrary(Album album, {required bool add});

  /// Kiểm tra album có trong thư viện không
  /// 
  /// [albumId] - ID của album cần kiểm tra
  /// Returns bool - true nếu album có trong library
  Future<bool> isAlbumInLibrary(String albumId);

  /// Lấy tất cả albums trong thư viện
  /// 
  /// Returns List<Album> - danh sách albums
  Future<List<Album>> getLibraryAlbums();

  /// Tạo playlist mới
  /// 
  /// [playlistName] - tên playlist
  /// [description] - mô tả playlist (optional)
  /// Returns Future<Playlist> - playlist object đã tạo
  Future<Playlist> createPlaylist(String playlistName, {String? description});

  /// Xóa playlist
  /// 
  /// [playlistId] - ID của playlist cần xóa
  /// Returns Future<void> - completed when playlist is deleted
  Future<void> deletePlaylist(String playlistId);

  /// Thêm bài hát vào playlist
  /// 
  /// [playlistId] - ID của playlist
  /// [song] - MediaItem của bài hát
  /// Returns Future<void> - completed when song is added to playlist
  Future<void> addSongToPlaylist(String playlistId, MediaItem song);

  /// Xóa bài hát khỏi playlist
  /// 
  /// [playlistId] - ID của playlist
  /// [songId] - ID của bài hát cần xóa
  /// Returns Future<void> - completed when song is removed from playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId);

  /// Lấy bài hát trong playlist
  /// 
  /// [playlistId] - ID của playlist
  /// Returns List<MediaItem> - danh sách bài hát trong playlist
  Future<List<MediaItem>> getPlaylistSongs(String playlistId);

  /// Cập nhật thông tin playlist
  /// 
  /// [playlistId] - ID của playlist
  /// [newName] - tên mới (optional)
  /// [newDescription] - mô tả mới (optional)
  /// Returns Future<void> - completed when playlist is updated
  Future<void> updatePlaylist(
    String playlistId, {
    String? newName,
    String? newDescription,
  });

  /// Lấy thống kê thư viện
  /// 
  /// Returns Map<String, int> - statistics về library
  /// Ví dụ: {'songs': 120, 'playlists': 5, 'albums': 8}
  Future<Map<String, int>> getLibraryStatistics();

  /// Sync library với cloud storage (nếu có)
  /// 
  /// Returns Future<void> - completed when sync is done
  Future<void> syncLibrary();

  /// Export library data
  /// 
  /// Returns Map<String, dynamic> - data có thể export/backup
  Future<Map<String, dynamic>> exportLibraryData();

  /// Import library data từ backup
  /// 
  /// [data] - data từ backup
  /// Returns Future<void> - completed when import is done
  Future<void> importLibraryData(Map<String, dynamic> data);
}