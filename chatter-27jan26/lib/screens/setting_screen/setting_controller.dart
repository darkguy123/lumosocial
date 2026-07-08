import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:lumosocial/common/api_service/notification_service.dart';
import 'package:lumosocial/common/api_service/user_service.dart';
import 'package:lumosocial/common/controller/base_controller.dart';
import 'package:lumosocial/common/managers/firebase_notification_manager.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/common/managers/subscription_manager.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/screens/login_screen/login_screen.dart';
import 'package:lumosocial/screens/room_invitation_screen/room_invitation_screen.dart';
import 'package:lumosocial/screens/rooms_you_own/rooms_you_own_screen.dart';
import 'package:lumosocial/screens/sheets/confirmation_sheet.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:get_storage/get_storage.dart';

class SettingController extends BaseController {
  bool isNotification = SessionManager.shared.getUser()?.isPushNotifications == 1 ? true : false;
  bool isGetInvited = SessionManager.shared.getUser()?.isInvitedToRoom == 1 ? true : false;
  bool isAutoplayVideos = GetStorage().read('lumo_autoplay_videos') ?? true;
  String notificationID = "notificationID";
  String getInvitedID = "getInvitedID";
  String autoplayVideosID = "autoplayVideosID";
  String version = "";

  @override
  void onReady() {
    PackageInfo.fromPlatform().then((packageInfo) {
      String version = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;
      print("$version $buildNumber");
      this.version = "$version ($buildNumber)";
      update(['version']);
    });
    super.onReady();
  }

  void changeOfNotification(bool value) {
    isNotification = value;
    update([notificationID]);
    UserService.shared.editProfile(
      isPushNotifications: isNotification,
      completion: (p0) {},
    );
    if (value) {
      NotificationService.shared.subscribeToAllMyRoom();
      FirebaseNotificationManager.shared.subscribeToTopic(notificationTopic);
    } else {
      NotificationService.shared.unsubscribeToAllMyRoom();
      FirebaseNotificationManager.shared.unsubscribeToTopic(notificationTopic);
    }
  }

  void changeOfGetInvited(bool value) {
    isGetInvited = value;
    update([getInvitedID]);
    UserService.shared.editProfile(
      isInvitedToRoom: isGetInvited,
      completion: (p0) {},
    );
  }

  void changeOfAutoplayVideos(bool value) {
    isAutoplayVideos = value;
    GetStorage().write('lumo_autoplay_videos', value);
    update([autoplayVideosID]);
  }

  void tapRoomsYouOwn() {
    Get.to(() => const RoomsYouOwnScreen());
  }

  void tapRoomInvitation() {
    Get.to(() => const RoomInvitationScreen());
  }

  void deleteAccount() {
    Get.bottomSheet(ConfirmationSheet(
        desc: LKeys.deleteAccDesc,
        buttonTitle: LKeys.delete,
        onTap: () {
          startLoading();
          UserService.shared.deleteUser(() {
            FirebaseAuth.instance.currentUser?.delete();
            cleanAllSession();
            Get.offAll(() => const LoginScreen());
          });
        }));
  }

  void logout() {
    Get.bottomSheet(ConfirmationSheet(
        desc: LKeys.logoutDesc,
        buttonTitle: LKeys.logOut,
        onTap: () {
          startLoading();
          UserService.shared.logOut(() {
            FirebaseAuth.instance.signOut();
            cleanAllSession();
            Get.offAll(() => const LoginScreen());
          });
        }));
  }

  void cleanAllSession() {
    SessionManager.shared.setLogin(false);

    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    FirebaseNotificationManager.shared.subscribeToTopic(notificationTopic);
    NotificationService.shared.unsubscribeToAllMyRoom();
    SessionManager.shared.setUser(null);
    if (isPurchaseConfig) {
      Purchases.logOut();
    }
    googleSignIn.signOut();
    stopLoading();
  }
}
