import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/ads/interstitial_manager.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/add_post_screen/add_post_screen.dart';
import 'package:untitled/screens/camera_screen/create_reel_screen.dart';
import 'package:untitled/screens/story_screen/create_story_screen/create_story_screen.dart';
import 'package:untitled/utilities/const.dart';

class FloatingBtnForCreating extends StatelessWidget {
  final Function(Post feed)? onPostBack;
  final Function()? onStoryBack;
  final Function(Reel reel)? onReelBack;

  FloatingBtnForCreating({super.key, this.onPostBack, this.onStoryBack, this.onReelBack});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: GestureDetector(
          onTap: _openSheet,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: cPrimary,
            child: Image.asset(
              MyImages.quill,
              width: 25,
              height: 25,
            ),
          ),
        ),
      ),
    );
  }

  void _openSheet() {
    InterstitialManager.shared.loadAd();
    Get.bottomSheet(_CreatingChooseSheet(
      onPostTap: _createPost,
      onReelTap: _createReel,
      onStoryTap: _createStory,
    ));
  }

  void _createStory() {
    Get.bottomSheet(
            CreateStoryScreen(
              user: SessionManager.shared.getUser() ?? User(),
              shouldShowStory: false,
            ),
            isScrollControlled: true,
            ignoreSafeArea: false)
        .then((value) {
      print(InterstitialManager.shared.interstitialAd);
      InterstitialManager.shared.showAd();
      if (onStoryBack != null) {
        onStoryBack!();
      }
    });
  }

  void _createPost() {
    Get.to(() => AddPostScreen())?.then((value) {
      InterstitialManager.shared.showAd();
      if (value is Post) {
        if (onPostBack != null) {
          onPostBack!(value);
        }
      }
    });
  }

  void _createReel() {
    Get.to(() => CreateReelScreen())?.then((value) {
      InterstitialManager.shared.showAd();
      if (value is Reel) {
        if (onReelBack != null) {
          onReelBack!(value);
        }
      }
    });
  }
}

class _CreatingChooseSheet extends StatelessWidget {
  final Function() onPostTap;
  final Function() onStoryTap;
  final Function() onReelTap;

  const _CreatingChooseSheet({required this.onPostTap, required this.onStoryTap, required this.onReelTap});

  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Wrap(
        children: [
          ClipSmoothRect(
            radius: SmoothBorderRadius.vertical(
              top: SmoothRadius(cornerRadius: 30, cornerSmoothing: cornerSmoothing),
            ),
            child: Container(
              color: cBlackSheetBG,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      height: 65,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LKeys.upload.tr,
                            style: MyTextStyle.gilroyRegular(color: cWhite),
                          ),
                          InkWell(
                            onTap: () {
                              Get.back();
                            },
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: cWhite.withValues(alpha: 0.1),
                              child: Image.asset(
                                MyImages.close,
                                height: 12,
                                width: 12,
                                color: cLightText,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      height: 0.5,
                      width: double.infinity,
                      color: cDarkText,
                    ),
                    SizedBox(height: 10),
                    _card(
                      imageName: MyImages.feed,
                      title: LKeys.feed,
                      onTap: onPostTap,
                    ),
                    _card(
                      imageName: MyImages.story,
                      title: LKeys.story,
                      onTap: onStoryTap,
                    ),
                    _card(
                      imageName: MyImages.reels,
                      title: LKeys.reels,
                      onTap: onReelTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required String imageName, required String title, required Function() onTap}) {
    return InkWell(
      onTap: () {
        Get.back();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            Image.asset(
              imageName,
              width: 30,
              height: 30,
              color: cWhite,
            ),
            SizedBox(width: 15),
            Text(
              title.tr,
              style: MyTextStyle.gilroyMedium(size: 18, color: cWhite),
            )
          ],
        ),
      ),
    );
  }
}
