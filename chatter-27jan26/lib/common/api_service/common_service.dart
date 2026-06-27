import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:untitled/common/api_service/api_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/agora_token_model.dart';
import 'package:untitled/models/agora_users_model.dart';
import 'package:untitled/models/faq_categories_model.dart';
import 'package:untitled/models/notification_model.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/models/user_notification_model.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

class CommonService {
  static var shared = CommonService();

  void fetchGlobalSettings(Function(bool) completion) {
    ApiService.shared.call(
      url: WebService.fetchSetting,
      completion: (p0) {
        var setting = SettingModel.fromJson(p0).data;
        if (setting != null) {
          SessionManager.shared.setSettings(setting);
          completion(true);
        }
      },
    );
  }

  Future<AgoraUsersModel> agoraListStreamingCheck(String channelName, String authToken, String agoraAppId) async {
    http.Response response = await http.get(Uri.parse('https://api.agora.io/dev/v1/channel/user/$agoraAppId/$channelName'), headers: {'Authorization': 'Basic $authToken'});
    print("URL: ${response.request?.url}");
    print("ChannelName: ${channelName}\n AgoraAppId: ${agoraAppId} \n AuthToken: $authToken}");
    print(response.body);
    return AgoraUsersModel.fromJson(jsonDecode(response.body));
  }

  Future<void> fetchPlatformNotification(int start, Function(List<PlatformNotification> notifications) completion) async {
    var param = {Param.start: start, Param.limit: Limits.pagination};
    await ApiService.shared.call(
      url: WebService.fetchPlatformNotification,
      param: param,
      completion: (response) {
        var notifications = NotificationModel.fromJson(response).data;
        if (notifications != null) {
          completion(notifications);
        }
      },
    );
  }

  void generateAgoraToken({required String channelName, required Function(String) completion}) {
    var param = {Param.channelName: channelName};
    ApiService.shared.call(
      url: WebService.generateAgoraToken,
      param: param,
      completion: (response) {
        var token = AgoraTokenModel.fromJson(response).token;
        if (token != null) {
          completion(token);
        }
      },
    );
  }

  Future<void> fetchUserNotifications(int start, Function(List<UserNotification> notifications) completion) async {
    var param = {Param.start: start, Param.limit: Limits.pagination, Param.myUserId: SessionManager.shared.getUserID()};
    await ApiService.shared.call(
      url: WebService.fetchUserNotification,
      param: param,
      completion: (response) {
        var notifications = UserNotificationModel.fromJson(response).data;
        if (notifications != null) {
          completion(notifications);
        }
      },
    );
  }

  void fetchFAQs(Function(List<FAQsCategory> categories) completion) {
    ApiService.shared.call(
      url: WebService.fetchFAQs,
      completion: (response) {
        var categories = FaqCategoriesModel.fromJson(response).data;
        if (categories != null) {
          completion(categories);
        }
      },
    );
  }
}
