# Business Logic Leakage Audit Report

## Summary
This report identifies widgets that violate the separation of concerns principle by importing services directly or containing business logic that should be extracted into controllers or service layers.

## Critical Violations

### 1. HomeScreen Body Widget (`lib/ui/screens/Home/home_screen.dart`)
**Issues:**
- Complex business logic in widget for calculating padding and layout
- Direct access to multiple controllers without proper separation
- Manual padding calculations based on player state

**Lines 144-288:** The `Body` widget contains complex conditional logic and calculations that should be in a controller:
```dart
// Business logic mixed in widget
final hasActiveSong = playerController.currentSong.value != null;
final bottomPadding = 200.0 + miniPlayerHeight + navBarHeight;
```

**Recommendation:**
- Extract layout logic into `HomeScreenController`
- Create dedicated layout calculation methods
- Move UI state management to controller

### 2. AlbumScreen Widget (`lib/ui/screens/Album/album_screen.dart`)
**Issues:**
- Direct import of `services/downloader.dart` (Line 11)
- Business logic mixed with UI rendering
- Complex player control logic in widget

**Lines 225-417:** Button action handlers contain extensive business logic:
```dart
// Business logic in widget
albumController.addNremoveFromLibrary(albumController.album.value, add: add)
playerController.playPlayListSong(...)
controller.downloadPlaylist(...)
```

**Recommendation:**
- Move all player actions to `AlbumScreenController`
- Extract button logic into controller methods
- Remove direct service imports from widget

### 3. AddToPlaylist Widget (`lib/ui/widgets/add_to_playlist.dart`)
**Issues:**
- Direct Hive database operations in controller (Lines 179-201, 210-231)
- Direct import of `services/piped_service.dart` (Line 7)
- Business logic in widget controller instead of service layer

**Critical Lines:**
```dart
// Direct Hive access in controller
final plstsBox = await Hive.openBox("LibraryPlaylists");
await plstBox.add(MediaItemBuilder.toJson(element));
```

**Recommendation:**
- Create dedicated `PlaylistService` for playlist operations
- Move all database operations to service layer
- Controller should only handle UI state, not data persistence

### 4. CreatePlaylistDialog Widget (`lib/ui/widgets/create_playlist_dialog.dart`)
**Issues:**
- Direct dependency on `LibraryPlaylistsController`
- Business logic in onTap handlers (Lines 130-167)
- Service layer calls mixed with UI logic

**Recommendation:**
- Extract playlist creation logic to service
- Use proper error handling patterns
- Separate UI logic from business operations

### 5. SongInfoBottomSheet (`lib/ui/widgets/songinfo_bottom_sheet.dart`)
**Issues:**
- Multiple service imports (Lines 8, 12)
- Direct Hive operations in widget
- Complex business logic in UI event handlers

**Critical violations:**
```dart
// Business logic in widget
Hive.box("SongDownloads").containsKey(song!.id)
playerController.enqueueSong(song)
```

**Recommendation:**
- Create `SongActionService` for all song operations
- Remove direct database access from widgets
- Implement proper service layer abstraction

### 6. SongListTile Widget (`lib/ui/widgets/song_list_tile.dart`)
**Issues:**
- Complex business logic in slidable actions (Lines 61-110)
- Direct player controller method calls in widget
- Service layer operations mixed with UI

**Recommendation:**
- Extract all song actions to service layer
- Create dedicated `SongActionController`
- Simplify widget to only handle UI events

### 7. BackupDialog & RestoreDialog (`lib/ui/widgets/backup_dialog.dart`, `lib/ui/widgets/restore_dialog.dart`)
**Issues:**
- Complex file operations in widget controllers
- Direct service imports and database access
- Heavy business logic in UI layer

**Critical Issues:**
```dart
// File operations in widget controller
filesToExport.addAll(await processDirectoryInIsolate(dbDir));
await outputFile.writeAsBytes(data);
```

**Recommendation:**
- Create dedicated `BackupService` and `RestoreService`
- Move all file operations to service layer
- Controllers should only manage UI state

### 8. SongDownloadButton (`lib/ui/widgets/song_download_btn.dart`)
**Issues:**
- Direct Hive access in widget (Lines 37, 74-84)
- Business logic mixed with UI rendering
- Service operations in widget event handlers

**Recommendation:**
- Create `DownloadService` abstraction
- Remove direct database access
- Separate download logic from UI logic

### 9. ImageWidget (`lib/ui/widgets/image_widget.dart`)
**Issues:**
- Direct dependency on `SettingsScreenController` (Lines 67, 75)
- File system operations in widget
- Service-level logic in UI component

**Recommendation:**
- Create `ImageCacheService` for file operations
- Remove direct controller dependencies
- Use dependency injection pattern

## Moderate Violations

### 10. Settings Screen (`lib/ui/screens/Settings/settings_screen.dart`)
**Issues:**
- Direct service method calls in UI handlers
- Business logic in widget event handlers

### 11. Various Widget Controllers
Many widgets have controllers that perform service-level operations instead of delegating to proper services.

## Architecture Recommendations

### 1. Create Service Layer
```dart
// Example service structure
abstract class PlaylistService {
  Future<bool> createPlaylist(String name, {bool isLocal = true});
  Future<bool> addSongToPlaylist(String playlistId, MediaItem song);
  Future<List<Playlist>> getAllPlaylists({bool includePiped = false});
}

abstract class SongActionService {
  Future<void> enqueueSong(MediaItem song);
  Future<void> playNext(MediaItem song);
  Future<void> addToFavorites(MediaItem song);
}
```

### 2. Implement GetX Service Pattern
```dart
class PlaylistServiceImpl extends GetxService implements PlaylistService {
  // Service implementation with proper error handling
}
```

### 3. Update Controllers
Controllers should only:
- Manage UI state (loading, error states)
- Handle user interactions
- Delegate business operations to services
- Update reactive variables

### 4. Widget Refactoring
Widgets should only:
- Render UI based on controller state
- Handle user input events
- Pass data to controllers
- No direct service or database access

## Priority Actions

1. **High Priority**: Extract all Hive database operations to dedicated services
2. **High Priority**: Remove direct service imports from widgets
3. **Medium Priority**: Create service abstractions for player operations
4. **Medium Priority**: Refactor dialog widgets to use service layer
5. **Low Priority**: Optimize controller responsibilities

## Files Requiring Immediate Attention

1. `lib/ui/widgets/add_to_playlist.dart` - Critical database access violations
2. `lib/ui/widgets/songinfo_bottom_sheet.dart` - Multiple service dependencies
3. `lib/ui/screens/Album/album_screen.dart` - Service imports and complex logic
4. `lib/ui/widgets/backup_dialog.dart` - Heavy file operations in widget
5. `lib/ui/widgets/song_list_tile.dart` - Business logic in UI handlers

## Conclusion

The current codebase has significant business logic leakage with 20+ widgets violating separation of concerns. The main issues are:

- Direct database (Hive) access in widgets and controllers
- Service imports in UI layer
- Complex business logic in event handlers
- Missing service layer abstractions

Implementing proper service layer architecture and refactoring the identified components will significantly improve code maintainability, testability, and adherence to Flutter/GetX best practices.
