<img src="https://github.com/anandnet/Harmony-Music/blob/main/cover.png" width="1200" >

# Harmony Music
A cross platform app for music streaming made with Flutter (Android, iOS).

## ✨ Platform Support
- ✅ **Android** - Full featured support
- ✅ **iOS** - Core features supported with iOS-specific optimizations

# Features

## 🎵 Core Features
* Ability to play song from Ytube/Ytube Music.
* Song cache while playing
* Radio feature support
* Background music playback
* Playlist creation & bookmark support
* Artist & Album bookmark support
* Import song,Playlist,Album,Artist via sharing from Ytube/Ytube Music.
* Streaming quality control
* Song downloading support
* Language support
* Skip silence
* Dynamic Theme
* Flexibility to switch between Bottom & Side Nav bar
* Synced & Plain Lyrics support
* Sleep Timer
* No Advertisment
* No Login required
* Piped playlist integration

## 📱 Platform-Specific Features

### Android
* ✅ System Equalizer integration
* ✅ Android Auto support
* ✅ Battery optimization controls
* ✅ External storage file exports
* ✅ Loudness normalization

### iOS
* ✅ Background audio playback (handled by just_audio + Info.plist)
* ✅ Files app integration for exports
* ✅ Photo library permission for file access
* ✅ Loudness normalization
* ⚠️ Equalizer through iOS Control Center/Settings
* ⚠️ CarPlay integration (planned)

## 🚧 iOS Features Under Development

### ⏳ Planned Features
- **CarPlay Integration**: Native iOS CarPlay support for in-car music control
- **Custom Equalizer**: In-app equalizer for iOS (currently uses system EQ)
- **Spotlight Integration**: Add songs to iOS Spotlight search
- **Siri Shortcuts**: Voice control for common actions
- **Apple Watch Companion**: Basic playback controls on Apple Watch

### 🔧 Technical Improvements Needed
- **iOS Widget**: Home screen widget for quick playback controls
- **AirPlay Support**: Native AirPlay streaming to other Apple devices
- **Background App Refresh**: Optimized background refresh for iOS
- **File Provider Extension**: Better integration with iOS Files app

### ⚠️ Known iOS Limitations
- **System Equalizer Only**: iOS restricts access to system-level audio processing, so equalizer must be accessed through Control Center or Settings app
- **Storage Permissions**: iOS has different file access model - files are exported to app's Documents directory accessible via Files app
- **Background Limits**: iOS may limit background processing more aggressively than Android

## 🎯 Cross-Platform Improvements Roadmap

### High Priority
1. **CarPlay/Android Auto Parity**: Ensure both platforms have similar in-car experiences
2. **Cloud Sync**: Cross-platform playlist and settings synchronization
3. **Performance Optimization**: Battery usage and memory optimization for mobile platforms

### Medium Priority
1. **Adaptive UI**: Better responsive design for different screen sizes
2. **Accessibility**: Improved screen reader and accessibility support
3. **Offline Mode**: Enhanced offline music management
4. **Smart Caching**: Intelligent cache management based on listening habits

### Low Priority
1. **Advanced Audio Effects**: Cross-platform audio effects beyond basic equalizer
2. **Social Features**: Share playlists and music discoveries
3. **Statistics**: Detailed listening statistics and insights

# Download
* Please choose one source for android apk. you won't be able to update from cross build apk source.

<a href="https://github.com/anandnet/Harmony-Music/releases/latest"><img src ="https://github.com/anandnet/Harmony-Music/blob/main/don_github.png" width = "250"></a> <a href= "https://f-droid.org/packages/com.anandnet.harmonymusic"><img src = "https://github.com/anandnet/Harmony-Music/blob/main/down_fdroid.png" width = '250'></a></a> 

**iOS**: iOS build will be available through TestFlight beta program. Contact developers for beta access.

# Translation
<a href="https://hosted.weblate.org/engage/harmony-music/">
<img src="https://hosted.weblate.org/widget/harmony-music/project-translations/multi-auto.svg" alt="Translation status" />
</a>

You can also help us in translation, click status image or <a href="https://hosted.weblate.org/projects/harmony-music/project-translations/"> here </a> to go to Weblate.

# Troubleshoot

## Android
* If you are facing Notification control issue or music playback stopped by system optimization, please enable ignore battery optimization option from settings

## iOS
* **Background Playback Issues**: Ensure Background App Refresh is enabled for Harmony Music in iOS Settings
* **File Export Issues**: Grant photo library access permission when prompted for file exports
* **Equalizer**: Use iOS Control Center or Settings > Music > EQ for audio equalizer controls
* **CarPlay**: Currently uses iOS built-in music interface, dedicated CarPlay UI coming soon

# License
```
Harmony Music is a free software licensed under GPL v3.0 with following condition.

- Copied/Modified version of this software can not be used for 'non-free' and profit purposes.
- You can not publish copied/modified version of this app on closed source app repository
  like PlayStore/AppStore.

```


# Disclaimer
```
This project has been created while learning & learning is the main intention.
This project is not sponsored or affiliated with, funded, authorized, endorsed by any content provider.
Any Song, content, trademark used in this app are intellectual property of their respective owners.
Harmony music is not responsible for any infringement of copyright or other intellectual property rights that may result
from the use of the songs and other content available through this app.

This Software is released "as-is", without any warranty, responsibility or liability.
In no event shall the Author of this Software be liable for any special, consequential,
incidental or indirect damages whatsoever (including, without limitation, any 
other pecuniary loss) arising out of the use of inability to use this product, even if
Author of this Sotware is aware of the possibility of such damages and known defect.
```

# Learning References & Credits
<a href = 'https://docs.flutter.dev/'>Flutter documentation</a> - a best guide to learn cross platform Ui/app developemnt<br/>
<a href = 'https://suragch.medium.com/'>Suragch</a>'s Article related to Just audio & state management,architectural style<br/>
<a href = 'https://github.com/sigma67'>sigma67</a>'s unofficial ytmusic api project<br/>
App UI inspired by <a href = 'https://github.com/vfsfitvnm'>vfsfitvnm</a>'s ViMusic<br/>
Synced lyrics provided by <a href = 'https://lrclib.net' >LRCLIB</a> <br/>
<a href = 'https://piped.video' >Piped</a> for playlists.

#### Major Packages used
* just_audio: ^0.9.40  -  audio player for android
* media_kit: ^1.1.9 - audio player for linux and windows
* audio_service: ^0.18.15 - manage background music & platform audio services
* get: ^4.6.6 -  package for high-performance state management, intelligent dependency injection, and route management
* youtube_explode_dart: ^2.0.2 - Third party package to provide song url
* hive: ^2.2.3 - offline db used 
* hive_flutter: ^1.1.0


