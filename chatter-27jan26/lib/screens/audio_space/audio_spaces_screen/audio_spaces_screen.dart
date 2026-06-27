import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_screen.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_spaces_controller.dart';
import 'package:untitled/screens/audio_space/models/audio_space.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';
import 'package:untitled/screens/extra_views/buttons.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/rooms_screen/rooms_by_interest/room_explore_by_interests.dart';
import 'package:untitled/utilities/const.dart';

import '../create_audio_space_screen/create_audio_space_screen.dart';

class AudioSpacesScreen extends StatelessWidget {
  const AudioSpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AudioSpacesController controller = AudioSpacesController();
    return Scaffold(
      body: GetBuilder(
          init: controller,
          builder: (controller) {
            return Column(
              children: [
                top(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        RoomExploreByInterests(audioSpaces: controller.spaces),
                        ListView.builder(
                          shrinkWrap: true,
                          primary: false,
                          itemCount: controller.spaces.length,
                          padding: EdgeInsets.only(top: 1),
                          itemBuilder: (context, index) {
                            return AudioSpaceCard(audioSpace: controller.spaces[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: CommonButton(
                      text: LKeys.startRoom,
                      onTap: () {
                        Get.to(() => CreateAudioSpaceScreen());
                      }),
                )
              ],
            );
          }),
    );
  }

  Widget top() {
    return Container(
      color: cBG,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const BackButton(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TopBarForLogin(
                  titleEnd: LKeys.spaces,
                  alignment: MainAxisAlignment.start,
                  titleStart: LKeys.audio,
                  size: 20,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class AudioSpaceCard extends StatelessWidget {
  final AudioSpace audioSpace;

  const AudioSpaceCard({super.key, required this.audioSpace});

  void _onTapHandler(BuildContext context) {
    var listenersLimit = SessionManager.shared.getSettings()?.audioSpaceListenersLimit ?? 0;
    if (listenersLimit == 0 || audioSpace.requestsAndListener.length < listenersLimit || (SessionManager.shared.getUserID() == audioSpace.admins.first.id?.toInt())) {
      var user = ((audioSpace.users ?? []) + (audioSpace.leavedUsers ?? [])).firstWhereOrNull((u) => u.id == SessionManager.shared.getUserID());

      if (user?.type == AudioSpaceUserType.kickedOut) {
        BaseController.share.showSnackBar(LKeys.adminHasKickedYouOut.tr);
      } else {
        Get.to(() => AudioSpaceScreen(audioSpace: audioSpace));
      }
    } else {
      BaseController.share.showSnackBar(LKeys.listenerLimitReached.tr, type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTapHandler(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: ClipSmoothRect(
          radius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 15, cornerSmoothing: cornerSmoothing)),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            color: cAudioSpaceBG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  audioSpace.title ?? '',
                  style: MyTextStyle.gilroyBold(size: 20, color: cWhite.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 5),
                _buildInterests(),
                const SizedBox(height: 5),
                _buildHostsList(),
                Text(
                  audioSpace.description ?? '',
                  style: MyTextStyle.gilroyMedium(size: 15, color: cWhite.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 15),
                _buildBottomRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterests() {
    return Wrap(
      children: audioSpace.interests.map((e) {
        return FittedBox(
          child: Row(children: [
            Text(
              e.title ?? '',
              style: MyTextStyle.gilroyMedium(size: 16, color: cWhite.withValues(alpha: 0.4)),
            ),
            if (audioSpace.interests.last.id != e.id)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: CircleAvatar(
                  backgroundColor: cPrimary,
                  radius: 4,
                ),
              ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildHostsList() {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        itemCount: audioSpace.hostsWithAdmin.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final user = audioSpace.hostsWithAdmin[index];
          return Container(
            width: 70,
            padding: const EdgeInsets.only(right: 8.0),
            child: Column(
              children: [
                ClipSmoothRect(
                  radius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 15, cornerSmoothing: cornerSmoothing)),
                  child: MyCachedProfileImage(
                    height: 60,
                    width: 60,
                    fullName: user.fullName,
                    imageUrl: user.image,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  user.fullName ?? '',
                  style: MyTextStyle.gilroySemiBold(size: 14, color: cWhite.withValues(alpha: 0.4)),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        _buildIconTextRow(MyImages.audioMic, audioSpace.hostsWithAdmin.length.toString(), 20),
        const SizedBox(width: 15),
        _buildIconTextRow(MyImages.headphone, audioSpace.requestsAndListener.length.toString(), 16),
        const Spacer(),
        // Optionally add more actions here, like an ellipsis button for more options
      ],
    );
  }

  Widget _buildIconTextRow(String asset, String text, double iconSize) {
    return Row(
      children: [
        Image.asset(asset, width: iconSize, height: iconSize),
        const SizedBox(width: 3),
        Text(
          text,
          style: MyTextStyle.gilroySemiBold(size: 15, color: cWhite.withValues(alpha: 0.4)),
        ),
      ],
    );
  }
}
