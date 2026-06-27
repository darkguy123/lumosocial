import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_controller.dart';
import 'package:untitled/utilities/const.dart';

class AudioSpaceEndedForHostScreen extends StatelessWidget {
  final AudioSpaceController controller;

  const AudioSpaceEndedForHostScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    var audioSpace = controller.audioSpace;
    var seconds = DateTime.now().difference(audioSpace.createdAt ?? DateTime.now()).inSeconds;
    return Container(
      color: cMainText,
      child: Column(
        children: [
          Container(
            height: AppBar().preferredSize.height,
            color: cAudioSpaceDarkBG,
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: Get.height / 10),
            child: Column(
              children: [
                Text(
                  formattedTime2(seconds),
                  style: MyTextStyle.gilroyBold(size: 25, color: cWhite),
                ),
                Text(
                  LKeys.roomEnded.tr,
                  style: MyTextStyle.gilroySemiBold(size: 21, color: cPrimary),
                ),
              ],
            ),
          ),
          divider(),
          Text(
            LKeys.roomEnded.tr,
            style: MyTextStyle.gilroySemiBold(size: 16, color: cRed),
          ),
          divider(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
          divider(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin: EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Image.asset(
                  MyImages.headphone,
                  width: 16,
                  height: 18,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  LKeys.totalHosts.tr,
                  style: MyTextStyle.gilroyMedium(size: 18, color: cWhite.withValues(alpha: 0.8)),
                ),
                Spacer(),
                Text(
                  '${audioSpace.hostsWithAdmin.length}',
                  style: MyTextStyle.gilroyMedium(size: 18, color: cPrimary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Image.asset(
                  MyImages.micFill,
                  width: 16,
                  height: 20,
                  color: cWhite,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  LKeys.totalListener.tr,
                  style: MyTextStyle.gilroyMedium(size: 18, color: cWhite.withValues(alpha: 0.8)),
                ),
                Spacer(),
                Text(
                  '${audioSpace.listener.length}',
                  style: MyTextStyle.gilroyMedium(size: 18, color: cPrimary),
                ),
              ],
            ),
          ),
          divider(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  LKeys.totalMembers.tr,
                  style: MyTextStyle.gilroyBold(size: 22, color: cWhite.withValues(alpha: 0.8)),
                ),
                Spacer(),
                Text(
                  '${((audioSpace.users ?? []).length) - audioSpace.addedUsers.length}',
                  style: MyTextStyle.gilroyBold(size: 22, color: cPrimary),
                ),
              ],
            ),
          ),
          divider(),
          Spacer(),
          GestureDetector(
            onTap: () {
              Get.back();
              Get.back();
            },
            child: SafeArea(
              child: ClipRRect(
                borderRadius: SmoothBorderRadius(cornerRadius: 100, cornerSmoothing: cornerSmoothing),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 60),
                  color: cWhite.withValues(alpha: 0.1),
                  child: Text(
                    LKeys.close.tr,
                    style: MyTextStyle.gilroySemiBold(size: 16, color: cWhite.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  String formattedTime2(int time) // --> time in form of seconds
  {
    final int hour = (time / 3600).floor();
    final int minute = ((time / 3600 - hour) * 60).floor();
    final int second = ((((time / 3600 - hour) * 60) - minute) * 60).floor();

    final String setTime = [
      if (hour > 0) hour.toString().padLeft(2, "0"),
      minute.toString().padLeft(2, "0"),
      second.toString().padLeft(2, '0'),
    ].join(':');
    return setTime;
  }

  Widget divider() {
    return Container(
      height: 2,
      margin: EdgeInsets.symmetric(vertical: 20),
      color: cAudioSpaceLightBG,
    );
  }
}
