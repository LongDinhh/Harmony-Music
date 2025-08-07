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
import '../../services/ytmusic_api_service.dart';
import '../../utils/error_handler.dart';

/// New implementation of MusicRepository using dart_ytmusic_api
class YTMusicRepository implements MusicRepository {
  final YTMusicAPIService _ytMusicService;
  final CacheRepository _cacheRepository;

  YTMusicRepository(this._ytMusicService, this._cacheRepository);

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
      final response = await _ytMusicService.search(query, filter: 'songs', limit: limit);
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
      final response = await _ytMusicService.search(
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

      // Fetch album data
      final response = await _ytMusicService.getAlbum(albumId);
      
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

      // Fetch artist data
      final response = await _ytMusicService.getArtist(artistId);
      
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
  Future<Map<String, dynamic>> getHomeContent({int limit = 4, bool forceRefresh = false}) async {
    try {
      print("===============getHomeContent new (forceRefresh: $forceRefresh)");
      
      // Skip cache if forceRefresh is true
      if (!forceRefresh) {
        final cachedContent = await _cacheRepository.getCachedHomeScreenData();
        if (cachedContent != null) {
          print("Loading home content from cache");
          // Convert cached serializable format back to Models
          return _convertSerializableFormatToModels(cachedContent);
        }
      }

      print("Loading home content from network");
      final response = await _ytMusicService.getHomeData(limit: limit);
      
      // Parse response into proper Models
      final parsedResponse = _parseHomeContentResponse(response);
      
      // Convert Models to serializable format for caching
      final serializableResponse = _convertModelsToSerializableFormat(parsedResponse);
      
      // Cache the serializable content
      await _cacheRepository.cacheHomeScreenData(serializableResponse);
      
      return parsedResponse;
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
      final response = await _ytMusicService.getWatchPlaylist(
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

      final response = await _ytMusicService.getPlaylistOrAlbumSongs(
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
      return await _ytMusicService.getSearchSuggestions(query);
    } catch (error) {
      throw MusicException.searchFailed('Failed to get search suggestions: ${error.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"}) async {
    try {
      return await _ytMusicService.getCharts(countryCode: countryCode);
    } catch (error) {
      throw MusicException.networkError('Failed to get charts: ${error.toString()}');
    }
  }

  @override
  Future<List> getSongDetails(String songId) async {
    try {
      return await _ytMusicService.getSongWithId(songId);
    } catch (error) {
      throw MusicException.networkError('Failed to get song details: ${error.toString()}');
    }
  }

  @override
  Future<dynamic> getRelatedContent(String videoId, String hlCode, {bool forceRefresh = false}) async {
    try {
      // Note: Related content is usually dynamic and short-lived, so we don't cache it extensively
      // But if needed, forceRefresh parameter is available for future cache implementation
      return await _ytMusicService.getContentRelatedToSong(videoId, hlCode);
    } catch (error) {
      throw MusicException.networkError('Failed to get related content: ${error.toString()}');
    }
  }

  @override
  Future<dynamic> getLyrics(String browseId) async {
    try {
      return await _ytMusicService.getLyrics(browseId);
    } catch (error) {
      throw MusicException.networkError('Failed to get lyrics: ${error.toString()}');
    }
  }

  @override
  Future<dynamic> getArtistRelatedContent(
    Map<String, dynamic> browseEndpoint,
    String category, {
    String additionalParams = "",
  }) async {
    try {
      return await _ytMusicService.getArtistRelatedContent(
        browseEndpoint,
        category,
        additionalParams: additionalParams,
      );
    } catch (error) {
      throw MusicException.networkError('Failed to get artist related content: ${error.toString()}');
    }
  }

  @override
  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    try {
      return await _ytMusicService.getAlbumBrowseId(audioPlaylistId);
    } catch (error) {
      throw MusicException.networkError('Failed to get album browse ID: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getSearchContinuation(
    Map additionalParamsNext, {
    int limit = 10,
  }) async {
    try {
      return await _ytMusicService.getSearchContinuation(
        additionalParamsNext,
        limit: limit,
      );
    } catch (error) {
      throw MusicException.networkError('Failed to get search continuation: ${error.toString()}');
    }
  }

  // Helper methods for parsing responses (similar to original implementation)
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

  Map<String, dynamic> _parseHomeContentResponse(dynamic response) {
    try {
      // Handle both direct API response (List) and wrapped response (Map with 'contents')
      List<dynamic> homeContentList = [];
      
      if (response is List) {
        homeContentList = response;
      } else if (response is Map && response.containsKey('contents')) {
        homeContentList = response['contents'] as List? ?? [];
      } else if (response is Map) {
        // Try to find the list in the response
        for (final value in response.values) {
          if (value is List && value.isNotEmpty) {
            homeContentList = value;
            break;
          }
        }
      }

      print("Parsing ${homeContentList.length} home content sections");
      
      // Debug: Print raw response structure
      if (homeContentList.isNotEmpty) {
        final firstSection = homeContentList[0];
        print("First section type: ${firstSection.runtimeType}");
        if (firstSection is Map) {
          print("First section keys: ${firstSection.keys}");
          if (firstSection['contents'] is List) {
            final contents = firstSection['contents'] as List;
            print("First section contents count: ${contents.length}");
            if (contents.isNotEmpty) {
              final firstContent = contents[0];
              print("First content type: ${firstContent.runtimeType}");
              if (firstContent is Map) {
                print("First content keys: ${firstContent.keys}");
              }
            }
          }
        }
      }

      final List<Map<String, dynamic>> parsedContents = [];

      for (final section in homeContentList) {
        if (section is! Map) {
          print("Skipping non-Map section: ${section.runtimeType}");
          continue;
        }
        
        final sectionMap = Map<String, dynamic>.from(section);
        final title = sectionMap['title'] as String? ?? 'Unknown Section';
        final contents = sectionMap['contents'] as List? ?? [];
        
        print("Processing section: $title with ${contents.length} items");
        
        if (contents.isEmpty) {
          print("Skipping empty section: $title");
          continue;
        }

        // Determine content type and handle both Maps and Model objects
        final firstItem = contents.first;
        print("First item type in $title: ${firstItem.runtimeType}");
        
        // Handle already parsed Model objects
        if (firstItem is Playlist) {
          print("Section $title contains Playlist objects");
          final playlists = contents.whereType<Playlist>().toList();
          print("Found ${playlists.length} playlists for section: $title");
          if (playlists.length >= 1) {
            parsedContents.add({
              'title': title,
              'contents': playlists,
            });
          }
        } else if (firstItem is Album) {
          print("Section $title contains Album objects");
          final albums = contents.whereType<Album>().toList();
          print("Found ${albums.length} albums for section: $title");
          if (albums.length >= 1) {
            parsedContents.add({
              'title': title,
              'contents': albums,
            });
          }
        } else if (firstItem is MediaItem) {
          print("Section $title contains MediaItem objects");
          final songs = contents.whereType<MediaItem>().toList();
          print("Found ${songs.length} songs for section: $title");
          if (songs.length >= 1) {
            parsedContents.add({
              'title': title,
              'contents': songs,
            });
          }
        }
        // Handle raw Map data that needs parsing
        else if (firstItem is Map) {
          final firstItemMap = Map<String, dynamic>.from(firstItem);
          print("Section $title contains Map objects with keys: ${firstItemMap.keys}");
          
          if (_isPlaylistData(firstItemMap)) {
            final playlists = <Playlist>[];
            for (final item in contents) {
              if (item is Map) {
                try {
                  final playlist = Playlist.fromJson(Map<String, dynamic>.from(item));
                  playlists.add(playlist);
                } catch (e) {
                  print("Failed to parse playlist: $e");
                  continue;
                }
              }
            }
            print("Parsed ${playlists.length} playlists for section: $title");
            if (playlists.length >= 1) {
              parsedContents.add({
                'title': title,
                'contents': playlists,
              });
            }
          } else if (_isAlbumData(firstItemMap)) {
            final albums = <Album>[];
            for (final item in contents) {
              if (item is Map) {
                try {
                  final album = Album.fromJson(Map<String, dynamic>.from(item));
                  albums.add(album);
                } catch (e) {
                  print("Failed to parse album: $e");
                  continue;
                }
              }
            }
            print("Parsed ${albums.length} albums for section: $title");
            if (albums.length >= 1) {
              parsedContents.add({
                'title': title,
                'contents': albums,
              });
            }
          } else if (_isSongData(firstItemMap)) {
            final songs = <MediaItem>[];
            for (final item in contents) {
              if (item is Map) {
                try {
                  final song = MediaItemBuilder.fromJson(Map<String, dynamic>.from(item));
                  songs.add(song);
                } catch (e) {
                  print("Failed to parse song: $e");
                  continue;
                }
              }
            }
            print("Parsed ${songs.length} songs for section: $title");
            if (songs.length >= 1) {
              parsedContents.add({
                'title': title,
                'contents': songs,
              });
            }
          } else {
            print("Unknown Map content type in section: $title, keys: ${firstItemMap.keys}");
          }
        } else {
          print("Unknown content type in section: $title, type: ${firstItem.runtimeType}");
        }
      }

      print("Successfully parsed ${parsedContents.length} content sections");
      
      return {
        'contents': parsedContents,
      };
    } catch (error) {
      throw MusicException.parseError('Failed to parse home content response: ${error.toString()}');
    }
  }

  // Helper methods to identify content types
  bool _isPlaylistData(Map<String, dynamic> data) {
    return data.containsKey('playlistId') && data.containsKey('title');
  }

  bool _isAlbumData(Map<String, dynamic> data) {
    return data.containsKey('browseId') && 
           data.containsKey('title') && 
           data.containsKey('artists');
  }

  bool _isSongData(Map<String, dynamic> data) {
    return data.containsKey('videoId') && data.containsKey('title');
  }

  // Convert Model objects to serializable format for caching (same as original)
  Map<String, dynamic> _convertModelsToSerializableFormat(Map<String, dynamic> parsedResponse) {
    try {
      final contents = parsedResponse['contents'] as List;
      final serializableContents = <Map<String, dynamic>>[];

      for (final section in contents) {
        if (section is Map<String, dynamic>) {
          final title = section['title'] as String;
          final sectionContents = section['contents'] as List;
          final serializableSectionContents = <Map<String, dynamic>>[];

          for (final item in sectionContents) {
            if (item is MediaItem) {
              serializableSectionContents.add({
                '_type': 'MediaItem',
                'data': MediaItemBuilder.toJson(item),
              });
            } else if (item is Playlist) {
              serializableSectionContents.add({
                '_type': 'Playlist', 
                'data': item.toJson(),
              });
            } else if (item is Album) {
              serializableSectionContents.add({
                '_type': 'Album',
                'data': item.toJson(),
              });
            }
          }

          serializableContents.add({
            'title': title,
            'contents': serializableSectionContents,
          });
        }
      }

      return {
        'contents': serializableContents,
      };
    } catch (error) {
      print("Error converting models to serializable format: $error");
      return parsedResponse; // Return original if conversion fails
    }
  }

  // Convert serializable format back to Model objects (same as original)
  Map<String, dynamic> _convertSerializableFormatToModels(Map<String, dynamic> serializableResponse) {
    try {
      final contents = serializableResponse['contents'] as List;
      final modelContents = <Map<String, dynamic>>[];

      for (final section in contents) {
        if (section is Map<String, dynamic>) {
          final title = section['title'] as String;
          final sectionContents = section['contents'] as List;
          final modelSectionContents = <dynamic>[];

          for (final item in sectionContents) {
            if (item is Map<String, dynamic> && item.containsKey('_type') && item.containsKey('data')) {
              final type = item['_type'] as String;
              final data = item['data'] as Map<String, dynamic>;

              switch (type) {
                case 'MediaItem':
                  modelSectionContents.add(MediaItemBuilder.fromJson(data));
                  break;
                case 'Playlist':
                  modelSectionContents.add(Playlist.fromJson(data));
                  break;
                case 'Album':
                  modelSectionContents.add(Album.fromJson(data));
                  break;
              }
            }
          }

          modelContents.add({
            'title': title,
            'contents': modelSectionContents,
          });
        }
      }

      return {
        'contents': modelContents,
      };
    } catch (error) {
      print("Error converting serializable format to models: $error");
      // If conversion fails, try to parse as if it's raw format
      return _parseHomeContentResponse(serializableResponse);
    }
  }
}