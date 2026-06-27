import 'package:chatter/common/api_service/post_service.dart';
import 'package:chatter/common/controller/base_controller.dart';
import 'package:chatter/models/registration.dart';

class PostLikedUsersController extends BaseController {
  List<User> users = [];
  int postId;

  PostLikedUsersController(this.postId);

  @override
  void onReady() {
    fetchUsers();
    super.onReady();
  }

  void fetchUsers() {
    startLoading();
    PostService.shared.fetchUsersWhoLikedPost(
      postId: postId,
      completion: (users) {
        stopLoading();
        this.users.addAll(users);
        update();
      },
    );
  }
}
