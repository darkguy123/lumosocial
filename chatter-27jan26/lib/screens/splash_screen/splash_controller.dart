import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:untitled/common/api_service/common_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/screens/block_by_admin_screen/block_by_admin_screen.dart';
import 'package:untitled/screens/interests_screen/interests_screen.dart';
import 'package:untitled/screens/maintenance_screen/maintenance_screen.dart';
import 'package:untitled/screens/on_boarding_screen/on_boarding_screen.dart';
import 'package:untitled/screens/profile_picture_screen/profile_picture_screen.dart';
import 'package:untitled/screens/tabbar/tabbar_screen.dart';
import 'package:untitled/screens/update_screen/update_app_screen.dart';
import 'package:untitled/screens/username_screen/username_screen.dart';

class SplashController extends BaseController {
  @override
  void onInit() {
    fetchSettings();
    super.onInit();
  }

  void fetchUser(Function() completion) {
    if (SessionManager.shared.getUser()?.id != null) {
      UserService.shared.fetchMyProfile(
        userID: SessionManager.shared.getUser()?.id ?? 0,
        completion: (user) {
          SessionManager.shared.setUser(user);
          completion();
        },
      );
    } else {
      completion();
    }
  }

  void fetchSettings() {
    fetchUser(() {
      CommonService.shared.fetchGlobalSettings((p0) async {
        if (p0) {
          var view = await gotoView();
          Get.offAll(() => view);
        }
      });
    });
  }

  Future<Widget> gotoView() async {
    final settings = SessionManager.shared.getSettings();
    if (settings?.isMaintenanceMode == 1) {
      return MaintenanceScreen();
    }

    if (settings?.isForceAppUpdate == 1) {
      var packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;

      if ((Platform.isAndroid && version != settings?.androidAppVersion) || (Platform.isIOS && version != settings?.iosAppVersion)) {
        return UpdateAppScreen();
      }
    }

    if (SessionManager.shared.isLogin()) {
      var user = SessionManager.shared.getUser();
      if (user?.isBlock == 1) {
        return const BlockedByAdminScreen();
      } else if (user?.interestIds == null) {
        return InterestScreen();
      } else if (user?.username == null) {
        return const UserNameScreen();
      } else if (user?.profile == null) {
        return const ProfilePictureScreen();
      } else {
        return TabBarScreen();
      }
    }
    return const OnBoardingScreen();
  }
}
