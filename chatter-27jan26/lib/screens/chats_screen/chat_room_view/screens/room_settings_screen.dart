import 'package:flutter/material.dart';
import 'package:lumosocial/models/room_model.dart';
import 'package:lumosocial/screens/rooms_you_own/create_room_screen/create_room_screen.dart';

class RoomSettingScreen extends StatelessWidget {
  final Room? room;

  const RoomSettingScreen({Key? key, this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CreateRoomScreen(
      room: room,
    );
  }
}
