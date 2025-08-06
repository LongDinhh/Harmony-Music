# Flutter Performance Profiling Guide

## Step 1: Run Flutter in Profile Mode
```bash
# Clean and run in profile mode with widget creation tracking
flutter clean
flutter run --profile --track-widget-creation

# For more detailed profiling:
flutter run --profile --track-widget-creation --dart-define=dart.vm.profile=true
```

## Step 2: Navigate Through Key Screens
Perform these actions while profiling:
1. **Home Screen**: Scroll through music content, switch categories
2. **Player Screen**: 
   - Open/close mini player
   - Switch between standard/gesture player
   - Control playback (play/pause/skip)
3. **Settings Screen**: 
   - Open/close expansion tiles
   - Change dropdown values
   - Toggle switches

## Step 3: Capture Performance Data

### Using Flutter Inspector (Recommended)
1. Open Flutter Inspector in your IDE
2. Enable "Select Widget Mode" 
3. Navigate through screens while monitoring:
   - Widget rebuild count
   - Frame rendering times
   - Memory usage

### Using Dart VM Timeline
```bash
# Run with observatory enabled
flutter run --profile --enable-dart-profiling

# In another terminal, capture timeline:
curl -o timeline.json http://localhost:8181/_flutter/traceEvents?timeOriginMicros=0&timeExtentMicros=30000000
```

## Step 4: Generate Flame Chart Screenshots
1. Open Chrome DevTools (chrome://inspect)
2. Click "Open dedicated DevTools for Node"
3. Go to Performance tab
4. Load the timeline.json file
5. Take screenshots of:
   - Main thread activity
   - Widget build times
   - Frame drops/janky frames

## Key Metrics to Monitor
- **Widget Rebuilds**: Look for widgets rebuilding >200 times per minute
- **Build Times**: Identify widgets taking >5ms to build
- **Frame Drops**: Watch for frames taking >16ms (60fps) or >8ms (120fps)
- **Memory Usage**: Monitor for memory leaks during navigation

## Critical Areas to Profile
Based on the rebuild hotspots analysis:

### High Priority Files:
- `mini_player.dart` - Expected ~500 rebuilds/min
- `settings_screen.dart` - Multiple Obx widgets
- `player_control.dart` - Frequent progress updates
- `home_screen.dart` - Dynamic content loading

### Focus Points:
1. **Mini Player**: Progress bar updates every ~100ms
2. **Settings Dropdowns**: State changes trigger rebuilds
3. **Player Controls**: Frequent playback state updates
4. **Image Widgets**: Check for unnecessary reloads

## Expected Results
After profiling, you should have:
- Timeline trace files (.json)
- Flame chart screenshots (.png)
- Widget rebuild counts
- Frame timing analysis
- Memory usage patterns

## Analysis Tips
- Compare profile data before/after optimizations
- Look for patterns in rebuild cascades
- Identify unused rebuilds (widgets that rebuild but don't change visually)
- Check for expensive operations in build methods
