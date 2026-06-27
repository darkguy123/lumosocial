import 'package:chatter/common/api_service/common_service.dart';
import 'package:chatter/common/controller/base_controller.dart';
import 'package:chatter/models/faq_categories_model.dart';

class FAQsController extends BaseController {
  List<FAQsCategory> categories = [];
  FAQsCategory? selectedCat;

  @override
  void onReady() {
    fetchData();
    super.onReady();
  }

  void onTapCategory(FAQsCategory category) {
    selectedCat = category;
    update();
  }

  void fetchData() {
    startLoading();
    CommonService.shared.fetchFAQs((categories) {
      stopLoading();
      this.categories = categories;
      selectedCat = categories.first;
      update();
    });
  }
}
