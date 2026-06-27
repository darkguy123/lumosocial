import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:chatter/common/managers/logger.dart';
import 'package:chatter/common/managers/session_manager.dart';
import 'package:chatter/utilities/const.dart';
import 'package:chatter/utilities/params.dart';

class FirebaseNotificationManager {
  static var shared = FirebaseNotificationManager();
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chatter', // id
      'Chatter Notification', // title
      playSound: true,
      enableLights: true,
      enableVibration: true,
      importance: Importance.max);

  String newMessageId = '';

  void init() async {
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, sound: true);

    await firebaseMessaging.requestPermission(alert: true, badge: false, sound: true);
    Loggers.success("NOTIFICATION DOOOOOOOOONE");

    var initializationSettingsAndroid = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    var initializationSettingsIOS = const DarwinInitializationSettings(defaultPresentAlert: true, defaultPresentSound: true, defaultPresentBadge: false);

    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data[Param.conversationId] == SessionManager.shared.getStoredConversation()) {
        print('In Same Chat');
        return;
      }
      if (message.messageId != newMessageId || Platform.isAndroid) {
        newMessageId = message.messageId!;
        print('Notification: ${message.messageId}');
        showNotification(message);
      }
    });

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    getNotificationToken(
      (token) {},
    );
    subscribeToTopic(notificationTopic);
  }

  void showNotification(RemoteMessage message) {
    flutterLocalNotificationsPlugin.show(
      1,
      message.data['title'],
      message.data['body'],
      NotificationDetails(iOS: const DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: false), android: AndroidNotificationDetails(channel.id, channel.name)),
    );
  }

  void getNotificationToken(Function(String token) completion) {
    try {
      FirebaseMessaging.instance.getToken().then(
        (value) {
          if (value?.isEmpty == true || value == null) {
            Loggers.error('Token: $value');
            completion('No Token');
          } else {
            Loggers.success('Token: $value');
            completion(value);
          }
        },
        onError: (e) {
          completion('No Token');
        },
      );
    } catch (e) {
      completion('No Token');
    }
  }

  void subscribeToTopic(String topic) async {
    var user = SessionManager.shared.getUser();
    if (user == null || user.isPushNotifications == 1) {
      await firebaseMessaging.subscribeToTopic('${topic}_${Platform.isIOS ? 'ios' : 'android'}').onError((error, stackTrace) {
        print(error);
      });

      if (kDebugMode) await firebaseMessaging.subscribeToTopic('test_${topic}_${Platform.isIOS ? 'ios' : 'android'}');
    }
  }

  void unsubscribeToTopic(String topic) async {
    await firebaseMessaging.unsubscribeFromTopic('${topic}_${Platform.isIOS ? 'ios' : 'android'}');

    if (kDebugMode) await firebaseMessaging.subscribeToTopic('test_${topic}_${Platform.isIOS ? 'ios' : 'android'}');
  }

  bool hasListenerSet = false;

  void setupListener() async {
    if (hasListenerSet) {
      return;
    }
    ;
    hasListenerSet = true;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("notification aavi: ${message.toMap()}");

      if (message.data[Param.conversationId] == SessionManager.shared.getStoredConversation()) {
        print('In Same Chat');
        return;
      }

      if (message.messageId != newMessageId || Platform.isAndroid) {
        newMessageId = message.messageId!;
        print('Notification: ${message.messageId}');
        showNotification(message);
      }
    });
  }
}
