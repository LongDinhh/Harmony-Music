import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';

import '../interfaces/music_repository.dart';
import '../interfaces/cache_repository.dart';
import '../exceptions/repository_exception.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/playlist.dart';
import '../../models/media_item_builder.dart';
import '../../services/api_service.dart';
import '../../utils/error_handler.dart';

/// Concrete implementation of MusicRepository for YouTube Music
class YouTubeMusicRepository implements MusicRepository {
  final APIService _apiService;
  final CacheRepository _cacheRepository;

  YouTubeMusicRepository(this._apiService, this._cacheRepository);

  @override
  Future<List<MediaItem>> searchSongs(String query, {int limit = 30}) async {
    try {
      // Check cache first
      final cachedResults = await _cacheRepository.getCachedSearchResults(query);
      if (cachedResults != null) {
        final songs = (cachedResults['songs'] as List?)
            ?.map((e) => MediaItemBuilder.fromJson(e))
            .toList() ?? [];
        return songs.take(limit).toList();
      }

      // Fetch from API
      final response = await _apiService.search(query, limit: limit);
      final songs = _parseSearchResponse(response);
      
      // Cache results
      await _cacheRepository.cacheSearchResults(query, {'songs': songs.map((s) => MediaItemBuilder.toJson(s)).toList()});
      
      return songs;
    } catch (error) {
      throw MusicException.searchFailed('Failed to search songs: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> searchWithFilter(
    String query, {
    String? filter,
    String? scope,
    int limit = 30,
    bool ignoreSpelling = false,
  }) async {
    try {
      final response = await _apiService.search(
        query,
        filter: filter,
        scope: scope,
        limit: limit,
        ignoreSpelling: ignoreSpelling,
      );
      return response;
    } catch (error) {
      throw MusicException.searchFailed('Failed to search with filter: ${error.toString()}');
    }
  }

  @override
  Future<Album> getAlbum(String albumId) async {
    try {
      // Check cache first
      final cachedAlbum = await _cacheRepository.getCachedAlbumData(albumId);
      if (cachedAlbum != null) {
        return Album.fromJson(cachedAlbum);
      }

      // Get album browse ID first
      final browseId = await _apiService.getAlbumBrowseId(albumId);
      
      // Fetch album data
      final response = await _apiService.getPlaylistOrAlbumSongs(albumId: browseId);
      
      if (response.isEmpty) {
        throw MusicException.albumNotFound(albumId);
      }

      final albumData = _parseAlbumResponse(response);
      final album = Album.fromJson(albumData);
      
      // Cache album data
      await _cacheRepository.cacheAlbumData(albumId, albumData);
      
      return album;
    } catch (error) {
      if (error is MusicException) rethrow;
      throw MusicException.albumNotFound('Failed to get album $albumId: ${error.toString()}');
    }
  }

  @override
  Future<Artist> getArtist(String artistId) async {
    try {
      // Check cache first
      final cachedArtist = await _cacheRepository.getCachedArtistData(artistId);
      if (cachedArtist != null) {
        return Artist.fromJson(cachedArtist);
      }

      final response = await _apiService.getArtist(artistId);
      
      if (response.isEmpty) {
        throw MusicException.artistNotFound(artistId);
      }

      final artistData = _parseArtistResponse(response);
      final artist = Artist.fromJson(artistData);
      
      // Cache artist data
      await _cacheRepository.cacheArtistData(artistId, artistData);
      
      return artist;
    } catch (error) {
      if (error is MusicException) rethrow;
      throw MusicException.artistNotFound('Failed to get artist $artistId: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getHomeContent({int limit = 4}) async {
    try {
      // Check cache first
      final cachedContent = await _cacheRepository.getCachedHomeScreenData();
      if (cachedContent != null) {
        return cachedContent;
      }

      final response = await _apiService.getHomeData(limit: limit);
      
      // Cache home content
      await _cacheRepository.cacheHomeScreenData(response);
      
      return response;
    } catch (error) {
      throw MusicException.networkError('Failed to get home content: ${error.toString()}');
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
      final response = await _apiService.getWatchPlaylist(
        videoId: videoId,
        playlistId: playlistId,
        limit: limit,
        radio: radio,
        shuffle: shuffle,
        additionalParamsNext: additionalParamsNext,
        onlyRelated: onlyRelated,
      );
      return response;
    } catch (error) {
      throw MusicException.networkError('Failed to get watch playlist: ${error.toString()}');
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
      // Check cache first if playlistId is provided
      if (playlistId != null) {
        final cachedPlaylist = await _cacheRepository.getCachedPlaylistData(playlistId);
        if (cachedPlaylist != null) {
          return cachedPlaylist;
        }
      }

      final response = await _apiService.getPlaylistOrAlbumSongs(
        playlistId: playlistId,
        albumId: albumId,
        limit: limit,
        related: related,
        suggestionsLimit: suggestionsLimit,
      );

      // Cache playlist data if playlistId is provided
      if (playlistId != null) {
        await _cacheRepository.cachePlaylistData(playlistId, response);
      }

      return response;
    } catch (error) {
      throw MusicException.networkError('Failed to get playlist/album songs: ${error.toString()}');
    }
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      return await _apiService.getSearchSuggestion(query);
    } catch (error) {
      throw MusicException.networkError('Failed to get search suggestions: ${error.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"}) async {
    try {
      return await _apiService.getCharts(countryCode: countryCode);
    } catch (error) {
      throw MusicException.networkError('Failed to get charts: ${error.toString()}');
    }
  }

  @override
  Future<List> getSongDetails(String songId) async {
    try {
      return await _apiService.getSongWithId(songId);
    } catch (error) {
      throw MusicException.networkError('Failed to get song details: ${error.toString()}');
    }
  }

  @override
  Future<dynamic> getRelatedContent(String videoId, String hlCode) async {
    try {
      return await _apiService.getContentRelatedToSong(videoId, hlCode);
    } catch (error) {
      throw MusicException.networkError('Failed to get related content: ${error.toString()}');
    }
  }

  @override
  Future<dynamic> getLyrics(String browseId) async {
    try {
      return await _apiService.getLyrics(browseId);
    } catch (error) {
      throw MusicException.networkError('Failed to get lyrics: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getArtistRelatedContent(
    Map<String, dynamic> browseEndpoint,
    String category, {
    String additionalParams = "",
  }) async {
    try {
      return await _apiService.getArtistRealtedContent(
        browseEndpoint,
        category,
        additionalParams: additionalParams,
      );
    } catch (error) {
      throw MusicException.networkError('Failed to get artist related content: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getSearchContinuation(
    Map additionalParamsNext, {
    int limit = 10,
  }) async {
    try {
      return await _apiService.getSearchContinuation(
        additionalParamsNext,
        limit: limit,
      );
    } catch (error) {
      throw MusicException.networkError('Failed to get search continuation: ${error.toString()}');
    }
  }

  // Helper methods for parsing responses
  List<MediaItem> _parseSearchResponse(Map<String, dynamic> response) {
    try {
      final contents = response['contents'] as List? ?? [];
      final songs = <MediaItem>[];
      
      for (final content in contents) {
        if (content is Map<String, dynamic>) {
          try {
            final song = MediaItemBuilder.fromJson(content);
            songs.add(song);
          } catch (e) {
            // Skip invalid items
            continue;
          }
        }
      }
      
      return songs;
    } catch (error) {
      throw MusicException.parseError('Failed to parse search response: ${error.toString()}');
    }
  }

  Map<String, dynamic> _parseAlbumResponse(Map<String, dynamic> response) {
    try {
      // Extract album information from the response
      // This is a simplified version - you may need to adjust based on actual API response structure
      return {
        'title': response['title'] ?? 'Unknown Album',
        'browseId': response['browseId'] ?? '',
        'artists': response['artists'] ?? [],
        'year': response['year'],
        'description': response['description'],
        'audioPlaylistId': response['audioPlaylistId'],
        'thumbnails': response['thumbnails'] ?? [],
      };
    } catch (error) {
      throw MusicException.parseError('Failed to parse album response: ${error.toString()}');
    }
  }

  Map<String, dynamic> _parseArtistResponse(Map<String, dynamic> response) {
    try {
      // Extract artist information from the response
      return {
        'artist': response['name'] ?? response['artist'] ?? 'Unknown Artist',
        'browseId': response['browseId'] ?? '',
        'radioId': response['radioId'],
        'subscribers': response['subscribers'],
        'thumbnails': response['thumbnails'] ?? [],
      };
    } catch (error) {
      throw MusicException.parseError('Failed to parse artist response: ${error.toString()}');
    }
  }
}