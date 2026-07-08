import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/managers/logger.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/screens/chats_screen/calling/voice_call_screen.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/utilities/params.dart';
import 'package:lumosocial/screens/chats_screen/chatting_screen/chatting_view.dart';
import 'package:lumosocial/screens/dashboard_reels_screen/live_tv_screen.dart';
import 'package:lumosocial/screens/single_reel_screen/single_reel_screen.dart';
import 'package:lumosocial/screens/single_post_screen/single_post_screen.dart';
import 'package:lumosocial/screens/rooms_screen/single_room/single_room_screen.dart';
import 'package:lumosocial/screens/profile_screen/profile_screen.dart';
import 'package:lumosocial/models/registration.dart';

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

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data[Param.conversationId] == SessionManager.shared.getStoredConversation()) {
        print('In Same Chat');
        return;
      }
      if (message.messageId != newMessageId || Platform.isAndroid) {
        newMessageId = message.messageId!;
        print('Notification: ${message.messageId}');
        await showNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(message);
      }
    });

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    getNotificationToken(
      (token) {},
    );
    subscribeToTopic(notificationTopic);
  }

  void _handleNotificationClick(RemoteMessage message) {
    final type = message.data['type']?.toString();
    final postId = message.data['postId'];
    final reelId = message.data['reelId'];
    final roomId = message.data['roomId'];
    final userId = message.data['userId'];

    if (type == 'call') {
      Get.to(() => VoiceCallScreen(
        callId: message.data['callId'] ?? '',
        channelId: message.data['channelId'] ?? '',
        callerId: int.tryParse(message.data['callerId']?.toString() ?? '0') ?? 0,
        callerName: message.data['callerName'] ?? 'Chatter User',
        callerImage: message.data['callerImage'] ?? '',
        isIncoming: true,
      ));
    } else if (reelId != null) {
      Get.to(() => SingleReelScreen(reelId: int.tryParse(reelId.toString()) ?? 0));
    } else if (postId != null) {
      Get.to(() => SinglePostScreen(postId: int.tryParse(postId.toString()) ?? 0));
    } else if (roomId != null) {
      Get.to(() => SingleRoomScreen(roomId: int.tryParse(roomId.toString()) ?? 0));
    } else if (type == 'chat' && userId != null) {
      Get.to(() => ChattingView(user: User(id: int.tryParse(userId.toString()))));
    } else if (type == 'live_match') {
      Get.to(() => const LiveTvScreen());
    } else if (userId != null) {
      Get.to(() => ProfileScreen(userId: int.tryParse(userId.toString()) ?? 0));
    }
  }

  Future<void> _ensureLocalNotificationsInitialized() async {
    var initializationSettingsAndroid = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    var initializationSettingsIOS = const DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: false,
    );
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(RemoteMessage message) async {
    String? title = message.data['title'] ?? message.notification?.title;
    String? body = message.data['body'] ?? message.notification?.body;
    if (title == null && body == null) return;

    await _ensureLocalNotificationsInitialized();

    final isCall = message.data['type'] == 'call';

    await flutterLocalNotificationsPlugin.show(
      isCall ? 999 : 1,
      title,
      body,
      NotificationDetails(
        iOS: const DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: false),
        android: AndroidNotificationDetails(
          isCall ? 'call_channel' : channel.id,
          isCall ? 'Calls' : channel.name,
          importance: isCall ? Importance.max : Importance.defaultImportance,
          priority: isCall ? Priority.high : Priority.defaultPriority,
          fullScreenIntent: isCall,
          ongoing: isCall,
        ),
      ),
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("notification aavi: ${message.toMap()}");

      if (message.data[Param.conversationId] == SessionManager.shared.getStoredConversation()) {
        print('In Same Chat');
        return;
      }

      if (message.messageId != newMessageId || Platform.isAndroid) {
        newMessageId = message.messageId!;
        print('Notification: ${message.messageId}');
        await showNotification(message);
      }
    });
  }
}
