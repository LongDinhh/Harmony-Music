import 'package:audio_service/audio_service.dart';
import '../models/album.dart';
import '../models/artist.dart';

/// Abstract repository interface cho music-related operations
/// Phân tách business logic khỏi data access layer
abstract class MusicRepository {
  /// Tìm kiếm bài hát theo query string
  /// 
  /// [query] - từ khóa tìm kiếm
  /// [filter] - bộ lọc tìm kiếm (optional)
  /// [limit] - giới hạn số kết quả
  /// Returns List<MediaItem> - danh sách bài hát tìm được
  Future<List<MediaItem>> searchSongs(
    String query, {
    String? filter,
    int limit = 30,
  });

  /// Lấy thông tin album theo albumId
  /// 
  /// [albumId] - ID của album
  /// Returns Album object với thông tin chi tiết
  Future<Album> getAlbum(String albumId);

  /// Lấy thông tin artist theo artistId
  /// 
  /// [artistId] - ID của artist/channel
  /// Returns Artist object với thông tin chi tiết  
  Future<Artist> getArtist(String artistId);

  /// Lấy nội dung trang chủ (home feed)
  /// 
  /// [limit] - số lượng sections cần lấy
  /// Returns dynamic data structure chứa home content
  Future<dynamic> getHomeContent({int limit = 4});

  /// Lấy charts/trending songs theo country
  /// 
  /// [countryCode] - mã quốc gia (default: "vi")
  /// Returns List chart data
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"});

  /// Lấy thông tin watch playlist
  /// 
  /// [videoId] - ID của video
  /// [playlistId] - ID của playlist (optional)
  /// [limit] - giới hạn số bài hát
  /// [radio] - có phải radio mode không
  /// [shuffle] - có shuffle không
  /// Returns Map với thông tin playlist
  Future<Map<String, dynamic>> getWatchPlaylist({
    String videoId = "",
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
    String? additionalParamsNext,
    bool onlyRelated = false,
  });

  /// Lấy danh sách bài hát trong playlist hoặc album
  /// 
  /// [playlistId] - ID của playlist (optional)
  /// [albumId] - ID của album (optional)
  /// [limit] - giới hạn số bài hát
  /// Returns Map với danh sách bài hát
  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs({
    String? playlistId,
    String? albumId,
    int limit = 3000,
    bool related = false,
    int suggestionsLimit = 0,
  });

  /// Lấy suggestions cho search
  /// 
  /// [queryStr] - query string
  /// Returns List<String> suggestions
  Future<List<String>> getSearchSuggestion(String queryStr);

  /// Lấy lyrics cho bài hát
  /// 
  /// [browseId] - ID để browse lyrics
  /// Returns dynamic lyrics data
  Future<dynamic> getLyrics(String browseId);

  /// Lấy nội dung liên quan đến bài hát
  /// 
  /// [videoId] - ID của video
  /// [hlCode] - language code
  /// Returns dynamic related content
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode);

  /// Lấy album browse ID từ audio playlist ID
  /// 
  /// [audioPlaylistId] - ID của audio playlist
  /// Returns String browse ID
  Future<String> getAlbumBrowseId(String audioPlaylistId);

  /// Lấy thông tin năm phát hành của bài hát
  /// 
  /// [songId] - ID của bài hát
  /// Returns String? năm phát hành
  Future<String?> getSongYear(String songId);

  /// Lấy thông tin bài hát bằng ID
  /// 
  /// [songId] - ID của bài hát
  /// Returns List thông tin bài hát
  Future<List> getSongWithId(String songId);
}