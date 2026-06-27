import 'package:get/get.dart';
import 'package:chatter/common/managers/session_manager.dart';
import 'package:chatter/common/api_service/user_service.dart';
import 'package:chatter/common/controller/base_controller.dart';
import 'package:chatter/localization/languages.dart';
import 'package:chatter/models/setting_model.dart';
import 'package:chatter/screens/username_screen/username_screen.dart';
import 'package:chatter/utilities/const.dart';

class InterestsController extends BaseController {
  static List<Interest> interests = SessionManager.shared.getSettings()?.interests ?? [];
  List<Interest> selectedInterests = [];

  void toggleInterest(Interest interest) {
    if (selectedInterests.contains(interest)) {
      removeInterest(interest);
    } else {
      if (selectedInterests.length < Limits.interestCount) {
        addInterest(interest);
      } else {
        showSnackBar("${LKeys.youCanNotSelectMoreThan.tr} ${Limits.interestCount}", type: SnackBarType.error);
      }
    }
  }

  void addInterest(Interest interest) {
    selectedInterests.add(interest);
    update();
  }

  void removeInterest(Interest interest) {
    selectedInterests.remove(interest);
    update();
  }

  void updateInterests() {
    startLoading();
    UserService.shared.editProfile(
        interests: selectedInterests,
        completion: (p0) {
          stopLoading();
          Get.offAll(() => const UserNameScreen());
        });
    // ApiService.shared.editProfile(param, (p0) {
    //   stopLoading();
    //   Get.to(() => const UserNameScreen());
    // });
  }
}
