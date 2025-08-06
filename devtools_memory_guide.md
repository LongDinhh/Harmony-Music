# DevTools Memory Analysis Quick Reference

## 🚀 Quick Start

1. **Run the automated script**:
   ```bash
   ./memory_profile_script.sh
   ```

2. **Or start manually**:
   ```bash
   flutter run --debug --observatory-port=8080 --devtools-port=8081
   ```

3. **Open DevTools**:
   - Automatically opens in browser
   - Or visit: http://localhost:8081

## 🧠 Memory Tab Overview

### Key Sections
- **Memory Usage Chart**: Real-time memory consumption
- **Heap Snapshot**: Point-in-time memory state
- **Memory Events**: GC activity and allocations
- **Settings**: Analysis options

### Taking Heap Snapshots
1. Click **"Take Snapshot"** in Memory tab
2. Wait for snapshot to complete (~10-30 seconds)  
3. Explore object types and retention paths
4. Compare multiple snapshots using **"Diff"**

## 🎯 Testing Protocol for Harmony Music

### Phase 1: Baseline (5 minutes)
```
1. Launch app → Home screen
2. Wait for complete load
3. Force GC (click "GC" button)
4. Take snapshot: "baseline_home"
5. Note total memory usage
```

### Phase 2: Player Navigation (10 minutes)
```
1. Navigate to Player screen
2. Open/close player panel 5 times
3. Swipe between player states
4. Navigate Home → Player → Home (10 cycles)
5. Force GC
6. Take snapshot: "after_player_navigation"
```

### Phase 3: ScrollController Testing (10 minutes)
```
1. Return to Home screen
2. Scroll through all content sections
3. Trigger pull-to-refresh 5 times
4. Navigate to different tabs
5. Force GC
6. Take snapshot: "after_scrolling"
```

### Phase 4: Memory Stress Test (10 minutes)
```
1. Rapid navigation: Home ↔ Player (20 times)
2. Force multiple screen rotations (if mobile)
3. Background/foreground app 5 times
4. Force GC
5. Take snapshot: "stress_test_final"
```

## 🔍 What to Look For

### 🟢 Normal Patterns
- **Total Memory**: 25-45MB for the app
- **Dart Heap**: 15-25MB
- **Native Heap**: 10-20MB
- **Growth Pattern**: Sawtooth (up/down with GC)

### 🟡 Warning Signs
- **Memory Growth**: >5MB per navigation cycle
- **Retained Objects**: Controllers not being disposed
- **GC Frequency**: Very frequent collections
- **Platform Memory**: >70MB total

### 🔴 Memory Leaks Indicators
- **Retained Size**: Objects >1MB that should be disposed
- **Growing Collections**: Lists/Maps that never shrink
- **Dangling References**: Controllers referenced by disposed widgets
- **Native Leaks**: Platform memory continuously growing

## 🎯 Harmony Music Specific Objects to Monitor

### StreamSubscriptions
```dart
Search in snapshots for:
- "StreamSubscription"
- "_StreamSubscription"
- "_BroadcastSubscription"

Expected: 2-3 active subscriptions
Warning: >10 subscriptions
```

### AnimationControllers  
```dart
Search for:
- "AnimationController"
- "_AnimationController"

Expected: 1-2 active controllers
Warning: >5 controllers
```

### ScrollControllers
```dart
Search for:
- "ScrollController"
- "_ScrollController"
- "ScrollControllerManager"

Expected: Managed by ScrollControllerManager
Warning: Orphaned controllers without manager
```

### PanelControllers
```dart
Search for:
- "PanelController"
- "SlidingUpPanelState"

Expected: 2 panel controllers (player + queue)
Warning: >5 panel controllers
```

## 📊 Snapshot Analysis Steps

### 1. Compare Snapshots
```
1. Select two snapshots to compare
2. Click "Diff" button
3. Sort by "Size Delta" (descending)
4. Look for large positive deltas
```

### 2. Analyze Retained Objects
```
1. Click on objects with large retained size
2. View "Retaining Path" tab
3. Identify what's keeping object alive
4. Check if disposal should have happened
```

### 3. Check Controller Hierarchies
```
1. Search for "Controller" in snapshot
2. Expand controller instances
3. Verify proper parent-child relationships
4. Check disposal states
```

## 🛠️ Memory Optimization Actions

### If ScrollController Leaks Found:
```dart
// Check ScrollControllerManager status
Get.find<HomeScreenController>().getScrollControllerStatus()

// Force cleanup
Get.find<HomeScreenController>().cleanupIdleScrollControllers()
```

### If AnimationController Leaks Found:
```dart
// Verify dispose() calls in:
- PlayerController.dispose()
- PlaylistScreenController.onClose() 
- AnimatedPlayButton.dispose()
```

### If StreamSubscription Leaks Found:
```dart
// Check cancellation in:
- PlayerController.dispose()
- AppLinksController.dispose()
```

## 📈 Benchmarking Results

### Target Performance Metrics
- **Cold Start Memory**: <30MB
- **Warm Navigation**: <45MB
- **Memory Growth/Navigation**: <2MB
- **GC Recovery**: >90% memory freed
- **Controller Retention**: <1MB after disposal

### Performance Thresholds
```
🟢 EXCELLENT: <35MB total, <1MB growth/cycle
🟡 GOOD:      35-50MB total, 1-3MB growth/cycle  
🟠 WARNING:   50-70MB total, 3-5MB growth/cycle
🔴 CRITICAL:  >70MB total, >5MB growth/cycle
```

## 🚨 Emergency Actions

### If Critical Memory Usage Detected:
1. **Immediate**: Force app restart
2. **Short-term**: Identify top retaining objects
3. **Medium-term**: Fix disposal in identified controllers
4. **Long-term**: Add automated memory tests to CI

### Memory Leak Mitigation:
```dart
// Force cleanup of all managed controllers
ScrollControllerManager.getInstance().disposeAll();

// Manual GC trigger (testing only)
import 'dart:io';
import 'dart:isolate';
Isolate.current.kill();
```

## 📝 Reporting Template

```markdown
### Memory Analysis Report
- **Date**: [DATE]
- **Baseline Memory**: [XX]MB
- **Peak Memory**: [XX]MB  
- **Memory Growth**: [XX]MB over [XX] cycles
- **Leaks Detected**: [YES/NO]
- **Action Required**: [YES/NO]

#### Objects of Concern:
- [ ] Retained Controllers: [COUNT]
- [ ] Orphaned Subscriptions: [COUNT]  
- [ ] Large Objects (>1MB): [LIST]

#### Recommendations:
- [ ] Monitor [SPECIFIC OBJECTS]
- [ ] Fix disposal in [SPECIFIC CONTROLLERS]
- [ ] Add tests for [SPECIFIC SCENARIOS]
```

---

*Use this guide alongside `dispose_issues.md` and the automated `memory_profile_script.sh` for comprehensive memory analysis.*
