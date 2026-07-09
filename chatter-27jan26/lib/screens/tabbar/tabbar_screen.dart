import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/extensions/image_extension.dart';
import 'package:lumosocial/common/managers/ads/banner_ad.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/common/widgets/functions.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/screens/chats_screen/chats_screen.dart';
import 'package:lumosocial/screens/chats_screen/chats_screen_controller.dart';
import 'package:lumosocial/screens/dashboard_reels_screen/dashboard_reels_screen.dart';
import 'package:lumosocial/screens/feed_screen/feed_screen.dart';
import 'package:lumosocial/screens/profile_screen/profile_screen.dart';
import 'package:lumosocial/screens/random_screen/random_screen.dart';
import 'package:lumosocial/screens/tabbar/tabbar_controller.dart';
import 'package:lumosocial/screens/drama_screen/drama_screen.dart';
import 'package:lumosocial/common/controller/post_upload_controller.dart';
import 'package:lumosocial/utilities/const.dart';

class TabBarScreen extends StatelessWidget {
  TabBarScreen({Key? key}) : super(key: key);
  final ScrollController scrollController = ScrollController();

  Widget? _buildAdminFloatingButton(BuildContext context) {
    final username = SessionManager.shared.getUser()?.username ?? '';
    if (username.toLowerCase() == 'admin') {
      return FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00FF87),
        onPressed: () async {
          final uri = Uri.parse('/index');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.black),
        label: const Text(
          'Admin Portal',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final TabBarController controller = Get.put(TabBarController());
    final ChatsScreensController chatScreenController = Get.put(ChatsScreensController());
    Get.put(PostUploadController());
    Functions.changStatusBar(StatusBarStyle.black);

    return GetBuilder<TabBarController>(
      init: controller,
      builder: (controller) {
        // Desktop Web Responsive Sidebar View (Instagram Web style)
        if (kIsWeb && MediaQuery.of(context).size.width > 600) {
          return Scaffold(
            backgroundColor: const Color(0xFF07080B),
            floatingActionButton: _buildAdminFloatingButton(context),
            body: Row(
              children: [
                // Instagram-style sidebar navigation
                Container(
                  width: 260,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 40),
                        child: Row(
                          children: [
                            Image.asset(
                              MyImages.meeting,
                              width: 32,
                              height: 32,
                              color: cPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'LUMO SOCIAL',
                              style: MyTextStyle.gilroyBold(size: 20, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _sidebarItem(LKeys.feed, MyImages.quill, 0, controller),
                            _sidebarItem(LKeys.drama, MyImages.drama, 1, controller),
                            _sidebarItem(LKeys.reels, MyImages.reels, 2, controller),
                            GetBuilder(
                              init: chatScreenController,
                              builder: (chatScreenController) {
                                return _sidebarItem(
                                  LKeys.chats,
                                  MyImages.chat,
                                  3,
                                  controller,
                                  isBudged: chatScreenController.isNewMessage,
                                );
                              },
                            ),
                            _sidebarItem(LKeys.profile, MyImages.profile, 4, controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider line
                Container(
                  width: 1,
                  color: Colors.white10,
                ),
                // Content pane (max-width centered frame)
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 960),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                      ),
                      child: ProsteIndexedStack(
                        children: [
                          IndexedStackChild(child: FeedScreen(scrollController: scrollController)),
                          IndexedStackChild(child: const DramaScreen()),
                          IndexedStackChild(child: DashboardReelsScreen(), preload: true),
                          IndexedStackChild(child: ChatsScreen(), preload: true),
                          IndexedStackChild(child: ProfileScreen(isFromTabBar: true, userId: SessionManager.shared.getUserID()), preload: true),
                        ],
                        index: controller.selectedTab,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Standard Mobile View
        return Scaffold(
          backgroundColor: cWhite,
          floatingActionButton: _buildAdminFloatingButton(context),
          body: Column(
            children: [
              Expanded(
                child: ProsteIndexedStack(
                  children: [
                    IndexedStackChild(child: FeedScreen(scrollController: scrollController)),
                    IndexedStackChild(child: const DramaScreen()),
                    IndexedStackChild(child: DashboardReelsScreen(), preload: true),
                    IndexedStackChild(child: ChatsScreen(), preload: true),
                    IndexedStackChild(child: ProfileScreen(isFromTabBar: true, userId: SessionManager.shared.getUserID()), preload: true),
                  ],
                  index: controller.selectedTab,
                ),
              ),
              BannerAdView(),
              Container(
                color: cBlack,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      button(LKeys.feed, MyImages.quill, 0, controller),
                      button(LKeys.drama, MyImages.drama, 1, controller),
                      button(LKeys.reels, MyImages.reels, 2, controller),
                      GetBuilder(
                          init: chatScreenController,
                          builder: (chatScreenController) {
                            return button(LKeys.chats, MyImages.chat, 3, controller, isBudged: chatScreenController.isNewMessage);
                          }),
                      button(LKeys.profile, MyImages.profile, 4, controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sidebarItem(String title, String image, int index, TabBarController controller, {bool isBudged = false}) {
    final isSelected = controller.selectedTab == index;
    return InkWell(
      onTap: () {
        if (index == 0 && controller.selectedTab == 0) {
          HapticFeedback.mediumImpact();
          if (scrollController.offset == 0) {
            refreshIndicatorKey.currentState?.show();
          } else {
            scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.linear);
          }
        }
        controller.selectIndex(index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  image,
                  width: 24,
                  height: 24,
                  color: isSelected ? cPrimary : cLightText,
                ),
                if (isBudged)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title.tr,
                style: MyTextStyle.gilroySemiBold(
                  size: 16,
                  color: isSelected ? cPrimary : cLightText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget button(String title, String image, int index, TabBarController controller, {bool isBudged = false}) {
    return GestureDetector(
      onTap: () {
        if (index == 0 && controller.selectedTab == 0) {
          HapticFeedback.mediumImpact();
          if (scrollController.offset == 0) {
            refreshIndicatorKey.currentState?.show();
          } else {
            scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.linear);
          }
        }
        controller.selectIndex(index);
      },
      child: Container(
        color: cBlack,
        width: Get.width / 5,
        child: TabBarButton(
          image: image,
          title: title,
          isSelected: controller.selectedTab == index,
          isBudged: isBudged,
        ),
      ),
    );
  }

  Widget selectedWidget(TabBarController controller) {
    switch (controller.selectedTab) {
      case 0:
        return FeedScreen(scrollController: scrollController);
      case 1:
        return const DramaScreen();
      case 2:
        return RandomScreen();
      case 3:
        return ChatsScreen();
      case 4:
        return ProfileScreen(
          isFromTabBar: true,
          userId: SessionManager.shared.getUserID(),
        );
    }
    return Container();
  }
}

class TabBarButton extends StatelessWidget {
  final String title;
  final String image;
  final bool isSelected;
  final bool isBudged;

  const TabBarButton({Key? key, required this.title, required this.image, required this.isSelected, this.isBudged = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topRight,
          children: [
            Image.asset(
              image,
              width: 20,
              height: 20,
              color: isSelected ? cPrimary : cLightText,
            ),
            if (isBudged)
              Positioned(
                bottom: 13,
                left: 13,
                child: ClipOval(
                  child: Container(
                    height: 10,
                    width: 10,
                    color: cRed,
                  ),
                ),
              )
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          title.tr,
          style: MyTextStyle.gilroyRegular(
            size: 12,
            color: isSelected ? cPrimary : cLightText,
          ),
        ),
      ],
    );
  }
}
