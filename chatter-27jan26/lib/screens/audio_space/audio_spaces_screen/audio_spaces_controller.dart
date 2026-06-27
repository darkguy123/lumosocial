import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/screens/audio_space/create_audio_space_screen/create_audio_space_controller.dart';
import 'package:untitled/screens/audio_space/models/audio_space.dart';
import 'package:untitled/utilities/firebase_const.dart';

class AudioSpacesController extends BaseController {
  List<AudioSpace> spaces = [];
  StreamSubscription? spacesListener;

  @override
  void onInit() {
    fetchSpaces();
    super.onInit();
  }

  bool _isUserInSpace(AudioSpace audioSpace) {
    final userId = SessionManager.shared.getUserID();
    final allUsers = (audioSpace.users ?? []) + (audioSpace.leavedUsers ?? []);
    return allUsers.any((user) => user.id == userId);
  }

  void fetchSpaces() {
    spacesListener = FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .withConverter(
          fromFirestore: AudioSpace.fromFireStore,
          toFirestore: (value, options) => value.toFireStore(),
        )
        .snapshots()
        .listen((event) {
      spaces = [];
      event.docs.forEach((element) {
        AudioSpace audioSpace = element.data();
        if (audioSpace.type == AudioSpaceType.public || _isUserInSpace(audioSpace)) {
          spaces.add(audioSpace);
        }
      });
      update();
    });
  }

  @override
  void onClose() {
    spacesListener?.cancel();
    super.onClose();
  }
}
