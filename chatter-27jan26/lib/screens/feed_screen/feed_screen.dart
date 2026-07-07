import 'dart:io';
import 'package:lumosocial/common/controller/post_upload_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/widgets/buttons/floating_btn_for_creating.dart';
import 'package:lumosocial/common/widgets/loader_widget.dart';
import 'package:lumosocial/common/widgets/no_data_view.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/screens/feed_screen/feed_screen_controller.dart';
import 'package:lumosocial/screens/feed_screen/feed_screen_top_bar.dart';
import 'package:lumosocial/screens/feed_screen/feed_stories_controller.dart';
import 'package:lumosocial/screens/feed_screen/feed_story_screen.dart';
import 'package:lumosocial/screens/feed_screen/side_menu_drawer.dart';
import 'package:lumosocial/screens/feed_screen/feed_ad_card.dart';
import 'package:lumosocial/screens/post/post_card.dart';
import 'package:lumosocial/screens/rooms_screen/room_card.dart';
import 'package:lumosocial/utilities/const.dart';

final GlobalKey<RefreshIndicatorState> refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

class FeedScreen extends StatelessWidget {
  final ScrollController scrollController;

  const FeedScreen({Key? key, required this.scrollController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FeedScreenController controller = FeedScreenController(isFromFeedScreen: true, scrollController: scrollController);
    FeedStoriesController feedStoriesController = FeedStoriesController();
    return Scaffold(
      drawer: const SideMenuDrawer(),
      body: Stack(
        children: [
          GetBuilder(
              init: controller,
              builder: (controller) {
                return Container(
                  color: cLightBg,
                  height: (controller.posts.isEmpty ? (0) : Get.height / 2),
                );
              }),
          GetBuilder(
              init: feedStoriesController,
              builder: (feedStoriesController) {
                return GetBuilder(
                    init: controller,
                    builder: (controller) {
                      return Column(
                        children: [
                          const FeedScreenTopBar(),
                          Obx(() {
                            final uploadController = Get.find<PostUploadController>();
                            if (uploadController.isUploading.value) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                color: Colors.white,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            uploadController.isStoryUpload.value
                                                ? "Uploading Story..."
                                                : "Uploading Post...",
                                            style: MyTextStyle.gilroyMedium(size: 14, color: cBlack),
                                          ),
                                          const SizedBox(height: 5),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(5),
                                            child: LinearProgressIndicator(
                                              value: uploadController.uploadProgress.value,
                                              backgroundColor: Colors.grey[200],
                                              valueColor: AlwaysStoppedAnimation<Color>(cPrimary),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    if (uploadController.thumbnailPath.value.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(uploadController.thumbnailPath.value),
                                          width: 45,
                                          height: 45,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }
                            if (uploadController.isCompleted.value) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                color: uploadController.isStoryUpload.value ? const Color(0xFF1A1A2E) : Colors.green,
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      uploadController.isStoryUpload.value ? Icons.auto_awesome_rounded : Icons.check_circle,
                                      color: uploadController.isStoryUpload.value ? const Color(0xFF00FF87) : Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      uploadController.isStoryUpload.value ? "Story Published! 🎉" : "Post uploaded successfully",
                                      style: MyTextStyle.gilroyBold(
                                        size: 15,
                                        color: uploadController.isStoryUpload.value ? const Color(0xFF00FF87) : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                          Container(color: cLightBg, height: 10),
                          Expanded(
                            child: Stack(
                              children: [
                                if (controller.isLoading.value && controller.posts.isEmpty)
                                  LoaderWidget()
                                else
                                  RefreshIndicator(
                                    key: refreshIndicatorKey,
                                    triggerMode: RefreshIndicatorTriggerMode.anywhere,
                                    color: refreshIndicatorColor,
                                    backgroundColor: refreshIndicatorBgColor,
                                    child: SingleChildScrollView(
                                      controller: controller.scrollController,
                                      primary: false,
                                      child: Column(
                                        children: [
                                          FeedStoryScreen(controller: feedStoriesController),
                                          Container(color: cLightBg, height: 5),
                                          Container(
                                            color: cWhite,
                                            child: FeedsView(
                                              controller: controller,
                                              id: controller.feedViewID,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onRefresh: () async {
                                      await controller.fetchFeeds(isForRefresh: true);
                                      await feedStoriesController.fetchStories();
                                      return await feedStoriesController.fetchMyStories();
                                    },
                                  ),
                                FloatingBtnForCreating(
                                  onPostBack: (feed) {
                                    Future.delayed(Duration(milliseconds: 100), () {
                                      controller.posts.insert(0, feed);
                                      controller.update([controller.feedViewID]);
                                      controller.update();
                                    });
                                  },
                                  onStoryBack: () {
                                    feedStoriesController.fetchMyStories();
                                  },
                                )
                              ],
                            ),
                          ),
                        ],
                      );
                    });
              }),
        ],
      ),
    );
  }
}

class FeedsView extends StatelessWidget {
  const FeedsView({
    super.key,
    required this.controller,
    required this.id,
  });

  final FeedScreenController controller;
  final String id;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: controller,
      tag: id,
      builder: (controller) {
        return NoDataView(
          showShow: controller.posts.isEmpty && !controller.isLoading.value,
          title: LKeys.noPosts.tr,
          child: SafeArea(
            top: false,
            child: ListView.builder(
              primary: false,
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 5),
              itemCount: controller.posts.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    (index == 2 && controller.suggestedRooms.isNotEmpty)
                        ? Container(
                            color: cBlack,
                            padding: const EdgeInsets.only(top: 20, right: 10, left: 10, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      LKeys.suggested.tr,
                                      style: MyTextStyle.gilroyLight(color: cWhite, size: 17),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      LKeys.rooms.tr,
                                      style: MyTextStyle.gilroyBold(color: cWhite, size: 17),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  height: 250,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: controller.suggestedRooms.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(horizontal: Get.width / 50),
                                        child: RoomCard(
                                          room: controller.suggestedRooms[index],
                                          isFromHome: true,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          )
                        : Container(),
                    if (index > 0 && index % 4 == 0 && controller.activeAds.isNotEmpty)
                      FeedAdCard(
                        ad: controller.activeAds[index % controller.activeAds.length],
                      ),
                    PostCard(
                      post: controller.posts[index],
                      onDeletePost: (postID) {
                        controller.posts.removeWhere((element) => element.id == postID);
                        controller.update();
                      },
                      refreshView: () {
                        controller.update();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
