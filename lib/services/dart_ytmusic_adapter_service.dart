import 'package:dart_ytmusic_api/yt_music.dart';
import 'package:get/get.dart' as getx;
import '../utils/error_handler.dart';
import 'api_service.dart';

/// Adapter service that implements IAPIService using the dart_ytmusic_api package
/// This replaces the custom YouTube Music API implementation
class DartYTMusicAdapterService extends getx.GetxService implements IAPIService {
  static DartYTMusicAdapterService? _instance;
  static DartYTMusicAdapterService get instance => _instance ??= DartYTMusicAdapterService._();

  DartYTMusicAdapterService._();

  late YTMusic _ytMusic;
  bool _initialized = false;

  @override
  void onInit() {
    super.onInit();
    _initializeYTMusic();
  }

  Future<void> _initializeYTMusic() async {
    try {
      _ytMusic = YTMusic();
      
      // Initialize the API - you can pass cookies, gl (geolocation), and hl (language) if needed
      await _ytMusic.initialize(
        // cookies: '', // Optional: Pass cookies for authenticated requests
        // gl: 'VN',    // Optional: Geolocation 
        // hl: 'vi',    // Optional: Language
      );
      
      _initialized = true;
      print('✅ dart_ytmusic_api initialized successfully');
    } catch (e) {
      print('Failed to initialize dart_ytmusic_api: $e');
      // Continue with uninitialized state - some methods might still work
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initializeYTMusic();
    }
  }

  @override
  Future<dynamic> getHomeData({int limit = 4}) async {
    try {
      await _ensureInitialized();
      
      // Get home sections from YouTube Music
      final homeSections = await _ytMusic.getHomeSections();
      
      // Transform to expected format and limit results
      final homeData = homeSections.take(limit).map((section) => {
        'title': section['title'] ?? 'Unknown Section',
        'contents': section['contents'] ?? [],
        'type': section['type'] ?? 'mixed',
      }).toList();

      return homeData;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get home data via dart_ytmusic_api');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"}) async {
    try {
      await _ensureInitialized();
      
      // dart_ytmusic_api doesn't have a direct charts endpoint
      // We'll simulate this by searching for popular music
      final searchResults = await _ytMusic.search('top hits chart');
      
      final charts = <Map<String, dynamic>>[];
      
      // Extract songs from search results
      if (searchResults['Songs'] != null) {
        final songs = searchResults['Songs'] as List;
        for (var song in songs.take(50)) {
          charts.add({
            'title': song['title'] ?? 'Unknown',
            'videoId': song['videoId'] ?? '',
            'thumbnails': song['thumbnails'] ?? [],
            'artists': song['artists'] ?? [],
            'country': countryCode,
            'rank': charts.length + 1,
          });
        }
      }

      return charts;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get charts via dart_ytmusic_api');
      return [];
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
    bool onlyRelated = false
  }) async {
    try {
      await _ensureInitialized();

      if (videoId.isEmpty && playlistId == null) {
        throw Exception("You must provide either a video id or playlist id");
      }

      if (playlistId != null) {
        // Get playlist details and videos
        final playlist = await _ytMusic.getPlaylist(playlistId);
        final playlistVideos = await _ytMusic.getPlaylistVideos(playlistId);

        final tracks = playlistVideos.take(limit).map((video) => {
          'title': video['title'] ?? 'Unknown',
          'videoId': video['videoId'] ?? '',
          'thumbnails': video['thumbnails'] ?? [],
          'artists': video['artists'] ?? [],
          'duration': video['duration'] ?? '0:00',
        }).toList();

        return {
          'tracks': tracks,
          'playlistId': playlistId,
          'lyrics': null,
          'related': null,
        };
      } else {
        // Get song details and related tracks
        final song = await _ytMusic.getSong(videoId);
        
        // Simulate related tracks by searching for similar content
        final artistName = song['artists']?.first?['name'] ?? '';
        final searchQuery = artistName.isNotEmpty ? artistName : song['title'] ?? '';
        final searchResults = await _ytMusic.searchSongs(searchQuery);

        final tracks = searchResults.take(limit).map((track) => {
          'title': track['title'] ?? 'Unknown',
          'videoId': track['videoId'] ?? '',
          'thumbnails': track['thumbnails'] ?? [],
          'artists': track['artists'] ?? [],
          'duration': track['duration'] ?? '0:00',
        }).toList();

        return {
          'tracks': tracks,
          'playlistId': null,
          'lyrics': null,
          'related': null,
        };
      }
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get watch playlist via dart_ytmusic_api');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs({
    String? playlistId,
    String? albumId,
    int limit = 3000,
    bool related = false,
    int suggestionsLimit = 0
  }) async {
    try {
      await _ensureInitialized();

      if (playlistId != null) {
        // Get playlist information
        final playlist = await _ytMusic.getPlaylist(playlistId);
        final playlistVideos = await _ytMusic.getPlaylistVideos(playlistId);

        final tracks = playlistVideos.take(limit).map((video) => {
          'title': video['title'] ?? 'Unknown',
          'videoId': video['videoId'] ?? '',
          'thumbnails': video['thumbnails'] ?? [],
          'artists': video['artists'] ?? [],
          'duration': video['duration'] ?? '0:00',
          'album': playlist['title'] ?? 'Unknown Playlist',
        }).toList();

        return {
          'id': playlistId,
          'title': playlist['title'] ?? 'Unknown Playlist',
          'description': playlist['description'] ?? '',
          'thumbnails': playlist['thumbnails'] ?? [],
          'tracks': tracks,
          'trackCount': tracks.length,
          'duration_seconds': tracks.length * 180, // Estimate 3 minutes per track
        };
      } else if (albumId != null) {
        // Get album information
        final album = await _ytMusic.getAlbum(albumId);

        final tracks = (album['tracks'] as List? ?? []).take(limit).map((track) => {
          'title': track['title'] ?? 'Unknown',
          'videoId': track['videoId'] ?? '',
          'thumbnails': track['thumbnails'] ?? album['thumbnails'] ?? [],
          'artists': track['artists'] ?? album['artists'] ?? [],
          'duration': track['duration'] ?? '0:00',
          'album': album['title'] ?? 'Unknown Album',
        }).toList();

        return {
          'id': albumId,
          'title': album['title'] ?? 'Unknown Album',
          'description': album['description'] ?? '',
          'thumbnails': album['thumbnails'] ?? [],
          'tracks': tracks,
          'trackCount': tracks.length,
          'duration_seconds': tracks.length * 180,
          'year': album['year'],
          'artists': album['artists'] ?? [],
        };
      }

      return {};
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get playlist/album songs via dart_ytmusic_api');
      return {};
    }
  }

  @override
  Future<List<String>> getSearchSuggestion(String queryStr) async {
    try {
      await _ensureInitialized();
      
      final suggestions = await _ytMusic.getSearchSuggestions(queryStr);
      return suggestions.cast<String>();
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get search suggestions via dart_ytmusic_api');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> search(
    String query, {
    String? filter,
    String? scope,
    int limit = 30,
    bool ignoreSpelling = false
  }) async {
    try {
      await _ensureInitialized();

      final results = <String, dynamic>{};

      if (filter == null) {
        // Search all types
        final searchResults = await _ytMusic.search(query);
        return searchResults;
      } else {
        // Search specific type
        switch (filter.toLowerCase()) {
          case 'songs':
            final songs = await _ytMusic.searchSongs(query);
            results['Songs'] = songs.take(limit).toList();
            break;
          case 'videos':
            final videos = await _ytMusic.searchVideos(query);
            results['Videos'] = videos.take(limit).toList();
            break;
          case 'artists':
            final artists = await _ytMusic.searchArtists(query);
            results['Artists'] = artists.take(limit).toList();
            break;
          case 'albums':
            final albums = await _ytMusic.searchAlbums(query);
            results['Albums'] = albums.take(limit).toList();
            break;
          case 'playlists':
            final playlists = await _ytMusic.searchPlaylists(query);
            results['Playlists'] = playlists.take(limit).toList();
            break;
          default:
            final searchResults = await _ytMusic.search(query);
            return searchResults;
        }
      }

      return results;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Search via dart_ytmusic_api');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getArtist(String channelId) async {
    try {
      await _ensureInitialized();

      final artist = await _ytMusic.getArtist(channelId);

      return {
        'name': artist['name'] ?? 'Unknown Artist',
        'channelId': channelId,
        'description': artist['description'] ?? '',
        'thumbnails': artist['thumbnails'] ?? [],
        'subscribers': artist['subscribers'] ?? '0',
        'songs': artist['songs'] ?? [],
        'albums': artist['albums'] ?? [],
        'singles': artist['singles'] ?? [],
      };
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get artist via dart_ytmusic_api');
      return {};
    }
  }

  @override
  Future<String?> getSongYear(String songId) async {
    try {
      await _ensureInitialized();

      final song = await _ytMusic.getSong(songId);
      return song['year']?.toString();
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get song year via dart_ytmusic_api');
      return null;
    }
  }

  @override
  Future<List> getSongWithId(String songId) async {
    try {
      await _ensureInitialized();

      final song = await _ytMusic.getSong(songId);
      
      if (song.isNotEmpty) {
        // Get related tracks by searching for the artist
        final artistName = song['artists']?.first?['name'] ?? '';
        final searchQuery = artistName.isNotEmpty ? artistName : song['title'] ?? '';
        final relatedSongs = await _ytMusic.searchSongs(searchQuery);
        
        return [true, relatedSongs.take(25).toList()];
      }

      return [false, null];
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get song with ID via dart_ytmusic_api');
      return [false, null];
    }
  }

  @override
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode) async {
    try {
      await _ensureInitialized();

      final song = await _ytMusic.getSong(videoId);
      
      // Get related content by searching for similar tracks
      final artistName = song['artists']?.first?['name'] ?? '';
      final searchQuery = artistName.isNotEmpty ? artistName : song['title'] ?? '';
      final relatedContent = await _ytMusic.searchSongs(searchQuery);

      return relatedContent.take(10).map((track) => {
        'title': track['title'] ?? 'Unknown',
        'videoId': track['videoId'] ?? '',
        'thumbnails': track['thumbnails'] ?? [],
        'artists': track['artists'] ?? [],
      }).toList();
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get content related to song via dart_ytmusic_api');
      return null;
    }
  }

  @override
  Future<dynamic> getLyrics(String browseId) async {
    try {
      await _ensureInitialized();

      // dart_ytmusic_api supports lyrics with videoId
      final lyrics = await _ytMusic.getLyrics(browseId);
      return lyrics;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get lyrics via dart_ytmusic_api');
      return null;
    }
  }

  @override
  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    try {
      // For dart_ytmusic_api, we can return the ID as-is
      return audioPlaylistId;
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get album browse ID via dart_ytmusic_api');
      return audioPlaylistId;
    }
  }

  @override
  Future<Map<String, dynamic>> getArtistRealtedContent(
    Map<String, dynamic> browseEndpoint,
    String category, {
    String additionalParams = ""
  }) async {
    try {
      await _ensureInitialized();

      final artistId = browseEndpoint['browseId'] as String?;
      if (artistId == null) {
        return {"results": []};
      }

      if (category == "Songs" || category == "Videos") {
        final artistSongs = await _ytMusic.getArtistSongs(artistId);
        
        return {
          'results': artistSongs.take(50).toList(),
          'additionalParams': '',
        };
      } else if (category == 'Albums') {
        final artistAlbums = await _ytMusic.getArtistAlbums(artistId);
        
        return {
          'results': artistAlbums.take(50).toList(),
          'additionalParams': '',
        };
      } else if (category == 'Singles') {
        final artistSingles = await _ytMusic.getArtistSingles(artistId);
        
        return {
          'results': artistSingles.take(50).toList(),
          'additionalParams': '',
        };
      }

      return {"results": []};
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get artist related content via dart_ytmusic_api');
      return {"results": []};
    }
  }

  @override
  Future<Map<String, dynamic>> getSearchContinuation(
    Map additionalParamsNext, {
    int limit = 10
  }) async {
    try {
      // dart_ytmusic_api handles pagination internally
      // This method would require additional implementation for continuation tokens
      return {};
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'Get search continuation via dart_ytmusic_api');
      return {};
    }
  }

  /// Set the language code
  set hlCode(String code) {
    // Language can be set during initialization
    // For runtime changes, we would need to reinitialize the API
  }
}