import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/room_service.dart';
import 'package:lumosocial/common/controller/cupertino_controller.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/models/registration.dart';
import 'package:lumosocial/models/room_member_model.dart';
import 'package:lumosocial/models/room_model.dart';
import 'package:lumosocial/screens/chats_screen/chatting_screen/chatting_controller.dart';
import 'package:lumosocial/screens/sheets/confirmation_sheet.dart';
import 'package:lumosocial/utilities/firebase_const.dart';

class RoomMembersController extends CupertinoController {
  final ChattingController chattingController;

  List<RoomMember> users = [];
  List<RoomMember> admins = [];

  RoomMembersController(this.chattingController);

  @override
  void onReady() {
    fetchRoomUsers();
    fetchRoomAdmins();
    super.onReady();
  }

  Future<void> fetchRoomUsers() async {
    if (users.isEmpty) {
      startLoading();
    }
    await RoomService.shared.fetchRoomUsersList(chattingController.room?.id ?? 0, users.length, (users) {
      stopLoading();
      this.users.addAll(users);
      update();
    });
  }

  void fetchRoomAdmins() {
    RoomService.shared.fetchRoomAdmins(chattingController.room?.id, (users) {
      admins = users;
      update();
    });
  }

  void removeUserFromRoom(RoomMember member) {
    var user = member.user ?? User();
    Future.delayed(
      const Duration(milliseconds: 5),
      () {
        Get.bottomSheet(ConfirmationSheet(
          desc: LKeys.removeFromRoom,
          buttonTitle: LKeys.remove,
          onTap: () {
            startLoading();
            RoomService.shared.removeUserFromRoom(chattingController.room?.id, user.id, () {
              stopLoading();
              users.removeWhere((element) => element.id == member.id);
              chattingController.room?.totalMember = (chattingController.room?.totalMember ?? 0) - 1;
              chattingController.chatUserRoom?.usersIds?.removeWhere((element) => element == user.id);
              chattingController.db.collection(FirebaseConst.chats).doc(chattingController.chatUserRoom?.conversationId ?? '').update(chattingController.chatUserRoom?.toFireStore() ?? {});
              chattingController.update();
              update();
            });
          },
        ));
      },
    );
  }

  void makeRoomAdmin(RoomMember roomMember) {
    RoomService.shared.makeRoomAdmin(chattingController.room?.id, roomMember.userId, (member) {
      stopLoading();
      users.removeWhere((element) => element.id == roomMember.id);
      if (member != null) {
        member.user = roomMember.user;
        admins.add(member);
        users.add(member);
      }
      update();
    });
  }

  void removeAdminFromAdmin(RoomMember roomMember) {
    Get.bottomSheet(ConfirmationSheet(
      desc: LKeys.removeFromAdmin,
      buttonTitle: LKeys.remove,
      onTap: () {
        RoomService.shared.removeAdminFromRoom(chattingController.room?.id, roomMember.userId, (member) {
          stopLoading();
          if (roomMember.user?.id == SessionManager.shared.getUserID()) {
            Get.back();
            chattingController.room?.userRoomStatus = GroupUserAccessType.member.value;
            chattingController.update();
          } else {
            admins.removeWhere((element) => element.id == roomMember.id);
            users.removeWhere((element) => element.id == roomMember.id);
            if (member != null) {
              member.user = roomMember.user;
              users.add(member);
            }
            update();
          }
        });
      },
    ));
  }
}
