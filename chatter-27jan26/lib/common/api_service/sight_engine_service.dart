import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/sight_engine_models/sight_engine_media_model.dart';
import 'package:untitled/models/sight_engine_models/text_moderation_model.dart';
import 'package:untitled/utilities/const.dart';

class SightEngineService {
  static var shared = SightEngineService();

  Future<void> checkImageInSightEngine({required XFile xFile, required Function() completion}) async {
    if (SessionManager.shared.getSettings()?.isSightEngineEnabled == 0) {
      completion();
      return;
    }

    File file = File(xFile.path);
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.sightengine.com/1.0/check-workflow.json'),
    );
    request.fields['workflow'] = SessionManager.shared.getSettings()?.sightEngineImageWorkflowId ?? '';
    request.fields['api_user'] = SessionManager.shared.getSettings()?.sightEngineApiUser ?? '';
    request.fields['api_secret'] = SessionManager.shared.getSettings()?.sightEngineApiSecret ?? '';

    request.files.add(
      http.MultipartFile('media', file.readAsBytes().asStream(), file.lengthSync(), filename: file.path.split("/").last),
    );

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    SightEngineMediaModel sightEngineMediaModel = SightEngineMediaModel.fromJson(jsonDecode(respStr));
    print(jsonDecode(respStr));
    if (sightEngineMediaModel.error != null) {
      BaseController.share.stopLoading();
      BaseController.share.showSnackBar(sightEngineMediaModel.error?.message ?? '', type: SnackBarType.error);
      return;
    }
    var result = sightEngineMediaModel.summary?.action ?? '';
    if (result == 'accept') {
      completion();
    } else if (result == 'reject') {
      var summaryDescription = sightEngineMediaModel.summary?.rejectReason?.map((e) => e.text ?? '').join(', ') ?? '';
      BaseController.share.stopLoading();
      BaseController.share.materialSnackBar('${LKeys.mediaRejectedAndContainsSuchThings.tr} $summaryDescription', type: SnackBarType.error);
    }
  }

  Future<void> checkVideoInSightEngine({required XFile xFile, required int duration, required Function() completion}) async {
    if (SessionManager.shared.getSettings()?.isSightEngineEnabled == 0) {
      completion();
      return;
    }

    File file = File(xFile.path);

    if (duration > Limits.sightEngineCropSec) {
      final videoTrimmer = VideoTrimmer();
      await videoTrimmer.loadVideo(file.path);
      final trimmedPath = await videoTrimmer.trimVideo(
        startTimeMs: 0,
        endTimeMs: Limits.sightEngineCropSec * 1000,
        includeAudio: false,
      );
      print(trimmedPath);
      file = File(trimmedPath ?? '');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.sightengine.com/1.0/video/check-workflow-sync.json'),
    );
    request.fields['workflow'] = SessionManager.shared.getSettings()?.sightEngineVideoWorkflowId ?? '';
    request.fields['api_user'] = SessionManager.shared.getSettings()?.sightEngineApiUser ?? '';
    request.fields['api_secret'] = SessionManager.shared.getSettings()?.sightEngineApiSecret ?? '';

    request.files.add(
      http.MultipartFile('media', file.readAsBytes().asStream(), file.lengthSync(), filename: file.path.split("/").last),
    );

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    SightEngineMediaModel sightEngineMediaModel = SightEngineMediaModel.fromJson(jsonDecode(respStr));
    print(jsonDecode(respStr));
    if (sightEngineMediaModel.error != null) {
      BaseController.share.stopLoading();
      BaseController.share.showSnackBar(sightEngineMediaModel.error?.message ?? '', type: SnackBarType.error);
      return;
    }
    var result = sightEngineMediaModel.summary?.action ?? '';
    if (result == 'accept') {
      completion();
    } else if (result == 'reject') {
      var summaryDescription = sightEngineMediaModel.summary?.rejectReason?.map((e) => e.text ?? '').join(', ') ?? '';
      BaseController.share.stopLoading();
      BaseController.share.materialSnackBar('${LKeys.mediaRejectedAndContainsSuchThings.tr} $summaryDescription', type: SnackBarType.error);
    }
  }

  Future<void> chooseTextModeration({required String text, required Function() completion}) async {
    if (SessionManager.shared.getSettings()?.isSightEngineEnabled == 0) {
      completion();
      return;
    }
    if (text.isEmpty) {
      completion();
      return;
    }
    var request = http.MultipartRequest('POST', Uri.parse('https://api.sightengine.com/1.0/text/check.json'));
    request.fields.addAll({
      'text': text,
      'lang': 'en,zh,da,nl,fi,fr,de,it,no,pl,pt,es,sv,tl,tr',
      'categories': 'profanity',
      'mode': 'rules',
      'api_user': SessionManager.shared.getSettings()?.sightEngineApiUser ?? '',
      'api_secret': SessionManager.shared.getSettings()?.sightEngineApiSecret ?? '',
    });

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      TextModerationModel textModerationModel = TextModerationModel.fromJson(jsonDecode(respStr));
      List<Matches> matches = textModerationModel.profanity?.matches ?? [];
      print(jsonDecode(respStr));
      if (textModerationModel.error != null) {
        BaseController.share.stopLoading();
        BaseController.share.showSnackBar(textModerationModel.error?.message ?? '', type: SnackBarType.error);
        return;
      }
      List<String> words = [];

      matches.forEach((element) {
        if (element.intensity == 'high' || element.intensity == 'medium') {
          words.add(element.match ?? '');
        }
      });

      if (words.isEmpty) {
        completion();
      } else {
        Get.back();
        log('${LKeys.textRejectedAndContainsSuchThings.tr} ${words.join(', ')}');
        BaseController.share.showSnackBar('${LKeys.textRejectedAndContainsSuchThings.tr} ${words.join(', ')}', type: SnackBarType.error);
      }
    } else {
      log(response.reasonPhrase ?? '');
    }
  }
}
