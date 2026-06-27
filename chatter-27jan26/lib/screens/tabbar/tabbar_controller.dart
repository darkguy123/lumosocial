import 'package:get/get.dart';
import 'package:chatter/common/controller/base_controller.dart';
import 'package:chatter/common/managers/firebase_notification_manager.dart';
import 'package:chatter/common/managers/share_manager.dart';
import 'package:chatter/screens/profile_screen/profile_screen.dart';
import 'package:chatter/screens/rooms_screen/single_room/single_room_screen.dart';
import 'package:chatter/screens/single_post_screen/single_post_screen.dart';
import 'package:chatter/screens/single_reel_screen/single_reel_screen.dart';

class TabBarController extends BaseController {
  int selectedTab = 0;

  @override
  void onInit() {
    super.onInit();
    handleShare();
    FirebaseNotificationManager.shared.setupListener();
  }

  void selectIndex(int index) {
    selectedTab = index;
    update();
  }

  void handleShare() async {
    ShareManager.shared.listen((key, id) {
      switch (key) {
        case ShareKeys.user:
          Get.to(() => ProfileScreen(userId: id), preventDuplicates: false);
        case ShareKeys.post:
          Get.to(() => SinglePostScreen(postId: id), preventDuplicates: false);
        case ShareKeys.reel:
          Get.to(() => SingleReelScreen(reelId: id), preventDuplicates: false);
        case ShareKeys.room:
          Get.to(() => SingleRoomScreen(roomId: id), preventDuplicates: false);
      }
    });
  }
}
