import 'dart:core';

/// Custom Exception classes for Harmony Music
/// Following user requirement: throw with errorCode and message,
/// and if caught, return the errorCode and message.

/// Base exception class for Harmony Music app
class HarmonyMusicException implements Exception {
  final String errorCode;
  final String message;

  const HarmonyMusicException(this.errorCode, this.message);

  @override
  String toString() => 'HarmonyMusicException($errorCode): $message';

  /// Returns error details as a Map for easy handling
  Map<String, String> toMap() => {
        'errorCode': errorCode,
        'message': message,
      };
}

/// Network related exceptions
class NetworkException extends HarmonyMusicException {
  const NetworkException(super.errorCode, super.message);

  /// No internet connection
  const NetworkException.noConnection()
      : super('NET_001', 'No internet connection available');

  /// Request timeout
  const NetworkException.timeout() : super('NET_002', 'Request timed out');

  /// Server error
  const NetworkException.serverError([String? details])
      : super('NET_003', 'Server error${details != null ? ': $details' : ''}');
}

/// Audio/Music related exceptions
class AudioException extends HarmonyMusicException {
  const AudioException(super.errorCode, super.message);

  /// Failed to load audio
  const AudioException.loadFailed()
      : super('AUD_001', 'Failed to load audio file');

  /// Unsupported audio format
  const AudioException.unsupportedFormat()
      : super('AUD_002', 'Unsupported audio format');

  /// Playback error
  const AudioException.playbackError([String? details])
      : super(
            'AUD_003', 'Playback error${details != null ? ': $details' : ''}');
}

/// Storage/Cache related exceptions
class StorageException extends HarmonyMusicException {
  const StorageException(super.errorCode, super.message);

  /// Insufficient storage space
  const StorageException.insufficientSpace()
      : super('STG_001', 'Insufficient storage space');

  /// File not found
  const StorageException.fileNotFound() : super('STG_002', 'File not found');

  /// Permission denied
  const StorageException.permissionDenied()
      : super('STG_003', 'Storage permission denied');
}

/// API/Service related exceptions
class ServiceException extends HarmonyMusicException {
  const ServiceException(super.errorCode, super.message);

  /// YouTube service error
  const ServiceException.youtubeError()
      : super('SVC_001', 'YouTube service unavailable');

  /// Search service error
  const ServiceException.searchError()
      : super('SVC_002', 'Music search service error');

  /// Lyrics service error
  const ServiceException.lyricsError()
      : super('SVC_003', 'Lyrics service unavailable');
}

/// Utility class for exception handling
class ExceptionHandler {
  /// Handles exceptions and returns error details
  /// Following user requirement: if error code is caught, return errorCode and message
  static Map<String, String> handleException(Object error) {
    if (error is HarmonyMusicException) {
      return error.toMap();
    } else if (error is Exception) {
      return {
        'errorCode': 'GEN_001',
        'message': 'An unexpected error occurred: ${error.toString()}',
      };
    } else {
      return {
        'errorCode': 'GEN_002',
        'message': 'An unknown error occurred',
      };
    }
  }

  /// Shows user-friendly error messages
  static String getUserFriendlyMessage(String errorCode) {
    switch (errorCode) {
      case 'NET_001':
        return 'Please check your internet connection and try again';
      case 'NET_002':
        return 'Request is taking too long. Please try again';
      case 'NET_003':
        return 'Server is temporarily unavailable';
      case 'AUD_001':
        return 'Unable to play this song. Try another one';
      case 'AUD_002':
        return 'This audio format is not supported';
      case 'STG_001':
        return 'Not enough storage space available';
      case 'STG_002':
        return 'The requested file could not be found';
      case 'STG_003':
        return 'Please grant storage permission in settings';
      case 'SVC_001':
        return 'YouTube service is currently unavailable';
      case 'SVC_002':
        return 'Music search is temporarily unavailable';
      case 'SVC_003':
        return 'Lyrics service is currently unavailable';
      default:
        return 'An unexpected error occurred';
    }
  }
}

/// Example usage in the app:
///
/// ```dart
/// try {
///   await musicService.loadSong(songId);
/// } catch (error) {
///   final errorDetails = ExceptionHandler.handleException(error);
///
///   // Following user requirement: return errorCode and message
///   print('Error Code: ${errorDetails['errorCode']}');
///   print('Message: ${errorDetails['message']}');
///
///   // Show user-friendly message
///   final userMessage = ExceptionHandler.getUserFriendlyMessage(
///     errorDetails['errorCode']!
///   );
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text(userMessage))
///   );
/// }
/// ```
