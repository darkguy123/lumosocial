import 'package:chatter/common/api_service/room_service.dart';
import 'package:chatter/common/controller/base_controller.dart';
import 'package:chatter/models/room_model.dart';

class SingleRoomController extends BaseController {
  Room? room;
  int roomId;

  SingleRoomController(this.roomId);

  @override
  void onReady() {
    fetchRoom();
    super.onReady();
  }

  void fetchRoom() {
    startLoading();
    RoomService.shared.fetchRoom(roomId, (room) {
      stopLoading();
      this.room = room;
      update();
    });
  }
}
