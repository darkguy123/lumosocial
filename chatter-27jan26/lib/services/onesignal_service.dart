import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:lumosocial/widgets/onesignal_verification_sheet.dart';

class OneSignalService {
  static const String appId = "8223666b-99ec-475d-82b8-ba74f01a99bc";
  static bool _hasShownVerificationDialog = false;

  /// Centralized initialization of OneSignal SDK
  static Future<void> initialize() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Initialize OneSignal SDK with project App ID
      OneSignal.initialize(appId);

      // Register Notification Click Handler (App opening when minimized/closed)
      OneSignal.Notifications.addClickListener((event) {
        debugPrint("OneSignal notification clicked: ${event.notification.title}");
      });

      // Register Notification Foreground Display Handler
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint("OneSignal foreground notification: ${event.notification.title}");
        event.notification.display();
      });

      // Setup push subscription observer & verification dialog
      _setupSubscriptionObserver();
    } catch (e) {
      debugPrint("OneSignal initialization failed: $e");
    }
  }

  /// Observe push subscription ID status
  static void _setupSubscriptionObserver() {
    final currentId = OneSignal.User.pushSubscription.id;
    _evaluateSubscriptionId(currentId);

    OneSignal.User.pushSubscription.addObserver((state) {
      final newId = state.current.id;
      _evaluateSubscriptionId(newId);
    });
  }

  /// Evaluate if real server-assigned subscription ID is assigned
  static void _evaluateSubscriptionId(String? subscriptionId) {
    if (subscriptionId != null &&
        subscriptionId.isNotEmpty &&
        !subscriptionId.startsWith('local-') &&
        !_hasShownVerificationDialog) {
      _hasShownVerificationDialog = true;
      _showVerificationDialog();
    }
  }

  /// Required Push Subscription Verification Dialog (Animated Slide-up Sheet)
  static void _showVerificationDialog() {
    Future.delayed(const Duration(milliseconds: 800), () {
      OneSignalVerificationSheet.show();
    });
  }

  /// Request Push Notification Permission
  static Future<void> requestPermission() async {
    await OneSignal.Notifications.requestPermission(true);
  }

  /// Associate user ID & email upon login
  static void loginUser(String userId, {String? email}) {
    try {
      OneSignal.login(userId);
      if (email != null && email.isNotEmpty) {
        OneSignal.User.addEmail(email);
      }
    } catch (e) {
      debugPrint("OneSignal login error: $e");
    }
  }

  /// Add email to user profile
  static void addEmail(String email) {
    try {
      if (email.isNotEmpty) {
        OneSignal.User.addEmail(email);
      }
    } catch (e) {
      debugPrint("OneSignal addEmail error: $e");
    }
  }

  /// Remove email from user profile
  static void removeEmail(String email) {
    try {
      if (email.isNotEmpty) {
        OneSignal.User.removeEmail(email);
      }
    } catch (e) {
      debugPrint("OneSignal removeEmail error: $e");
    }
  }

  /// Clear user session on logout
  static void logoutUser() {
    try {
      OneSignal.logout();
    } catch (e) {
      debugPrint("OneSignal logout error: $e");
    }
  }
}
