# Performance Refactor Checklist

## Overview
This document identifies UI elements that currently rebuild unnecessarily because they live inside large Obx widgets. Each item should be extracted into smaller, more granular reactive widgets.

## Target Files Analysis

### 1. lib/ui/player/components/gesture_player.dart

| Line Range | Current Pattern | Variables Listened To | Ideal Widget | Priority |
|------------|----------------|---------------------|--------------|----------|
| 95-116 | `Obx(() => Marquee(...))` - Song title | `currentSong.value` | `_SongTitleMarquee extends StatelessWidget` | HIGH |
| 120-143 | `GetX<PlayerController>(builder: (controller) => Marquee(...))` - Artist | `currentSong.value` | `_ArtistMarquee extends StatelessWidget` | HIGH |
| 158-167 | `Obx(() => Icon(...))` - Favorite button | `isCurrentSongFav` | `_FavoriteButton extends StatelessWidget` | MEDIUM |
| 172-194 | `Obx(() => IconButton(...))` - Loop mode | `isLoopModeEnabled.value` | `_LoopModeButton extends StatelessWidget` | MEDIUM |
| 202-217 | `Obx(() => Icon(...))` - Shuffle button | `isShuffleModeEnabled.value` | `_ShuffleModeButton extends StatelessWidget` | MEDIUM |
| 229-251 | `GetX<PlayerController>(builder: (controller) => ProgressBar(...))` - Progress bar | `progressBarStatus.value` | `_PlayerProgressBar extends StatelessWidget` | HIGH |
| 282-293 | `Obx(() => FadeTransition(...))` - Gesture icon | `gesturePlayerVisibleState.value`, `gesturePlayerStateAnimation` | Already optimized ✓ | LOW |

### 2. lib/ui/player/components/mini_player_content.dart

| Line Range | Current Pattern | Variables Listened To | Ideal Widget | Priority |
|------------|----------------|---------------------|--------------|----------|
| 29-249 | **MASSIVE Obx** wrapping entire content | `HomeScreenController.currentRoute`, `playerPanelMinHeight` | Split into multiple widgets | CRITICAL |
| 50-68 | `GetX<PlayerController>` - Progress bar (mobile) | `progressBarStatus.value` | `_MobileProgressBar extends StatelessWidget` | HIGH |
| 70-101 | `GetX<PlayerController>` - Progress bar (desktop) | `progressBarStatus.value` | `_DesktopProgressBar extends StatelessWidget` | HIGH |
| 193-212 | `GetX<PlayerController>` - Progress bar (bottom) | `progressBarStatus.value` | `_BottomProgressBar extends StatelessWidget` | HIGH |
| 213-244 | `GetX<PlayerController>` - Progress bar (desktop bottom) | `progressBarStatus.value` | `_DesktopBottomProgressBar extends StatelessWidget` | HIGH |
| 330-355 | `Obx(() => InkWell(...))` - Next button state | `currentQueue`, `isShuffleModeEnabled`, `isQueueLoopModeEnabled`, `currentSong` | `_NextButton extends StatelessWidget` | MEDIUM |
| 410-415 | `Obx(() => Icon(...))` - Favorite icon | `isCurrentSongFav` | Already optimized as `_FavoriteIcon` ✓ | LOW |
| 425-434 | `Obx(() => Icon(...))` - Shuffle icon | `isShuffleModeEnabled.value` | Already optimized as `_ShuffleIcon` ✓ | LOW |

### 3. lib/ui/player/components/mini_player.dart

| Line Range | Current Pattern | Variables Listened To | Ideal Widget | Priority |
|------------|----------------|---------------------|--------------|----------|
| 30-550 | **MASSIVE Obx** wrapping entire widget | `isPlayerpanelTopVisible`, `playerPaneOpacity`, `playerPanelMinHeight` | Split into multiple widgets | CRITICAL |
| 54-67 | `GetX<PlayerController>` - Mobile progress bar | `progressBarStatus.value` | `_MiniPlayerMobileProgress extends StatelessWidget` | HIGH |
| 68-98 | `GetX<PlayerController>` - Desktop progress bar | `progressBarStatus.value` | `_MiniPlayerDesktopProgress extends StatelessWidget` | HIGH |
| 203-213 | `Obx(() => Icon(...))` - Favorite button | `isCurrentSongFav` | `_FavoriteButton extends StatelessWidget` | MEDIUM |
| 221-235 | `Obx(() => Icon(...))` - Shuffle button | `isShuffleModeEnabled.value` | `_ShuffleButton extends StatelessWidget` | MEDIUM |
| 284-319 | `Obx(() => InkWell(...))` - Next button logic | `currentQueue`, `isShuffleModeEnabled`, `isQueueLoopModeEnabled`, `currentSong` | `_NextButton extends StatelessWidget` | MEDIUM |
| 389-434 | `Obx(() => Row(...))` - Volume control | `volume.value` | `_VolumeControl extends StatelessWidget` | HIGH |

### 4. lib/ui/player/player.dart

| Line Range | Current Pattern | Variables Listened To | Ideal Widget | Priority |
|------------|----------------|---------------------|--------------|----------|
| 29-204 | **MASSIVE Obx** wrapping SlidingUpPanel | `playerUi.value` | Split into smaller components | CRITICAL |
| 107-119 | `Obx(() => Text(...))` - Queue song count | `currentQueue.length` | `_QueueSongCounter extends StatelessWidget` | MEDIUM |
| 126-140 | `Obx(() => Container(...))` - Queue loop button | `isQueueLoopModeEnabled` | `_QueueLoopButton extends StatelessWidget` | MEDIUM |

## Implementation Strategy

### Phase 1: Critical Priority (Break up massive Obx widgets)
1. **mini_player_content.dart**: Extract the main Obx (lines 29-249) into separate widgets:
   - `_MiniPlayerVisibilityWrapper` (for visibility logic)
   - `_MiniPlayerProgressSection` (for progress bars)
   - `_MiniPlayerContentSection` (for main content)

2. **mini_player.dart**: Extract the main Obx (lines 30-550) into:
   - `_MiniPlayerWrapper` (for visibility/opacity)
   - `_MiniPlayerProgressBar` component
   - `_MiniPlayerControls` component

3. **player.dart**: Extract main Obx (lines 29-204) into:
   - `_PlayerBodyWrapper` component
   - `_QueuePanelSection` component

### Phase 2: High Priority (Progress bars and heavy components)
1. Create dedicated progress bar widgets for each context
2. Extract volume control and other complex UI elements
3. Optimize song title/artist display components

### Phase 3: Medium Priority (Individual controls)
1. Create individual button components (Favorite, Shuffle, Next, etc.)
2. Extract queue control buttons
3. Optimize remaining smaller Obx instances

### Phase 4: Low Priority (Already optimized or minor)
1. Review and test all optimized components
2. Performance validation
3. Clean up any remaining minor issues

## Expected Performance Improvements

- **Rebuild frequency**: Reduce from 500 rebuilds/min to ~50-100 rebuilds/min for critical components
- **Build time**: Reduce from 15-18ms to 3-5ms per component
- **Memory usage**: Lower memory pressure from fewer widget tree recreations
- **UI responsiveness**: Smoother animations and interactions

## Notes
- Priority levels: CRITICAL (must fix first), HIGH (significant impact), MEDIUM (noticeable improvement), LOW (minor optimization)
- ✓ indicates components already optimized in recent changes
- Focus on extracting the largest Obx widgets first as they have the most impact
- Each extracted widget should listen to only the specific variables it needs
