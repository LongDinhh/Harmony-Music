import 'package:hive/hive.dart';

import '../interfaces/user_repository.dart';
import '../exceptions/repository_exception.dart';

/// Concrete implementation of UserRepository using Hive for user preferences storage
class HiveUserRepository implements UserRepository {
  static const String _preferencesBoxName = 'user_preferences';
  static const String _playbackHistoryBoxName = 'playback_history';
  static const String _userStatsBoxName = 'user_stats';

  Box<dynamic>? _preferencesBox;
  Box<String>? _playbackHistoryBox;
  Box<Map>? _userStatsBox;

  Future<void> _ensureBoxesOpen() async {
    _preferencesBox ??= await Hive.openBox<dynamic>(_preferencesBoxName);
    _playbackHistoryBox ??= await Hive.openBox<String>(_playbackHistoryBoxName);
    _userStatsBox ??= await Hive.openBox<Map>(_userStatsBoxName);
  }

  @override
  Future<T?> getPreference<T>(String key, {T? defaultValue}) async {
    try {
      await _ensureBoxesOpen();
      final value = _preferencesBox!.get(key, defaultValue: defaultValue);
      return value is T ? value : defaultValue;
    } catch (error) {
      throw UserException.storageError('Failed to get preference $key: ${error.toString()}');
    }
  }

  @override
  Future<void> setPreference<T>(String key, T value) async {
    try {
      await _ensureBoxesOpen();
      await _preferencesBox!.put(key, value);
    } catch (error) {
      throw UserException.storageError('Failed to set preference $key: ${error.toString()}');
    }
  }

  @override
  Future<void> removePreference(String key) async {
    try {
      await _ensureBoxesOpen();
      await _preferencesBox!.delete(key);
    } catch (error) {
      throw UserException.storageError('Failed to remove preference $key: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getAllPreferences() async {
    try {
      await _ensureBoxesOpen();
      final prefs = <String, dynamic>{};
      
      for (final key in _preferencesBox!.keys) {
        prefs[key.toString()] = _preferencesBox!.get(key);
      }
      
      return prefs;
    } catch (error) {
      throw UserException.storageError('Failed to get all preferences: ${error.toString()}');
    }
  }

  @override
  Future<void> clearAllPreferences() async {
    try {
      await _ensureBoxesOpen();
      await _preferencesBox!.clear();
    } catch (error) {
      throw UserException.storageError('Failed to clear all preferences: ${error.toString()}');
    }
  }

  @override
  Future<String> getThemeMode() async {
    return await getPreference<String>('theme_mode', defaultValue: 'system') ?? 'system';
  }

  @override
  Future<void> setThemeMode(String themeMode) async {
    if (!['light', 'dark', 'system'].contains(themeMode)) {
      throw UserException.invalidValue('theme_mode', themeMode);
    }
    await setPreference('theme_mode', themeMode);
  }

  @override
  Future<String> getAudioQuality() async {
    return await getPreference<String>('audio_quality', defaultValue: 'high') ?? 'high';
  }

  @override
  Future<void> setAudioQuality(String quality) async {
    if (!['low', 'medium', 'high', 'lossless'].contains(quality)) {
      throw UserException.invalidValue('audio_quality', quality);
    }
    await setPreference('audio_quality', quality);
  }

  @override
  Future<String> getLanguage() async {
    return await getPreference<String>('language', defaultValue: 'en') ?? 'en';
  }

  @override
  Future<void> setLanguage(String language) async {
    await setPreference('language', language);
  }

  @override
  Future<Map<String, double>?> getEqualizerSettings() async {
    try {
      final settings = await getPreference<Map>('equalizer_settings');
      return settings?.cast<String, double>();
    } catch (error) {
      return null;
    }
  }

  @override
  Future<void> setEqualizerSettings(Map<String, double> settings) async {
    await setPreference('equalizer_settings', settings);
  }

  @override
  Future<String?> getDownloadLocation() async {
    return await getPreference<String>('download_location');
  }

  @override
  Future<void> setDownloadLocation(String path) async {
    await setPreference('download_location', path);
  }

  @override
  Future<bool> getAutoDownload() async {
    return await getPreference<bool>('auto_download', defaultValue: false) ?? false;
  }

  @override
  Future<void> setAutoDownload(bool enabled) async {
    await setPreference('auto_download', enabled);
  }

  @override
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final settings = await getPreference<Map>('notification_settings', 
          defaultValue: {
            'playback_notifications': true,
            'download_notifications': true,
            'library_notifications': false,
          });
      return settings?.cast<String, bool>() ?? {
        'playback_notifications': true,
        'download_notifications': true,
        'library_notifications': false,
      };
    } catch (error) {
      return {
        'playback_notifications': true,
        'download_notifications': true,
        'library_notifications': false,
      };
    }
  }

  @override
  Future<void> setNotificationSettings(Map<String, bool> settings) async {
    await setPreference('notification_settings', settings);
  }

  @override
  Future<Map<String, bool>> getPrivacySettings() async {
    try {
      final settings = await getPreference<Map>('privacy_settings',
          defaultValue: {
            'analytics_enabled': false,
            'crash_reports_enabled': true,
            'usage_statistics': false,
            'personalized_ads': false,
          });
      return settings?.cast<String, bool>() ?? {
        'analytics_enabled': false,
        'crash_reports_enabled': true,
        'usage_statistics': false,
        'personalized_ads': false,
      };
    } catch (error) {
      return {
        'analytics_enabled': false,
        'crash_reports_enabled': true,
        'usage_statistics': false,
        'personalized_ads': false,
      };
    }
  }

  @override
  Future<void> setPrivacySettings(Map<String, bool> settings) async {
    await setPreference('privacy_settings', settings);
  }

  @override
  Future<String?> getLastPlayedSong() async {
    return await getPreference<String>('last_played_song');
  }

  @override
  Future<void> setLastPlayedSong(String songId) async {
    await setPreference('last_played_song', songId);
  }

  @override
  Future<List<String>> getPlaybackHistory({int limit = 100}) async {
    try {
      await _ensureBoxesOpen();
      final history = <String>[];
      
      // Get the most recent entries (Hive stores in order)
      final keys = _playbackHistoryBox!.keys.toList();
      final startIndex = keys.length > limit ? keys.length - limit : 0;
      
      for (int i = keys.length - 1; i >= startIndex; i--) {
        final songId = _playbackHistoryBox!.getAt(i);
        if (songId != null) {
          history.add(songId);
        }
      }
      
      return history;
    } catch (error) {
      throw UserException.storageError('Failed to get playback history: ${error.toString()}');
    }
  }

  @override
  Future<void> addToPlaybackHistory(String songId) async {
    try {
      await _ensureBoxesOpen();
      
      // Remove existing entry if present (to avoid duplicates)
      final existingKeys = <int>[];
      for (int i = 0; i < _playbackHistoryBox!.length; i++) {
        if (_playbackHistoryBox!.getAt(i) == songId) {
          existingKeys.add(i);
        }
      }
      
      // Remove from back to front to maintain indices
      for (final key in existingKeys.reversed) {
        await _playbackHistoryBox!.deleteAt(key);
      }
      
      // Add to end (most recent)
      await _playbackHistoryBox!.add(songId);
      
      // Keep only last 1000 entries
      if (_playbackHistoryBox!.length > 1000) {
        final entriesToRemove = _playbackHistoryBox!.length - 1000;
        for (int i = 0; i < entriesToRemove; i++) {
          await _playbackHistoryBox!.deleteAt(0);
        }
      }
    } catch (error) {
      throw UserException.storageError('Failed to add to playback history: ${error.toString()}');
    }
  }

  @override
  Future<void> clearPlaybackHistory() async {
    try {
      await _ensureBoxesOpen();
      await _playbackHistoryBox!.clear();
    } catch (error) {
      throw UserException.storageError('Failed to clear playback history: ${error.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      await _ensureBoxesOpen();
      
      final stats = _userStatsBox!.get('user_stats');
      if (stats != null) {
        return Map<String, dynamic>.from(stats);
      }
      
      // Return default stats
      return {
        'totalListeningTime': 0,
        'songsPlayed': 0,
        'favoriteSongs': 0,
        'playlistsCreated': 0,
        'accountCreated': DateTime.now().millisecondsSinceEpoch,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (error) {
      throw UserException.storageError('Failed to get user stats: ${error.toString()}');
    }
  }

  @override
  Future<void> updateUserStats(Map<String, dynamic> stats) async {
    try {
      await _ensureBoxesOpen();
      
      final currentStats = await getUserStats();
      final updatedStats = {
        ...currentStats,
        ...stats,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _userStatsBox!.put('user_stats', updatedStats);
    } catch (error) {
      throw UserException.storageError('Failed to update user stats: ${error.toString()}');
    }
  }
}