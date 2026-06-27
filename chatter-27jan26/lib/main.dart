import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:untitled/common/managers/firebase_notification_manager.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/subscription_manager.dart';
import 'package:untitled/common/widgets/functions.dart';
import 'package:untitled/localization/allLanguages.dart';
import 'package:untitled/screens/splash_screen/splash_screen_view.dart';
import 'package:untitled/utilities/const.dart';

import 'common/managers/ads/interstitial_manager.dart';
import 'localization/languages.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Loggers.success("Handling a background message: ${message.data}");
  await Firebase.initializeApp();
  FirebaseNotificationManager.shared.showNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp();
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await GetStorage.init();
  SessionManager.shared;
  InterstitialManager.shared;
  await AppTrackingTransparency.requestTrackingAuthorization();
  PackageInfo.fromPlatform();
  SubscriptionManager.shared.initPlatformState();
  MobileAds.instance.initialize();
  (await AudioSession.instance).configure(const AudioSessionConfiguration.speech());

  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.library == 'image resource service' && (details.exception.toString().contains('404') || details.exception.toString().contains('403'))) {
      return;
    }

    FlutterError.presentError(details);
  };
  // fvp.registerWith();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Functions.changStatusBar(StatusBarStyle.black);
    Lang lang = SessionManager.shared.getLang();

    return GetMaterialApp(
      translations: Languages(),
      locale: lang.language.local,
      builder: (context, child) {
        return ScrollConfiguration(behavior: MyScrollBehavior(), child: child!);
      },
      fallbackLocale: LANGUAGES.first.language.local,
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: ThemeData(useMaterial3: false, highlightColor: Colors.transparent, splashColor: Colors.transparent),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SplashScreenView(),
    );
  }
}

class MyScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
