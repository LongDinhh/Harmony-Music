# API Service Migration to dart_ytmusic_api

## Overview

This document describes the migration from the custom YouTube Music API implementation to the official [dart_ytmusic_api package](https://github.com/MusilyApp/dart_ytmusic_api).

## Changes Made

### 1. Package Dependencies

**Added:**
- `dart_ytmusic_api: ^1.2.1` - Official YouTube Music API package for Dart

**Removed:**
- Custom API implementation with complex network handling, cookie management, and response parsing

### 2. New Architecture

The new implementation uses an adapter pattern to maintain compatibility with existing code:

```
APIService (Interface remains same)
    ↓
DartYTMusicAdapterService (New adapter)
    ↓
dart_ytmusic_api package (YTMusic class)
```

### 3. Files Modified

#### `pubspec.yaml`
- Added `dart_ytmusic_api: ^1.2.1`

#### `lib/services/dart_ytmusic_adapter_service.dart` (New)
- Implements `IAPIService` interface using `dart_ytmusic_api` package
- Handles transformation between the package's API and our existing interface
- Provides all required methods: search, playlists, albums, artists, lyrics, etc.

#### `lib/services/api_service.dart` (Simplified)
- Removed 900+ lines of custom YouTube Music API implementation
- Now delegates all calls to `DartYTMusicAdapterService`
- Maintains the same public interface for backward compatibility

#### `lib/services/service_registry.dart`
- Updated to initialize `DartYTMusicAdapterService`
- Ensures proper dependency injection order

### 4. API Methods Supported

The dart_ytmusic_api package provides comprehensive YouTube Music functionality:

**Search:**
- `getSearchSuggestions(query)` - Get search suggestions
- `search(query)` - General search
- `searchSongs(query)` - Search for songs
- `searchVideos(query)` - Search for videos  
- `searchArtists(query)` - Search for artists
- `searchAlbums(query)` - Search for albums
- `searchPlaylists(query)` - Search for playlists

**Content Retrieval:**
- `getSong(videoId)` - Get song details
- `getVideo(videoId)` - Get video details
- `getLyrics(videoId)` - Get song lyrics
- `getTimedLyrics(videoId)` - Get synchronized lyrics
- `getArtist(artistId)` - Get artist information
- `getAlbum(albumId)` - Get album details
- `getPlaylist(playlistId)` - Get playlist information

**Artist Content:**
- `getArtistSongs(artistId)` - Get artist's songs
- `getArtistAlbums(artistId)` - Get artist's albums
- `getArtistSingles(artistId)` - Get artist's singles

**Home & Discovery:**
- `getHomeSections()` - Get YouTube Music home sections

### 5. Benefits of Migration

1. **Reliability:** Uses tested and maintained package instead of custom implementation
2. **Reduced Complexity:** Eliminates 900+ lines of complex YouTube API handling code
3. **Better Maintenance:** Package is actively maintained by the community
4. **Feature Completeness:** Access to all YouTube Music API features
5. **Type Safety:** Better TypeScript-like annotations and error handling

### 6. Breaking Changes

**None for existing code!** The migration maintains full backward compatibility through the adapter pattern.

### 7. Configuration

The package can be configured with optional parameters:

```dart
await ytMusic.initialize(
  cookies: '', // Optional: For authenticated requests
  gl: 'VN',    // Optional: Geolocation (country code)
  hl: 'vi',    // Optional: Language code
);
```

### 8. Error Handling

The adapter service includes comprehensive error handling that wraps package exceptions and maintains the existing error handling patterns using `AppErrorHandler`.

### 9. Future Improvements

With the new package, we can easily add:
- Authenticated user operations (with proper cookies)
- Better lyric synchronization with `getTimedLyrics()`
- Enhanced search filtering
- More efficient pagination

## Migration Checklist

- [x] Add dart_ytmusic_api package dependency
- [x] Create DartYTMusicAdapterService
- [x] Update APIService to use adapter
- [x] Update ServiceRegistry for proper initialization
- [x] Maintain backward compatibility
- [x] Comprehensive error handling
- [ ] Test all functionality
- [ ] Performance optimization
- [ ] Add optional authentication support

## Testing

After migration, test these key functionalities:
1. Home page loading (`getHomeData`)
2. Search functionality (`search`)
3. Playlist loading (`getPlaylistOrAlbumSongs`)
4. Artist information (`getArtist`)
5. Song details and lyrics (`getSong`, `getLyrics`)

## References

- [dart_ytmusic_api GitHub Repository](https://github.com/MusilyApp/dart_ytmusic_api)
- [Package Documentation](https://pub.dev/packages/dart_ytmusic_api)
- [Original Python ytmusicapi](https://ytmusicapi.readthedocs.io/) (inspiration for the Dart package)