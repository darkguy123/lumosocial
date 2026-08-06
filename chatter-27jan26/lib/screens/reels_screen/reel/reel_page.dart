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
import 'package:lumosocial/screens/reels_screen/reel/widget/reels_video_ad_overlay.dart';
import 'package:lumosocial/screens/reels_screen/reels_ad_manager.dart';
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
            key: ValueKey('key_${reelData?.id}_${reelData?.content ?? ''}'),
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
          ReelVideoAdContainer(
            mainVideoController: videoPlayerController,
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

class ReelVideoAdContainer extends StatefulWidget {
  final VideoPlayerController? mainVideoController;
  final Reel? reelData;

  const ReelVideoAdContainer({
    Key? key,
    required this.mainVideoController,
    required this.reelData,
  }) : super(key: key);

  @override
  State<ReelVideoAdContainer> createState() => _ReelVideoAdContainerState();
}

class _ReelVideoAdContainerState extends State<ReelVideoAdContainer> {
  bool _shouldShowAd = false;

  @override
  void initState() {
    super.initState();
    final adManager = ReelsAdManager.instance;
    adManager.reelsViewedCount++;
    _shouldShowAd = adManager.shouldTriggerAd(adManager.reelsViewedCount, ReelsScreenController.activeAds);
    debugPrint("ReelPage initialized. Viewed count: ${adManager.reelsViewedCount}, Trigger Ad: $_shouldShowAd");
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldShowAd && ReelsScreenController.activeAds.isNotEmpty) {
      return ReelsVideoAdOverlayWidget(
        mainVideoController: widget.mainVideoController,
        ads: ReelsScreenController.activeAds,
      );
    }
    return const SizedBox.shrink();
  }
}
