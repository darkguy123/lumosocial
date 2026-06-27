import 'package:get/get.dart';
import 'package:chatter/common/api_service/post_service.dart';
import 'package:chatter/common/controller/base_controller.dart';
import 'package:chatter/localization/languages.dart';
import 'package:chatter/screens/feed_screen/feed_screen_controller.dart';

class SinglePostController extends FeedScreenController {
  int postId;

  SinglePostController(this.postId);

  @override
  void onReady() {
    fetchPost();
    super.onReady();
  }

  void fetchPost() {
    startLoading();
    PostService.shared.fetchPost(postId, (post) {
      stopLoading();
      if (post == null) {
        showSnackBar(LKeys.someThingWentWrong.tr, type: SnackBarType.error);
        return;
      }
      posts.add(post);
      update();
    });
  }
}
