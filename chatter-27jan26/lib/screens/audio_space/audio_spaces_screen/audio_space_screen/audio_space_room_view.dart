import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';
import 'package:untitled/screens/rooms_you_own/create_room_screen/create_room_screen.dart';
import 'package:untitled/utilities/const.dart';

import 'audio_space_controller.dart';

class AudioSpaceRoomView extends StatelessWidget {
  final AudioSpaceController controller;

  AudioSpaceRoomView(this.controller);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
                shrinkWrap: true,
                primary: false,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                ),
                itemCount: controller.audioSpace.hostsWithAdmin.length,
                padding: EdgeInsets.only(top: 20),
                itemBuilder: (BuildContext context, int index) {
                  var user = (controller.audioSpace.admins + controller.audioSpace.hosts)[index];
                  return GestureDetector(
                    onTap: () {
                      controller.showUserDetails(user);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipSmoothRect(
                          radius: SmoothBorderRadius(cornerRadius: 26.5, cornerSmoothing: cornerSmoothing),
                          child: Container(
                            color: user.micStatus == AudioSpaceMicStatus.on ? cPrimary : Colors.transparent,
                            padding: const EdgeInsets.all(1.5),
                            child: MyCachedProfileImage(
                              width: Get.width / 4,
                              height: Get.width / 4,
                              imageUrl: user.image,
                              fullName: user.fullName,
                              cornerRadius: 25,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          width: Get.width / 4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  user.fullName ?? '',
                                  style: MyTextStyle.gilroySemiBold(size: 18, color: cWhite.withValues(alpha: 0.5)),
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Image.asset(
                                user.micStatus == AudioSpaceMicStatus.on ? MyImages.audioMic : MyImages.micSlash,
                                height: 20,
                                width: 20,
                                color: cWhite.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                      ],
                    ),
                  );
                }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                LKeys.otherListeners.tr,
                style: MyTextStyle.gilroyMedium(color: cWhite.withValues(alpha: 0.4)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  color: cAudioSpaceLightBG,
                  padding: const EdgeInsets.only(right: 15, left: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: MyTextField(
                          color: cAudioSpaceLightBG,
                          controller: controller.searchController,
                          placeHolder: LKeys.searchHere,
                          onChange: (text) {
                            controller.filterListeners();
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            GridView.builder(
                shrinkWrap: true,
                primary: false,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.73),
                itemCount: controller.allListener.length,
                padding: EdgeInsets.only(top: 10, right: 10, left: 10),
                itemBuilder: (BuildContext context, int index) {
                  var user = controller.allListener[index];
                  return GestureDetector(
                    onTap: () {
                      controller.showUserDetails(user);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MyCachedProfileImage(
                          imageUrl: user.image,
                          fullName: user.fullName,
                          height: (Get.width / 5) - 15,
                          width: (Get.width / 5) - 15,
                          cornerRadius: 15,
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Expanded(
                          child: Text(
                            user.fullName ?? '',
                            style: MyTextStyle.gilroySemiBold(size: 14, color: cWhite.withValues(alpha: 0.4)),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                      ],
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }
}
