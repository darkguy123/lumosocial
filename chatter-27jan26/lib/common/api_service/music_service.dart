import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/models/music_categories_model.dart';
import 'package:lumosocial/models/musics_model.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/utilities/params.dart';
import 'package:lumosocial/utilities/web_service.dart';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MusicService {
  static var shared = MusicService();

  static Future<String> resolveYouTubeAudioUrl(String videoId) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      return audioStreamInfo.url.toString();
    } finally {
      yt.close();
    }
  }

  Future<List<Music>> fetchMusicWithSearch(String query, int start) async {
    var param = {Param.keyword: query, Param.start: start, Param.limit: Limits.pagination};
    List<Music> musics = [];
    await ApiService.shared.call(
        url: WebService.fetchMusicWithSearch,
        param: param,
        completion: (response) {
          musics = MusicsModel.fromJson(response).data ?? [];
        });
    return musics;
  }

  Future<List<Music>> fetchSavedMusic() async {
    var param = {Param.userId: SessionManager.shared.getUserID()};
    List<Music> musics = [];
    await ApiService.shared.call(
        url: WebService.fetchSavedMusic,
        param: param,
        completion: (response) {
          musics = MusicsModel.fromJson(response).data ?? [];
        });
    return musics;
  }

  Future<List<MusicCategory>> fetchMusicCategories() async {
    List<MusicCategory> categories = [];
    await ApiService.shared.call(
        url: WebService.fetchMusicCategories,
        completion: (response) {
          categories = MusicCategoriesModel.fromJson(response).data ?? [];
        });
    return categories;
  }

  Future<List<Music>> fetchMusicByCategory({
    required int start,
    required int categoryId,
  }) async {
    var param = {Param.start: start, Param.limit: Limits.pagination, Param.categoryId: categoryId};
    List<Music> musics = [];
    await ApiService.shared.call(
        url: WebService.fetchMusicByCategory,
        param: param,
        completion: (response) {
          musics = MusicsModel.fromJson(response).data ?? [];
        });
    return musics;
  }
}
