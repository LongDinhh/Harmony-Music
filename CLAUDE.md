# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Harmony Music is a cross-platform music streaming app built with Flutter that supports Only Android, iOS. It streams music from YouTube/YouTube Music with features like offline downloads, playlists, equalizer, and background playback.

## Architecture

### Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: GetX (dependency injection + state management)
- **Audio**: just_audio, just_audio_media_kit (mobile)
- **Database**: Hive (offline storage)
- **UI Framework**: Material Design with custom theming

### Key Directories
- `lib/main.dart` - App entry point with initialization logic
- `lib/services/` - Core business logic (audio, music, downloads)
- `lib/ui/` - UI components and screens
- `lib/models/` - Data models (songs, albums, playlists)
- `lib/utils/` - Utility functions and helpers
- `localization/` - Multi-language support (40+ languages)

### Core Services
- **AudioHandler** (`services/audio_handler.dart`) - Background audio service
- **MusicService** (`services/music_service.dart`) - YouTube Music API integration
- **Downloader** (`services/downloader.dart`) - Download management
- **PipedService** (`services/piped_service.dart`) - Piped playlist integration

### State Management
- **PlayerController** (`ui/player/player_controller.dart`) - Audio playback state
- **ThemeController** (`ui/utils/theme_controller.dart`) - Dynamic theming
- **HomeScreenController** - Home screen data management
- **Library controllers** - User library management

## Development Commands

### Setup & Build
```bash
# Install dependencies
flutter pub get

# Run app (specify platform)
flutter run
flutter run -d android
flutter run -d ios

# Build release
flutter build apk --release
flutter build ios --release
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Format code
dart format .
```

### Platform-Specific Notes
- **Android**: Uses just_audio, supports Android Auto
- **iOS**: Uses just_audio, background audio configured in Info.plist

### Database Schema
Hive boxes used:
- `SongsCache` - Cached song metadata
- `SongDownloads` - Downloaded songs
- `SongsUrlCache` - Cached streaming URLs
- `AppPrefs` - User preferences
- `CookieStorage` - Authentication cookies

### Key Files to Know
- `lib/main.dart:25-35` - App initialization
- `lib/services/audio_handler.dart` - Background audio service
- `lib/ui/home.dart` - Main UI container
- `lib/ui/player/player.dart` - Music player UI