import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';

import '../interfaces/music_repository.dart';
import '../interfaces/cache_repository.dart';
import '../exceptions/repository_exception.dart';
import '../../models/media_item.dart';
import '../../models/playlist.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../services/ytmusic_api_service.dart';
import '../../utils/error_handler.dart';

/// Implementation of MusicRepository using YTMusicAPIService (dart_ytmusic_api)
class YTMusicRepository implements MusicRepository {
  final YTMusicAPIService _ytMusicService;
  final CacheRepository _cacheRepository;

  YTMusicRepository(this._ytMusicService, this._cacheRepository);

  @override
  Future<Map<String, dynamic>> getHomeContent({int limit = 4, bool forceRefresh = false}) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedContent = await _cacheRepository.getCachedHomeScreenData();
        if (cachedContent != null) {
          return _convertSerializableFormatToModels(cachedContent);
        }
      }

      // Fetch from API
      final response = await _ytMusicService.getHomeData(limit: limit);
      final parsedResponse = _parseHomeContentResponse(response);
      
      // Cache the serializable format
      final serializableResponse = _convertModelsToSerializableFormat(parsedResponse);
      await _cacheRepository.cacheHomeScreenData(serializableResponse);
      
      return parsedResponse;
    } catch (error) {
      throw MusicException('Failed to get home content: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> search(String query, {String? filter, int limit = 20}) async {
    try {
      final response = await _ytMusicService.search(query, type: filter, limit: limit);
      return _parseSearchResponse(response);
    } catch (error) {
      throw MusicException('Failed to search: $error');
    }
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      return await _ytMusicService.getSearchSuggestions(query);
    } catch (error) {
      throw MusicException('Failed to get search suggestions: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getAlbum(String albumId) async {
    try {
      final response = await _ytMusicService.getAlbum(albumId);
      return _parseAlbumResponse(response);
    } catch (error) {
      throw MusicException('Failed to get album: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getArtist(String artistId) async {
    try {
      final response = await _ytMusicService.getArtist(artistId);
      return _parseArtistResponse(response);
    } catch (error) {
      throw MusicException('Failed to get artist: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs(String playlistId) async {
    try {
      final response = await _ytMusicService.getPlaylistOrAlbumSongs(playlistId);
      return {'songs': _parsePlaylistSongs(response)};
    } catch (error) {
      throw MusicException('Failed to get playlist songs: $error');
    }
  }

  @override
  Future<dynamic> getWatchPlaylist(String videoId, String? playlistId) async {
    try {
      return await _ytMusicService.getWatchPlaylist(videoId, playlistId);
    } catch (error) {
      throw MusicException('Failed to get watch playlist: $error');
    }
  }

  @override
  Future<List> getSongWithId(String songId) async {
    try {
      final response = await _ytMusicService.getSongWithId(songId);
      return [response];
    } catch (error) {
      throw MusicException('Failed to get song: $error');
    }
  }

  @override
  Future<dynamic> getRelatedContent(String videoId, String hlCode, {bool forceRefresh = false}) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cacheKey = 'related_$videoId';
        final cachedContent = await _cacheRepository.getCachedData(cacheKey);
        if (cachedContent != null) {
          return cachedContent;
        }
      }

      final response = await _ytMusicService.getContentRelatedToSong(videoId, hlCode);
      
      // Cache the response
      final cacheKey = 'related_$videoId';
      await _cacheRepository.cacheData(cacheKey, response);
      
      return response;
    } catch (error) {
      throw MusicException('Failed to get related content: $error');
    }
  }

  @override
  Future<dynamic> getLyrics(String browseId) async {
    try {
      return await _ytMusicService.getLyrics(browseId);
    } catch (error) {
      throw MusicException('Failed to get lyrics: $error');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCharts(String countryCode) async {
    try {
      final response = await _ytMusicService.getCharts(countryCode);
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (error) {
      throw MusicException('Failed to get charts: $error');
    }
  }

  @override
  Future<String?> getSongYear(String songId) async {
    try {
      final response = await _ytMusicService.getSongYear(songId);
      return response?.toString();
    } catch (error) {
      return null;
    }
  }

  @override
  Future<String?> getAlbumBrowseId(String albumName) async {
    try {
      return await _ytMusicService.getAlbumBrowseId(albumName);
    } catch (error) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getArtistRelatedContent(String artistId) async {
    try {
      final response = await _ytMusicService.getArtistRelatedContent(artistId);
      return {'content': response};
    } catch (error) {
      throw MusicException('Failed to get artist related content: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getSearchContinuation(String continuationToken) async {
    try {
      final response = await _ytMusicService.getSearchContinuation(continuationToken);
      return {'results': response};
    } catch (error) {
      throw MusicException('Failed to get search continuation: $error');
    }
  }

  // Helper methods for parsing responses and converting between formats

  Map<String, dynamic> _parseHomeContentResponse(dynamic response) {
    print('Loading home content from network');
    
    if (response == null) {
      print('API returned null response');
      return {'contents': []};
    }

    try {
      List<dynamic> sections = [];
      
      if (response is List) {
        sections = response;
      } else if (response is Map && response['sections'] != null) {
        sections = response['sections'];
      } else {
        print('Unexpected response format: ${response.runtimeType}');
        return {'contents': []};
      }

      print('Parsing ${sections.length} home content sections');

      List<Map<String, dynamic>> contentTemp = [];

      for (var section in sections) {
        if (section is! Map) continue;
        
        final title = section['title'] ?? section['header'] ?? 'Unknown Section';
        final contents = section['contents'] ?? section['items'] ?? [];
        
        if (contents is! List || contents.isEmpty) continue;
        
        print('Processing section: $title with ${contents.length} items');

        final firstItem = contents[0];
        print('First item type in $title: ${firstItem.runtimeType}');

        List<dynamic> parsedItems = [];

        // Parse items based on type or content structure
        if (_isPlaylistSection(contents)) {
          print('Section $title contains Playlist objects');
          parsedItems = _parsePlaylistItems(contents);
        } else if (_isAlbumSection(contents)) {
          print('Section $title contains Album objects');
          parsedItems = _parseAlbumItems(contents);
        } else if (_isSongSection(contents)) {
          print('Section $title contains MediaItem objects');
          parsedItems = _parseSongItems(contents);
        } else {
          print('Unknown section type for: $title');
          continue;
        }

        if (parsedItems.isNotEmpty) {
          contentTemp.add({
            'title': title,
            'contents': parsedItems,
          });
          print('Found ${parsedItems.length} items for section: $title');
        }
      }

      print('Successfully parsed ${contentTemp.length} content sections');
      return {'contents': contentTemp};
    } catch (error) {
      print('Error parsing home content: $error');
      return {'contents': []};
    }
  }

  bool _isPlaylistSection(List contents) {
    return contents.any((item) => 
      item is Map && (
        item['type'] == 'playlist' ||
        item['playlistId'] != null ||
        item['browseId']?.toString().startsWith('VL') == true
      )
    );
  }

  bool _isAlbumSection(List contents) {
    return contents.any((item) => 
      item is Map && (
        item['type'] == 'album' ||
        item['albumId'] != null ||
        item['browseId']?.toString().startsWith('MPREb') == true
      )
    );
  }

  bool _isSongSection(List contents) {
    return contents.any((item) => 
      item is Map && (
        item['type'] == 'song' ||
        item['videoId'] != null ||
        item['duration'] != null
      )
    );
  }

  List<Playlist> _parsePlaylistItems(List contents) {
    return contents.where((item) => item is Map).map((item) {
      return Playlist(
        id: item['playlistId'] ?? item['browseId'] ?? '',
        title: item['title'] ?? '',
        description: item['description'] ?? '',
        thumbnails: _parseThumbnails(item['thumbnails']),
        author: item['author']?['name'] ?? '',
        year: item['year']?.toString(),
        videoCount: item['videoCount']?.toString(),
      );
    }).toList();
  }

  List<Album> _parseAlbumItems(List contents) {
    return contents.where((item) => item is Map).map((item) {
      return Album(
        id: item['albumId'] ?? item['browseId'] ?? '',
        title: item['title'] ?? '',
        artist: item['artist']?['name'] ?? item['artists']?.first?['name'] ?? '',
        thumbnails: _parseThumbnails(item['thumbnails']),
        year: item['year']?.toString(),
        type: item['type'] ?? 'Album',
      );
    }).toList();
  }

  List<MediaItem> _parseSongItems(List contents) {
    return contents.where((item) => item is Map).map((item) {
      return MediaItem(
        id: item['videoId'] ?? '',
        title: item['title'] ?? '',
        artist: item['artist']?['name'] ?? item['artists']?.first?['name'] ?? '',
        duration: item['duration'] ?? '',
        thumbnails: _parseThumbnails(item['thumbnails']),
        album: item['album']?['name'],
        year: item['year']?.toString(),
      );
    }).toList();
  }

  List<Map<String, dynamic>> _parseThumbnails(dynamic thumbnails) {
    if (thumbnails == null) return [];
    if (thumbnails is List) {
      return thumbnails.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Map<String, dynamic> _parseSearchResponse(Map<String, dynamic> response) {
    // Parse search response from dart_ytmusic_api format to our format
    return response;
  }

  Map<String, dynamic> _parseAlbumResponse(dynamic response) {
    // Parse album response
    return response is Map<String, dynamic> ? response : {};
  }

  Map<String, dynamic> _parseArtistResponse(dynamic response) {
    // Parse artist response
    return response is Map<String, dynamic> ? response : {};
  }

  List<MediaItem> _parsePlaylistSongs(dynamic response) {
    if (response == null) return [];
    
    List<dynamic> songs = [];
    if (response is Map && response['tracks'] != null) {
      songs = response['tracks'];
    } else if (response is List) {
      songs = response;
    }

    return songs.where((song) => song is Map).map((song) {
      return MediaItem(
        id: song['videoId'] ?? '',
        title: song['title'] ?? '',
        artist: song['artist']?['name'] ?? song['artists']?.first?['name'] ?? '',
        duration: song['duration'] ?? '',
        thumbnails: _parseThumbnails(song['thumbnails']),
        album: song['album']?['name'],
      );
    }).toList();
  }

  // Convert models to serializable format for Hive caching
  Map<String, dynamic> _convertModelsToSerializableFormat(Map<String, dynamic> parsedResponse) {
    final contents = parsedResponse['contents'] as List? ?? [];
    
    final serializableContents = contents.map((section) {
      if (section is! Map) return section;
      
      final sectionContents = section['contents'] as List? ?? [];
      final serializableItems = sectionContents.map((item) {
        if (item is Playlist) {
          return {
            '_type': 'Playlist',
            'data': item.toJson(),
          };
        } else if (item is Album) {
          return {
            '_type': 'Album',
            'data': item.toJson(),
          };
        } else if (item is MediaItem) {
          return {
            '_type': 'MediaItem',
            'data': item.toJson(),
          };
        }
        return item;
      }).toList();
      
      return {
        'title': section['title'],
        'contents': serializableItems,
      };
    }).toList();
    
    return {'contents': serializableContents};
  }

  // Convert serializable format back to models
  Map<String, dynamic> _convertSerializableFormatToModels(Map<String, dynamic> serializableResponse) {
    final contents = serializableResponse['contents'] as List? ?? [];
    
    final modelContents = contents.map((section) {
      if (section is! Map) return section;
      
      final sectionContents = section['contents'] as List? ?? [];
      final modelItems = sectionContents.map((item) {
        if (item is Map && item['_type'] != null && item['data'] != null) {
          switch (item['_type']) {
            case 'Playlist':
              return Playlist.fromJson(item['data']);
            case 'Album':
              return Album.fromJson(item['data']);
            case 'MediaItem':
              return MediaItem.fromJson(item['data']);
          }
        }
        return item;
      }).toList();
      
      return {
        'title': section['title'],
        'contents': modelItems,
      };
    }).toList();
    
    return {'contents': modelContents};
  }
}