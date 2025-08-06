# Granular Reactive Player Widgets

This directory contains granular reactive widgets for the music player UI. Each widget wraps **one** reactive GetX getter with its own `Obx` and provides callbacks for reuse across different UI contexts.

## Architecture Benefits

- **Granular reactivity**: Each widget listens only to its specific reactive property
- **Optimized rebuilds**: Only the specific widget rebuilds when its data changes
- **Reusable**: All widgets expose onTap callbacks for custom behavior
- **Consistent**: All widgets follow Flutter best practices with const constructors and unique keys

## Available Widgets

### 1. SongTitleMarquee
Displays current song title with marquee scrolling effect.
```dart
// Basic usage
const SongTitleMarquee()

// With custom styling and tap handler
SongTitleMarquee(
  style: Theme.of(context).textTheme.headlineSmall,
  onTap: () => playerController.playerPanelController.open(),
)
```

### 2. ArtistMarquee
Displays current song artist with marquee scrolling effect.
```dart
// Basic usage
const ArtistMarquee()

// With custom styling
ArtistMarquee(
  style: TextStyle(color: Colors.grey),
  onTap: () => navigateToArtistPage(),
)
```

### 3. FavoriteIconBtn
Reactive favorite icon button that shows filled/outlined heart.
```dart
// Basic usage
const FavoriteIconBtn()

// With custom styling
FavoriteIconBtn(
  iconSize: 20,
  color: Colors.red,
  onTap: () => showFavoriteDialog(),
)
```

### 4. LoopModeIconBtn
Reactive loop mode toggle button with active/inactive states.
```dart
// Basic usage
const LoopModeIconBtn()

// With custom colors
LoopModeIconBtn(
  iconSize: 18,
  color: Colors.blue,
  inactiveColor: Colors.grey,
)
```

### 5. ShuffleIconBtn
Reactive shuffle mode toggle button with active/inactive states.
```dart
// Basic usage
const ShuffleIconBtn()

// With custom behavior
ShuffleIconBtn(
  onTap: () => showShuffleOptions(),
)
```

### 6. MiniPlayPauseBtn
Reactive play/pause button with loading, playing, and paused states.
```dart
// Basic usage
const MiniPlayPauseBtn()

// With background styling
MiniPlayPauseBtn(
  iconSize: 43,
  showBackground: true,
  backgroundColor: Theme.of(context).colorScheme.secondary,
  borderRadius: 10,
)
```

### 7. QueueLengthLabel
Displays the current queue length as reactive text.
```dart
// Basic usage
const QueueLengthLabel()

// With custom formatting
QueueLengthLabel(
  prefix: "Queue: ",
  suffix: " songs",
  style: Theme.of(context).textTheme.caption,
  onTap: () => openQueueScreen(),
)
```

## Usage in Existing Code

### Before (from mini_player_content.dart)
```dart
// Old approach with large Obx wrapping multiple properties
Obx(() {
  return Column(
    children: [
      Text(playerController.currentSong.value?.title ?? ""),
      Text(playerController.currentSong.value?.artist ?? ""),
      IconButton(
        onPressed: playerController.toggleFavourite,
        icon: Icon(playerController.isCurrentSongFav.value 
            ? Icons.favorite 
            : Icons.favorite_border),
      ),
      // ... more widgets
    ],
  );
})
```

### After (using granular widgets)
```dart
// New approach with granular reactivity
Column(
  children: [
    SongTitleMarquee(
      onTap: () => playerController.playerPanelController.open(),
    ),
    ArtistMarquee(),
    FavoriteIconBtn(),
    // Each widget has its own Obx and rebuilds independently
  ],
)
```

## Performance Benefits

1. **Reduced rebuilds**: Only the specific widget rebuilds when its data changes
2. **Better separation of concerns**: Each widget handles one reactive property
3. **Easier testing**: Each widget can be tested in isolation
4. **Improved code reuse**: Widgets can be used in mini-player, full player, queue, etc.

## Import

```dart
import 'package:harmonymusic/ui/player/widgets/widgets.dart';
```
