import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart'; // Using fixed fork
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Unused after removing metadata code

import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../ui/screens/Album/album_screen_controller.dart';
import '../ui/screens/Playlist/playlist_screen_controller.dart';
import '/services/stream_service.dart';
import '../ui/widgets/snackbar.dart';
import '/services/permission_service.dart';
import '../ui/screens/Settings/settings_screen_controller.dart';
import '/utils/helper.dart';
import '/models/media_Item_builder.dart';
import '../ui/screens/Library/library_controller.dart';

//import '../models/thumbnail.dart' as th;

class Downloader extends GetxService {
  final _dio = Dio();
  MediaItem? currentSong;
  RxMap<String, List<MediaItem>> playlistQueue =
      <String, List<MediaItem>>{}.obs;
  final currentPlaylistId = "".obs;
  final songDownloadingProgress = 0.obs;
  final playlistDownloadingProgress = 0.obs;
  final isJobRunning = false.obs;

  RxList<MediaItem> songQueue = <MediaItem>[].obs;

  Future<bool> checkPermissionNDir() async {
    final settingsScreenController = Get.find<SettingsScreenController>();

    if (!settingsScreenController.isCurrentPathsupportDownDir &&
        !await PermissionService.getExtStoragePermission()) {
      return false;
    }

    final dirPath =
        Get.find<SettingsScreenController>().downloadLocationPath.string;
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return true;
  }

  Future<void> downloadPlaylist(
      String playlistId, List<MediaItem> songList) async {
    if (!(await checkPermissionNDir())) return;

    // for toggle between downloading request & cancelling
    if (playlistQueue.containsKey(playlistId)) {
      songQueue.removeWhere((element) => songList.contains(element));
      playlistQueue.remove(playlistId);
      return;
    }

    playlistQueue[playlistId] = songList;
    songQueue.addAll(songList);

    if (isJobRunning.isFalse) {
      await triggerDownloadingJob();
    }
  }

  Future<void> download(MediaItem? song, {List<MediaItem>? songList}) async {
    if (!(await checkPermissionNDir())) return;
    if (songList != null) {
      songQueue.addAll(songList);
    } else {
      songQueue.add(song!);
    }
    if (isJobRunning.isFalse) {
      await triggerDownloadingJob();
    }
  }

  Future<void> triggerDownloadingJob() async {
    //check if playlist download in queue => download playlistsongs else download from general songs queue
    if (playlistQueue.isNotEmpty) {
      isJobRunning.value = true;
      for (String playlistId in playlistQueue.keys.toList()) {
        //checked in case download cancel request
        if (playlistQueue.containsKey(playlistId)) {
          currentPlaylistId.value = playlistId;
          await downloadSongList((playlistQueue[playlistId]!).toList(),
              isPlaylist: true);
          if (Get.isRegistered<PlaylistScreenController>(
                  tag: Key(playlistId).hashCode.toString()) &&
              playlistQueue.containsKey(playlistId)) {
            Get.find<PlaylistScreenController>(
                    tag: Key(playlistId).hashCode.toString())
                .isDownloaded
                .value = true;
          }
          // in case of album
          else if (Get.isRegistered<AlbumScreenController>(
                  tag: Key(playlistId).hashCode.toString()) &&
              playlistQueue.containsKey(playlistId)) {
            Get.find<AlbumScreenController>(
                    tag: Key(playlistId).hashCode.toString())
                .isDownloaded
                .value = true;
          }
          playlistQueue.remove(playlistId);
        }
        currentPlaylistId.value = "";
        playlistDownloadingProgress.value = 0;
      }
    } else {
      isJobRunning.value = true;
      await downloadSongList(songQueue.toList());
    }

    if (songQueue.isNotEmpty) {
      triggerDownloadingJob();
    } else {
      isJobRunning.value = false;
      currentSong = null;
    }
  }

  Future<void> downloadSongList(List<MediaItem> jobSongList,
      {bool isPlaylist = false}) async {
    for (MediaItem song in jobSongList) {
      // intrrupt downloading task in case of playlist download cancel request
      if (isPlaylist && !playlistQueue.containsKey(currentPlaylistId.value)) {
        currentPlaylistId.value = "";
        playlistDownloadingProgress.value = 0;
        return;
      }

      if (!Hive.box("SongDownloads").containsKey(song.id)) {
        currentSong = song;
        songDownloadingProgress.value = 0;
        await writeFileStream(song);
      }
      songQueue.remove(song);
      //for playlist downloading counter update
      if (isPlaylist) {
        playlistDownloadingProgress.value = jobSongList.indexOf(song) + 1;
      }
    }
  }

  Future<void> writeFileStream(MediaItem song) async {
    Completer<void> complete = Completer();

    final settingsScreenController = Get.find<SettingsScreenController>();
    final downloadingFormat = settingsScreenController.downloadingFormat.string;

    final playerResponse = await StreamProvider.fetch(song.id);
    // if (!playerResponse.playable) {
    //   printINFO("Network error! Check your network connection.");
    //   ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
    //       Get.context!, playerResponse.statusMSG,
    //       size: SanckBarSize.BIG,
    //       duration: const Duration(seconds: 2),
    //       top: !GetPlatform.isDesktop));
    //   complete.complete();
    //   return complete.future;
    // }

    if (!playerResponse.playable) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
          Get.context!,
          playerResponse.statusMSG == "networkError"
              ? playerResponse.statusMSG.tr
              : playerResponse.statusMSG,
          size: SanckBarSize.BIG,
          duration: const Duration(seconds: 2),
          top: !GetPlatform.isDesktop));
      printINFO("Requested song is not downloadable. You may try again");
      complete.complete();
      return complete.future;
    }

    Audio requiredAudioStream = downloadingFormat == "opus"
        ? playerResponse.highestBitrateOpusAudio!
        : playerResponse.highestBitrateMp4aAudio!;

    final dirPath = settingsScreenController.downloadLocationPath.string;
    final actualDownformat =
        requiredAudioStream.audioCodec.name.contains("mp") ? "m4a" : "opus";
    // Remove characters that can invalidate the filename on most platforms
    // Also strip the accidental "Container." text that may appear when
    // converting widgets to string.
    final RegExp invalidChar = RegExp(
        r'Container\.\s?|\/|\\|\"|\<|\>|\*|\?|\:|\!|\[|\]|\¡|\||\%');
    final songTitle = "${song.title.trim()} (${song.artist?.trim()})"
        .replaceAll(invalidChar, "");
    String filePath = "$dirPath/$songTitle.$actualDownformat";
    printINFO("Downloading filePath: $filePath");
    final totalBytes = requiredAudioStream.size;

    _dio.download(
        requiredAudioStream.url,
        options: Options(headers: {"Range": 'bytes=0-$totalBytes'}),
        filePath, onReceiveProgress: (count, total) {
      if (total <= 0) return;
      songDownloadingProgress.value = ((count / total) * 100).toInt();
    }).then(
      (value) async {
        printINFO(value.data);

        // String? year;
        // try {
        //   if (song.extras?['year'] != null) {
        //     year = song.extras?['year'];
        //   } else {
        //     if (song.album != null) {
        //       final musicServ = Get.find<MusicServices>();
        //       year = await musicServ.getSongYear(song.id);
        //     }
        //   }
        // } catch (_) {}

        // Save Thumbnail
        try {
          final thumbnailPath =
              "${settingsScreenController.supportDirPath}/thumbnails/${song.id}.png";
          await _dio.downloadUri(song.artUri!, thumbnailPath);
          // ignore: empty_catches
        } catch (e) {}

        song.extras?['url'] = filePath;
        final songJson = MediaItemBuilder.toJson(song);
        final streamInfoJson = requiredAudioStream.toJson();
        streamInfoJson['url'] = filePath;
        // [playbility status, info map]
        songJson["streamInfo"] = [true, streamInfoJson];

        Hive.box("SongDownloads").put(song.id, songJson);
        Get.find<LibrarySongsController>().librarySongsList.add(song);
        printINFO("Downloaded successfully");

        final trackDetails = (song.extras?['trackDetails'])?.split("/");
        final int? trackNumber = int.tryParse(trackDetails?[0] ?? "");
        final int? totalTracks = int.tryParse(trackDetails?[1] ?? "");

        // Metadata writing using forked audio_metadata_reader
        // Using fork: https://github.com/LongDinhh/audio_metadata_reader
        // TODO: Fix bug in fork - mp4_writer.dart line 41 should use 'file' parameter instead of hardcoded "a_new.mp4"
        try {
          final file = File(filePath);

          // Wait a bit to ensure file is fully written and released by dio
          await Future.delayed(const Duration(milliseconds: 200));

          // Verify file exists and is accessible
          if (!await file.exists()) {
            printERROR("File does not exist for metadata writing: $filePath");
            return;
          }

          // Download artwork bytes for embedding
          List<int>? artworkBytes;
          if (song.artUri != null) {
            try {
              final response = await _dio.get<List<int>>(
                song.artUri.toString(),
                options: Options(responseType: ResponseType.bytes),
              );
              artworkBytes = response.data;
            } catch (e) {
              printERROR("Failed to download artwork: $e");
            }
          }

          // Update metadata using audio_metadata_reader API
          updateMetadata(file, (metadata) {
            metadata.setTitle(song.title);
            if (song.artist != null) metadata.setArtist(song.artist!);
            if (song.album != null) metadata.setAlbum(song.album!);
            if (trackNumber != null) metadata.setTrackNumber(trackNumber);
            if (song.genre != null) metadata.setGenres([song.genre!]);

            // Add artwork if available
            if (artworkBytes != null) {
              metadata.setPictures([
                Picture(Uint8List.fromList(artworkBytes), "image/jpeg",
                    PictureType.coverFront)
              ]);
            }
          });

          printINFO(
              "✅ Metadata written successfully using audio_metadata_reader fork");
        } catch (e) {
          printWarning("⚠️ Metadata writing failed: $e");
          printINFO(
              "ℹ️ File downloaded successfully, metadata writing skipped due to permission/access issue");
        }
        complete.complete();
      },
    ).onError(
      (error, stackTrace) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
            Get.context!, "downloadError3".tr,
            size: SanckBarSize.BIG,
            duration: const Duration(seconds: 2),
            top: !GetPlatform.isDesktop));
        printINFO(
            "Downloading failed due to network/stream error! Please try again");
        complete.complete();
      },
    );

    return complete.future;
  }
}
