# Project Metadata Audit - Harmony Music

## 📱 Project Overview
- **Project Name**: Harmony Music (harmonymusic)
- **Type**: Cross-platform Flutter music streaming application
- **Current Version**: 1.12.0+25
- **License**: GNU General Public License Version 3.0

## 📋 pubspec.yaml Key Information

### Basic Details
- **Name**: harmonymusic
- **Description**: A cross platform app for music streaming.
- **Version**: 1.12.0+25
- **Publish Status**: Not published to pub.dev (`publish_to: "none"`)

### SDK Requirements
- **Dart SDK**: >=3.1.5 <4.0.0
- **Flutter**: Uses stable channel

### Key Dependencies
**Audio/Media:**
- audio_service: ^0.18.17
- just_audio: ^0.10.4
- just_audio_media_kit: ^2.1.0
- media_kit_libs_android_audio: any
- media_kit_libs_ios_audio: any
- audio_video_progress_bar: ^2.0.3
- flutter_lyric: ^2.0.4+6

**Custom Dependencies:**
- audio_metadata_reader (Git: https://github.com/LongDinhh/audio_metadata_reader.git)
- youtube_explode_dart (Git: https://github.com/LongDinhh/youtube_explode_dart.git)
- sidebar_with_animation (Git: https://github.com/anandnet/animated_side_bar.git)

**UI/UX:**
- flutter_keyboard_visibility: ^6.0.0
- flutter_slidable: ^4.0.0
- get: ^4.7.1
- google_fonts: ^6.1.0
- ionicons: ^0.2.2
- shimmer: ^3.0.0
- toggle_switch: ^2.1.0
- buttons_tabbar: ^1.3.13
- animations: ^2.0.11

**Storage/Data:**
- hive: ^2.2.3
- hive_flutter: ^1.1.0
- cached_network_image: ^3.4.0

**Other:**
- dio: ^5.7.0
- permission_handler: ^12.0.1
- path_provider: ^2.1.1
- webview_flutter: ^4.10.0
- share_plus: ^11.0.0

## 🚀 Fastlane Store Metadata

### App Title
**Harmony Music**

### Short Description
**An Android App for streaming Music**

### Full Description Features List
- Ability to play song from Ytube/Ytube Music.
- Song cache while playing
- Radio feature support
- Background music
- Playlist creation & bookmark support
- Artist & Album bookmark support
- Import song,Playlist,Album,Artist via sharing from Ytube/Ytube Music.
- Streaming quality control
- Song downloading support
- Language support
- Skip silence
- Dynamic Theme
- Flexibility to switch between Bottom & Side Nav bar
- Equalizer support
- Synced & Plain Lyrics support
- Sleep Timer
- Android Auto support
- No Advertisment
- No Login required
- Piped playlist integration

## 📜 License Information
- **License Type**: GNU General Public License Version 3, 29 June 2007
- **Copyright**: Free Software Foundation, Inc. <https://fsf.org/>
- **Key Points**: 
  - Free, copyleft license for software
  - Users have freedom to distribute copies of free software
  - Modified versions must be marked as changed
  - No warranty provided

## 🔧 GitHub Workflow Files (CI/CD)

### Code Quality Workflow (.github/workflows/code_quality.yml)
- **Trigger**: Manual dispatch, Pull requests to main branch
- **Runner**: ubuntu-latest
- **Flutter Version**: 3.24.2 (stable channel)
- **Java Version**: JDK 17 (Temurin distribution)
- **Actions**: 
  - Flutter analyze (linting)
  - Build APK
  - Upload APK artifact
- **Supported Build Target**: Android APK

### Windows EXE Build Workflow (.github/workflows/win_exe.yml)
- **Trigger**: Manual dispatch only
- **Runner**: windows-latest
- **Flutter Version**: 3.24.2 (stable channel)
- **Features**:
  - Localization data update
  - Windows executable packaging
  - Code signing with certificates
  - Signature verification
- **Supported Build Target**: Windows EXE

### Supported Platforms (from workflows)
- ✅ Android (APK build)
- ✅ Windows (EXE build with signing)

## 📸 Screenshots and Assets

### App Screenshots Location
**fastlane/metadata/android/en-US/images/phoneScreenshots/**
- 1.jpg
- 2.jpg  
- 3.jpg
- 4.jpg

### App Icons and Assets
**Main Assets:**
- assets/icons/ (album.png, artist.png, icon.png, song.png)
- cover.png (main cover image)
- icon.png (main app icon)
- playlist_placeholder.png

**Platform Specific Icons:**
- Android: Multiple launcher icons in various densities (hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)
- iOS: Complete app icon set for iOS devices
- macOS: App icons for macOS builds  
- Web: Favicon and web icons (192px, 512px, maskable variants)

**Download/Distribution Assets:**
- don_github.png
- down_IzzyOnDroid.png  
- down_fdroid.png

## 🔍 Additional Metadata Files Found
- CHANGELOG.md (version history)
- TODO.md (planned features/tasks)
- CLAUDE.md (possibly AI assistant documentation)
- Multiple changelog files in fastlane/metadata/android/changelogs/ (versions 10-25)

## 📊 Platform Support Evidence
Based on project structure and dependencies:
- ✅ **Android**: Full support with fastlane metadata, launcher icons, workflow
- ✅ **iOS**: App icons and iOS-specific assets present
- ✅ **macOS**: App icons present, likely supported
- ✅ **Windows**: Dedicated build workflow with signing
- ✅ **Linux**: CMakeLists.txt files present
- ✅ **Web**: Web assets and favicon present

## 🎯 Key Project Characteristics
- **No Login Required**: Emphasized in feature list
- **No Advertisements**: Clean user experience
- **YouTube Integration**: Core functionality for streaming
- **Offline Capabilities**: Song caching and downloading
- **Multi-platform**: Comprehensive platform support
- **Open Source**: GPL-3.0 licensed
- **Active Development**: Recent version 1.12.0+25 with build workflows
