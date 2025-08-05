# Harmony Music

**A cross-platform music streaming application for YouTube and YouTube Music**

## Badges

[![GitHub Actions CI](https://img.shields.io/github/actions/workflow/status/longdinhh/Harmony-Music/code_quality.yml?branch=main&label=CI&logo=github)](https://github.com/longdinhh/Harmony-Music/actions/workflows/code_quality.yml)
[![Latest Release](https://img.shields.io/github/v/release/longdinhh/Harmony-Music?logo=github)](https://github.com/longdinhh/Harmony-Music/releases/latest)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![GitHub Stars](https://img.shields.io/github/stars/longdinhh/Harmony-Music?style=social)](https://github.com/longdinhh/Harmony-Music/stargazers)
[![GitHub Downloads](https://img.shields.io/github/downloads/longdinhh/Harmony-Music/total)](https://github.com/longdinhh/Harmony-Music/releases)
[![F-Droid](https://img.shields.io/f-droid/v/com.anandnet.harmonymusic.svg)](https://f-droid.org/packages/com.anandnet.harmonymusic/)

## Table of Contents

- [Detailed Description](#detailed-description)
- [Key Features](#key-features)
- [Screenshots](#screenshots)
- [Download & Installation](#download--installation)
- [Building From Source](#building-from-source)
- [Technical Specifications & Requirements](#technical-specifications--requirements)
- [Project Structure Overview](#project-structure-overview)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements & Credits](#acknowledgements--credits)
- [Support / Contact](#support--contact)

## Detailed Description

Harmony Music is a free, open-source music streaming application that provides
seamless access to YouTube and YouTube Music content without advertisements or
login requirements. Built with Flutter, it offers a beautiful, native experience
across Android and iOS platforms.

The app focuses on providing a clean, intuitive interface for music discovery
and playback, featuring advanced capabilities like song caching, playlist
management, equalizer controls, and synchronization with external services like
Piped. Whether you're discovering new music, creating playlists, or enjoying
your favorite tracks offline, Harmony Music delivers a premium music experience
while respecting your privacy.

## Key Features

- 🎵 **YouTube/YouTube Music Integration** - Stream music directly from YouTube
  without ads
- 💾 **Smart Caching** - Cache songs while playing for offline access
- 📻 **Radio Mode** - Discover new music with radio-style playback
- 🎧 **Background Playback** - Continue listening while using other apps
- 📱 **Cross-Platform** - Available on Android and iOS
- 📋 **Playlist Management** - Create, edit, and organize your music collections
- 🎨 **Artist & Album Bookmarks** - Save and organize your favorite artists and albums
- 📤 **Import from YouTube** - Share songs, playlists, albums, and artists
  directly from YouTube/YouTube Music
- ⚡ **Streaming Quality Control** - Choose your preferred audio quality
- 📥 **Song Downloads** - Download tracks for complete offline listening
- 🌍 **Multi-Language Support** - Available in multiple languages
- 🔇 **Skip Silence** - Automatically skip silent parts in tracks
- 🎨 **Dynamic Theming** - Beautiful themes that adapt to your music
- 🧭 **Flexible Navigation** - Switch between bottom and side navigation bars
- 🎛️ **Equalizer** - Fine-tune your audio experience
- 📝 **Lyrics Support** - Both synced and plain lyrics display
- ⏰ **Sleep Timer** - Set automatic playback stop
- 🚗 **Android Auto** - Full Android Auto integration for car use
- 🔐 **Privacy Focused** - No ads, no tracking, no login required
- 🔗 **Piped Integration** - Sync playlists with Piped instances

## Screenshots

![Home Screen](fastlane/metadata/android/en-US/images/phoneScreenshots/1.jpg)
*Home screen with music discovery and recommendations*

![Player Interface](fastlane/metadata/android/en-US/images/phoneScreenshots/2.jpg)
*Beautiful music player with album art and controls*

![Playlist Management](fastlane/metadata/android/en-US/images/phoneScreenshots/3.jpg)
*Create and manage your music playlists*

![Library & Search](fastlane/metadata/android/en-US/images/phoneScreenshots/4.jpg)
*Browse your library and search for new music*

## Download & Installation

### Android APK

[![APK Release](https://img.shields.io/badge/APK-Download-green?logo=android)](https://github.com/longdinhh/Harmony-Music/releases/latest)

1. Download the latest `app-release.apk` from [GitHub Releases](https://github.com/longdinhh/Harmony-Music/releases/latest)
2. Enable "Install from Unknown Sources" in Android Settings → Security
3. Open the downloaded APK file and tap "Install"
4. Grant necessary permissions when prompted

**System Requirements:** Android 5.0 (API level 21) or higher

### iOS App Store

*Coming soon - iOS version will be available through the App Store and TestFlight.*

### Alternative App Stores

*Note: F-Droid and IzzyOnDroid distribution badges would appear here when the
corresponding image files (down_fdroid.png, down_IzzyOnDroid.png) are added
to the repository.*

- **F-Droid:** Install from the official F-Droid repository
- **IzzyOnDroid:** Available through IzzyOnDroid F-Droid repository

### Development Builds

For the latest features and bug fixes, you can download development builds from
[GitHub Actions](https://github.com/longdinhh/Harmony-Music/actions) (requires
GitHub account).

## Building From Source

### Prerequisites

- **Flutter SDK:** ≥3.24.0 (stable channel)
- **Dart SDK:** ≥3.1.5 <4.0.0
- **JDK:** 17 (for Android builds)
- **Git:** For cloning the repository
- **Platform-specific tools:**
  - Android: Android SDK, Android Studio (recommended)
  - iOS: Xcode (for iOS builds, macOS required)

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/longdinhh/Harmony-Music.git
cd Harmony-Music

# Verify Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Generate localization files
dart localization/generator.dart

# Run the app in debug mode
flutter run

# Run tests
flutter test

# Analyze code quality
flutter analyze
```

### Platform-Specific Build Commands

#### Android APK

```bash
# Build release APK
flutter build apk --release

# Build app bundle (for Play Store)
flutter build appbundle --release

# Output location: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS IPA

```bash
# Build iOS app (requires macOS and Xcode)
flutter build ios --release

# Build iOS archive for App Store
flutter build ipa --release

# Output location: build/ios/ipa/harmonymusic.ipa
```

## Technical Specifications & Requirements

### System Requirements

#### Android

- **Minimum:** Android 5.0 (API level 21)
- **Recommended:** Android 8.0+ (API level 26)
- **RAM:** 2GB minimum, 4GB recommended
- **Storage:** 100MB for app, additional space for cached music
- **Permissions:** Internet, storage access, wake lock, foreground service

#### iOS

- **Minimum:** iOS 12.0
- **Recommended:** iOS 15.0+
- **RAM:** 2GB minimum, 4GB recommended
- **Storage:** 100MB for app, additional space for cached music
- **Devices:** iPhone 6s and newer, iPad Air 2 and newer

### Technical Stack

- **Programming Language:** Dart 3.1.5+
- **Framework:** Flutter 3.24.0+ (stable)
- **State Management:** GetX (Get 4.7.1+)
- **Local Database:** Hive 2.2.3+ (NoSQL, key-value store)
- **Audio Playback:**
  - just_audio 0.10.4+ (primary audio engine)
  - audio_service 0.18.17+ (background playback)
- **HTTP Client:** Dio 5.7.0+ (networking)
- **Caching:** cached_network_image 3.4.0+ (image caching)
- **UI Components:**
  - Material Design 3
  - Google Fonts 6.1.0+
  - Custom animations and transitions

### Key Dependencies

- **youtube_explode_dart:** YouTube data extraction
- **audio_metadata_reader:** Music metadata parsing
- **flutter_lyric:** Lyrics display and synchronization
- **palette_generator:** Dynamic theming from album art
- **permission_handler:** System permissions management
- **webview_flutter:** In-app web browsing (for authentication)
- **jni:** Native Android integration (equalizer)

### Architecture Overview

Harmony Music follows a clean architecture pattern with clear separation of concerns:

- **UI Layer:** Flutter widgets with GetX for state management
- **Service Layer:** Business logic and API integration
- **Data Layer:** Hive database for local storage and caching
- **Platform Layer:** Native integrations for Android Auto, equalizer, etc.

The app uses a reactive architecture where UI components automatically update
based on state changes, ensuring smooth user experience across Android and iOS.

## Project Structure Overview

```text
Harmony-Music/
├── lib/                           # Main Flutter application code
│   ├── main.dart                 # Application entry point
│   ├── base_class/               # Base classes and interfaces
│   ├── models/                   # Data models (Song, Album, Artist, etc.)
│   ├── services/                 # Business logic and API services
│   │   ├── audio_handler.dart    # Audio playback management
│   │   ├── music_service.dart    # YouTube Music API integration
│   │   ├── downloader.dart       # Song download functionality
│   │   ├── piped_service.dart    # Piped integration
│   │   └── stream_service.dart   # Audio streaming service
│   ├── ui/                       # User interface components
│   │   ├── screens/              # App screens (Home, Player, Settings)
│   │   ├── widgets/              # Reusable UI components
│   │   ├── player/               # Music player UI and controls
│   │   └── utils/                # UI utilities and theme management
│   ├── utils/                    # Utility functions and helpers
│   └── mixins/                   # Reusable code mixins
├── android/                       # Android-specific code and configuration
│   ├── app/src/main/kotlin/      # Kotlin native code (equalizer, SDK utils)
│   └── app/src/main/res/         # Android resources and launcher icons
├── ios/                          # iOS-specific code and configuration
│   ├── Runner/                   # iOS app configuration
│   └── Runner.xcodeproj/         # Xcode project files
├── localization/                 # Multi-language support files
│   ├── *.json                   # Translation files for each language
│   └── generator.dart            # Localization generator script
├── fastlane/                     # App store deployment configuration
│   ├── metadata/android/         # Play Store metadata and screenshots
│   └── metadata/ios/             # App Store metadata (when added)
├── assets/                       # Static assets (icons, images)
├── .github/                      # GitHub Actions CI/CD workflows
│   └── workflows/                # Automated build and quality checks
├── pubspec.yaml                  # Flutter dependencies and configuration
├── analysis_options.yaml         # Dart code analysis rules
└── LICENSE                       # GPL-3.0 license file
```

### Key Directories Explained

- **`lib/`**: Core Flutter application code organized by functionality
- **`lib/services/`**: Backend services handling music streaming, downloads, and external APIs
- **`lib/ui/`**: All user interface code including screens, player, and reusable widgets
- **`android/`**: Android-specific native code, including Kotlin implementations for equalizer
- **`localization/`**: Multi-language support with JSON files for 50+ languages
- **`fastlane/`**: App store metadata, screenshots, and deployment configuration
- **`.github/workflows/`**: Automated CI/CD pipelines for building and testing

## Contributing

We welcome contributions from the community! Whether you're fixing bugs,
adding features, improving documentation, or translating the app, your help is
appreciated.

### How to Contribute

1. **Fork the repository** on GitHub
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes** following our coding standards
4. **Test your changes** thoroughly
5. **Commit your changes** (`git commit -m 'feat: Add amazing feature'`)
6. **Push to your branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request** with a clear description of your changes

### Development Guidelines

- **Code Style:** Follow Dart/Flutter best practices and existing code patterns
- **Commit Messages:** Use conventional commit format (feat:, fix:, docs:, etc.)
- **Testing:** Run `flutter test` and `flutter analyze` before submitting
- **Documentation:** Update relevant documentation for new features
- **Localization:** Add translations for new user-facing strings

### Types of Contributions

- 🐛 **Bug Fixes:** Report and fix issues
- ✨ **New Features:** Implement new functionality
- 🌍 **Translations:** Help translate the app into new languages
- 📚 **Documentation:** Improve README, code comments, or guides
- 🎨 **UI/UX:** Enhance the user interface and experience
- ⚡ **Performance:** Optimize app performance and resource usage

### Before Contributing

- Check existing [Issues](https://github.com/longdinhh/Harmony-Music/issues) and [Pull Requests](https://github.com/longdinhh/Harmony-Music/pulls)
- For major changes, please open an issue first to discuss your proposal
- Ensure your development environment meets the [build requirements](#building-from-source)

### Code of Conduct

This project follows a standard code of conduct. Be respectful, inclusive,
and constructive in all interactions. Harassment, discrimination, or toxic
behavior will not be tolerated.

## License

This project is licensed under the **GNU General Public License v3.0** - see
the [LICENSE](LICENSE) file for complete terms.

### GPL-3.0 License Summary

```text
Copyright (C) 2024 Harmony Music Contributors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
```

**What this means:**

- ✅ You can use, modify, and distribute this software freely
- ✅ You can use it for commercial purposes
- ✅ Source code must remain open when redistributing
- ✅ Changes must be documented and made available
- ❌ No warranty or liability is provided

For more information about GPL-3.0, visit:
<https://www.gnu.org/licenses/gpl-3.0.html>

## Acknowledgements & Credits

### Original Authors & Maintainers

- **@longdinhh** - Original author and primary maintainer
- **@anandnet** - Core contributor and Android optimizations
- All [contributors](https://github.com/longdinhh/Harmony-Music/contributors) who have helped improve this project

### Built With Amazing Open Source Projects

- **[Flutter](https://flutter.dev/)** - Google's UI toolkit for cross-platform development
- **[YouTube Explode Dart](https://github.com/Hexer10/youtube_explode_dart)** - YouTube data extraction library
- **[just_audio](https://pub.dev/packages/just_audio)** - Feature-rich audio player for Flutter
- **[GetX](https://pub.dev/packages/get)** - High-performance state management
- **[Hive](https://pub.dev/packages/hive)** - Lightning-fast NoSQL database

### Key Third-Party Libraries & Licenses

- **audio_service** - [MIT License](https://pub.dev/packages/audio_service/license)
- **cached_network_image** - [MIT License](https://pub.dev/packages/cached_network_image/license)
- **dio** - [MIT License](https://pub.dev/packages/dio/license)
- **flutter_lyric** - [MIT License](https://pub.dev/packages/flutter_lyric/license)
- **google_fonts** - [Apache 2.0](https://pub.dev/packages/google_fonts/license)
- **palette_generator** - [BSD-3-Clause](https://pub.dev/packages/palette_generator/license)
- **webview_flutter** - [BSD-3-Clause](https://pub.dev/packages/webview_flutter/license)

### Special Thanks

- **YouTube/YouTube Music** - For providing the content platform
- **Piped Project** - For privacy-focused YouTube proxy integration
- **F-Droid Community** - For supporting open-source app distribution
- **Flutter Community** - For the amazing ecosystem and support
- **All Users & Testers** - For feedback, bug reports, and feature requests
- **Translation Contributors** - For making the app accessible worldwide

### Icons & Assets

- **Material Design Icons** - [Apache 2.0](https://material.io/resources/icons/)
- **Ionicons** - [MIT License](https://ionic.io/ionicons)

## Support / Contact

### Get Help & Report Issues

- **🐛 Bug Reports**: [GitHub Issues](https://github.com/longdinhh/Harmony-Music/issues/new?template=bug_report.md)
- **💡 Feature Requests**: [GitHub Issues](https://github.com/longdinhh/Harmony-Music/issues/new?template=feature_request.md)
- **💬 General Discussion**: [GitHub Discussions](https://github.com/longdinhh/Harmony-Music/discussions)
- **📖 Documentation**: [Project Wiki](https://github.com/longdinhh/Harmony-Music/wiki) (coming soon)

### Community & Updates

- **📢 Release Notes**: [GitHub Releases](https://github.com/longdinhh/Harmony-Music/releases)
- **🔔 Follow Updates**: Watch this repository for notifications
- **⭐ Show Support**: Star the project if you find it useful!

### Contact Information

- **Primary Maintainer**: [@longdinhh](https://github.com/longdinhh)
- **Project Repository**: <https://github.com/longdinhh/Harmony-Music>
- **F-Droid Listing**: <https://f-droid.org/packages/com.anandnet.harmonymusic/>

### Getting Help - Step by Step

1. **Search First**: Check if your question has been answered in existing [Issues](https://github.com/longdinhh/Harmony-Music/issues)
2. **Check Releases**: See if the latest version fixes your problem
3. **Provide Details**: When reporting issues, include:
   - App version and platform
   - Steps to reproduce the problem
   - Error messages or screenshots
   - Device/system information
4. **Be Patient**: This is an open-source project maintained by volunteers

### Supporting the Project

- ⭐ **Star the repository** to show your support
- 🐛 **Report bugs** and help improve stability
- 🌍 **Contribute translations** for your language
- 💻 **Submit code contributions** for new features
- 📢 **Share with friends** who love music
- ☕ **Consider donating** to support development (links in sponsor section)

---
*Harmony Music - Free, Open Source, No Ads, No Tracking*  
*Last updated: January 2024*
