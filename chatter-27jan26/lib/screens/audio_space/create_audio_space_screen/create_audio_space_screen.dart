import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_screen.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/extra_views/buttons.dart';
import 'package:untitled/screens/extra_views/search_bar.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/interests_screen/interests_controller.dart';
import 'package:untitled/screens/interests_screen/interests_screen.dart';
import 'package:untitled/screens/rooms_you_own/create_room_screen/create_room_screen.dart';
import 'package:untitled/utilities/const.dart';

import 'create_audio_space_controller.dart';

class CreateAudioSpaceScreen extends StatelessWidget {
  const CreateAudioSpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CreateAudioSpaceController controller = CreateAudioSpaceController();
    return GetBuilder(
        init: controller,
        builder: (controller) {
          var hostsLimit = SessionManager.shared.getSettings()?.audioSpaceHostsLimit ?? 0;
          if (controller.space != null) {
            return AudioSpaceScreen(audioSpace: controller.space!);
          } else {
            return Scaffold(
              body: !controller.isNext
                  ? Column(
                      children: [
                        TopBarForInView(title: LKeys.startNewRoom),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  const CreateRoomHeading(title: LKeys.roomName),
                                  MyTextField(controller: controller.titleTextController, placeHolder: "Nature Lover"),
                                  CreateRoomHeading(
                                    title: LKeys.shortDescription,
                                    bracketText: "(${controller.descriptionTextController.text.length}/${Limits.roomDescCount})",
                                  ),
                                  MyTextField(
                                    controller: controller.descriptionTextController,
                                    placeHolder: LKeys.whatIsYourRoomAbout,
                                    isEditor: true,
                                    limit: Limits.roomDescCount,
                                    onChange: (text) {
                                      controller.update();
                                    },
                                  ),
                                  Column(
                                    children: [
                                      CreateRoomHeading(
                                        title: LKeys.selectTag,
                                        bracketText: "(${controller.selectedInterests.length}/${Limits.interestCount})",
                                      ),
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        alignment: WrapAlignment.center,
                                        children: InterestsController.interests.map((e) {
                                          return InterestTag(
                                              interest: e.title ?? "",
                                              isContain: controller.selectedInterests.contains(e),
                                              onTap: () {
                                                controller.toggleInterest(e);
                                              });
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  const CreateRoomHeading(title: LKeys.visibility),
                                  ListView.builder(
                                    padding: EdgeInsets.only(top: 10, bottom: 0),
                                    itemCount: AudioSpaceType.values.length,
                                    primary: false,
                                    shrinkWrap: true,
                                    itemBuilder: (context, index) {
                                      var type = AudioSpaceType.values[index];
                                      return GestureDetector(
                                        child: AudioSpaceTypeCard(
                                          type: type,
                                          isSelected: controller.selectedSpaceType == type,
                                        ),
                                        onTap: () {
                                          controller.changeType(type);
                                        },
                                      );
                                    },
                                  ),
                                  if (controller.selectedSpaceType == AudioSpaceType.private)
                                    controller.addedUsers.length == 0
                                        ? GestureDetector(
                                            onTap: () {
                                              controller.showAddUsersSheet();
                                            },
                                            child: Container(
                                              alignment: Alignment.center,
                                              padding: EdgeInsets.symmetric(vertical: 20),
                                              decoration: ShapeDecoration(color: cLightBg, shape: SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 12, cornerSmoothing: cornerSmoothing)))),
                                              child: Text(
                                                LKeys.addUsers.tr,
                                                style: MyTextStyle.gilroySemiBold(color: cBlack),
                                              ),
                                            ),
                                          )
                                        : Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: 110,
                                                  child: ListView.builder(
                                                    itemCount: controller.addedUsers.length,
                                                    scrollDirection: Axis.horizontal,
                                                    itemBuilder: (context, index) {
                                                      var user = controller.addedUsers[index];
                                                      return GestureDetector(
                                                        onTap: () {
                                                          controller.removeUserFromSpace(user);
                                                        },
                                                        child: Container(
                                                          width: 80,
                                                          margin: const EdgeInsets.only(right: 7),
                                                          child: Stack(
                                                            alignment: Alignment.centerLeft,
                                                            children: [
                                                              Column(
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(bottom: 7, top: 10),
                                                                    child: ClipSmoothRect(
                                                                      radius: SmoothBorderRadius(cornerRadius: 15, cornerSmoothing: cornerSmoothing),
                                                                      child: MyCachedProfileImage(
                                                                        imageUrl: user.image,
                                                                        fullName: user.fullName,
                                                                        height: 70,
                                                                        width: 70,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    width: 70,
                                                                    child: Text(
                                                                      user.fullName ?? '',
                                                                      style: MyTextStyle.gilroySemiBold(size: 14, color: cDarkText),
                                                                      maxLines: 1,
                                                                      textAlign: TextAlign.center,
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                              Positioned(
                                                                right: 3,
                                                                top: 7,
                                                                child: ClipRRect(
                                                                  borderRadius: BorderRadius.circular(50),
                                                                  child: Container(color: cWhite, child: Icon(Icons.remove_circle, color: cRed)),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: controller.showAddUsersSheet,
                                                child: Container(
                                                  decoration: ShapeDecoration(color: cLightBg, shape: SmoothRectangleBorder(borderRadius: SmoothBorderRadius(cornerRadius: 15))),
                                                  height: 70,
                                                  width: 70,
                                                  margin: EdgeInsets.only(bottom: 7, top: 10),
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 40,
                                                    color: cLightText,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                  SizedBox(height: 30),
                                  SafeArea(
                                    top: false,
                                    child: CommonButton(
                                      text: LKeys.next,
                                      onTap: () {
                                        controller.next();
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TopBarForInView(
                          title: LKeys.selectHosts,
                          onTap: () {
                            controller.isNext = false;
                            controller.update();
                          },
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: controller.scrollController,
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CreateRoomHeading(
                                    title: LKeys.selectHosts,
                                    bracketText: hostsLimit != 0 ? '(${controller.hosts.length}/${hostsLimit})' : '',
                                  ),
                                  Text(
                                    (controller.selectedSpaceType == AudioSpaceType.public ? LKeys.youCanAddHosts : LKeys.youCanSelectHostFromSelectedUsers).tr,
                                    style: MyTextStyle.gilroyRegular(size: 14, color: cLightText),
                                  ),
                                  SizedBox(
                                    height: 110,
                                    child: controller.hosts.length == 0
                                        ? ListView.builder(
                                            itemCount: 5,
                                            scrollDirection: Axis.horizontal,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 10),
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      decoration: ShapeDecoration(color: cLightBg, shape: SmoothRectangleBorder(borderRadius: SmoothBorderRadius(cornerRadius: 15))),
                                                      height: 70,
                                                      width: 70,
                                                      margin: EdgeInsets.only(bottom: 7, top: 10),
                                                    ),
                                                    Text(
                                                      'Host',
                                                      style: MyTextStyle.gilroySemiBold(size: 14, color: cDarkText),
                                                    )
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                        : ListView.builder(
                                            itemCount: controller.hosts.length,
                                            scrollDirection: Axis.horizontal,
                                            itemBuilder: (context, index) {
                                              var user = controller.hosts[index];
                                              return GestureDetector(
                                                onTap: () {
                                                  controller.toggleHost(user);
                                                },
                                                child: Container(
                                                  width: 80,
                                                  margin: const EdgeInsets.only(right: 7),
                                                  child: Stack(
                                                    alignment: Alignment.centerLeft,
                                                    children: [
                                                      Column(
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.only(bottom: 7, top: 10),
                                                            child: MyCachedProfileImage(
                                                              imageUrl: user.image,
                                                              fullName: user.fullName,
                                                              height: 70,
                                                              width: 70,
                                                              cornerRadius: 15,
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 70,
                                                            child: Text(
                                                              user.fullName ?? '',
                                                              style: MyTextStyle.gilroySemiBold(size: 14, color: cDarkText),
                                                              maxLines: 1,
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                      Positioned(
                                                        right: 3,
                                                        top: 7,
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(50),
                                                          child: Container(color: cWhite, child: Icon(Icons.remove_circle, color: cRed)),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(height: 20),
                                  MySearchBar(
                                      controller: controller.searchTextController,
                                      onChange: (text) {
                                        controller.allFollowers.clear();
                                        controller.fetchFollowers();
                                      }),
                                  const SizedBox(height: 10),
                                  ListView.builder(
                                    primary: false,
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.all(0),
                                    itemCount: (controller.selectedSpaceType == AudioSpaceType.public ? controller.allFollowers : controller.addedUsers).length,
                                    itemBuilder: (context, index) {
                                      var user = (controller.selectedSpaceType == AudioSpaceType.public ? controller.allFollowers : controller.addedUsers)[index];
                                      var isSelected = (controller.hosts.firstWhereOrNull((element) => user.id == element.id) != null);
                                      return Column(
                                        children: [
                                          Row(
                                            children: [
                                              MyCachedImage(
                                                imageUrl: user.image,
                                                width: 55,
                                                height: 55,
                                                cornerRadius: 12,
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        user.fullName ?? 'Unknown',
                                                        style: MyTextStyle.gilroyBold(size: 17),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      VerifyIcon(user: User(isVerified: user.isVerified == true ? 2 : 0))
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    "@${user.username ?? "unknown"}",
                                                    style: MyTextStyle.gilroyLight(color: cLightText, size: 15),
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              GestureDetector(
                                                onTap: () {
                                                  if (hostsLimit == 0 || controller.hosts.length < hostsLimit) {
                                                    controller.toggleHost(user);
                                                  } else {
                                                    controller.showSnackBar(LKeys.hostLimitReached.tr, type: SnackBarType.error);
                                                  }
                                                },
                                                child: Container(
                                                  decoration: ShapeDecoration(
                                                    shape: CircleBorder(),
                                                    color: (isSelected ? cRed : cGreen).withValues(alpha: 0.1),
                                                  ),
                                                  padding: EdgeInsets.all(12),
                                                  child: Image.asset(
                                                    isSelected ? MyImages.close : MyImages.check,
                                                    color: (isSelected ? cRed : cGreen),
                                                    width: 15,
                                                    height: 15,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider()
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: CommonButton(
                              text: LKeys.startNewRoom,
                              onTap: controller.startAudioSpace,
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          }
        });
  }
}

class AudioSpaceTypeCard extends StatelessWidget {
  final AudioSpaceType type;
  final bool isSelected;

  const AudioSpaceTypeCard({super.key, required this.type, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: cLightBg,
        shape: SmoothRectangleBorder(
          side: BorderSide(
            color: isSelected ? cPrimary : cLightBg,
            width: 2,
          ),
          borderRadius: SmoothBorderRadius(
            cornerRadius: 15,
            cornerSmoothing: cornerSmoothing,
          ),
          borderAlign: BorderAlign.outside,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      margin: EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type.title.toUpperCase(),
            style: MyTextStyle.gilroyExtraBold(),
          ),
          SizedBox(height: 5),
          Text(
            type.description,
            style: MyTextStyle.gilroyMedium(color: cLightText),
          ),
        ],
      ),
    );
  }
}
