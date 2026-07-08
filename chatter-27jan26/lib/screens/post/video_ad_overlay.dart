import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/screens/feed_screen/in_app_browser_screen.dart';
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

  bool _isImageAd = false;
  double _imageProgress = 0.0;
  Timer? _imageProgressTimer;
  String _mediaUrl = '';

  @override
  void initState() {
    super.initState();
    _initAdPlayer();
    _startSkipTimer();
  }

  void _initAdPlayer() {
    List<dynamic> mediaList = [];
    try {
      final rawMedia = widget.ad['media_url'] ?? widget.ad['mediaUrl'];
      if (rawMedia is String) {
        mediaList = jsonDecode(rawMedia);
      } else if (rawMedia is List) {
        mediaList = rawMedia;
      } else if (rawMedia != null) {
        mediaList = [rawMedia];
      }
    } catch (e) {
      if (widget.ad['mediaUrl'] != null) {
        mediaList = [widget.ad['mediaUrl']];
      }
    }

    _mediaUrl = mediaList.isNotEmpty ? mediaList[0] : '';
    if (_mediaUrl.isEmpty && widget.ad['mediaUrl'] != null) {
      _mediaUrl = widget.ad['mediaUrl'];
    }

    if (_mediaUrl.isNotEmpty) {
      _isImageAd = widget.ad['mediaType'] == 'image' ||
          _mediaUrl.toLowerCase().contains('.jpg') ||
          _mediaUrl.toLowerCase().contains('.jpeg') ||
          _mediaUrl.toLowerCase().contains('.png') ||
          _mediaUrl.toLowerCase().contains('.webp');

      if (_isImageAd) {
        setState(() {
          _isInitialized = true;
        });
        _startImageProgress();
      } else {
        _adPlayerController = VideoPlayerController.networkUrl(Uri.parse(_mediaUrl.addBaseURL()))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
              _adPlayerController!.play();
              _adPlayerController!.addListener(_adListener);
            }
          });
      }
    } else {
      widget.onAdFinished();
    }
  }

  void _startImageProgress() {
    const duration = Duration(milliseconds: 100);
    int elapsed = 0;
    _imageProgressTimer = Timer.periodic(duration, (timer) {
      elapsed += 100;
      if (mounted) {
        setState(() {
          _imageProgress = elapsed / 10000.0; // 10 seconds total
        });
      }

      // Grant reward at 80% (8 seconds)
      if (elapsed >= 8000 && !_rewardGranted) {
        _rewardGranted = true;
        _grantReward();
      }

      if (elapsed >= 10000) {
        timer.cancel();
        _finishAd();
      }
    });
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
    _imageProgressTimer?.cancel();
    _adPlayerController?.removeListener(_adListener);
    _adPlayerController?.pause();
    _adPlayerController?.dispose();
    _adPlayerController = null;

    // Log impression in MySQL for system ads
    if (widget.ad['id'] != null && widget.ad['id'] is! String) {
      ApiService.shared.call(
        url: "${apiURL}ad/logImpression",
        param: {"ad_id": widget.ad['id']},
        completion: (response) {},
      );
    }

    // Log impression in Firestore for user ads
    final firestoreAdId = widget.ad['id']?.toString() ?? '';
    if (firestoreAdId.isNotEmpty && widget.ad['userId'] != null) {
      FirebaseFirestore.instance.collection('ads').doc(firestoreAdId).update({
        'viewsCount': FieldValue.increment(1),
        'remainingViews': FieldValue.increment(-1),
      }).catchError((e) => debugPrint("Error updating ad impression in Firestore: $e"));
    }

    widget.onAdFinished();
  }

  void _onAdClicked() {
    // Log click in MySQL for system ads
    if (widget.ad['id'] != null && widget.ad['id'] is! String) {
      ApiService.shared.call(
        url: "${apiURL}ad/logClick",
        param: {"ad_id": widget.ad['id']},
        completion: (response) {},
      );
    }

    // Log click in Firestore for user ads
    final firestoreAdId = widget.ad['id']?.toString() ?? '';
    if (firestoreAdId.isNotEmpty && widget.ad['userId'] != null) {
      FirebaseFirestore.instance.collection('ads').doc(firestoreAdId).update({
        'clicksCount': FieldValue.increment(1),
        'remainingClicks': FieldValue.increment(-1),
      }).catchError((e) => debugPrint("Error updating ad click in Firestore: $e"));
    }

    final link = widget.ad['target_link'] ?? widget.ad['targetLink'] ?? '';
    if (link.isNotEmpty) {
      Get.to(() => InAppBrowserScreen(url: link));
    }
  }

  @override
  void dispose() {
    _imageProgressTimer?.cancel();
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
          if (_isInitialized) ...[
            if (_isImageAd)
              GestureDetector(
                onTap: _onAdClicked,
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: MyCachedImage(
                    imageUrl: _mediaUrl,
                  ),
                ),
              )
            else if (_adPlayerController != null)
              GestureDetector(
                onTap: _onAdClicked,
                child: AspectRatio(
                  aspectRatio: _adPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_adPlayerController!),
                ),
              ),
          ] else
            const Center(child: CircularProgressIndicator(color: cPrimary)),

          // Progress line
          if (_isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 4,
                child: _isImageAd
                    ? LinearProgressIndicator(
                        value: _imageProgress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(cPrimary),
                      )
                    : ValueListenableBuilder(
                        valueListenable: _adPlayerController!,
                        builder: (context, VideoPlayerValue value, child) {
                          final duration = value.duration.inMilliseconds;
                          final position = value.position.inMilliseconds;
                          final progress = duration > 0 ? position / duration : 0.0;
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(cPrimary),
                          );
                        },
                      ),
              ),
            ),

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

          // Sponsored Tag / Campaign title
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
                widget.ad['campaign_name'] ?? widget.ad['title'] ?? "Sponsored Ad",
                style: MyTextStyle.gilroyBold(size: 12, color: cPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
