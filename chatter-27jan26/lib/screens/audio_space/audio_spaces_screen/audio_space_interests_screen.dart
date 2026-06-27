import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_spaces_screen.dart';
import 'package:untitled/screens/audio_space/models/audio_space.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/rooms_screen/rooms_by_interest/room_explore_by_interests.dart';
import 'package:untitled/utilities/const.dart';

import 'audio_spaces_controller.dart';

class AudioSpaceInterestsScreen extends StatelessWidget {
  final Interest interest;
  final List<AudioSpace> audioSpaces;
  final AudioSpacesController controller;

  const AudioSpaceInterestsScreen({super.key, required this.interest, required this.audioSpaces, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder(
          init: controller,
          builder: (controller) {
            var filteredSpaces = controller.spaces.where((element) => element.interests.contains(interest)).toList();
            return Column(
              children: [
                top(),
                Expanded(
                  child: controller.spaces.isEmpty
                      ? Center(
                          child: Text(
                          LKeys.noDataFound.tr,
                          style: MyTextStyle.gilroySemiBold(color: cLightText),
                        ))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: filteredSpaces.length,
                          itemBuilder: (context, index) {
                            return AudioSpaceCard(audioSpace: filteredSpaces[index]);
                          },
                        ),
                ),
              ],
            );
          }),
    );
  }

  Widget top() {
    return Container(
      color: cBG,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                  titleEnd: LKeys.interests,
                  alignment: MainAxisAlignment.start,
                  titleStart: LKeys.roomsBy,
                  size: 20,
                ),
                RoomInterestTag(title: interest.title, count: audioSpaces.length)
              ],
            )
          ],
        ),
      ),
    );
  }
}
