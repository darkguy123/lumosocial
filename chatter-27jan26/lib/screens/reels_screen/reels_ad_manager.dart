import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReelsAdManager extends GetxController {
  static ReelsAdManager get instance {
    if (!Get.isRegistered<ReelsAdManager>()) {
      return Get.put(ReelsAdManager(), permanent: true);
    }
    return Get.find<ReelsAdManager>();
  }

  // Session state
  int reelsViewedCount = 0;
  DateTime? lastAdFinishedTime;
  int dailyAdCount = 0;
  String _todayDateStr = '';

  @override
  void onInit() {
    super.onInit();
    _loadDailyCount();
  }

  /// Reset session when user enters/navigates back to Reels Screen
  void resetSession() {
    reelsViewedCount = 0;
    debugPrint("ReelsAdManager: Session reset. reelsViewedCount = 0");
  }

  /// Load daily count
  void _loadDailyCount() {
    _todayDateStr = DateTime.now().toIso8601String().substring(0, 10);
  }

  /// Increment daily count
  void incrementDailyCount() {
    final currentToday = DateTime.now().toIso8601String().substring(0, 10);
    if (_todayDateStr != currentToday) {
      _todayDateStr = currentToday;
      dailyAdCount = 0;
    }
    dailyAdCount++;
    lastAdFinishedTime = DateTime.now();
    debugPrint("ReelsAdManager: Daily ad count = $dailyAdCount");
  }

  /// Check if an ad should be triggered for the current reel
  bool shouldTriggerAd(int pageIndex, List<dynamic> activeAds) {
    // 1. Check daily limit (max 5 ads daily)
    final currentToday = DateTime.now().toIso8601String().substring(0, 10);
    if (_todayDateStr != currentToday) {
      _todayDateStr = currentToday;
      dailyAdCount = 0;
    }

    if (dailyAdCount >= 5) {
      debugPrint("ReelsAdManager: Daily limit reached ($dailyAdCount/5). Skipping ad.");
      return false;
    }

    // 2. Check 20-minute cooldown
    if (lastAdFinishedTime != null) {
      final minutesSinceLastAd = DateTime.now().difference(lastAdFinishedTime!).inMinutes;
      if (minutesSinceLastAd < 20) {
        debugPrint("ReelsAdManager: Cooldown active ($minutesSinceLastAd/20 min). Skipping ad.");
        return false;
      }
    }

    // 3. Filter for Video Ads ONLY (No image ads)
    final videoAds = getVideoAds(activeAds);
    if (videoAds.isEmpty) {
      debugPrint("ReelsAdManager: No video ads available.");
      return false;
    }

    // 4. Trigger on 3rd video viewed in the session
    return reelsViewedCount == 3;
  }

  /// Filter activeAds for Video Ads ONLY
  List<dynamic> getVideoAds(List<dynamic> ads) {
    return ads.where((ad) {
      final type = (ad['ad_type'] ?? '').toString().toLowerCase();
      final mediaRaw = (ad['media_url'] ?? ad['mediaUrl'] ?? '').toString().toLowerCase();

      bool isVideoType = type.contains('video');
      bool isVideoUrl = mediaRaw.contains('.mp4') ||
          mediaRaw.contains('.mov') ||
          mediaRaw.contains('.mkv') ||
          mediaRaw.contains('.avi');

      return isVideoType || isVideoUrl;
    }).toList();
  }

  /// Select next video ad
  Map<String, dynamic>? selectVideoAd(List<dynamic> ads) {
    final videoAds = getVideoAds(ads);
    if (videoAds.isEmpty) return null;
    return Map<String, dynamic>.from(videoAds[0]);
  }
}
