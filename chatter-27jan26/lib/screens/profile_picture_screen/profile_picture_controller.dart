import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatter/common/api_service/user_service.dart';
import 'package:chatter/localization/languages.dart';
import 'package:chatter/screens/tabbar/tabbar_screen.dart';
import 'package:chatter/screens/username_screen/username_controller.dart';
import 'package:chatter/utilities/const.dart';

class ProfilePictureController extends UsernameController {
  final ImagePicker picker = ImagePicker();
  String imagePath = "";
  XFile? file;

  void pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      XFile? image = await picker.pickImage(source: source, maxHeight: Limits.imageSize, maxWidth: Limits.imageSize, imageQuality: Limits.quality);
      print(image);
      if (image != null) {
        file = image;
        imagePath = image.path;
        update();
      }
    } catch (e) {
      showSnackBar("Invalid Image");
    }
  }

  void uploadImage() {
    if (file == null) {
      showSnackBar(LKeys.pleaseSelectImage.tr);
      return;
    }
    startLoading();
    UserService.shared.editProfile(
      profileImage: file,
      completion: (p0) {
        stopLoading();
        Get.offAll(() => TabBarScreen());
      },
    );
  }
}
