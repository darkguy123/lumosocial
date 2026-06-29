import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/enums/reel_page_type.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/screens/dashboard_reels_screen/dashboard_reels_controller.dart';
import 'package:lumosocial/screens/reels_screen/reels_screen.dart';
import 'package:lumosocial/screens/dashboard_reels_screen/live_tv_screen.dart';
import 'package:lumosocial/utilities/const.dart';

class DashboardReelsScreen extends StatelessWidget {
  const DashboardReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DashboardReelsController controller = Get.put(DashboardReelsController());
    Widget topTag(DashboardReelPageType type) {
      return Obx(
        () => Expanded(
          child: InkWell(
            onTap: () {
              controller.changeTheType(type);
            },
            child: Container(
              height: 50,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                type.title.tr,
                style: (type == controller.selectedPageType.value ? MyTextStyle.gilroyBold(color: cWhite, size: 16) : MyTextStyle.gilroyRegular(color: cWhite, size: 16)).copyWith(
                  shadows: [BoxShadow(color: cBlack.withValues(alpha: 0.3), blurRadius: 50)],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: cBlack,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.onChangePage,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ReelsScreen(
                reels: controller.reelsOfFollowings,
                position: 0.obs,
                pageType: ReelPageType.following,
                isLoading: controller.isLoading,
                onFetchMoreData: controller.fetchFollowingReels,
                onRefresh: controller.fetchReels,
                noReelDescription: LKeys.noReelsFromFollowings,
              ),
              ReelsScreen(
                reels: controller.reels,
                position: 0.obs,
                pageType: ReelPageType.home,
                isLoading: controller.isLoading,
                onFetchMoreData: controller.fetchReels,
                onRefresh: controller.refreshReels,
              ),
              const LiveTvScreen(),
            ],
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                topTag(DashboardReelPageType.following),
                Container(
                  height: 15,
                  width: 1,
                  color: cWhite,
                ),
                topTag(DashboardReelPageType.forYou),
                Container(
                  height: 15,
                  width: 1,
                  color: cWhite,
                ),
                topTag(DashboardReelPageType.liveTv),
              ],
            ),
          )
        ],
      ),
    );
  }
}
