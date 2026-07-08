import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/extensions/image_extension.dart';
import 'package:lumosocial/common/widgets/black_gradient_shadow.dart';
import 'package:lumosocial/models/reel_model.dart';
import 'package:lumosocial/screens/camera_screen/reel_editor_screen.dart';
import 'package:lumosocial/screens/post/double_click_like.dart';
import 'package:lumosocial/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:lumosocial/screens/reels_screen/reel/widget/side_bar_list.dart';
import 'package:lumosocial/screens/reels_screen/reel/widget/user_info_and_description.dart';
import 'package:lumosocial/screens/reels_screen/reels_screen_controller.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/screens/post/video_ad_overlay.dart';
import 'dart:math';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReelPage extends StatelessWidget {
  final Reel? reelData;
  final VideoPlayerController? videoPlayerController;

  const ReelPage({super.key, required this.reelData, this.videoPlayerController});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReelController(reelData.obs), tag: '${reelData?.id}');
    RxBool isPlaying = true.obs;

    void onPlayPause() {
      if (videoPlayerController != null) {
        if (videoPlayerController?.value.isPlaying == true) {
          videoPlayerController?.pause();
          isPlaying.value = false;
        } else {
          videoPlayerController?.play();
          isPlaying.value = true;
        }
      }
    }

    return Scaffold(
      backgroundColor: cBlack,
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
              child: CupertinoActivityIndicator(
            color: cWhite,
          )),
          VisibilityDetector(
            onVisibilityChanged: (VisibilityInfo info) {
              var visiblePercentage = info.visibleFraction * 100;
              if (videoPlayerController?.value.isInitialized == true && videoPlayerController?.value.isPlaying == false) {
                if (visiblePercentage > 50) {
                  videoPlayerController?.play();
                  isPlaying.value = true;
                } else {
                  videoPlayerController?.pause();
                  isPlaying.value = false;
                }
              }
            },
            key: Key('key_${reelData?.content ?? ''}_${DateTime.now().millisecondsSinceEpoch}'),
            child: DoubleClickLikeAnimator(
              onAnimation: controller.likeWithDoubleTap,
              onTap: onPlayPause,
              child: ClipRect(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    videoPlayerController != null ? CustomCacheVideoPlayer(videoPlayerController: videoPlayerController, onPlayPause: onPlayPause) : const SizedBox(),
                    const BlackGradientShadow(),
                    PlayAnimationButton(isPlaying: isPlaying),
                  ],
                ),
              ),
            ),
          ),
          ReelSkipableAdOverlay(
            mainVideoController: videoPlayerController,
            ads: ReelsScreenController.activeAds,
            reelData: reelData,
          ),
          ReelInfoSection(controller: controller)
        ],
      ),
    );
  }
}

class ReelInfoSection extends StatelessWidget {
  final ReelController controller;

  const ReelInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ReelInfoRow(controller: controller),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ReelInfoRow extends StatelessWidget {
  final ReelController controller;

  const ReelInfoRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: UserInfoAndDescription(controller: controller)),
        SideBarList(controller: controller),
      ],
    );
  }
}

class PlayAnimationButton extends StatelessWidget {
  final RxBool isPlaying;

  const PlayAnimationButton({super.key, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Opacity(
        opacity: isPlaying.value ? 0 : 1,
        child: Align(
          alignment: Alignment.center,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: cBlack.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  isPlaying.value ? MyImages.pauseFill : MyImages.playFill,
                  width: 20,
                  height: 20,
                  color: cWhite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReelSkipableAdOverlay extends StatefulWidget {
  final VideoPlayerController? mainVideoController;
  final List<dynamic> ads;
  final Reel? reelData;

  const ReelSkipableAdOverlay({
    Key? key,
    required this.mainVideoController,
    required this.ads,
    required this.reelData,
  }) : super(key: key);

  @override
  State<ReelSkipableAdOverlay> createState() => _ReelSkipableAdOverlayState();
}

class _ReelSkipableAdOverlayState extends State<ReelSkipableAdOverlay> {
  bool _adTriggered = false;
  bool _showAd = false;
  Map<String, dynamic>? _selectedAd;
  late int _triggerSecond;
  late bool _shouldShowAd;

  @override
  void initState() {
    super.initState();
    _triggerSecond = 3 + Random().nextInt(8); // random between 3 and 10 seconds
    _shouldShowAd = widget.ads.isNotEmpty && Random().nextBool(); // 50% chance
    widget.mainVideoController?.addListener(_videoListener);
  }

  @override
  void dispose() {
    widget.mainVideoController?.removeListener(_videoListener);
    super.dispose();
  }

  void _videoListener() {
    if (widget.mainVideoController == null || !widget.mainVideoController!.value.isInitialized) return;

    final position = widget.mainVideoController!.value.position.inSeconds;
    if (position >= _triggerSecond && !_adTriggered && _shouldShowAd) {
      if (mounted) {
        setState(() {
          _adTriggered = true;
          _selectedAd = Map<String, dynamic>.from(widget.ads[Random().nextInt(widget.ads.length)]);
          _showAd = true;
        });
      }
      widget.mainVideoController?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showAd && _selectedAd != null) {
      return VideoAdOverlay(
        ad: _selectedAd!,
        onAdFinished: () {
          if (mounted) {
            setState(() {
              _showAd = false;
            });
          }
          widget.mainVideoController?.play();
        },
      );
    }
    return const SizedBox.shrink();
  }
}
