/// Abstract repository interface for user preferences and settings
abstract class UserRepository {
  /// Get user preference by key
  Future<T?> getPreference<T>(String key, {T? defaultValue});

  /// Set user preference
  Future<void> setPreference<T>(String key, T value);

  /// Remove user preference
  Future<void> removePreference(String key);

  /// Get all user preferences
  Future<Map<String, dynamic>> getAllPreferences();

  /// Clear all user preferences
  Future<void> clearAllPreferences();

  /// Get user theme preference
  Future<String> getThemeMode();

  /// Set user theme preference
  Future<void> setThemeMode(String themeMode);

  /// Get audio quality preference
  Future<String> getAudioQuality();

  /// Set audio quality preference
  Future<void> setAudioQuality(String quality);

  /// Get language preference
  Future<String> getLanguage();

  /// Set language preference
  Future<void> setLanguage(String language);

  /// Get equalizer settings
  Future<Map<String, double>?> getEqualizerSettings();

  /// Set equalizer settings
  Future<void> setEqualizerSettings(Map<String, double> settings);

  /// Get download location preference
  Future<String?> getDownloadLocation();

  /// Set download location preference
  Future<void> setDownloadLocation(String path);

  /// Get auto-download preference
  Future<bool> getAutoDownload();

  /// Set auto-download preference
  Future<void> setAutoDownload(bool enabled);

  /// Get notification preferences
  Future<Map<String, bool>> getNotificationSettings();

  /// Set notification preferences
  Future<void> setNotificationSettings(Map<String, bool> settings);

  /// Get privacy settings
  Future<Map<String, bool>> getPrivacySettings();

  /// Set privacy settings
  Future<void> setPrivacySettings(Map<String, bool> settings);

  /// Get last played song ID
  Future<String?> getLastPlayedSong();

  /// Set last played song ID
  Future<void> setLastPlayedSong(String songId);

  /// Get playback history
  Future<List<String>> getPlaybackHistory({int limit = 100});

  /// Add song to playback history
  Future<void> addToPlaybackHistory(String songId);

  /// Clear playback history
  Future<void> clearPlaybackHistory();

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats();

  /// Update user statistics
  Future<void> updateUserStats(Map<String, dynamic> stats);
}