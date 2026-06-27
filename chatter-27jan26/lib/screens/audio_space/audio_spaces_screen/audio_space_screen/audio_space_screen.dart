import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/audio_space/create_audio_space_screen/create_audio_space_controller.dart';
import 'package:untitled/screens/audio_space/models/audio_space.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';
import 'package:untitled/screens/post/comment/comment_screen.dart';
import 'package:untitled/utilities/const.dart';

import 'audio_space_controller.dart';
import 'audio_space_members_view.dart';
import 'audio_space_messages_view.dart';
import 'audio_space_requests_view.dart';
import 'audio_space_room_view.dart';

class AudioSpaceScreen extends StatelessWidget {
  final AudioSpace audioSpace;

  const AudioSpaceScreen({super.key, required this.audioSpace});

  @override
  Widget build(BuildContext context) {
    AudioSpaceController controller = AudioSpaceController(this.audioSpace);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          controller.dragAndBack();
        }
      },
      child: Scaffold(
        backgroundColor: cMainText,
        body: GetBuilder(
            init: controller,
            builder: (controller) {
              var audioSpace = controller.audioSpace;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: cAudioSpaceBG,
                    padding: const EdgeInsets.all(15),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (controller.isMySpace) {
                                controller.endRoom();
                              } else {
                                controller.leaveSpace();
                              }
                            },
                            child: Icon(
                              CupertinoIcons.chevron_back,
                              size: 24,
                              color: cPrimary,
                            ),
                          ),
                          Spacer(),
                          Row(
                            children: [
                              Image.asset(
                                MyImages.audioMic,
                                width: 20,
                                height: 20,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '${audioSpace.hostsWithAdmin.length}',
                                style: MyTextStyle.gilroySemiBold(
                                  size: 15,
                                  color: cWhite.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 15),
                          Row(
                            children: [
                              Image.asset(
                                MyImages.headphone,
                                width: 16,
                                height: 18,
                              ),
                              SizedBox(width: 7),
                              Text(
                                '${(audioSpace.requestsAndListener).length}',
                                style: MyTextStyle.gilroySemiBold(
                                  size: 15,
                                  color: cWhite.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: cAudioSpaceBG,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              audioSpace.title ?? '',
                              style: MyTextStyle.gilroyBold(size: 20, color: cWhite.withValues(alpha: 0.8)),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Wrap(
                              children: audioSpace.interests.map(
                                (e) {
                                  return FittedBox(
                                    child: Row(children: [
                                      Text(
                                        e.title ?? '',
                                        style: MyTextStyle.gilroyMedium(size: 16, color: cWhite.withValues(alpha: 0.4)),
                                      ),
                                      (audioSpace.interests.last.id != e.id)
                                          ? Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: CircleAvatar(
                                                backgroundColor: cPrimary,
                                                radius: 4,
                                              ),
                                            )
                                          : Container(),
                                    ]),
                                  );
                                },
                              ).toList(),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              audioSpace.description ?? '',
                              style: MyTextStyle.gilroyMedium(size: 15, color: cWhite.withValues(alpha: 0.8)),
                            ),
                            SizedBox(height: 15),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.end,
                            //   children: [
                            //     Icon(
                            //       CupertinoIcons.ellipsis,
                            //       size: 20,
                            //       color: cWhite.withValues(alpha: 0.4),
                            //     ),
                            //   ],
                            // )
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          AudioSpaceTabButton(controller: controller, type: AudioSpacePageType.room),
                          AudioSpaceTabButton(
                            controller: controller,
                            type: AudioSpacePageType.messages,
                            count: controller.countOfUnreadMessages(),
                          ),
                          AudioSpaceTabButton(controller: controller, type: AudioSpacePageType.members),
                          if (controller.showOptionsShow)
                            AudioSpaceTabButton(
                              controller: controller,
                              type: AudioSpacePageType.requests,
                              count: controller.audioSpace.requests.length,
                            ),
                        ],
                      ),
                      selectedScreen(controller)
                    ],
                  )),
                  bottomBar(controller)
                ],
              );
            }),
      ),
    );
  }

  Widget bottomBar(AudioSpaceController controller) {
    switch (controller.selectedType) {
      case AudioSpacePageType.room:
        return Container(
          color: cAudioSpaceDarkBG,
          padding: EdgeInsets.all(15),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (controller.isMySpace) {
                      controller.endRoom();
                    } else {
                      controller.leaveSpace();
                    }
                  },
                  child: Container(
                    decoration: ShapeDecoration(
                      shape: StadiumBorder(side: BorderSide(color: cRed)),
                      color: cRed.withValues(alpha: 0.15),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Text(
                      (controller.isMySpace ? LKeys.endRoom : LKeys.leaveRoom).tr,
                      style: MyTextStyle.gilroySemiBold(color: cRed),
                    ),
                  ),
                ),
                Spacer(),
                controller.amIHost
                    ? GestureDetector(
                        onTap: controller.toggleMic,
                        child: Container(
                          decoration: ShapeDecoration(
                            shape: StadiumBorder(),
                            color: cAudioSpaceLightBG,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Image.asset(
                                controller.myUser.micStatus == AudioSpaceMicStatus.muted ? MyImages.micSlash : MyImages.audioMic,
                                color: controller.myUser.micStatus == AudioSpaceMicStatus.muted ? cLightText : cGreen,
                                height: 20,
                                width: 20,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                controller.myUser.micStatus == AudioSpaceMicStatus.muted ? LKeys.micOff.tr : LKeys.micOn.tr,
                                style: MyTextStyle.gilroySemiBold(color: controller.myUser.micStatus == AudioSpaceMicStatus.muted ? cLightText : cGreen),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          controller.requestForHost(controller.myUser);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: controller.myUser.type == AudioSpaceUserType.requested ? cAudioSpaceLightBG : cWhite,
                            borderRadius: SmoothBorderRadius(cornerRadius: 100, cornerSmoothing: cornerSmoothing),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Image.asset(
                                MyImages.handRaised,
                                color: controller.myUser.type == AudioSpaceUserType.requested ? cLightText : cAudioSpaceBG,
                                height: 20,
                                width: 20,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                controller.myUser.type == AudioSpaceUserType.requested ? LKeys.handRaised.tr : LKeys.raiseHand.tr,
                                style: MyTextStyle.gilroySemiBold(color: controller.myUser.type == AudioSpaceUserType.requested ? cLightText : cAudioSpaceBG),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      case AudioSpacePageType.messages:
        return Container(
          color: cAudioSpaceDarkBG,
          padding: EdgeInsets.all(15),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: ShapeDecoration(color: cLightText.withValues(alpha: 0.15), shape: const SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 20, cornerSmoothing: cornerSmoothing)))),
                    padding: const EdgeInsets.only(left: 15, top: 2, right: 2, bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: TextField(
                                controller: controller.messageTextController,
                                maxLines: 5,
                                minLines: 1,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(hintText: LKeys.writeHere.tr, hintStyle: MyTextStyle.gilroyRegular(color: cLightText.withValues(alpha: 0.6)), border: InputBorder.none, counterText: '', isDense: true, contentPadding: const EdgeInsets.all(0)),
                                cursorColor: cPrimary,
                                style: MyTextStyle.gilroyRegular(color: cLightText),
                                textInputAction: TextInputAction.newline,
                              )),
                        ),
                        GestureDetector(
                          child: const SendBtn(),
                          onTap: controller.sendMessage,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case AudioSpacePageType.members:
        return controller.audioSpace.type == AudioSpaceType.private && controller.isMySpace
            ? Container(
                color: cAudioSpaceDarkBG,
                padding: EdgeInsets.all(15),
                child: SafeArea(
                  top: false,
                  child: GestureDetector(
                    onTap: controller.showAddUsersSheet,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cPrimary,
                        borderRadius: SmoothBorderRadius(cornerRadius: 100, cornerSmoothing: cornerSmoothing),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        LKeys.addUsers.tr,
                        style: MyTextStyle.gilroySemiBold(color: cBlack),
                      ),
                    ),
                  ),
                ),
              )
            : Container();
      case AudioSpacePageType.requests:
        return Container();
    }
  }

  Widget selectedScreen(AudioSpaceController controller) {
    switch (controller.selectedType) {
      case AudioSpacePageType.room:
        return AudioSpaceRoomView(controller);
      case AudioSpacePageType.messages:
        return AudioSpaceMessagesView(controller);
      case AudioSpacePageType.members:
        return AudioSpaceMembersView(controller);
      case AudioSpacePageType.requests:
        return AudioSpaceRequestsView(controller);
    }
  }
}

class AudioSpaceTabButton extends StatelessWidget {
  final AudioSpaceController controller;
  final AudioSpacePageType type;
  final int count;

  const AudioSpaceTabButton({
    super.key,
    required this.controller,
    required this.type,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    var isSelected = type == controller.selectedType;
    return GestureDetector(
      onTap: () {
        controller.selectType(type);
      },
      child: Container(
        alignment: Alignment.center,
        height: 35,
        width: Get.width / (controller.showOptionsShow ? 4 : 3),
        color: isSelected ? cPrimary : cAudioSpaceLightBG,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              type.title,
              style: MyTextStyle.gilroyMedium(color: controller.selectedType == type ? cBlack : cLightText, size: 14),
            ),
            if (count != 0) SizedBox(width: 5),
            if (count != 0)
              Container(
                decoration: ShapeDecoration(shape: CircleBorder(), color: isSelected ? cBlack : cPrimary),
                padding: EdgeInsets.all(7),
                child: Text(
                  count.makeToString(),
                  style: MyTextStyle.gilroySemiBold(color: isSelected ? cPrimary : cBlack, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum AudioSpacePageType {
  room,
  messages,
  members,
  requests;

  String get title {
    switch (this) {
      case AudioSpacePageType.room:
        return LKeys.room.tr;
      case AudioSpacePageType.messages:
        return LKeys.messages.tr;
      case AudioSpacePageType.members:
        return LKeys.members.tr;
      case AudioSpacePageType.requests:
        return LKeys.requests.tr;
    }
  }
}

class AudioSpaceIconButton extends StatelessWidget {
  final bool isFromSheet;
  final String title;
  final String image;
  final Color? bgColor;
  final Color? borderColor;
  final double size;
  final Color? color;
  final Function() onTap;

  const AudioSpaceIconButton({super.key, required this.image, this.color, required this.onTap, this.size = 20, required this.title, this.bgColor, required this.isFromSheet, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: isFromSheet
          ? Container(
              decoration: ShapeDecoration(
                shape: StadiumBorder(side: BorderSide(color: borderColor ?? cWhite.withValues(alpha: 0.1))),
                color: bgColor ?? cBlack,
              ),
              padding: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    image,
                    color: color ?? cLightText,
                    width: size,
                    height: size,
                  ),
                  SizedBox(width: 10),
                  Text(
                    title.tr,
                    style: MyTextStyle.gilroySemiBold(color: color),
                  )
                ],
              ),
            )
          : CircleAvatar(
              backgroundColor: Color(0xFF474747),
              radius: 20,
              child: Image.asset(
                image,
                color: color ?? cLightText,
                width: size,
                height: size,
              ),
            ),
    );
  }
}
