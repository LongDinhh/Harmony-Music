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
import '../../services/music_service.dart';

/// Adapter that wraps the existing MusicServices to implement MusicRepository interface
/// This provides a bridge between the new repository pattern and existing service architecture
class MusicServiceAdapter implements MusicRepository {
  final MusicServices _musicService;
  final CacheRepository _cacheRepository;

  MusicServiceAdapter(this._musicService, this._cacheRepository);

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

      // Fetch from MusicServices
      final response = await _musicService.search(query, limit: limit);
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
      return await _musicService.search(query, limit: limit, filter: filter);
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

      // Fetch from MusicServices
      final response = await _musicService.getPlaylistOrAlbumSongs(albumId: albumId);
      
      if (response.isEmpty) {
        throw MusicException.albumNotFound(albumId);
      }

      final albumData = _parseAlbumResponse(response, albumId);
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

      final response = await _musicService.getArtist(artistId);
      
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
        // Convert cached serializable data back to MediaItems
        final deserializedContents = _convertFromSerializableFormat(cachedContent['contents']);
        return {
          'contents': deserializedContents,
          'timestamp': cachedContent['timestamp'],
          'limit': cachedContent['limit'],
        };
      }

      final response = await _musicService.getHome(limit: limit);
      
      // Convert MediaItems to serializable format for caching
      final serializableResponse = _convertToSerializableFormat(response);
      
      // Convert List response to Map format expected by repository interface
      final homeContentMap = {
        'contents': serializableResponse,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'limit': limit,
      };
      
      // Cache the serializable version
      await _cacheRepository.cacheHomeScreenData(homeContentMap);
      
      // Return the original response structure for the controller
      return {
        'contents': response,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'limit': limit,
      };
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
      return await _musicService.getWatchPlaylist(
        videoId: videoId,
        playlistId: playlistId,
        limit: limit,
        radio: radio,
        shuffle: shuffle,
        additionalParamsNext: additionalParamsNext,
        onlyRelated: onlyRelated,
      );
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

      final response = await _musicService.getPlaylistOrAlbumSongs(
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
      return await _musicService.getSearchSuggestion(query);
    } catch (error) {
      throw MusicException.networkError('Failed to get search suggestions: ${error.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"}) async {
    try {
      return await _musicService.getCharts(countryCode: countryCode);
    } catch (error) {
      throw MusicException.networkError('Failed to get charts: ${error.toString()}');
    }
  }

  @override
  Future<List> getSongDetails(String songId) async {
    try {
      return await _musicService.getSongWithId(songId);
    } catch (error) {
      throw MusicException.networkError('Failed to get song details: ${error.toString()}');
    }
  }

  @override
  Future<dynamic> getRelatedContent(String videoId, String hlCode) async {
    try {
      return await _musicService.getContentRelatedToSong(videoId, hlCode);
    } catch (error) {
      throw MusicException.networkError('Failed to get related content: ${error.toString()}');
    }
  }

  @override
  Future<dynamic> getLyrics(String browseId) async {
    try {
      return await _musicService.getLyrics(browseId);
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
      return await _musicService.getArtistRealtedContent(
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
      return await _musicService.getSearchContinuation(
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

  Map<String, dynamic> _parseAlbumResponse(Map<String, dynamic> response, String albumId) {
    try {
      // Extract album information from the response
      return {
        'title': response['title'] ?? 'Unknown Album',
        'browseId': albumId,
        'artists': response['artists'] ?? [],
        'year': response['year'],
        'description': response['description'],
        'audioPlaylistId': response['audioPlaylistId'],
        'thumbnails': response['thumbnails'] ?? [{'url': 'https://via.placeholder.com/300'}],
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
        'thumbnails': response['thumbnails'] ?? [{'url': 'https://via.placeholder.com/300'}],
      };
    } catch (error) {
      throw MusicException.parseError('Failed to parse artist response: ${error.toString()}');
    }
  }

  /// Convert home content to serializable format for caching
  dynamic _convertToSerializableFormat(dynamic data) {
    if (data is List) {
      return data.map((item) => _convertToSerializableFormat(item)).toList();
    } else if (data is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in data.entries) {
        result[entry.key] = _convertToSerializableFormat(entry.value);
      }
      return result;
    } else if (data is MediaItem) {
      // Convert MediaItem to JSON
      return MediaItemBuilder.toJson(data);
    } else {
      // Return primitive types as-is
      return data;
    }
  }

  /// Convert serializable format back to original format with MediaItems
  dynamic _convertFromSerializableFormat(dynamic data) {
    if (data is List) {
      return data.map((item) => _convertFromSerializableFormat(item)).toList();
    } else if (data is Map<String, dynamic>) {
      // Check if this looks like a MediaItem JSON
      if (data.containsKey('videoId') && data.containsKey('title')) {
        try {
          return MediaItemBuilder.fromJson(data);
        } catch (e) {
          // If conversion fails, return as Map
          final result = <String, dynamic>{};
          for (final entry in data.entries) {
            result[entry.key] = _convertFromSerializableFormat(entry.value);
          }
          return result;
        }
      } else {
        // Regular Map, convert recursively
        final result = <String, dynamic>{};
        for (final entry in data.entries) {
          result[entry.key] = _convertFromSerializableFormat(entry.value);
        }
        return result;
      }
    } else {
      // Return primitive types as-is
      return data;
    }
  }
}