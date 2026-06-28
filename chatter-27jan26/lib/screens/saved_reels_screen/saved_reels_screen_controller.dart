import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/reel_service.dart';
import 'package:lumosocial/common/controller/base_controller.dart';
import 'package:lumosocial/models/reel_model.dart';

class SavedReelsScreenController extends BaseController {
  RxList<Reel> reels = RxList();

  @override
  void onReady() {
    fetchReels();
    super.onReady();
  }

  Future<void> fetchReels({bool shouldRefresh = false}) async {
    isLoading.value = true;
    var newReels = await ReelService.shared.fetchSavedReels(start: shouldRefresh ? 0 : reels.length);
    if (shouldRefresh) {
      reels.clear();
    }
    reels.addAll(newReels);
    isLoading.value = false;
  }
}
