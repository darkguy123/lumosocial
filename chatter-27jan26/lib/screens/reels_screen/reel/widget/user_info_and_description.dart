import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/models/reel_model_extension.dart';
import 'package:lumosocial/screens/extra_views/back_button.dart';
import 'package:lumosocial/screens/follow_button/follow_button.dart';
import 'package:lumosocial/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:lumosocial/screens/tag_screen/tag_controller.dart';
import 'package:lumosocial/screens/tag_screen/tag_screen.dart';
import 'package:lumosocial/utilities/const.dart';

import 'dart:convert';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/screens/feed_screen/in_app_browser_screen.dart';
import 'package:lumosocial/screens/reels_screen/reels_screen_controller.dart';

class UserInfoAndDescription extends StatelessWidget {
  final ReelController controller;

  const UserInfoAndDescription({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UserInfoHeader(controller: controller),
          const SizedBox(height: 2),
          UserStats(controller: controller),
          const SizedBox(height: 10),
          ReelDescriptionSection(
            controller: controller,
          ),
        ],
      ),
    );
  }
}

class ReelImageAdWidget extends StatelessWidget {
  final Map<String, dynamic> ad;

  const ReelImageAdWidget({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    List<dynamic> mediaList = [];
    try {
      final rawMedia = ad['media_url'];
      if (rawMedia is String) {
        mediaList = jsonDecode(rawMedia);
      } else if (rawMedia is List) {
        mediaList = rawMedia;
      }
    } catch (_) {}

    final String mediaUrl = mediaList.isNotEmpty ? mediaList[0].toString() : '';
    final String title = ad['campaign_name'] ?? 'Sponsored Ad';
    final String link = ad['target_link'] ?? '';

    return GestureDetector(
      onTap: () {
        if (link.isNotEmpty) {
          ApiService.shared.call(
            url: "${apiURL}ad/logClick",
            param: {"ad_id": ad['id']},
            completion: (_) {},
          );
          Get.to(() => InAppBrowserScreen(url: link));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: mediaUrl.isNotEmpty
                  ? MyCachedImage(
                      imageUrl: mediaUrl,
                      width: 44,
                      height: 44,
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      color: cPrimary,
                      child: const Icon(Icons.campaign_rounded, color: Colors.black, size: 24),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: cPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Ad",
                          style: MyTextStyle.gilroyBold(size: 10, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: MyTextStyle.gilroyBold(color: Colors.white, size: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    link.isNotEmpty ? Uri.parse(link).host : "Tap to open sponsored link",
                    style: MyTextStyle.gilroyRegular(color: Colors.white70, size: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: cPrimary, size: 18),
          ],
        ),
      ),
    );
  }
}

class UserInfoHeader extends StatelessWidget {
  const UserInfoHeader({required this.controller, super.key});

  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: InkWell(
            onTap: controller.onProfileTap,
            child: Obx(
              () {
                return Text(
                  controller.reel.value?.user?.username ?? 'unknown',
                  style: MyTextStyle.gilroyBold(color: cWhite, size: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: VerifyIcon(
            user: controller.reel.value?.user,
          ),
        ),
        if (controller.reel.value?.isMyReel == false)
          FollowButton(
            user: controller.reel.value?.user,
            child: (isFollowing) {
              return Opacity(
                opacity: !isFollowing ? 1 : 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.only(top: 6, left: 10, right: 10, bottom: 4),
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(cornerRadius: 30),
                      side: BorderSide(color: cWhite.withValues(alpha: 0.3)),
                      borderAlign: BorderAlign.inside,
                    ),
                    color: cWhite.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    isFollowing ? LKeys.unFollow.tr : LKeys.follow.tr,
                    style: MyTextStyle.gilroyRegular(size: 13, color: cWhite),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class UserStats extends StatelessWidget {
  const UserStats({super.key, required this.controller});

  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          DateFormat('dd MMM yyyy').format(controller.reel.value?.createdAt ?? DateTime.now()),
          style: MyTextStyle.outfitLight(color: cWhite.withValues(alpha: 0.8), size: 11),
        ),
        Container(
          height: 3,
          width: 3,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: cWhite.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '${controller.reel.value?.viewsCount ?? '1'} ${LKeys.views.tr}',
          style: MyTextStyle.outfitLight(
            color: cWhite.withValues(alpha: 0.8),
            size: 11,
          ),
        ),
      ],
    );
  }
}

class ReelDescriptionSection extends StatelessWidget {
  const ReelDescriptionSection({super.key, required this.controller});

  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.reel.value?.description == null || (controller.reel.value?.description ?? '').isEmpty) {
      return const SizedBox();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: ReadMoreText(
          controller.reel.value?.description ?? '',
          style: MyTextStyle.outfitLight(color: cWhite.withValues(alpha: 0.8), size: 15).copyWith(height: 1.4),
          annotations: [
            Annotation(
              regExp: RegExp(r'#([a-zA-Z0-9_]+)'),
              spanBuilder: ({required String text, TextStyle? textStyle}) => TextSpan(
                  text: text,
                  style: textStyle?.copyWith(
                    color: cPrimary,
                    fontFamily: MyTextStyle.gilroyMedium().fontFamily,
                    fontSize: 15,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      if (text.startsWith('#')) {
                        Get.delete<TagController>().then((value) {
                          Get.to(() => TagScreen(tag: text, isForReel: true), preventDuplicates: false);
                        });
                      }
                      // await Get.to(() => HashtagScreen(hashtag: text), preventDuplicates: false);
                    }),
            ),
          ],
          trimMode: TrimMode.Line,
          trimLines: 3,
          trimCollapsedText: ' ${LKeys.showMore.tr}',
          trimExpandedText: '   ${LKeys.showLess.tr}',
          moreStyle: MyTextStyle.outfitLight(color: cWhite.withValues(alpha: 0.8), size: 15),
          lessStyle: MyTextStyle.outfitLight(color: cWhite.withValues(alpha: 0.8), size: 15),
        ),
      ),
    );
  }
}
