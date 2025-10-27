import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:audio_service/audio_service.dart';

import 'package:harmonymusic/repositories/interfaces/music_repository.dart';
import 'package:harmonymusic/repositories/interfaces/cache_repository.dart';
import 'package:harmonymusic/repositories/implementations/youtube_music_repository.dart';
import 'package:harmonymusic/repositories/exceptions/repository_exception.dart';
import 'package:harmonymusic/services/api_service.dart';
import 'package:harmonymusic/models/album.dart';
import 'package:harmonymusic/models/artist.dart';

import 'music_repository_test.mocks.dart';

@GenerateMocks([APIService, CacheRepository])
void main() {
  group('YouTubeMusicRepository Tests', () {
    late YouTubeMusicRepository repository;
    late MockAPIService mockApiService;
    late MockCacheRepository mockCacheRepository;

    setUp(() {
      mockApiService = MockAPIService();
      mockCacheRepository = MockCacheRepository();
      repository = YouTubeMusicRepository(mockApiService, mockCacheRepository);
    });

    group('searchSongs', () {
      test('should return cached results when available', () async {
        // Arrange
        const query = 'test song';
        final cachedResults = {
          'songs': [
            {
              'videoId': '123',
              'title': 'Test Song',
              'artists': [{'name': 'Test Artist'}],
              'thumbnails': [{'url': 'https://example.com/thumb.jpg'}],
              'length': '3:30',
            }
          ]
        };
        
        when(mockCacheRepository.getCachedSearchResults(query))
            .thenAnswer((_) async => cachedResults);

        // Act
        final result = await repository.searchSongs(query);

        // Assert
        expect(result, isA<List<MediaItem>>());
        expect(result.length, equals(1));
        expect(result.first.title, equals('Test Song'));
        verify(mockCacheRepository.getCachedSearchResults(query)).called(1);
        verifyNever(mockApiService.search(any, limit: anyNamed('limit')));
      });

      test('should fetch from API when cache is empty', () async {
        // Arrange
        const query = 'test song';
        final apiResponse = {
          'contents': [
            {
              'videoId': '123',
              'title': 'Test Song',
              'artists': [{'name': 'Test Artist'}],
              'thumbnails': [{'url': 'https://example.com/thumb.jpg'}],
              'length': '3:30',
            }
          ]
        };
        
        when(mockCacheRepository.getCachedSearchResults(query))
            .thenAnswer((_) async => null);
        when(mockApiService.search(query, limit: 30))
            .thenAnswer((_) async => apiResponse);
        when(mockCacheRepository.cacheSearchResults(any, any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.searchSongs(query);

        // Assert
        expect(result, isA<List<MediaItem>>());
        verify(mockCacheRepository.getCachedSearchResults(query)).called(1);
        verify(mockApiService.search(query, limit: 30)).called(1);
        verify(mockCacheRepository.cacheSearchResults(query, any)).called(1);
      });

      test('should throw MusicException when API call fails', () async {
        // Arrange
        const query = 'test song';
        
        when(mockCacheRepository.getCachedSearchResults(query))
            .thenAnswer((_) async => null);
        when(mockApiService.search(query, limit: 30))
            .thenThrow(Exception('API Error'));

        // Act & Assert
        expect(
          () => repository.searchSongs(query),
          throwsA(isA<MusicException>()),
        );
      });

      test('should respect limit parameter', () async {
        // Arrange
        const query = 'test song';
        const limit = 10;
        final apiResponse = {
          'contents': List.generate(15, (i) => {
            'videoId': '$i',
            'title': 'Test Song $i',
            'artists': [{'name': 'Test Artist'}],
            'thumbnails': [{'url': 'https://example.com/thumb.jpg'}],
            'length': '3:30',
          })
        };
        
        when(mockCacheRepository.getCachedSearchResults(query))
            .thenAnswer((_) async => null);
        when(mockApiService.search(query, limit: limit))
            .thenAnswer((_) async => apiResponse);
        when(mockCacheRepository.cacheSearchResults(any, any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.searchSongs(query, limit: limit);

        // Assert
        verify(mockApiService.search(query, limit: limit)).called(1);
        expect(result.length, lessThanOrEqualTo(limit));
      });
    });

    group('getAlbum', () {
      test('should return cached album when available', () async {
        // Arrange
        const albumId = 'album123';
        final cachedAlbum = {
          'title': 'Test Album',
          'browseId': 'browse123',
          'artists': [{'name': 'Test Artist'}],
          'thumbnails': [{'url': 'https://example.com/thumb.jpg'}],
        };
        
        when(mockCacheRepository.getCachedAlbumData(albumId))
            .thenAnswer((_) async => cachedAlbum);

        // Act
        final result = await repository.getAlbum(albumId);

        // Assert
        expect(result, isA<Album>());
        expect(result.title, equals('Test Album'));
        verify(mockCacheRepository.getCachedAlbumData(albumId)).called(1);
        verifyNever(mockApiService.getAlbumBrowseId(any));
      });

      test('should fetch from API when cache is empty', () async {
        // Arrange
        const albumId = 'album123';
        const browseId = 'browse123';
        final apiResponse = {
          'title': 'Test Album',
          'browseId': browseId,
          'artists': [{'name': 'Test Artist'}],
          'thumbnails': [{'url': 'https://example.com/thumb.jpg'}],
        };
        
        when(mockCacheRepository.getCachedAlbumData(albumId))
            .thenAnswer((_) async => null);
        when(mockApiService.getAlbumBrowseId(albumId))
            .thenAnswer((_) async => browseId);
        when(mockApiService.getPlaylistOrAlbumSongs(albumId: browseId))
            .thenAnswer((_) async => apiResponse);
        when(mockCacheRepository.cacheAlbumData(any, any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getAlbum(albumId);

        // Assert
        expect(result, isA<Album>());
        verify(mockCacheRepository.getCachedAlbumData(albumId)).called(1);
        verify(mockApiService.getAlbumBrowseId(albumId)).called(1);
        verify(mockApiService.getPlaylistOrAlbumSongs(albumId: browseId)).called(1);
        verify(mockCacheRepository.cacheAlbumData(albumId, any)).called(1);
      });

      test('should throw MusicException.albumNotFound when album does not exist', () async {
        // Arrange
        const albumId = 'nonexistent';
        const browseId = 'browse123';
        
        when(mockCacheRepository.getCachedAlbumData(albumId))
            .thenAnswer((_) async => null);
        when(mockApiService.getAlbumBrowseId(albumId))
            .thenAnswer((_) async => browseId);
        when(mockApiService.getPlaylistOrAlbumSongs(albumId: browseId))
            .thenAnswer((_) async => <String, dynamic>{});

        // Act & Assert
        expect(
          () => repository.getAlbum(albumId),
          throwsA(isA<MusicException>()),
        );
      });
    });

    group('getArtist', () {
      test('should return cached artist when available', () async {
        // Arrange
        const artistId = 'artist123';
        final cachedArtist = {
          'artist': 'Test Artist',
          'browseId': 'browse123',
          'thumbnails': [{'url': 'https://example.com/thumb.jpg'}],
        };
        
        when(mockCacheRepository.getCachedArtistData(artistId))
            .thenAnswer((_) async => cachedArtist);

        // Act
        final result = await repository.getArtist(artistId);

        // Assert
        expect(result, isA<Artist>());
        expect(result.name, equals('Test Artist'));
        verify(mockCacheRepository.getCachedArtistData(artistId)).called(1);
        verifyNever(mockApiService.getArtist(any));
      });

      test('should fetch from API when cache is empty', () async {
        // Arrange
        const artistId = 'artist123';
        final apiResponse = {
          'name': 'Test Artist',
          'browseId': 'browse123',
          'thumbnails': [{'url': 'https://example.com/thumb.jpg'}],
        };
        
        when(mockCacheRepository.getCachedArtistData(artistId))
            .thenAnswer((_) async => null);
        when(mockApiService.getArtist(artistId))
            .thenAnswer((_) async => apiResponse);
        when(mockCacheRepository.cacheArtistData(any, any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getArtist(artistId);

        // Assert
        expect(result, isA<Artist>());
        verify(mockCacheRepository.getCachedArtistData(artistId)).called(1);
        verify(mockApiService.getArtist(artistId)).called(1);
        verify(mockCacheRepository.cacheArtistData(artistId, any)).called(1);
      });

      test('should throw MusicException.artistNotFound when artist does not exist', () async {
        // Arrange
        const artistId = 'nonexistent';
        
        when(mockCacheRepository.getCachedArtistData(artistId))
            .thenAnswer((_) async => null);
        when(mockApiService.getArtist(artistId))
            .thenAnswer((_) async => <String, dynamic>{});

        // Act & Assert
        expect(
          () => repository.getArtist(artistId),
          throwsA(isA<MusicException>()),
        );
      });
    });

    group('getHomeContent', () {
      test('should return cached home content when available', () async {
        // Arrange
        final cachedContent = {
          'quickPicks': [],
          'middleContent': [],
          'fixedContent': [],
        };
        
        when(mockCacheRepository.getCachedHomeScreenData())
            .thenAnswer((_) async => cachedContent);

        // Act
        final result = await repository.getHomeContent();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        verify(mockCacheRepository.getCachedHomeScreenData()).called(1);
        verifyNever(mockApiService.getHomeData(limit: anyNamed('limit')));
      });

      test('should fetch from API when cache is empty', () async {
        // Arrange
        final apiResponse = {
          'quickPicks': [],
          'middleContent': [],
          'fixedContent': [],
        };
        
        when(mockCacheRepository.getCachedHomeScreenData())
            .thenAnswer((_) async => null);
        when(mockApiService.getHomeData(limit: 4))
            .thenAnswer((_) async => apiResponse);
        when(mockCacheRepository.cacheHomeScreenData(any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getHomeContent();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        verify(mockCacheRepository.getCachedHomeScreenData()).called(1);
        verify(mockApiService.getHomeData(limit: 4)).called(1);
        verify(mockCacheRepository.cacheHomeScreenData(any)).called(1);
      });

      test('should respect limit parameter', () async {
        // Arrange
        const limit = 10;
        final apiResponse = {'content': []};
        
        when(mockCacheRepository.getCachedHomeScreenData())
            .thenAnswer((_) async => null);
        when(mockApiService.getHomeData(limit: limit))
            .thenAnswer((_) async => apiResponse);
        when(mockCacheRepository.cacheHomeScreenData(any))
            .thenAnswer((_) async {});

        // Act
        await repository.getHomeContent(limit: limit);

        // Assert
        verify(mockApiService.getHomeData(limit: limit)).called(1);
      });
    });

    group('getSearchSuggestions', () {
      test('should return search suggestions from API', () async {
        // Arrange
        const query = 'test';
        final suggestions = ['test song', 'test artist', 'test album'];
        
        when(mockApiService.getSearchSuggestion(query))
            .thenAnswer((_) async => suggestions);

        // Act
        final result = await repository.getSearchSuggestions(query);

        // Assert
        expect(result, equals(suggestions));
        verify(mockApiService.getSearchSuggestion(query)).called(1);
      });

      test('should throw MusicException when API call fails', () async {
        // Arrange
        const query = 'test';
        
        when(mockApiService.getSearchSuggestion(query))
            .thenThrow(Exception('API Error'));

        // Act & Assert
        expect(
          () => repository.getSearchSuggestions(query),
          throwsA(isA<MusicException>()),
        );
      });
    });

    group('getCharts', () {
      test('should return charts from API', () async {
        // Arrange
        const countryCode = 'US';
        final charts = [{'name': 'Top 100'}];
        
        when(mockApiService.getCharts(countryCode: countryCode))
            .thenAnswer((_) async => charts);

        // Act
        final result = await repository.getCharts(countryCode: countryCode);

        // Assert
        expect(result, equals(charts));
        verify(mockApiService.getCharts(countryCode: countryCode)).called(1);
      });

      test('should use default country code when not provided', () async {
        // Arrange
        final charts = [{'name': 'Top 100'}];
        
        when(mockApiService.getCharts(countryCode: 'vi'))
            .thenAnswer((_) async => charts);

        // Act
        final result = await repository.getCharts();

        // Assert
        expect(result, equals(charts));
        verify(mockApiService.getCharts(countryCode: 'vi')).called(1);
      });
    });
  });
}