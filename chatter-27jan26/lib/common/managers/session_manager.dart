import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:untitled/localization/allLanguages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/setting_model.dart';

class SessionManager {
  static var shared = SessionManager();
  var storage = GetStorage();
  var conversationId = '';

  void setLang(Lang lang) {
    storage.write("lang", lang.language.languageCode);
  }

  Lang getLang() {
    return LANGUAGES.firstWhere((element) => element.language.languageCode == (storage.read("lang") ?? LANGUAGES.first.language.languageCode));
  }

  String getStoredConversation() {
    return conversationId;
  }

  void setStoredConversation(String conversation) {
    conversationId = conversation;
  }

  DateTime? getLastMessageReadDate({required String spaceId}) {
    var date = storage.read(spaceId);
    if (date is DateTime)
      return date;
    else
      return null;
  }

  void setLastMessageReadDate({required String spaceId}) {
    storage.write(spaceId, DateTime.now());
  }

  bool isLogin() {
    return storage.read(SessionKeys.isLogin) ?? false;
  }

  void setUsersForGroup({required String conversationId, required List<User> users}) {
    storage.write(conversationId, users);
  }

  List<User> getUsersForGroup({required String conversationId}) {
    var users = storage.read(conversationId);
    if (users is List<User>) {
      return users;
    } else if (users is List<dynamic>) {
      return users.map((user) => User.fromJson(user)).toList();
    }
    return [];
  }

  void setLogin(bool isLog) {
    storage.write(SessionKeys.isLogin, isLog);
  }

  void setUser(User? obj) {
    storage.write("user", obj);
  }

  User? getUser() {
    var user = storage.read("user");
    if (user is User?) {
      return user;
    } else {
      return User.fromJson(user);
    }
  }

  int getUserID() {
    return (getUser()?.id ?? 0).toInt();
  }

  void setSettings(Settings settings) {
    storage.write("setting", settings);
  }

  Settings? getSettings() {
    var data = storage.read("setting");
    if (data is Map<String, dynamic>) {
      return Settings.fromJson(data);
    } else if (data is Settings) {
      return data;
    }
    return null;
  }

  String getBannerAdId() {
    return (Platform.isAndroid ? (getSettings()?.adBannerAndroid) : (getSettings()?.adBannerIOs)) ?? '';
  }

  String getInterstitialAdId() {
    return (Platform.isAndroid ? (getSettings()?.adInterstitialAndroid) : (getSettings()?.adInterstitialIOs)) ?? '';
  }

  bool isAdMobOn() {
    return getSettings()?.isAdmobOn == 1 ? true : false;
  }

  void clear() {
    storage.erase();
  }
}

class SessionKeys {
  static const isLogin = "isLogin";
}
