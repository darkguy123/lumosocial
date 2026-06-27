import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled/common/api_service/common_service.dart';
import 'package:untitled/common/api_service/notification_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_ended_for_host_screen.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_ended_for_user_screen.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_members_view.dart';
import 'package:untitled/screens/audio_space/create_audio_space_screen/audio_space_invite_screen.dart';
import 'package:untitled/screens/audio_space/models/audio_space.dart';
import 'package:untitled/screens/audio_space/models/audio_space_message.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/firebase_const.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'audio_space_screen.dart';

class AudioSpaceController extends BaseController {
  AudioSpacePageType selectedType = AudioSpacePageType.room;
  TextEditingController searchController = TextEditingController();
  TextEditingController messageTextController = TextEditingController();
  AudioSpace audioSpace;
  List<AudioSpaceUser> allListener = [];
  List<AudioSpaceMessage> messages = [];
  ScrollController messageScrollController = ScrollController();
  StreamSubscription? spacesListener;
  StreamSubscription? messagesListener;
  bool showOptionsShow = false;
  bool isMySpace = false;
  bool amIHost = false;
  RtcEngine? _engine;
  bool isJoined = false;
  RtcEngineEventHandler? agoraHandler;
  Timer? _timer;
  int _remainingSeconds = (SessionManager.shared.getSettings()?.audioSpaceDurationInMinutes?.toInt() ?? 0) * 60;
  bool isPermissionGranted = false;

  AudioSpaceController(this.audioSpace) {
    initAgora().then(
      (value) {
        WakelockPlus.enable();
        _setupSpaceListener();
        _setupMessagesListener();
      },
    );
  }

  /// Firebase
  /// -----------------------------------------------------------

  void _startTimer() {
    if (isMySpace && _remainingSeconds != 0) {
      _changeUserType(user: myUser, createdDate: DateTime.now().add(Duration(seconds: 1)));
      const oneSec = const Duration(seconds: 1);
      _timer = new Timer.periodic(
        oneSec,
        (Timer timer) {
          if (_remainingSeconds == 5) {
            timer.cancel();
            showSnackBar(LKeys.spaceDurationReached.tr, type: SnackBarType.error);
            Future.delayed(Duration(seconds: 5), () {
              _endRoom();
            });
          } else {
            _remainingSeconds--;
          }
        },
      );
    }
  }

  /// Firebase
  /// -----------------------------------------------------------
  void _setupSpaceListener() {
    spacesListener = FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .withConverter(
          fromFirestore: AudioSpace.fromFireStore,
          toFirestore: (value, options) => value.toFireStore(),
        )
        .doc(audioSpace.id ?? '')
        .snapshots()
        .listen((event) {
      var space = event.data();

      if (space != null) {
        if (myUserBySpace(space: space).type == AudioSpaceUserType.listener && myUser.type == AudioSpaceUserType.host) {
          showSnackBar(LKeys.adminHasMadeYouListener.tr);
          _engine?.setClientRole(role: ClientRoleType.clientRoleAudience);
        }

        if (myUserBySpace(space: space).type == AudioSpaceUserType.host && myUser.type == AudioSpaceUserType.requested) {
          showSnackBar(LKeys.nowYouAreHost.tr, type: SnackBarType.success);
          _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        }

        if (myUserBySpace(space: space).type == AudioSpaceUserType.kickedOut && myUser.type == AudioSpaceUserType.listener) {
          _engine?.leaveChannel();
          Get.back();
          showSnackBar(LKeys.adminHasKickedYouOut.tr, type: SnackBarType.error);
        }

        audioSpace = space;
        showOptionsShow = audioSpace.admins.firstWhereOrNull((element) => element.id == SessionManager.shared.getUserID()) != null;
        isMySpace = audioSpace.admins.firstWhereOrNull((element) => element.id == SessionManager.shared.getUserID()) != null;
        amIHost = audioSpace.hostsWithAdmin.firstWhereOrNull((element) => element.id == SessionManager.shared.getUserID()) != null;

        if (isMySpace && _timer == null) {
          _startTimer();
        }

        update();
        if (!isJoined) {
          joinSpace();
        } else {
          _engine?.enableLocalAudio(myUser.micStatus == AudioSpaceMicStatus.on);
          _engine?.setClientRole(
            role: amIHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience,
          );
        }
      } else {
        if (!isMySpace) {
          showUserEndedScreen();
        }
        _engine?.leaveChannel();
      }

      update();
      filterListeners();
    });
  }

  void _setupMessagesListener() {
    messagesListener = FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .doc(audioSpace.id ?? '')
        .collection(FirebaseAudioConst.messages)
        .withConverter(
          fromFirestore: AudioSpaceMessage.fromFireStore,
          toFirestore: (value, options) => value.toJson(),
        )
        .snapshots()
        .listen((event) {
      event.docChanges.forEach((element) {
        var data = element.doc.data();

        if (data != null) {
          data.user = ((audioSpace.users ?? []) + (audioSpace.leavedUsers ?? [])).firstWhereOrNull(
            (element) => element.id == data.userId,
          );
          switch (element.type) {
            case DocumentChangeType.added:
              messages.add(data);
              break;

            case DocumentChangeType.modified:
              int index = messages.indexWhere((message) => message.id == data.id);
              if (index != -1) {
                messages[index] = data;
              }
              break;

            case DocumentChangeType.removed:
              messages.removeWhere((message) => message.id == data.id);
              break;
          }
        }
        if (selectedType == AudioSpacePageType.messages) {
          readAllMessages();
        }
        update();
      });
    });
  }

  /// Agora
  /// -----------------------------------------------------------

  Future<void> initAgora() async {
    var permission = await [Permission.microphone].request();
    isPermissionGranted = permission[Permission.microphone] == PermissionStatus.granted;

    _engine = await createAgoraRtcEngine();

    await _engine?.initialize(const RtcEngineContext(
      appId: agoraAppId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    await _engine?.enableAudio();
    agoraHandler = RtcEngineEventHandler(
      // Occurs when the local user joins the channel successfully
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint("local user ${connection.localUid} joined");
      },
      // Occurs when a remote user join the channel
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("remote user $remoteUid joined");
      },
      // Occurs when a remote user leaves the channel
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        debugPrint("remote user $remoteUid left channel");
        if (audioSpace.admins.last.id?.toInt() == remoteUid && !isMySpace) {
          showUserEndedScreen();
          _engine?.leaveChannel();
          _deleteFirebaseRoom();
        }
      },
      onError: (err, msg) {
        debugPrint("Error $err , Message: $msg");
      },
    );

    if (agoraHandler != null) {
      _engine?.registerEventHandler(agoraHandler!);
    }
  }

  void filterListeners() {
    allListener = audioSpace.requestsAndListener.where((user) {
      final usernameLower = user.username?.toLowerCase() ?? '';
      // final fullNameLower = user.fullName?.toLowerCase() ?? '';
      final queryLower = searchController.text.toLowerCase();
      return usernameLower.contains(queryLower);
      // || fullNameLower.contains(queryLower);
    }).toList();
    update();
  }

  Future<void> joinSpace() async {
    if (!isMySpace) {
      if (!isJoined) {
        startLoading();
        String authString = '${agoraCustomerId}:${agoraCustomerSecret}';
        String authToken = base64.encode(authString.codeUnits);

        var value = await CommonService.shared.agoraListStreamingCheck(audioSpace.id ?? '', authToken, agoraAppId);
        stopLoading();
        if (value.data?.channelExist != true || (value.data?.broadcasters?.isEmpty ?? true)) {
          await _engine?.leaveChannel();
          _deleteFirebaseRoom();
          return;
        }
      }
    }

    if (!audioSpace.isUserInAudioSpace(myUser)) {
      if (audioSpace.isUserInLeavedUsers(myUser)) {
        // Already joined onetime
        _changeUserType(user: myUser);
      } else {
        _changeUserType(user: myUser, type: AudioSpaceUserType.listener, micStatus: AudioSpaceMicStatus.muted);
      }
    }

    if (!isJoined) {
      await _engine?.enableAudio();
      // await _engine?.enableLocalAudio(true);

      await _engine?.enableLocalAudio(true);
      // print('isJoined: $isJoined, mic On ${myUser.micStatus == AudioSpaceMicStatus.on}, user: ${myUser.toJson()}');

      await _engine?.setClientRole(
        role: amIHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience,
      );
      await _engine?.joinChannel(token: audioSpace.token ?? '', channelId: audioSpace.id ?? '', uid: myUser.id?.toInt() ?? 0, options: ChannelMediaOptions());

      isJoined = true;
    }
  }

  void showUserEndedScreen() {
    if (Get.isBottomSheetOpen == false) {
      isJoined = false;
      Get.bottomSheet(
        AudioSpaceEndedForUserScreen(),
        isScrollControlled: true,
        enableDrag: false,
      );
    }
  }

  void dragAndBack() async {
    if (isMySpace) {
      await _engine?.leaveChannel();
      _deleteFirebaseRoom();
    } else {
      await _engine?.leaveChannel();
      if (isJoined) {
        _changeUserType(user: myUser, shouldRemove: true);
      }
    }
  }

  void leaveSpace() async {
    await _engine?.leaveChannel();
    _changeUserType(user: myUser, shouldRemove: true);
    Get.back();
  }

  void selectType(AudioSpacePageType type) {
    selectedType = type;
    if (type == AudioSpacePageType.messages) {
      readAllMessages();
    }
    update();
  }

  /// Actions for Both
  void toggleMic() {
    myUser.micStatus = myUser.micStatus == AudioSpaceMicStatus.muted ? AudioSpaceMicStatus.on : AudioSpaceMicStatus.muted;
    _changeUserType(user: myUser, micStatus: myUser.micStatus);
    _engine?.enableLocalAudio(myUser.micStatus == AudioSpaceMicStatus.on);
    update();
  }

  void showUserDetails(AudioSpaceUser user) {
    Get.bottomSheet(
      AudioSpaceUserSheet(user: user, controller: this),
      isScrollControlled: true,
    );
  }

  /// Actions for User
  void showAddUsersSheet() {
    Get.bottomSheet(
        AudioSpaceInviteScreen(
          audioSpaceUsers: (audioSpace.users ?? []),
          onBack: (users) {
            _changeUserType(user: myUser, allUsers: users);
            update();
            List<AudioSpaceUser> oldUsers = (audioSpace.users ?? []) + (audioSpace.leavedUsers ?? []);
            var newUsers = (users + (audioSpace.leavedUsers ?? []))
                .where(
                  (user) => oldUsers.firstWhereOrNull((oldUser) => oldUser.id == user.id) == null,
                )
                .toList();
            newUsers.forEach((user) {
              NotificationService.shared.sendToSingleUser(
                token: user.deviceToken ?? '',
                deviceType: user.deviceType,
                title: appName,
                body: '${myUser.fullName ?? ''} ${LKeys.hasAddedYouTo.tr} ${audioSpace.title ?? ''} ${LKeys.audioSpace.tr.toLowerCase()}',
              );
            });
          },
        ),
        isScrollControlled: true);
  }

  void requestForHost(AudioSpaceUser user) {
    _changeUserType(user: user, type: AudioSpaceUserType.requested);
    showSnackBar(LKeys.requestHasBeenSetForHost.tr, type: SnackBarType.success);
  }

  void micToggleOfUser(AudioSpaceUser user) {
    if (user.micStatus == AudioSpaceMicStatus.muted) {
      _changeUserType(user: user, micStatus: AudioSpaceMicStatus.on);
    } else {
      _changeUserType(user: user, micStatus: AudioSpaceMicStatus.muted);
    }
  }

  AudioSpaceUser myUserBySpace({required AudioSpace space}) {
    return space.users?.firstWhereOrNull(
          (element) => element.id == SessionManager.shared.getUserID(),
        ) ??
        space.leavedUsers?.firstWhereOrNull(
          (element) => element.id == SessionManager.shared.getUserID(),
        ) ??
        SessionManager.shared.getUser()!.toAudioSpaceUser(AudioSpaceUserType.listener);
  }

  /// Actions for Admin

  void _deleteFirebaseRoom() {
    FirebaseFirestore.instance.collection(FirebaseAudioConst.audioSpaces).doc(audioSpace.id ?? '').delete();
    _deleteAllMessages();
  }

  Future<void> _endRoom() async {
    await _engine?.leaveChannel();
    _deleteFirebaseRoom();
    Future.delayed(
      Duration(milliseconds: 500),
      () {
        Get.bottomSheet(
            AudioSpaceEndedForHostScreen(
              controller: this,
            ),
            isScrollControlled: true,
            enableDrag: false);
      },
    );
  }

  Future<void> endRoom() async {
    showConfirmationSheet(
        desc: LKeys.wantToEndTheRoom,
        buttonTitle: LKeys.yes,
        onTap: () async {
          await _endRoom();
        });
  }

  AudioSpaceUser get myUser {
    return audioSpace.users?.firstWhereOrNull(
          (element) => element.id == SessionManager.shared.getUserID(),
        ) ??
        audioSpace.leavedUsers?.firstWhereOrNull(
          (element) => element.id == SessionManager.shared.getUserID(),
        ) ??
        SessionManager.shared.getUser()!.toAudioSpaceUser(AudioSpaceUserType.listener);
  }

  void acceptRequest(AudioSpaceUser user) {
    var hostsLimit = SessionManager.shared.getSettings()?.audioSpaceHostsLimit ?? 0;
    if (hostsLimit == 0 || audioSpace.hosts.length < hostsLimit) {
      _changeUserType(user: user, type: AudioSpaceUserType.host);
    } else {
      showSnackBar(LKeys.hostLimitReached.tr, type: SnackBarType.error);
    }
  }

  void kickOut(AudioSpaceUser user) {
    showConfirmationSheet(
        desc: LKeys.wantToKickOutUser,
        buttonTitle: LKeys.yes,
        onTap: () {
          _changeUserType(user: user, type: AudioSpaceUserType.kickedOut);
        });
  }

  void removeAddedUser(AudioSpaceUser user) {
    showConfirmationSheet(
        desc: LKeys.wantToRemoveUser,
        buttonTitle: LKeys.yes,
        onTap: () {
          audioSpace.users?.removeWhere(
            (element) => element.id == user.id,
          );
          _changeUserType(user: myUser, allUsers: audioSpace.users);
          update();
        });
  }

  void makeUserToListener(AudioSpaceUser user) {
    showConfirmationSheet(
        desc: LKeys.wantToMakeHostListener,
        buttonTitle: LKeys.yes,
        onTap: () {
          _changeUserType(user: user, type: AudioSpaceUserType.listener, micStatus: AudioSpaceMicStatus.muted);
        });
  }

  void rejectRequest(AudioSpaceUser user) {
    showConfirmationSheet(
        desc: LKeys.wantToRejectRequest,
        buttonTitle: LKeys.yes,
        onTap: () {
          _changeUserType(user: user, type: AudioSpaceUserType.listener);
        });
  }

  void _changeUserType({
    required AudioSpaceUser user,
    AudioSpaceUserType? type,
    AudioSpaceMicStatus? micStatus,
    bool shouldRemove = false,
    List<AudioSpaceUser>? allUsers,
    DateTime? createdDate,
  }) {
    if (micStatus != null) {
      user.micStatus = micStatus;
    }
    if (type != null) {
      user.type = type;
    }
    if (createdDate != null) {
      audioSpace.createdAt = createdDate;
    }
    var users = allUsers ?? audioSpace.users;
    users?.removeWhere((element) => element.id == user.id);
    if (!shouldRemove) {
      audioSpace.leavedUsers?.removeWhere((element) => element.id == user.id);
      users?.add(user);
    } else {
      audioSpace.users?.removeWhere((element) => element.id == user.id);
      if (audioSpace.leavedUsers == null) {
        audioSpace.leavedUsers = [];
      }
      audioSpace.leavedUsers?.add(user);
    }
    update();
    FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .withConverter(
          fromFirestore: AudioSpace.fromFireStore,
          toFirestore: (value, options) => value.toFireStore(),
        )
        .doc(audioSpace.id ?? '')
        .set(audioSpace, SetOptions(merge: true));
  }

  /// Message Segment
  ///

  void _deleteAllMessages() async {
    final instance = FirebaseFirestore.instance;
    final batch = instance.batch();
    var collection = FirebaseFirestore.instance.collection(FirebaseAudioConst.audioSpaces).doc(audioSpace.id ?? '').collection(FirebaseAudioConst.messages);
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  void readAllMessages() {
    SessionManager.shared.setLastMessageReadDate(spaceId: audioSpace.id ?? '');
  }

  int countOfUnreadMessages() {
    var isLastViewedDate = SessionManager.shared.getLastMessageReadDate(spaceId: audioSpace.id ?? '');
    if (isLastViewedDate == null) {
      return messages.length;
    } else {
      return messages.where((element) => element.time?.isAfter(isLastViewedDate) ?? true).length;
    }
  }

  void sendMessage() {
    if (messageTextController.text.isEmpty) {
      return;
    }
    var id = DateTime.now().microsecondsSinceEpoch.toString();
    var message = AudioSpaceMessage(id: id, content: messageTextController.text, time: DateTime.now(), userId: myUser.id?.toInt());
    FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .doc(audioSpace.id ?? '')
        .collection(FirebaseAudioConst.messages)
        .withConverter(
          fromFirestore: AudioSpaceMessage.fromFireStore,
          toFirestore: (value, options) => value.toJson(),
        )
        .doc(id)
        .set(message);
    messageTextController.text = "";
    readAllMessages();
    messageScrollController.jumpTo(messageScrollController.position.minScrollExtent);
    update();
  }

  @override
  void onClose() {
    WakelockPlus.disable();
    _timer?.cancel();
    spacesListener?.cancel();
    messagesListener?.cancel();
    if (agoraHandler != null) {
      _engine?.unregisterEventHandler(agoraHandler!);
    }
    super.onClose();
  }
}
