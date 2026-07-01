import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumosocial/common/api_service/post_service.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/screens/add_post_screen/add_post_controller.dart';
import 'package:lumosocial/screens/feed_screen/feed_screen_controller.dart';

import 'package:lumosocial/common/api_service/story_service.dart';
import 'package:lumosocial/screens/feed_screen/feed_stories_controller.dart';

class PostUploadController extends GetxController {
  static PostUploadController get to => Get.find();

  var isUploading = false.obs;
  var uploadProgress = 0.0.obs;
  var thumbnailPath = "".obs;
  var isCompleted = false.obs;

  void startUpload({
    required String desc,
    required String tags,
    required PostType contentType,
    String? urlPreview,
    required List<XFile> images,
    XFile? video,
    XFile? audioFile,
    required String thumbnail,
    required List<double> waves,
    required String interestIds,
  }) {
    isUploading.value = true;
    uploadProgress.value = 0.0;
    isCompleted.value = false;
    thumbnailPath.value = thumbnail.isEmpty && images.isNotEmpty ? images.first.path : thumbnail;
    update();

    PostService.shared.uploadPost(
      desc: desc,
      tags: tags,
      contentType: contentType,
      urlPreview: urlPreview,
      images: images,
      video: video,
      audioFile: audioFile,
      onProgress: (percentage) {
        uploadProgress.value = percentage;
        update();
      },
      completion: (post) {
        post.user = SessionManager.shared.getUser();
        isUploading.value = false;
        isCompleted.value = true;
        update();

        // Try to insert the new post to the top of the feed and refresh
        try {
          if (Get.isRegistered<FeedScreenController>()) {
            final feedController = Get.find<FeedScreenController>();
            feedController.posts.insert(0, post);
            feedController.update([feedController.feedViewID]);
            feedController.update();
          }
        } catch (e) {
          print("Error updating FeedScreenController: $e");
        }

        // Auto reset completed banner after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          isCompleted.value = false;
          update();
        });
      },
      thumbnailPath: thumbnail,
      waves: waves,
      interestIds: interestIds,
    );
  }

  void startStoryUpload({
    required String fileURL,
    String? thumbnail,
    required int type,
    required double duration,
  }) {
    isUploading.value = true;
    uploadProgress.value = 0.0;
    isCompleted.value = false;
    thumbnailPath.value = thumbnail ?? fileURL;
    update();

    StoryService.shared.createStory(
      fileURL: fileURL,
      thumbnail: thumbnail,
      type: type,
      duration: duration,
      onProgress: (percentage) {
        uploadProgress.value = percentage;
        update();
      },
      completion: () {
        isUploading.value = false;
        isCompleted.value = true;
        update();

        // Auto-refresh the stories on FeedStoriesController
        try {
          if (Get.isRegistered<FeedStoriesController>()) {
            Get.find<FeedStoriesController>().fetchMyStories();
            Get.find<FeedStoriesController>().fetchStories();
          }
        } catch (e) {
          print("Error updating FeedStoriesController: $e");
        }

        // Auto reset completed banner after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          isCompleted.value = false;
          update();
        });
      },
    );
  }
}
