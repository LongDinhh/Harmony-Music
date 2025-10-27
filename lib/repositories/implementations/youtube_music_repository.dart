import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart' as getx;
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/media_Item_builder.dart';
import '../../services/music_service.dart';
import '../../services/youtube_data_parser_service.dart';
import '../../utils/helper.dart';
import '../repositories.dart';

/// Concrete implementation của MusicRepository sử dụng YouTube Music API
/// Wraps around existing MusicServices để maintain backward compatibility
class YouTubeMusicRepository implements MusicRepository {
  final MusicServices _musicService;
  final YouTubeDataParserService _parserService;

  YouTubeMusicRepository({
    MusicServices? musicService,
    YouTubeDataParserService? parserService,
  })  : _musicService = musicService ?? getx.Get.find<MusicServices>(),
        _parserService = parserService ?? YouTubeDataParserService.instance;

  @override
  Future<List<MediaItem>> searchSongs(
    String query, {
    String? filter,
    int limit = 30,
  }) async {
    try {
      RepositoryUtils.validateNonEmpty(query, 'search query');
      
      printINFO('🔍 YouTubeMusicRepository: Searching songs for query: $query');
      
      final response = await _musicService.search(
        query,
        filter: filter,
        limit: limit,
      );

      // Parse search results to get songs - need to extract songs from response
      final contents = response['contents'];
      if (contents == null) {
        printWARN('🔍 YouTubeMusicRepository: No contents in search response');
        return [];
      }
      
      // Parse search results using existing parser
      final songs = _parserService.parseSearchResults(
        contents, 
        ['songs'], 
        'songs', 
        'music'
      );
      
      printINFO('🔍 YouTubeMusicRepository: Found ${songs.length} songs');
      
      return songs.map((songData) => MediaItemBuilder.fromJson(songData)).toList();
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.searchSongs error: $error');
      throw MusicException.searchFailed('Failed to search songs: $error');
    }
  }

  @override
  Future<Album> getAlbum(String albumId) async {
    try {
      RepositoryUtils.validateNonEmpty(albumId, 'albumId');
      
      printINFO('📀 YouTubeMusicRepository: Getting album: $albumId');
      
      final response = await _musicService.getPlaylistOrAlbumSongs(
        albumId: albumId,
        limit: 3000,
      );

      // Parse album header data
      final albumHeaderData = _parserService.parseAlbumHeader(response);
      final album = Album.fromJson(albumHeaderData);
      
      printINFO('📀 YouTubeMusicRepository: Got album: ${album.title}');
      
      return album;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getAlbum error: $error');
      throw MusicException.albumNotFound(albumId);
    }
  }

  @override
  Future<Artist> getArtist(String artistId) async {
    try {
      RepositoryUtils.validateNonEmpty(artistId, 'artistId');
      
      printINFO('🎤 YouTubeMusicRepository: Getting artist: $artistId');
      
      final response = await _musicService.getArtist(artistId);
      
      // Parse artist contents - need to extract artist info from response
      final contents = response['contents'] ?? [];
      final artistContents = _parserService.parseArtistContents(contents);
      
      // Extract artist basic info from response header or first content
      final artistData = response['header'] ?? artistContents;
      final artist = Artist.fromJson(artistData);
      
      printINFO('🎤 YouTubeMusicRepository: Got artist: ${artist.name}');
      
      return artist;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getArtist error: $error');
      throw MusicException.artistNotFound(artistId);
    }
  }

  @override
  Future<dynamic> getHomeContent({int limit = 4}) async {
    try {
      printINFO('🏠 YouTubeMusicRepository: Getting home content (limit: $limit)');
      
      final response = await _musicService.getHome(limit: limit);
      
      printINFO('🏠 YouTubeMusicRepository: Got home content');
      
      return response;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getHomeContent error: $error');
      throw MusicException.networkError('Failed to get home content: $error');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"}) async {
    try {
      printINFO('📊 YouTubeMusicRepository: Getting charts for country: $countryCode');
      
      final response = await _musicService.getCharts(countryCode: countryCode);
      
      printINFO('📊 YouTubeMusicRepository: Got ${response.length} chart sections');
      
      return response;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getCharts error: $error');
      throw MusicException.networkError('Failed to get charts: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getWatchPlaylist({
    String videoId = "",
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
    String? additionalParamsNext,
    bool onlyRelated = false,
  }) async {
    try {
      printINFO('📺 YouTubeMusicRepository: Getting watch playlist (videoId: $videoId, playlistId: $playlistId)');
      
      final response = await _musicService.getWatchPlaylist(
        videoId: videoId,
        playlistId: playlistId,
        limit: limit,
        radio: radio,
        shuffle: shuffle,
        additionalParamsNext: additionalParamsNext,
        onlyRelated: onlyRelated,
      );
      
      printINFO('📺 YouTubeMusicRepository: Got watch playlist');
      
      return response;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getWatchPlaylist error: $error');
      throw MusicException.networkError('Failed to get watch playlist: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs({
    String? playlistId,
    String? albumId,
    int limit = 3000,
    bool related = false,
    int suggestionsLimit = 0,
  }) async {
    try {
      if (playlistId == null && albumId == null) {
        throw const MusicException.parseError('Either playlistId or albumId must be provided');
      }
      
      printINFO('🎵 YouTubeMusicRepository: Getting songs (playlistId: $playlistId, albumId: $albumId)');
      
      final response = await _musicService.getPlaylistOrAlbumSongs(
        playlistId: playlistId,
        albumId: albumId,
        limit: limit,
        related: related,
        suggestionsLimit: suggestionsLimit,
      );
      
      printINFO('🎵 YouTubeMusicRepository: Got playlist/album songs');
      
      return response;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getPlaylistOrAlbumSongs error: $error');
      throw MusicException.networkError('Failed to get playlist/album songs: $error');
    }
  }

  @override
  Future<List<String>> getSearchSuggestion(String queryStr) async {
    try {
      RepositoryUtils.validateNonEmpty(queryStr, 'queryStr');
      
      printINFO('💡 YouTubeMusicRepository: Getting search suggestions for: $queryStr');
      
      final response = await _musicService.getSearchSuggestion(queryStr);
      
      printINFO('💡 YouTubeMusicRepository: Got ${response.length} suggestions');
      
      return response;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getSearchSuggestion error: $error');
      throw MusicException.networkError('Failed to get search suggestions: $error');
    }
  }

  @override
  Future<dynamic> getLyrics(String browseId) async {
    try {
      RepositoryUtils.validateNonEmpty(browseId, 'browseId');
      
      printINFO('📝 YouTubeMusicRepository: Getting lyrics for: $browseId');
      
      final response = await _musicService.getLyrics(browseId);
      
      printINFO('📝 YouTubeMusicRepository: Got lyrics');
      
      return response;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getLyrics error: $error');
      throw MusicException.networkError('Failed to get lyrics: $error');
    }
  }

  @override
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode) async {
    try {
      RepositoryUtils.validateNonEmpty(videoId, 'videoId');
      RepositoryUtils.validateNonEmpty(hlCode, 'hlCode');
      
      printINFO('🔗 YouTubeMusicRepository: Getting related content for: $videoId');
      
      final response = await _musicService.getContentRelatedToSong(videoId, hlCode);
      
      printINFO('🔗 YouTubeMusicRepository: Got related content');
      
      return response;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getContentRelatedToSong error: $error');
      throw MusicException.networkError('Failed to get related content: $error');
    }
  }

  @override
  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    try {
      RepositoryUtils.validateNonEmpty(audioPlaylistId, 'audioPlaylistId');
      
      printINFO('🔍 YouTubeMusicRepository: Getting album browse ID for: $audioPlaylistId');
      
      final response = await _musicService.getAlbumBrowseId(audioPlaylistId);
      
      printINFO('🔍 YouTubeMusicRepository: Got album browse ID: $response');
      
      return response;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getAlbumBrowseId error: $error');
      throw MusicException.networkError('Failed to get album browse ID: $error');
    }
  }

  @override
  Future<String?> getSongYear(String songId) async {
    try {
      RepositoryUtils.validateNonEmpty(songId, 'songId');
      
      printINFO('📅 YouTubeMusicRepository: Getting song year for: $songId');
      
      final response = await _musicService.getSongYear(songId);
      
      printINFO('📅 YouTubeMusicRepository: Got song year: $response');
      
      return response;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getSongYear error: $error');
      throw MusicException.networkError('Failed to get song year: $error');
    }
  }

  @override
  Future<List> getSongWithId(String songId) async {
    try {
      RepositoryUtils.validateNonEmpty(songId, 'songId');
      
      printINFO('🎵 YouTubeMusicRepository: Getting song with ID: $songId');
      
      final response = await _musicService.getSongWithId(songId);
      
      printINFO('🎵 YouTubeMusicRepository: Got song data');
      
      return response;
    } catch (error) {
      printERROR('❌ YouTubeMusicRepository.getSongWithId error: $error');
      throw MusicException.networkError('Failed to get song: $error');
    }
  }
}