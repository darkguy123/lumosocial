import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/load_more_widget.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';
import 'package:untitled/screens/extra_views/buttons.dart';
import 'package:untitled/screens/extra_views/search_bar.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/search_screen/search_controller.dart';
import 'package:untitled/screens/search_screen/search_screen.dart';
import 'package:untitled/utilities/const.dart';

class AudioSpaceInviteScreen extends StatelessWidget {
  final List<AudioSpaceUser> audioSpaceUsers;
  final Function(List<AudioSpaceUser> users) onBack;

  const AudioSpaceInviteScreen({super.key, required this.audioSpaceUsers, required this.onBack});

  @override
  Widget build(BuildContext context) {
    var controller = SearchScreenController();
    controller.selectedUsers = audioSpaceUsers;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        onBack(controller.selectedUsers);
      },
      child: Container(
        color: cWhite,
        child: GetBuilder(
            init: controller,
            builder: (context) {
              return Column(
                children: [
                  Container(
                    height: AppBar().preferredSize.height,
                    color: cDarkBG,
                  ),
                  const TopBarForInView(
                    title: LKeys.addUsers,
                    backIcon: Icons.close_rounded,
                    size: 30,
                  ),
                  MySearchBar(
                    controller: controller.textEditingController,
                    onChange: (text) {
                      controller.searchUser(shouldErase: true);
                    },
                  ),
                  Expanded(
                    child: LoadMoreWidget(
                      loadMore: controller.searchUser,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: controller.users.length,
                        itemBuilder: (context, index) {
                          var user = controller.users[index];
                          if (user.id == SessionManager.shared.getUserID()) {
                            return Container();
                          }
                          var audioSpaceUser = controller.selectedUsers.firstWhereOrNull((element) => element.id == user.id);
                          return ProfileCard(
                            user: user,
                            widget: GestureDetector(
                              onTap: () {
                                controller.addAndRemoveUser(user);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 18),
                                decoration: ShapeDecoration(
                                    color: !controller.isUserSelected(user)
                                        ? cPrimary.withValues(alpha: 0.15)
                                        : audioSpaceUser?.type == AudioSpaceUserType.added
                                            ? cRed.withValues(alpha: 0.15)
                                            : cLightBg,
                                    shape: const SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 5, cornerSmoothing: cornerSmoothing)))),
                                child: Text(
                                  (!controller.isUserSelected(user)
                                          ? LKeys.add
                                          : audioSpaceUser?.type == AudioSpaceUserType.added
                                              ? LKeys.remove
                                              : LKeys.alreadyJoined)
                                      .tr
                                      .toUpperCase(),
                                  style: MyTextStyle.gilroySemiBold(
                                          size: 12,
                                          color: !controller.isUserSelected(user)
                                              ? cBlack
                                              : audioSpaceUser?.type == AudioSpaceUserType.added
                                                  ? cRed
                                                  : cLightText)
                                      .copyWith(letterSpacing: 1),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CommonButton(
                        text: LKeys.done,
                        onTap: () {
                          Get.back();
                        }),
                  )
                ],
              );
            }),
      ),
    );
  }
}
