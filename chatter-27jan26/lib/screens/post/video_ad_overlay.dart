import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';

class VideoAdOverlay extends StatefulWidget {
  final Map<String, dynamic> ad;
  final VoidCallback onAdFinished;

  const VideoAdOverlay({
    Key? key,
    required this.ad,
    required this.onAdFinished,
  }) : super(key: key);

  @override
  State<VideoAdOverlay> createState() => _VideoAdOverlayState();
}

class _VideoAdOverlayState extends State<VideoAdOverlay> {
  VideoPlayerController? _adPlayerController;
  bool _isInitialized = false;
  bool _canSkip = false;
  int _countdown = 5;
  bool _rewardGranted = false;

  @override
  void initState() {
    super.initState();
    _initAdPlayer();
    _startSkipTimer();
  }

  void _initAdPlayer() {
    List<dynamic> mediaList = [];
    try {
      final rawMedia = widget.ad['media_url'];
      if (rawMedia is String) {
        mediaList = jsonDecode(rawMedia);
      } else if (rawMedia is List) {
        mediaList = rawMedia;
      }
    } catch (e) {
      // Ignore
    }

    final String mediaUrl = mediaList.isNotEmpty ? mediaList[0] : '';
    if (mediaUrl.isNotEmpty) {
      _adPlayerController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl.addBaseURL()))
        ..initialize().then((_) {
          setState(() {
            _isInitialized = true;
          });
          _adPlayerController!.play();
          _adPlayerController!.addListener(_adListener);
        });
    } else {
      // Fallback if no media
      widget.onAdFinished();
    }
  }

  void _startSkipTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _canSkip = true;
        }
      });
      return _countdown > 1;
    });
  }

  void _adListener() {
    if (_adPlayerController == null || !_adPlayerController!.value.isInitialized) return;

    final duration = _adPlayerController!.value.duration.inMilliseconds;
    final position = _adPlayerController!.value.position.inMilliseconds;

    // Check if watched 80%
    if (duration > 0 && position >= duration * 0.8 && !_rewardGranted) {
      _rewardGranted = true;
      _grantReward();
    }

    // Check finished
    if (position >= duration) {
      _finishAd();
    }
  }

  void _grantReward() {
    final userId = SessionManager.shared.getUserID();
    if (userId == 0) return;

    ApiService.shared.call(
      url: "${apiURL}wallet/reward",
      param: {
        "user_id": userId,
        "amount": 10.0
      },
      completion: (response) {
        if (response['status'] == true) {
          _showRewardBottomSheet();
        }
      },
    );
  }

  void _showRewardBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: const BoxDecoration(
          color: Color(0xFF121217),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: cPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.black, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              "Ad Earning Reward!",
              style: MyTextStyle.gilroyBold(color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              "Congratulations! You just earned 10 LC Coins for watching this sponsored ad.",
              style: MyTextStyle.gilroyMedium(color: Colors.white70, size: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cPrimary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              ),
              onPressed: () => Get.back(),
              child: Text(
                "Awesome",
                style: MyTextStyle.gilroyBold(size: 14),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _finishAd() {
    _adPlayerController?.removeListener(_adListener);
    _adPlayerController?.pause();
    _adPlayerController?.dispose();
    _adPlayerController = null;
    widget.onAdFinished();
  }

  @override
  void dispose() {
    _adPlayerController?.removeListener(_adListener);
    _adPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isInitialized && _adPlayerController != null)
            AspectRatio(
              aspectRatio: _adPlayerController!.value.aspectRatio,
              child: VideoPlayer(_adPlayerController!),
            )
          else
            const Center(child: CircularProgressIndicator(color: cPrimary)),

          // Countdown / Skip Button Overlay
          Positioned(
            bottom: 20,
            right: 20,
            child: _canSkip
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: _finishAd,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(
                      "Skip Ad",
                      style: MyTextStyle.gilroyBold(size: 13),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      "Skip in $_countdown s",
                      style: MyTextStyle.gilroyBold(size: 13, color: Colors.white),
                    ),
                  ),
          ),

          // Sponsored Tag
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Sponsored Video Ad",
                style: MyTextStyle.gilroyBold(size: 12, color: cPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
