// ignore_for_file: unused_element, unused_local_variable

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'repositories.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/media_Item_builder.dart';
import '../utils/helper.dart';

/// Repository Usage Examples
/// 
/// This file demonstrates how to use the repository pattern
/// in controllers and services to maintain clean architecture
/// 
/// Key Benefits:
/// - Clean separation of business logic from data access
/// - Easy testing with mock repositories
/// - Consistent error handling
/// - Type-safe operations

class RepositoryUsageExamples {
  
  /// Example 1: Using MusicRepository for search operations
  /// 
  /// This shows how a controller can use repository for clean data access
  static Future<void> _searchMusicExample() async {
    try {
      // Get repository instance from GetX
      final musicRepository = Get.find<MusicRepository>();
      
      // Search for songs - repository handles API calls and parsing
      final songs = await musicRepository.searchSongs(
        'Vietnamese pop music',
        filter: 'songs',
        limit: 20,
      );
      
      // Use the results in UI
      printINFO('Found ${songs.length} songs');
      for (final song in songs) {
        printINFO('Song: ${song.title} by ${song.artist}');
      }
      
      // Get home content
      final homeData = await musicRepository.getHomeContent(limit: 5);
      printINFO('Home content loaded: $homeData');
      
    } on MusicException catch (e) {
      // Handle specific music-related errors
      printERROR('Music operation failed: ${e.message}');
      switch (e.code) {
        case 'SEARCH_FAILED':
          // Show search error to user
          break;
        case 'NETWORK_ERROR':
          // Show network error to user
          break;
        default:
          // Show generic error
      }
    } catch (e) {
      // Handle unexpected errors
      printERROR('Unexpected error: $e');
    }
  }

  /// Example 2: Using LibraryRepository for local operations
  /// 
  /// This shows how to manage user's personal library
  static Future<void> _libraryManagementExample() async {
    try {
      final libraryRepository = Get.find<LibraryRepository>();
      
      // Add song to favorites
      final song = MediaItem(
        id: 'test123',
        title: 'Test Song',
        artist: 'Test Artist',
      );
      
      await libraryRepository.addSongToLibrary(song);
      printINFO('Song added to library');
      
      // Check if song is in library
      final isInLibrary = await libraryRepository.isSongInLibrary('test123');
      printINFO('Song in library: $isInLibrary');
      
      // Create a new playlist
      final playlist = await libraryRepository.createPlaylist(
        'My Awesome Playlist',
        description: 'Collection of my favorite songs',
      );
      printINFO('Created playlist: ${playlist.title}');
      
      // Add song to playlist
      await libraryRepository.addSongToPlaylist(playlist.playlistId, song);
      printINFO('Song added to playlist');
      
      // Get all playlists
      final playlists = await libraryRepository.getPlaylists();
      printINFO('Total playlists: ${playlists.length}');
      
      // Get library statistics
      final stats = await libraryRepository.getLibraryStatistics();
      printINFO('Library stats: $stats');
      
    } on LibraryException catch (e) {
      // Handle library-specific errors
      printERROR('Library operation failed: ${e.message}');
      switch (e.code) {
        case 'ADD_FAILED':
          // Show add error to user
          break;
        case 'PLAYLIST_NOT_FOUND':
          // Show playlist not found error
          break;
        default:
          // Show generic library error
      }
    }
  }

  /// Example 3: Using CacheRepository for performance
  /// 
  /// This shows how to implement smart caching for better performance
  static Future<void> _cacheManagementExample() async {
    try {
      final cacheRepository = Get.find<CacheRepository>();
      
      // Check if audio is cached before downloading
      final songId = 'cached_song_123';
      final isAudioCached = await cacheRepository.isAudioCached(songId);
      
      if (isAudioCached) {
        // Get cached audio
        final audioData = await cacheRepository.getCachedAudio(songId);
        printINFO('Using cached audio (${audioData?.length} bytes)');
      } else {
        // Download and cache audio
        printINFO('Audio not cached, downloading...');
        // final audioData = await downloadAudio(songId);
        // await cacheRepository.cacheAudio(song, audioData);
      }
      
      // Cache search results for offline access
      await cacheRepository.cacheMetadata(
        'search_vietnamese_pop',
        {'query': 'vietnamese pop', 'results': []},
        CacheType.searchResults,
        expirationDuration: const Duration(hours: 1),
      );
      
      // Get cache statistics
      final stats = await cacheRepository.getCacheStatistics();
      final sizeMB = (stats.totalSizeBytes / 1024 / 1024).toStringAsFixed(1);
      printINFO('Cache stats: ${stats.totalEntries} entries, ${sizeMB} MB');
      
      // Clean up expired cache
      final removedCount = await cacheRepository.clearExpiredCache();
      printINFO('Removed $removedCount expired cache entries');
      
    } on CacheException catch (e) {
      // Handle cache-specific errors
      printERROR('Cache operation failed: ${e.message}');
      // Cache errors are usually non-critical, continue operation
    }
  }

  /// Example 4: Controller implementation with repositories
  /// 
  /// This shows how to properly use repositories in a GetX controller
  static void _controllerExampleWithRepositories() {
    // See ModernHomeController class below for example implementation
    printINFO('See ModernHomeController class for repository usage example');
  }

  /// Example 5: Testing with mock repositories
  /// 
  /// This shows how clean architecture enables easy testing  
  static void _testingExample() {
    // See MockMusicRepository class below for example implementation
    printINFO('See MockMusicRepository class for testing example');
  }

  /// Example 6: Repository configuration and optimization
  /// 
  /// This shows how to configure repositories for optimal performance
  static Future<void> _repositoryOptimizationExample() async {
    final cacheRepository = Get.find<CacheRepository>();
    
    // Configure cache settings for optimal performance
    await cacheRepository.setCacheConfiguration(
      maxAudioCacheSize: 200 * 1024 * 1024, // 200MB for audio
      maxImageCacheSize: 100 * 1024 * 1024, // 100MB for images
      defaultExpirationDuration: const Duration(hours: 6),
    );
    
    // Preload frequently accessed songs
    final favoritesSongs = await Get.find<LibraryRepository>().getLibrarySongs();
    await cacheRepository.preloadSongs(favoritesSongs.take(10).toList(), priority: 8);
    
    // Optimize cache periodically
    await cacheRepository.optimizeCache(
      maxSizeBytes: 300 * 1024 * 1024, // 300MB total
      maxEntries: 1000,
    );
    
    printINFO('Repository optimization completed');
  }
}

/// Example controller implementation with repositories
/// 
/// This shows how to properly use repositories in a GetX controller
class ModernHomeController extends GetxController {
  // Repository dependencies
  final MusicRepository _musicRepository = Get.find<MusicRepository>();
  final LibraryRepository _libraryRepository = Get.find<LibraryRepository>();
  final CacheRepository _cacheRepository = Get.find<CacheRepository>();
  
  // Reactive variables
  final isLoading = false.obs;
  final homeContent = <dynamic>[].obs;
  final errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadHomeContent();
  }
  
  /// Load home content with smart caching
  Future<void> loadHomeContent() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Try to get cached home content first
      final cachedContent = await _cacheRepository.getCachedMetadata(
        'home_content',
        CacheType.metadata,
      );
      
      if (cachedContent != null) {
        homeContent.value = cachedContent['data'] ?? [];
        printINFO('Using cached home content');
      }
      
      // Fetch fresh content in background
      final freshContent = await _musicRepository.getHomeContent(limit: 6);
      homeContent.value = freshContent;
      
      // Cache the fresh content
      await _cacheRepository.cacheMetadata(
        'home_content',
        {'data': freshContent},
        CacheType.metadata,
        expirationDuration: const Duration(minutes: 30),
      );
      
    } on MusicException catch (e) {
      errorMessage.value = e.message;
      printERROR('Failed to load home content: ${e.message}');
    } catch (e) {
      errorMessage.value = 'Unknown error occurred';
      printERROR('Unexpected error: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Add song to favorites with proper error handling
  Future<bool> addToFavorites(MediaItem song) async {
    try {
      await _libraryRepository.addSongToLibrary(song);
      printINFO('Song added to favorites: ${song.title}');
      return true;
    } on LibraryException catch (e) {
      printERROR('Failed to add to favorites: ${e.message}');
      errorMessage.value = 'Failed to add song to favorites';
      return false;
    }
  }
  
  /// Search with caching and error handling
  Future<List<MediaItem>> searchSongs(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      isLoading.value = true;
      
      // Check for cached search results
      final cacheKey = 'search_${query.toLowerCase()}';
      final cachedResults = await _cacheRepository.getCachedMetadata(
        cacheKey,
        CacheType.searchResults,
      );
      
      if (cachedResults != null) {
        printINFO('Using cached search results for: $query');
        return (cachedResults['songs'] as List<dynamic>)
            .map((data) => MediaItemBuilder.fromJson(data))
            .toList();
      }
      
      // Perform fresh search
      final songs = await _musicRepository.searchSongs(query, limit: 50);
      
      // Cache search results
      await _cacheRepository.cacheMetadata(
        cacheKey,
        {'songs': songs.map((s) => MediaItemBuilder.toJson(s)).toList()},
        CacheType.searchResults,
        expirationDuration: const Duration(minutes: 15),
      );
      
      return songs;
      
    } on MusicException catch (e) {
      errorMessage.value = 'Search failed: ${e.message}';
      return [];
    } finally {
      isLoading.value = false;
    }
  }
}

/// Mock repository for testing
/// 
/// This shows how clean architecture enables easy testing
class MockMusicRepository implements MusicRepository {
  @override
  Future<List<MediaItem>> searchSongs(String query, {String? filter, int limit = 30}) async {
    // Return mock data for testing
    return [
      MediaItem(id: '1', title: 'Test Song 1', artist: 'Test Artist'),
      MediaItem(id: '2', title: 'Test Song 2', artist: 'Test Artist'),
    ];
  }
  
  @override
  Future<Album> getAlbum(String albumId) async {
    return Album(
      title: 'Test Album',
      browseId: albumId,
      artists: [{'name': 'Test Artist'}],
      thumbnailUrl: 'test.jpg',
    );
  }
  
  // Implement other required methods...
  @override
  Future<dynamic> getHomeContent({int limit = 4}) async => [];
  
  @override
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"}) async => [];

  @override
  Future<Map<String, dynamic>> getWatchPlaylist({
    String videoId = "",
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
    String? additionalParamsNext,
    bool onlyRelated = false,
  }) async => {};

  @override
  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs({
    String? playlistId,
    String? albumId,
    int limit = 3000,
    bool related = false,
    int suggestionsLimit = 0,
  }) async => {};

  @override
  Future<List<String>> getSearchSuggestion(String queryStr) async => [];

  @override
  Future<dynamic> getLyrics(String browseId) async => {};

  @override
  Future<dynamic> getContentRelatedToSong(String videoId, String hlCode) async => {};

  @override
  Future<String> getAlbumBrowseId(String audioPlaylistId) async => '';

  @override
  Future<String?> getSongYear(String songId) async => null;

  @override
  Future<List> getSongWithId(String songId) async => [];

  @override
  Future<Artist> getArtist(String artistId) async {
    return Artist(
      name: 'Test Artist',
      browseId: artistId,
      thumbnailUrl: 'test.jpg',
    );
  }
}

/// Integration example showing how repositories work together
/// 
/// This demonstrates a complete music discovery and library workflow
class MusicDiscoveryWorkflow {
  final MusicRepository _musicRepository = Get.find<MusicRepository>();
  final LibraryRepository _libraryRepository = Get.find<LibraryRepository>();
  final CacheRepository _cacheRepository = Get.find<CacheRepository>();
  
  /// Complete workflow: search -> preview -> add to library -> cache
  Future<void> discoverAndSaveMusic(String artistName) async {
    try {
      printINFO('🎵 Starting music discovery for: $artistName');
      
      // 1. Search for artist and songs
      final songs = await _musicRepository.searchSongs(
        artistName,
        filter: 'songs',
        limit: 20,
      );
      printINFO('Found ${songs.length} songs');
      
      // 2. Get artist information
      // final artist = await _musicRepository.getArtist(artistId);
      
      // 3. Let user preview and select favorites
      final favoriteSongs = songs.take(5).toList(); // Simulate user selection
      
      // 4. Add selected songs to library
      for (final song in favoriteSongs) {
        await _libraryRepository.addSongToLibrary(song);
        printINFO('Added to library: ${song.title}');
      }
      
      // 5. Cache songs for offline access
      await _cacheRepository.preloadSongs(favoriteSongs, priority: 7);
      
      // 6. Get updated library statistics
      final stats = await _libraryRepository.getLibraryStatistics();
      printINFO('🎵 Discovery complete! Library now has ${stats['songs']} songs');
      
    } catch (e) {
      printERROR('Music discovery failed: $e');
      rethrow;
    }
  }
}