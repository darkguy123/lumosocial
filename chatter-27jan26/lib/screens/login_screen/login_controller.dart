import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:lumosocial/common/api_service/notification_service.dart';
import 'package:lumosocial/common/api_service/user_service.dart';
import 'package:lumosocial/common/controller/base_controller.dart';
import 'package:lumosocial/common/managers/firebase_notification_manager.dart';
import 'package:lumosocial/common/managers/logger.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/common/managers/subscription_manager.dart';
import 'package:lumosocial/screens/block_by_admin_screen/block_by_admin_screen.dart';
import 'package:lumosocial/screens/interests_screen/interests_screen.dart';
import 'package:lumosocial/screens/login_screen/sign_in_with_email_screen.dart';
import 'package:lumosocial/screens/profile_picture_screen/profile_picture_screen.dart';
import 'package:lumosocial/screens/tabbar/tabbar_screen.dart';
import 'package:lumosocial/screens/username_screen/username_screen.dart';
import 'package:lumosocial/utilities/const.dart';

class LoginController extends BaseController {
  @override
  void onReady() {
    Loggers.info("TRYING NOTIFICATION");
    FirebaseNotificationManager.shared.init();

    super.onReady();
  }

  Future<String> getWebClientId() async {
    final jsonStr = await rootBundle.loadString('android/app/google-services.json');
    final data = json.decode(jsonStr);

    final oauthClients = data['client'][0]['oauth_client'] as List;
    final webClient = oauthClients.firstWhere((c) => c['client_type'] == 3);

    return webClient['client_id'];
  }

  void emailLogin() {
    Get.bottomSheet(SignInWithEmailScreen(
      onSubmit: (fullName, identity, affiliateId) {
        registerUser(identity: identity, loginType: LoginType.email, fullName: fullName, affiliateId: affiliateId);
      },
    ), isScrollControlled: true, ignoreSafeArea: false);
  }

  void googleLogin() async {
    startLoading();
    try {
      if (!kIsWeb && Platform.isAndroid) {
        String id = await getWebClientId();
        await GoogleSignIn.instance.initialize(serverClientId: id);
      } else {
        await GoogleSignIn.instance.initialize();
      }

      GoogleSignInAccount? googleSignInAccount = await GoogleSignIn.instance.authenticate(scopeHint: ['email']);
      if (googleSignInAccount == null) {
        stopLoading();
        return;
      }
      
      registerUser(
        fullName: googleSignInAccount.displayName,
        identity: googleSignInAccount.email,
        profile: googleSignInAccount.photoUrl,
        loginType: LoginType.google,
      );
    } catch (exception) {
      stopLoading();
      Loggers.error("Google Sign-In error: ${exception.toString()}");
      showSnackBar("Google Sign-In failed: ${exception.toString()}", type: SnackBarType.error);
    }
  }

  void appleLogin() async {
    try {
      AuthorizationCredentialAppleID value = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName]);
      registerUser(fullName: '${value.givenName ?? 'John'} ${value.familyName ?? 'Deo'}', identity: value.userIdentifier ?? '', loginType: LoginType.apple);
    } on SignInWithAppleException catch (exception) {
      log("Something wrong ${exception.toString()}");
    }
  }

  void registerUser({String? fullName, String? profile, String? password, String? affiliateId, required String identity, required LoginType loginType}) {
    startLoading();

    bool hasCompleted = false;
    void safeStopLoading() {
      if (!hasCompleted) {
        hasCompleted = true;
        stopLoading();
      }
    }

    // Backup safety timer to prevent infinite loading state
    Future.delayed(const Duration(seconds: 15), () {
      if (!hasCompleted) {
        safeStopLoading();
        showSnackBar("Login operation timed out. Please try again.", type: SnackBarType.error);
      }
    });

    try {
      FirebaseNotificationManager.shared.getNotificationToken((token) {
        UserService.shared.registration(
          name: fullName,
          profile: profile,
          password: password,
          affiliateId: affiliateId,
          identity: identity,
          deviceToken: token,
          loginType: loginType,
          onError: (errorMsg) {
            safeStopLoading();
            showSnackBar(errorMsg, type: SnackBarType.error);
          },
          completion: (p0) {
            hasCompleted = true;
            SessionManager.shared.setLogin(true);

            Widget w = InterestScreen();
            var user = p0.data;
            if (isPurchaseConfig) {
              try {
                Purchases.logIn('${user?.id ?? 0}');
              } catch (_) {}
            }
            if (user?.isPushNotifications == 1) {
              try {
                FirebaseNotificationManager.shared.subscribeToTopic(notificationTopic);
                NotificationService.shared.subscribeToAllMyRoom();
              } catch (_) {}
            }
            if (user?.isBlock == 1) {
              w = const BlockedByAdminScreen();
            } else if (user?.interestIds == null) {
              w = InterestScreen();
            } else if (user?.username == null) {
              w = const UserNameScreen();
            } else if (user?.profile == null) {
              w = const ProfilePictureScreen();
            } else {
              w = TabBarScreen();
            }
            Get.offAll(() => w);
            stopLoading();
          },
        );
      });
    } catch (e) {
      safeStopLoading();
      showSnackBar("Login error: ${e.toString()}", type: SnackBarType.error);
    }
  }
}

enum LoginType {
  google(0),
  apple(1),
  email(2);

  const LoginType(this.value);

  final int value;
}
