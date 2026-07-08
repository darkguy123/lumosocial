import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/extensions/image_extension.dart';
import 'package:lumosocial/common/managers/ads/banner_ad.dart';
import 'package:lumosocial/common/managers/load_more_widget.dart';
import 'package:lumosocial/common/managers/my_refresh_indicator.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/common/widgets/no_data_view.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/models/notification_model.dart';
import 'package:lumosocial/models/user_notification_model.dart';
import 'package:lumosocial/screens/extra_views/back_button.dart';
import 'package:lumosocial/screens/extra_views/top_bar.dart';
import 'package:lumosocial/screens/notification_screen/notification_controller.dart';
import 'package:lumosocial/screens/profile_screen/profile_screen.dart';
import 'package:lumosocial/screens/rooms_screen/single_room/single_room_screen.dart';
import 'package:lumosocial/screens/single_post_screen/single_post_screen.dart';
import 'package:lumosocial/screens/single_reel_screen/single_reel_screen.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/screens/chats_screen/chatting_screen/chatting_view.dart';
import 'package:lumosocial/screens/dashboard_reels_screen/live_tv_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    NotificationScreenController controller = NotificationScreenController();
    return Scaffold(
      body: Column(
        children: [
          const TopBarForInView(title: LKeys.notification),
          GetBuilder<NotificationScreenController>(
              init: controller,
              builder: (controller) {
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        color: cDarkBG,
                        width: double.infinity,
                        child: Column(
                          children: [
                            const SizedBox(height: 15),
                            segmentController(controller),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PageView(
                          controller: controller.controller,
                          onPageChanged: controller.onChangePage,
                          children: [
                            MyRefreshIndicator(
                              onRefresh: () async {
                                await controller.fetchUserNotifications(shouldRefresh: true);
                              },
                              child: NoDataView(
                                showShow: !controller.isLoading.value && controller.forYouNotifications.isEmpty,
                                child: LoadMoreWidget(
                                  loadMore: controller.fetchUserNotifications,
                                  child: ListView.builder(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    controller: controller.userScrollController,
                                    padding: const EdgeInsets.all(10),
                                    itemCount: controller.forYouNotifications.length,
                                    itemBuilder: (context, index) {
                                      return UserNotificationCard(
                                        notification: controller.forYouNotifications[index],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            MyRefreshIndicator(
                              onRefresh: () async {
                                await controller.fetchNotification(shouldRefresh: true);
                              },
                              child: LoadMoreWidget(
                                loadMore: controller.fetchNotification,
                                child: listView(controller: controller),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          BannerAdView(bottom: true)
        ],
      ),
    );
  }

  Widget segmentController(NotificationScreenController controller) {
    return CupertinoSlidingSegmentedControl(
      children: {0: buildSegment(LKeys.forYou, 0, controller), 1: buildSegment(LKeys.platform, 1, controller)},
      groupValue: controller.selectedPage,
      backgroundColor: cWhite.withValues(alpha: 0.12),
      thumbColor: cWhite,
      padding: const EdgeInsets.all(0),
      onValueChanged: (value) {
        controller.onChangeSegment(value ?? 0);
      },
    );
  }

  Widget buildSegment(String text, int index, NotificationScreenController controller) {
    return Container(
      alignment: Alignment.center,
      width: (Get.width / 2) - 30,
      child: Text(
        text.tr.toUpperCase(),
        style: MyTextStyle.gilroySemiBold(size: 13, color: controller.selectedPage == index ? cBlack : cWhite).copyWith(letterSpacing: 2),
      ),
    );
  }

  Widget listView({required NotificationScreenController controller}) {
    final list = controller.combinedPlatformNotifications;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: controller.scrollController,
      padding: const EdgeInsets.all(10),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        if (item is UserNotification) {
          return UserNotificationCard(notification: item);
        } else {
          return NotificationCard(notification: item as PlatformNotification);
        }
      },
    );
  }
}

class UserNotificationCard extends StatelessWidget {
  final UserNotification notification;

  const UserNotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final t = (notification.type ?? 0).toInt();
            if (t == 12 && notification.user != null) {
              Get.to(() => ChattingView(user: notification.user));
            } else if (t == 15) {
              Get.to(() => const LiveTvScreen());
            } else if (notification.reel != null) {
              Get.to(() => SingleReelScreen(reelId: notification.reel?.id ?? 0));
            } else if (notification.post != null) {
              Get.to(() => SinglePostScreen(postId: notification.post?.id ?? 0));
            } else if (notification.room != null) {
              Get.to(() => SingleRoomScreen(roomId: notification.room?.id?.toInt() ?? 0));
            } else if (notification.user != null) {
              Get.to(() => ProfileScreen(userId: notification.user?.id ?? 0));
            }
          },
          child: Container(
            color: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.to(() => ProfileScreen(userId: notification.user?.id ?? 0));
                  },
                  child: MyCachedImage(
                    imageUrl: notification.user?.profile,
                    width: 55,
                    height: 55,
                    cornerRadius: 12,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              notification.user?.fullName ?? '',
                              style: MyTextStyle.gilroyBold(),
                            ),
                          ),
                          const SizedBox(width: 1),
                          VerifyIcon(user: notification.user)
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${notification.user?.fullName ?? ''} ${notificationContent()}",
                        style: MyTextStyle.gilroyRegular(color: cLightText, size: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider()
      ],
    );
  }

  String notificationContent() {
    switch ((notification.type ?? 0).toInt()) {
      case 1:
        return LKeys.hasStartedFollowingYou.tr;
      case 2:
        return LKeys.hasCommentedToYourPost.tr;
      case 3:
        return LKeys.hasLikedYourPost.tr;
      case 4:
        return '${LKeys.hasInvitedToRoom.tr} ${notification.room?.title ?? ''}';
      case 5:
        return '${LKeys.hasAcceptedYourInvitationOfRoom.tr} ${notification.room?.title ?? ''}';
      case 6:
        return '${LKeys.hasRequestedToJoinYourRoom.tr} ${notification.room?.title ?? ''}';
      case 7:
        return '${LKeys.hasJoinedYourRoom.tr} ${notification.room?.title ?? ''}';
      case 8:
        return '${LKeys.hasAcceptedYourJoinRequestOfRoom.tr} ${notification.room?.title ?? ''}';
      case 9:
        return LKeys.hasLikedYourReel.tr;
      case 10:
        return LKeys.hasCommentedToYourReel.tr;
      case 11:
        return "released a new episode on the drama you watched last.";
      case 12:
        return "sent you a message.";
      case 13:
        return "completed a transaction.";
      case 14:
        return "posted a new feed post.";
      case 15:
        return "published a live match.";
      case 16:
        return "sent you a coin transfer.";
      case 17:
        return "blocked or reported you.";
      case 18:
        return "earned Lc coins from activities.";
    }
    return "";
  }
}

class NotificationCard extends StatelessWidget {
  final PlatformNotification notification;

  const NotificationCard({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipSmoothRect(
              radius: SmoothBorderRadius(cornerRadius: 12, cornerSmoothing: cornerSmoothing),
              child: Container(
                color: cBlack,
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  MyImages.logo,
                  width: 22,
                  height: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        notification.title ?? '',
                        style: MyTextStyle.gilroyBold(),
                      ),
                      const SizedBox(width: 5),
                      const VerifyIcon()
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    notification.description ?? '',
                    style: MyTextStyle.gilroyLight(color: cLightText, size: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider()
      ],
    );
  }
}
