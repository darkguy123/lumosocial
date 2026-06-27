import 'package:chatter/common/api_service/room_service.dart';
import 'package:chatter/common/controller/base_controller.dart';
import 'package:chatter/models/room_model.dart';

class RoomsYouOwnController extends BaseController {
  List<Room> rooms = [];
  bool isFirstTime = true;

  @override
  void onReady() {
    super.onReady();
    getMyRooms();
  }

  void getMyRooms() {
    if (isFirstTime) {
      startLoading();
    }
    RoomService.shared.fetchMyOwnRooms((rooms) {
      if (isFirstTime) {
        stopLoading();
      }
      isFirstTime = false;
      this.rooms = rooms;
      update();
    });
  }
}
