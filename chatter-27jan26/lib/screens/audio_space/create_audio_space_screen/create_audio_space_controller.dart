import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/common_service.dart';
import 'package:untitled/common/api_service/notification_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/audio_space/create_audio_space_screen/audio_space_invite_screen.dart';
import 'package:untitled/screens/interests_screen/interests_controller.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/firebase_const.dart';
import 'package:uuid/uuid.dart';

import '../models/audio_space.dart';
import '../models/audio_space_user.dart';

class CreateAudioSpaceController extends InterestsController {
  TextEditingController titleTextController = TextEditingController();
  TextEditingController descriptionTextController = TextEditingController();
  TextEditingController searchTextController = TextEditingController();
  ScrollController scrollController = ScrollController();

  AudioSpaceType selectedSpaceType = AudioSpaceType.public;
  bool isNext = false;
  List<AudioSpaceUser> hosts = [];
  List<AudioSpaceUser> addedUsers = [];

  List<AudioSpaceUser> allFollowers = [];

  AudioSpace? space;
  var myUser = SessionManager.shared.getUser() ?? User();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        fetchFollowers();
      }
    });
  }

  void showAddUsersSheet() {
    Get.bottomSheet(
        AudioSpaceInviteScreen(
          audioSpaceUsers: addedUsers,
          onBack: (users) {
            addedUsers = users;
            update();
          },
        ),
        isScrollControlled: true);
  }

  void removeUserFromSpace(AudioSpaceUser user) {
    addedUsers.removeWhere((element) => element.id == user.id);
    update();
  }

  void startAudioSpace() async {
    var id = Uuid().v1();
    startLoading();
    CommonService.shared.generateAgoraToken(
        channelName: id,
        completion: (token) async {
          addedUsers.removeWhere((element) => hosts.firstWhereOrNull((e) => e.id == element.id) != null);
          var audioSpace = AudioSpace(
            id: id,
            token: token,
            type: selectedSpaceType,
            title: titleTextController.text,
            description: descriptionTextController.text,
            topics: selectedInterests.map((e) => e.id ?? 0).join(','),
            users: [myUser.toAudioSpaceUser(AudioSpaceUserType.admin)] + hosts + addedUsers,
            leavedUsers: [],
            createdAt: DateTime.now(),
          );

          await FirebaseFirestore.instance
              .collection(FirebaseAudioConst.audioSpaces)
              .withConverter(
                fromFirestore: AudioSpace.fromFireStore,
                toFirestore: (value, options) => value.toFireStore(),
              )
              .doc(id)
              .set(audioSpace, SetOptions(merge: true));
          // Future.delayed(
          //   Duration(seconds: 2),
          //   () {
          stopLoading();
          this.space = audioSpace;
          sendPushNotification();
          update();
          // },
          // );
        });
  }

  void sendPushNotification() {
    hosts.forEach((user) {
      NotificationService.shared.sendToSingleUser(
        token: user.deviceToken ?? '',
        deviceType: user.deviceType,
        title: appName,
        body: '${myUser.fullName ?? ''} ${LKeys.hasAddedYouTo.tr} \'${space?.title ?? ''}\' ${LKeys.audioSpace.tr.toLowerCase()} ${LKeys.asHost.tr}',
      );
    });
    addedUsers.forEach((user) {
      NotificationService.shared.sendToSingleUser(
        token: user.deviceToken ?? '',
        deviceType: user.deviceType,
        title: appName,
        body: '${myUser.fullName ?? ''} ${LKeys.hasAddedYouTo.tr} \'${space?.title ?? ''}\' ${LKeys.audioSpace.tr.toLowerCase()}',
      );
    });
  }

  void next() {
    if (titleTextController.text.isEmpty) {
      showSnackBar(LKeys.pleaseEnterRoomName.tr);
      return;
    }
    if (descriptionTextController.text.isEmpty) {
      showSnackBar(LKeys.pleaseEnterDescription.tr);
      return;
    }
    if (selectedInterests.isEmpty) {
      showSnackBar(LKeys.pleaseSelectAtLeastOneInterest.tr);
      return;
    }
    isNext = true;
    fetchFollowers();
    update();
  }

  void changeType(AudioSpaceType type) {
    selectedSpaceType = type;
    update();
  }

  void fetchFollowers() {
    UserService.shared.fetchFollowerList(keyword: searchTextController.text, SessionManager.shared.getUserID(), allFollowers.length, (users) {
      stopLoading();
      users.forEach((element) {
        if ((allFollowers.firstWhereOrNull((user) => user.id == element.id) == null)) {
          allFollowers.add(element.toAudioSpaceUser(AudioSpaceUserType.added));
        }
      });
      update();
    });
  }

  void toggleHost(AudioSpaceUser user) {
    if ((hosts.firstWhereOrNull((element) => user.id == element.id) != null)) {
      hosts.removeWhere((element) => element.id == user.id);
    } else {
      user.type = AudioSpaceUserType.host;
      hosts.add(user);
    }
    update();
  }
}

enum AudioSpaceType {
  public('PUBLIC'),
  private('PRIVATE');

  const AudioSpaceType(this.value);

  final String value;

  String get title {
    switch (this) {
      case AudioSpaceType.public:
        return LKeys.public.tr;
      case AudioSpaceType.private:
        return LKeys.private.tr;
    }
  }

  String get description {
    switch (this) {
      case AudioSpaceType.public:
        return LKeys.publicAudioDesc.tr;
      case AudioSpaceType.private:
        return LKeys.privateAudioDesc.tr;
    }
  }
}
