import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/moderator_service.dart';
import 'package:lumosocial/common/api_service/post_service.dart';
import 'package:lumosocial/common/controller/base_controller.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/common/managers/share_manager.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/models/posts_model.dart';
import 'package:lumosocial/screens/add_post_screen/add_post_controller.dart';
import 'package:lumosocial/screens/post/audio_player_sheet.dart';
import 'package:lumosocial/screens/post/post_liked_users_screen.dart';
import 'package:lumosocial/screens/post/video_player_sheet.dart';
import 'package:lumosocial/screens/report_screen/report_sheet.dart';
import 'package:lumosocial/screens/sheets/confirmation_sheet.dart';
import 'package:lumosocial/common/managers/sound_manager.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PostController extends BaseController {
  int selectedImageIndex = 0;
  bool isMyPost = false;
  Post post;
  Function(int postID) onDeletePost;
  Function() refreshView;
  Function(VisibilityInfo info)? onVisibilityChanged;

  RxInt likeCount = 0.obs;
  RxBool isLiked = false.obs;

  PostController(this.post, this.onDeletePost, this.refreshView) {
    likeCount.value = this.post.likesCount ?? 0;
    isLiked.value = this.post.isLike == 1;
  }

  void openVideoSheet() {
    if (post.type == PostType.video) {
      Get.bottomSheet(VideoPlayerSheet(controller: this), isScrollControlled: true);
    }
  }

  void onPageChange(int value) {
    selectedImageIndex = value;
    update(["pageView"]);
  }

  void toggleFav() {
    if (post.isLike == 1) {
      post.likesCount = (post.likesCount ?? 0) - 1;
      likeCount.value = this.post.likesCount ?? 0;
      isLiked.value = false;
      post.isLike = 0;
      update();
      dislikePost();
    } else {
      post.likesCount = (post.likesCount ?? 0) + 1;
      likeCount.value = this.post.likesCount ?? 0;
      isLiked.value = true;
      post.isLike = 1;
      update();
      likePost();
    }

    // update(["fav"]);
  }

  void likeFromDoubleTap() {
    post.likesCount = (post.likesCount ?? 0) + 1;
    likeCount.value = this.post.likesCount ?? 0;
    isLiked.value = true;
    post.isLike = 1;
    update();
    refreshView();
    likePost();
  }

  void likePost() {
    SoundManager.shared.playPopSound();
    refreshView();
    PostService.shared.likePost(post.id ?? 0, () {});
  }

  void dislikePost() {
    refreshView();
    PostService.shared.dislikePost(post.id ?? 0, () {});
  }

  void deleteOrReport() {
    if (post.userId == SessionManager.shared.getUserID()) {
      deletePost();
    } else {
      reportPost();
    }
  }

  void showWhoLikedThePost() {
    Get.to(() => PostLikedUsersScreen(postId: post.id ?? 0));
  }

  void deletePosyByModerator() {
    Future.delayed(const Duration(milliseconds: 1), () {
      Get.bottomSheet(ConfirmationSheet(
        desc: LKeys.deletePostDesc.tr,
        buttonTitle: LKeys.delete.tr,
        onTap: () {
          startLoading();
          ModeratorService.shared.deletePost(
              postID: post.id ?? 0,
              completion: () {
                stopLoading();
                onDeletePost(post.id ?? 0);
              });
        },
      ));
    });
  }

  void sharePost() {
    ShareManager.shared.shareTheContent(key: ShareKeys.post, value: post.id ?? 0);
  }

  void reportPost() {
    Future.delayed(const Duration(milliseconds: 1), () {
      Get.bottomSheet(
          ReportSheet(
            post: post,
          ),
          isScrollControlled: true,
          ignoreSafeArea: false);
    });
  }

  void deletePost() {
    Future.delayed(const Duration(milliseconds: 1), () {
      Get.bottomSheet(ConfirmationSheet(
        desc: LKeys.deletePostDesc.tr,
        buttonTitle: LKeys.delete.tr,
        onTap: () {
          startLoading();
          PostService.shared.deletePost(
            post.id ?? 0,
            () {
              stopLoading();
              onDeletePost(post.id ?? 0);
            },
          );
        },
      ));
    });
  }

  void openAudioSheet() {
    // (await AudioSession.instance).configure(const AudioSessionConfiguration.speech());

    if (post.type == PostType.audio) {
      Get.bottomSheet(AudioPlayerSheet(controller: this), isScrollControlled: true).then((value) {});
    }
  }

  void editPost() {
    final textController = TextEditingController(text: post.desc ?? '');
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: cWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Edit Post", style: MyTextStyle.gilroyBold(size: 18)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 5,
              minLines: 3,
              autofocus: true,
              style: MyTextStyle.gilroyRegular(size: 16),
              decoration: InputDecoration(
                hintText: LKeys.writeHere.tr,
                hintStyle: MyTextStyle.gilroyRegular(color: cLightText.withValues(alpha: 0.6)),
                filled: true,
                fillColor: cLightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  final newText = textController.text.trim();
                  if (newText.isEmpty) return;
                  Get.back();
                  startLoading();
                  PostService.shared.editPost(
                    postId: post.id ?? 0,
                    desc: newText,
                    completion: (status, updatedPost) {
                      stopLoading();
                      if (status) {
                        post.desc = newText;
                        post.isEdited = true;
                        post.editedAt = DateTime.now();
                        update();
                        refreshView();
                      }
                    },
                  );
                },
                child: Text("Update & Repost", style: MyTextStyle.gilroyBold(size: 16, color: cWhite)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
