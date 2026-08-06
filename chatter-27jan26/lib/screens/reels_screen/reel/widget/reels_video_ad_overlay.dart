import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/screens/feed_screen/in_app_browser_screen.dart';
import 'package:lumosocial/screens/reels_screen/reels_ad_manager.dart';
import 'package:lumosocial/utilities/const.dart';

class ReelsVideoAdOverlayWidget extends StatefulWidget {
  final VideoPlayerController? mainVideoController;
  final List<dynamic> ads;

  const ReelsVideoAdOverlayWidget({
    Key? key,
    required this.mainVideoController,
    required this.ads,
  }) : super(key: key);

  @override
  State<ReelsVideoAdOverlayWidget> createState() => _ReelsVideoAdOverlayWidgetState();
}

class _ReelsVideoAdOverlayWidgetState extends State<ReelsVideoAdOverlayWidget> {
  bool _adSequenceStarted = false;
  bool _showingGreenLoading = false;
  bool _showingAdPlayer = false;
  double _greenLoadingProgress = 0.0;
  Timer? _greenLoadingTimer;

  VideoPlayerController? _adPlayerController;
  bool _isAdPlayerInitialized = false;
  bool _canSkipAd = false;
  int _skipCountdown = 5;
  Timer? _skipTimer;
  Map<String, dynamic>? _selectedAd;
  String _mediaUrl = '';

  @override
  void initState() {
    super.initState();
    widget.mainVideoController?.addListener(_mainVideoListener);
  }

  @override
  void dispose() {
    widget.mainVideoController?.removeListener(_mainVideoListener);
    _greenLoadingTimer?.cancel();
    _skipTimer?.cancel();
    _adPlayerController?.dispose();
    super.dispose();
  }

  void _mainVideoListener() {
    if (widget.mainVideoController == null ||
        !widget.mainVideoController!.value.isInitialized ||
        _adSequenceStarted) {
      return;
    }

    final positionSec = widget.mainVideoController!.value.position.inSeconds;

    // Check if watched 10 seconds of this 3rd video
    if (positionSec >= 10 && !_adSequenceStarted) {
      _adSequenceStarted = true;
      _startGreenLoadingSequence();
    }
  }

  /// Phase 1: Show 1.8-second Green Loading Line & Text
  void _startGreenLoadingSequence() {
    final adManager = ReelsAdManager.instance;
    _selectedAd = adManager.selectVideoAd(widget.ads);
    if (_selectedAd == null) return;

    if (mounted) {
      setState(() {
        _showingGreenLoading = true;
        _greenLoadingProgress = 0.0;
      });
    }

    const interval = Duration(milliseconds: 50);
    int elapsedMs = 0;

    _greenLoadingTimer = Timer.periodic(interval, (timer) {
      elapsedMs += 50;
      if (mounted) {
        setState(() {
          _greenLoadingProgress = (elapsedMs / 1800.0).clamp(0.0, 1.0);
        });
      }

      if (elapsedMs >= 1800) {
        timer.cancel();
        _launchAdPlayer();
      }
    });
  }

  /// Phase 2: Pause Main Video & Launch Fullscreen Video Ad Player
  void _launchAdPlayer() {
    widget.mainVideoController?.pause();

    // Parse video media URL
    List<dynamic> mediaList = [];
    try {
      final rawMedia = _selectedAd!['media_url'] ?? _selectedAd!['mediaUrl'];
      if (rawMedia is String) {
        mediaList = jsonDecode(rawMedia);
      } else if (rawMedia is List) {
        mediaList = rawMedia;
      }
    } catch (_) {}

    _mediaUrl = mediaList.isNotEmpty ? mediaList[0].toString() : (_selectedAd!['media_url'] ?? '');

    if (_mediaUrl.isEmpty) {
      _dismissAd();
      return;
    }

    if (mounted) {
      setState(() {
        _showingGreenLoading = false;
        _showingAdPlayer = true;
      });
    }

    _adPlayerController = VideoPlayerController.networkUrl(Uri.parse(_mediaUrl.addBaseURL()))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isAdPlayerInitialized = true;
          });
          _adPlayerController!.play();
          _adPlayerController!.addListener(_adPlayerListener);
          _startSkipCountdown();
        }
      });
  }

  void _startSkipCountdown() {
    _skipCountdown = 5;
    _canSkipAd = false;

    _skipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_skipCountdown > 1) {
          _skipCountdown--;
        } else {
          _canSkipAd = true;
          timer.cancel();
        }
      });
    });
  }

  void _adPlayerListener() {
    if (_adPlayerController == null || !_adPlayerController!.value.isInitialized) return;

    final duration = _adPlayerController!.value.duration.inMilliseconds;
    final position = _adPlayerController!.value.position.inMilliseconds;

    // Finish when ad ends
    if (position >= duration && duration > 0) {
      _dismissAd();
    }
  }

  void _dismissAd() {
    _greenLoadingTimer?.cancel();
    _skipTimer?.cancel();
    _adPlayerController?.removeListener(_adPlayerListener);
    _adPlayerController?.pause();

    // Increment Daily Ad Count & Set 20-minute Cooldown
    ReelsAdManager.instance.incrementDailyCount();

    // Log impression in backend
    if (_selectedAd != null && _selectedAd!['id'] != null) {
      ApiService.shared.call(
        url: "${apiURL}ad/logImpression",
        param: {"ad_id": _selectedAd!['id']},
        completion: (_) {},
      );
    }

    if (mounted) {
      setState(() {
        _showingAdPlayer = false;
        _showingGreenLoading = false;
      });
    }

    // Resume main Reels video
    widget.mainVideoController?.play();
  }

  void _onAdClicked() {
    if (_selectedAd != null && _selectedAd!['id'] != null) {
      ApiService.shared.call(
        url: "${apiURL}ad/logClick",
        param: {"ad_id": _selectedAd!['id']},
        completion: (_) {},
      );
    }

    final link = _selectedAd?['target_link'] ?? '';
    if (link.isNotEmpty) {
      Get.to(() => InAppBrowserScreen(url: link));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Phase 1: Green Loading Line Overlay
    if (_showingGreenLoading) {
      return Positioned(
        top: 60,
        left: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF40E378).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF40E378).withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.slow_motion_video_rounded, color: Color(0xFF40E378), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Ad Starting Soon...",
                    style: MyTextStyle.gilroyBold(size: 13, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _greenLoadingProgress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF40E378)),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Phase 2: Fullscreen Video Ad Player
    if (_showingAdPlayer && _selectedAd != null) {
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isAdPlayerInitialized && _adPlayerController != null)
              GestureDetector(
                onTap: _onAdClicked,
                child: AspectRatio(
                  aspectRatio: _adPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_adPlayerController!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF40E378)),
              ),

            // Top Sponsored Tag
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF40E378), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_rounded, color: Color(0xFF40E378), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _selectedAd!['campaign_name'] ?? "Sponsored Video Ad",
                      style: MyTextStyle.gilroyBold(size: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Progress Line
            if (_isAdPlayerInitialized && _adPlayerController != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder(
                  valueListenable: _adPlayerController!,
                  builder: (context, VideoPlayerValue value, child) {
                    final duration = value.duration.inMilliseconds;
                    final position = value.position.inMilliseconds;
                    final progress = duration > 0 ? position / duration : 0.0;
                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF40E378)),
                      minHeight: 4,
                    );
                  },
                ),
              ),

            // Transparent Skip Ad Button (gated by 5s countdown)
            Positioned(
              bottom: 40,
              right: 20,
              child: _canSkipAd
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.55),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: _dismissAd,
                      icon: const Icon(Icons.skip_next_rounded, size: 20),
                      label: Text(
                        "Skip Ad",
                        style: MyTextStyle.gilroyBold(size: 14),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        "Skip in $_skipCountdown s",
                        style: MyTextStyle.gilroyBold(size: 13, color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
