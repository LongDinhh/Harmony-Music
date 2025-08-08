# Migration từ APIService sang dart_ytmusic_api Package

## Tóm tắt thay đổi

Đã thực hiện migration từ API service tự build (`lib/services/api_service.dart`) sang sử dụng package `dart_ytmusic_api` version 1.2.1.

## Files đã thay đổi

### 1. Tạo mới: `lib/services/dart_ytmusic_api_service.dart`
- **Mục đích**: Service wrapper mới sử dụng `dart_ytmusic_api` package
- **Implement**: Interface `IAPIService` để duy trì backward compatibility
- **Features**:
  - Singleton pattern với lazy initialization
  - Error handling với `AppErrorHandler`
  - Transform methods để convert data format từ package sang format mong đợi
  - Implement đầy đủ tất cả methods trong `IAPIService`

### 2. Cập nhật: `lib/services/music_service.dart`
- **Thay đổi**: 
  - Import `dart_ytmusic_api_service.dart`
  - Thay đổi `APIService` thành `IAPIService` type
  - Update initialization để sử dụng `DartYTMusicAPIService.instance`
  - Update lazy getter cho `apiService`

### 3. Cập nhật: `lib/services/service_registry.dart`
- **Thay đổi**: Thêm import cho `dart_ytmusic_api_service.dart`

## Mapping API Methods

| Original APIService Method | DartYTMusicAPIService Implementation | Notes |
|---------------------------|-----------------------------------|-------|
| `getHomeData()` | `ytMusic.getHome()` | Transform data format |
| `getCharts()` | `ytMusic.getCharts()` | Support country parameter |
| `getWatchPlaylist()` | `ytMusic.getWatchPlaylist()` | Map parameters |
| `getPlaylistOrAlbumSongs()` | `ytMusic.getPlaylist()` / `ytMusic.getAlbum()` | Route based on type |
| `getSearchSuggestion()` | `ytMusic.getSearchSuggestions()` | Transform to string list |
| `search()` | `ytMusic.search()` | Map filter và parameters |
| `getArtist()` | `ytMusic.getArtist()` | Direct mapping |
| `getSongYear()` | `ytMusic.getSong()` + extract year | Custom extraction logic |
| `getSongWithId()` | `ytMusic.getSong()` | Format return value |
| `getContentRelatedToSong()` | `ytMusic.getSongRelated()` | Transform related content |
| `getLyrics()` | `ytMusic.getLyrics()` | Direct mapping |
| `getAlbumBrowseId()` | `ytMusic.getAlbumBrowseId()` | Direct mapping |

## Các tính năng cần implement thêm

1. **Transform methods**: Các helper methods `_transform*Data()` cần được implement chi tiết dựa trên actual data structure của `dart_ytmusic_api`

2. **Artist related content**: Method `getArtistRealtedContent()` có thể cần implementation chi tiết hơn

3. **Search continuation**: Method `getSearchContinuation()` cần implement pagination logic

4. **Authentication**: Có thể cần setup authentication/cookies cho `dart_ytmusic_api`

## Lợi ích của migration

1. **Maintenance**: Sử dụng package được maintain bởi community thay vì tự build
2. **Features**: Có thể access các features mới của package
3. **Reliability**: Package đã được test và sử dụng bởi nhiều projects
4. **Updates**: Tự động nhận updates và bug fixes từ package

## Backward Compatibility

- ✅ Giữ nguyên interface `IAPIService`
- ✅ Tất cả existing code sử dụng `MusicServices.apiService` vẫn hoạt động
- ✅ Không cần thay đổi UI components
- ✅ Error handling pattern giữ nguyên

## Testing

Cần test các scenarios sau:

1. **Basic functionality**: Tất cả API methods hoạt động
2. **Error handling**: Error cases được handle đúng cách
3. **Data format**: Transform methods trả về đúng format
4. **Performance**: So sánh performance với implementation cũ
5. **Authentication**: Verify authentication flow hoạt động

## Rollback Plan

Nếu cần rollback:

1. Revert changes trong `music_service.dart` để sử dụng `APIService.instance`
2. Revert changes trong `service_registry.dart`
3. Remove `dart_ytmusic_api_service.dart`
4. Existing `api_service.dart` vẫn intact và có thể sử dụng lại

## Next Steps

1. ✅ Implement basic service wrapper
2. ✅ Update service dependencies
3. 🔄 Test basic functionality
4. ⏳ Implement detailed transform methods
5. ⏳ Add authentication support if needed
6. ⏳ Performance testing
7. ⏳ Production deployment

---

**Created**: $(date)
**Status**: In Progress
**Author**: AI Assistant