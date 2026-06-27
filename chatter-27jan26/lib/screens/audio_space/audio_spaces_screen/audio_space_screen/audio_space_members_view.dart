import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/utilities/const.dart';

import 'audio_space_controller.dart';
import 'audio_space_screen.dart';

class AudioSpaceMembersView extends StatelessWidget {
  final AudioSpaceController controller;

  AudioSpaceMembersView(this.controller);

  final EdgeInsets paddingSymmetric = EdgeInsets.symmetric(horizontal: 25);
  final EdgeInsets listPadding = EdgeInsets.only(bottom: 12, left: 12, right: 12, top: 8);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AudioSpaceController>(
      init: controller,
      builder: (controller) {
        return Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 15),
                _buildSectionHeader(LKeys.admin.tr),
                _buildUserList(controller.audioSpace.admins),
                if (controller.audioSpace.hosts.isNotEmpty) _buildSectionHeader(LKeys.hosts.tr),
                _buildUserList(controller.audioSpace.hosts),
                if (controller.audioSpace.requestsAndListener.isNotEmpty) _buildSectionHeader(LKeys.listeners.tr),
                _buildUserList(controller.audioSpace.requestsAndListener),
                if (controller.audioSpace.addedUsers.isNotEmpty) _buildSectionHeader(LKeys.addedUsers.tr),
                _buildUserList(controller.audioSpace.addedUsers),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: paddingSymmetric,
      child: Text(
        title,
        style: MyTextStyle.gilroyMedium(color: cLightText),
      ),
    );
  }

  Widget _buildUserList(List<AudioSpaceUser> users) {
    return ListView.separated(
      primary: false,
      shrinkWrap: true,
      itemCount: users.length,
      padding: listPadding,
      itemBuilder: (context, index) {
        var user = users[index];
        return AudioSpaceUserCard(user: user, controller: controller);
      },
      separatorBuilder: (context, index) => SizedBox(height: 12),
    );
  }
}

class AudioSpaceUserCard extends StatelessWidget {
  final AudioSpaceUser user;
  final AudioSpaceController controller;

  const AudioSpaceUserCard({
    Key? key,
    required this.user,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isAdmin = user.type == AudioSpaceUserType.admin;

    return GestureDetector(
      onTap: () {
        controller.showUserDetails(user);
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cAudioSpaceLightBG,
          borderRadius: SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: cornerSmoothing),
        ),
        child: Row(
          children: [
            MyCachedProfileImage(
              imageUrl: user.image,
              height: 40,
              width: 40,
              cornerRadius: 20,
            ),
            SizedBox(width: 10, height: 20),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      user.fullName ?? '',
                      style: MyTextStyle.gilroyBold(size: 18, color: cAudioSpaceText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // if (user.isVerified == true)
                  VerifyIcon(user: User(isVerified: 2)),
                ],
              ),
            ),
            if (!isAdmin && controller.showOptionsShow) options()
          ],
        ),
      ),
    );
  }

  Widget options() {
    switch (user.type ?? AudioSpaceUserType.listener) {
      case AudioSpaceUserType.listener:
        return OptionsForListener(user: user, controller: controller);
      case AudioSpaceUserType.host:
        return OptionsForHost(user: user, controller: controller);
      case AudioSpaceUserType.admin:
        return Container();
      case AudioSpaceUserType.requested:
        return OptionsForRequestedUser(user: user, controller: controller);
      case AudioSpaceUserType.kickedOut:
        return Container();
      case AudioSpaceUserType.added:
        return OptionsForAddedUser(user: user, controller: controller);
    }
  }
}

class OptionsForAddedUser extends StatelessWidget {
  final bool isFromSheet;
  final AudioSpaceUser user;
  final AudioSpaceController controller;

  const OptionsForAddedUser({
    Key? key,
    required this.user,
    required this.controller,
    this.isFromSheet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isFromSheet ? Column(children: options()) : Row(mainAxisAlignment: MainAxisAlignment.end, children: options());
  }

  List<Widget> options() {
    return [
      AudioSpaceIconButton(
        isFromSheet: isFromSheet,
        image: MyImages.trash,
        color: cRed,
        title: LKeys.removeTheUser,
        bgColor: cWhite,
        onTap: () {
          controller.removeAddedUser(user);
        },
      ),
    ];
  }
}

class OptionsForListener extends StatelessWidget {
  final bool isFromSheet;
  final AudioSpaceUser user;
  final AudioSpaceController controller;

  const OptionsForListener({
    Key? key,
    required this.user,
    required this.controller,
    this.isFromSheet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isFromSheet ? Column(children: options()) : Row(mainAxisAlignment: MainAxisAlignment.end, children: options());
  }

  List<Widget> options() {
    return [
      isFromSheet
          ? AudioSpaceIconButton(
              isFromSheet: isFromSheet,
              image: MyImages.makeHost,
              color: cWhite,
              onTap: () {
                controller.acceptRequest(user);
              },
              title: LKeys.makeHost,
            )
          : GestureDetector(
              onTap: () {
                controller.acceptRequest(user);
              },
              child: Container(
                decoration: ShapeDecoration(
                    color: cPrimary,
                    shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius.all(
                      SmoothRadius(cornerRadius: 12, cornerSmoothing: cornerSmoothing),
                    ))),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  LKeys.makeHost.tr,
                  style: MyTextStyle.gilroySemiBold(size: 12),
                ),
              ),
            ),
      SizedBox(width: 10, height: 20),
      AudioSpaceIconButton(
        isFromSheet: isFromSheet,
        image: MyImages.trash,
        color: cRed,
        bgColor: cWhite,
        onTap: () {
          controller.kickOut(user);
        },
        title: LKeys.removeFromSpace,
      ),
    ];
  }
}

class OptionsForRequestedUser extends StatelessWidget {
  final AudioSpaceUser user;
  final AudioSpaceController controller;
  final bool isFromSheet;

  const OptionsForRequestedUser({
    Key? key,
    required this.user,
    required this.controller,
    this.isFromSheet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isFromSheet ? Column(children: options()) : Row(mainAxisAlignment: MainAxisAlignment.end, children: options());
  }

  List<Widget> options() {
    return [
      AudioSpaceIconButton(
        isFromSheet: isFromSheet,
        image: MyImages.close,
        size: 14,
        color: cRed,
        bgColor: cRed.withValues(alpha: 0.1),
        borderColor: cRed,
        title: LKeys.rejectRequest,
        onTap: () {
          controller.rejectRequest(user);
        },
      ),
      SizedBox(width: 10, height: 20),
      AudioSpaceIconButton(
        isFromSheet: isFromSheet,
        title: LKeys.acceptRequest,
        image: MyImages.check,
        size: 18,
        bgColor: cGreen,
        color: cWhite,
        onTap: () {
          controller.acceptRequest(user);
        },
      ),
    ];
  }
}

class OptionsForHost extends StatelessWidget {
  final AudioSpaceUser user;
  final AudioSpaceController controller;
  final bool isFromSheet;

  const OptionsForHost({
    Key? key,
    required this.user,
    required this.controller,
    this.isFromSheet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isFromSheet ? Column(children: options()) : Row(mainAxisAlignment: MainAxisAlignment.end, children: options());
  }

  List<Widget> options() {
    return [
      AudioSpaceIconButton(
        isFromSheet: isFromSheet,
        title: user.micStatus == AudioSpaceMicStatus.on ? LKeys.mute : LKeys.unmute,
        image: user.micStatus == AudioSpaceMicStatus.on ? MyImages.micSlash : MyImages.audioMic,
        color: user.micStatus == AudioSpaceMicStatus.on ? cRed : cGreen,
        onTap: () {
          controller.micToggleOfUser(user);
        },
      ),
      SizedBox(width: 10, height: 20),
      AudioSpaceIconButton(
        isFromSheet: isFromSheet,
        title: LKeys.removeFromHost,
        image: MyImages.trash,
        color: cRed,
        bgColor: cWhite,
        onTap: () {
          controller.makeUserToListener(user);
        },
      ),
    ];
  }
}

class AudioSpaceUserSheet extends StatelessWidget {
  final AudioSpaceUser user;
  final AudioSpaceController controller;

  const AudioSpaceUserSheet({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        GetBuilder(
            init: controller,
            builder: (controller) {
              return Container(
                decoration: const ShapeDecoration(
                  shape: SmoothRectangleBorder(borderRadius: SmoothBorderRadius.only(topLeft: SmoothRadius(cornerRadius: 30, cornerSmoothing: cornerSmoothing), topRight: SmoothRadius(cornerRadius: 30, cornerSmoothing: cornerSmoothing))),
                  color: cBlack,
                ),
                padding: const EdgeInsets.all(25),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: ShapeDecoration(shape: StadiumBorder(side: BorderSide(color: cPrimary, width: 0.5)), color: cPrimary.withValues(alpha: 0.1)),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                            child: Text(
                              title().tr,
                              style: MyTextStyle.gilroyRegular(size: 14, color: cPrimary),
                            ),
                          ),
                          Spacer(),
                          XMarkButton(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        MyCachedProfileImage(
                          imageUrl: user.image,
                          height: 60,
                          width: 60,
                          cornerRadius: 15,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user.fullName ?? '',
                                  style: MyTextStyle.gilroyBold(size: 18, color: cAudioSpaceText),
                                  maxLines: 1,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                if (user.isVerified == true) VerifyIcon(user: User(isVerified: 2)),
                              ],
                            ),
                            Text(
                              user.username ?? '',
                              style: MyTextStyle.gilroyLight(size: 17, color: cPrimary),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 30),
                      if (user.type == AudioSpaceUserType.admin) options()
                    ],
                  ),
                ),
              );
            }),
      ],
    );
  }

  String title() {
    switch (user.type ?? AudioSpaceUserType.listener) {
      case AudioSpaceUserType.listener:
        return LKeys.listener;
      case AudioSpaceUserType.host:
        return LKeys.host;
      case AudioSpaceUserType.admin:
        return LKeys.admin;
      case AudioSpaceUserType.requested:
        return LKeys.listener;
      case AudioSpaceUserType.kickedOut:
        return LKeys.user;
      case AudioSpaceUserType.added:
        return LKeys.user;
    }
  }

  Widget options() {
    switch (user.type ?? AudioSpaceUserType.listener) {
      case AudioSpaceUserType.listener:
        return OptionsForListener(user: user, controller: controller, isFromSheet: true);
      case AudioSpaceUserType.host:
        return OptionsForHost(user: user, controller: controller, isFromSheet: true);
      case AudioSpaceUserType.admin:
        return Container();
      case AudioSpaceUserType.requested:
        return OptionsForRequestedUser(user: user, controller: controller, isFromSheet: true);
      case AudioSpaceUserType.kickedOut:
        return Container();
      case AudioSpaceUserType.added:
        return OptionsForAddedUser(user: user, controller: controller, isFromSheet: true);
    }
  }
}
