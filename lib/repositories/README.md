# Repository Pattern Implementation

This directory contains the Repository Pattern implementation for the Harmony Music app. The repository pattern provides a clean separation between business logic and data access, improving testability and maintainability.

## Architecture Overview

```
Controllers → Repository Interfaces → Concrete Implementations → Data Sources (API, Cache, Hive)
```

## Directory Structure

```
repositories/
├── interfaces/           # Abstract repository contracts
│   ├── music_repository.dart
│   ├── library_repository.dart
│   ├── cache_repository.dart
│   └── user_repository.dart
├── implementations/      # Concrete repository implementations
│   ├── youtube_music_repository.dart
│   ├── hive_library_repository.dart
│   ├── hive_cache_repository.dart
│   └── hive_user_repository.dart
├── exceptions/          # Repository-specific exceptions
│   └── repository_exception.dart
└── repository_module.dart   # Dependency injection setup
```

## Repository Interfaces

### MusicRepository
Handles music streaming operations:
- Search songs and artists
- Get album/artist details
- Retrieve home screen content
- Fetch charts and trending music
- Get lyrics and related content

### LibraryRepository
Manages user's local music library:
- Add/remove songs from library
- Create and manage playlists
- Track play counts and history
- Export/import library data

### CacheRepository
Handles caching operations:
- Cache song audio data
- Store metadata and search results
- Manage cache expiration and optimization
- Cache home screen and API responses

### UserRepository
Manages user preferences and settings:
- Theme and audio quality settings
- Equalizer and notification preferences
- Playback history and statistics
- Privacy settings

## Implementation Details

### YouTubeMusicRepository
- Integrates with YouTube Music API through APIService
- Implements intelligent caching via CacheRepository
- Provides fallback error handling with custom exceptions
- Supports pagination and filtering

### HiveLibraryRepository
- Uses Hive for local storage
- Manages separate boxes for songs, playlists, and statistics
- Implements efficient search and sorting
- Provides data export/import functionality

### HiveCacheRepository
- Implements LRU cache eviction policy
- Supports different expiration times for different data types
- Provides cache size management and optimization
- Handles cache corruption gracefully

### HiveUserRepository
- Stores user preferences in Hive boxes
- Provides type-safe preference access
- Manages playback history with size limits
- Tracks user statistics and usage patterns

## Dependency Injection

The `RepositoryModule` class handles dependency injection setup:

```dart
// Initialize all repositories
await RepositoryModule.init();

// Access repositories in controllers
final musicRepo = Get.find<MusicRepository>();
final libraryRepo = Get.find<LibraryRepository>();
```

## Error Handling

Custom exception hierarchy provides specific error types:
- `MusicException`: Music streaming errors
- `LibraryException`: Library management errors
- `CacheException`: Caching operation errors
- `UserException`: User preference errors

## Testing

Comprehensive unit tests with 90%+ coverage:
- Mock dependencies using Mockito
- Test caching behavior and fallbacks
- Verify error handling scenarios
- Test edge cases and boundary conditions

## Usage in Controllers

Controllers can use repositories with graceful fallbacks:

```dart
class HomeScreenController extends GetxController {
  MusicRepository? _musicRepository;

  @override
  onInit() {
    super.onInit();
    try {
      _musicRepository = Get.find<MusicRepository>();
    } catch (e) {
      // Fallback to direct service calls
    }
  }

  Future<void> loadContent() async {
    final content = _musicRepository != null
        ? await _musicRepository!.getHomeContent()
        : await _musicServices.getHome();
    // Process content...
  }
}
```

## Benefits

1. **Separation of Concerns**: Clear separation between business logic and data access
2. **Testability**: Easy to mock repositories for unit testing
3. **Caching**: Intelligent caching reduces API calls and improves performance
4. **Error Handling**: Centralized error handling with specific exception types
5. **Maintainability**: Changes to data sources don't affect business logic
6. **Flexibility**: Easy to switch between different data sources
7. **Performance**: Built-in caching and optimization strategies

## Migration Strategy

The implementation provides backward compatibility:
- Controllers can gradually migrate to use repositories
- Fallback to direct service calls when repositories are unavailable
- No breaking changes to existing UI functionality
- Graceful degradation if repository initialization fails

## Future Enhancements

- Add offline-first capabilities
- Implement data synchronization
- Add more sophisticated caching strategies
- Support for multiple music providers
- Real-time data updates via streams