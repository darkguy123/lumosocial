import 'package:get/get.dart';
import 'package:chatter/common/controller/base_controller.dart';
import 'package:chatter/common/managers/session_manager.dart';
import 'package:chatter/localization/allLanguages.dart';

class LanguagesController extends BaseController {
  List<Lang> languages = LANGUAGES;
  Lang selectedLan = SessionManager.shared.getLang();

  void setLang(Lang lang) {
    selectedLan = lang;
    SessionManager.shared.setLang(lang);
    Get.updateLocale(lang.language.local);
  }
}
