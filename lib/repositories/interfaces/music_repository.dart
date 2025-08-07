import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/playlist.dart';

/// Abstract repository interface for music streaming operations
abstract class MusicRepository {
  /// Search for songs with a given query
  Future<List<MediaItem>> searchSongs(String query, {int limit = 30});

  /// Search for songs with advanced filters
  Future<Map<String, dynamic>> searchWithFilter(
    String query, {
    String? filter,
    String? scope,
    int limit = 30,
    bool ignoreSpelling = false,
  });

  /// Get album details by album ID
  Future<Album> getAlbum(String albumId);

  /// Get artist details by artist/channel ID
  Future<Artist> getArtist(String artistId);

  /// Get home screen content (quick picks, playlists, albums)
  Future<Map<String, dynamic>> getHomeContent({int limit = 4});

  /// Get watch playlist for a specific video
  Future<Map<String, dynamic>> getWatchPlaylist({
    String videoId = "",
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
    String? additionalParamsNext,
    bool onlyRelated = false,
  });

  /// Get songs from a playlist or album
  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs({
    String? playlistId,
    String? albumId,
    int limit = 3000,
    bool related = false,
    int suggestionsLimit = 0,
  });

  /// Get search suggestions for autocomplete
  Future<List<String>> getSearchSuggestions(String query);

  /// Get charts/trending music
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode = "vi"});

  /// Get song details by song ID
  Future<List> getSongDetails(String songId);

  /// Get content related to a song
  Future<dynamic> getRelatedContent(String videoId, String hlCode);

  /// Get lyrics for a song
  Future<dynamic> getLyrics(String browseId);

  /// Get artist related content
  Future<Map<String, dynamic>> getArtistRelatedContent(
    Map<String, dynamic> browseEndpoint,
    String category, {
    String additionalParams = "",
  });

  /// Get search continuation for pagination
  Future<Map<String, dynamic>> getSearchContinuation(
    Map additionalParamsNext, {
    int limit = 10,
  });
}