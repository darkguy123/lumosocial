import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/load_more_widget.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/reels_screen/comments/reel_comment_card.dart';
import 'package:untitled/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';

import 'reel_comment_controller.dart';

class ReelCommentScreen extends StatelessWidget {
  final ReelController reelController;

  const ReelCommentScreen({Key? key, required this.reelController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(ReelCommentController(reelController));
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(color: cBlack, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 15,
                  ),
                  Text(
                    LKeys.comments.tr,
                    style: MyTextStyle.gilroyMedium(color: cWhite, size: 18),
                  ),
                  const Spacer(),
                  const XMarkButton(),
                  const SizedBox(
                    width: 5,
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Divider(
                color: cLightIcon.withValues(alpha: 0.5),
              ),
              Expanded(
                child: Obx(() {
                  return NoDataView(
                    showShow: controller.comments.isEmpty && !controller.isLoading.value,
                    child: LoadMoreWidget(
                      loadMore: controller.fetchComments,
                      child: ListView.builder(
                        itemCount: controller.comments.length,
                        itemBuilder: (context, index) {
                          return ReelCommentCard(
                              comment: controller.comments[index],
                              onDeleteTap: () {
                                Get.bottomSheet(ConfirmationSheet(
                                  desc: LKeys.deleteCommentDisc,
                                  buttonTitle: LKeys.delete,
                                  onTap: () {
                                    controller.deleteComment(controller.comments[index]);
                                  },
                                ));
                              },
                              onDeleteModeratorTap: () {
                                controller.deleteCommentByModerator(controller.comments[index]);
                              });
                        },
                      ),
                    ),
                  );
                }),
              ),
              commentTextField(controller)
            ],
          ),
        ),
      ),
    );
  }

  Widget commentTextField(ReelCommentController controller) {
    return Container(
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: cWhite.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller.textEditingController,
              decoration: InputDecoration(hintText: LKeys.writeSomething.tr, hintStyle: MyTextStyle.gilroyRegular(color: cLightText), border: InputBorder.none, counterText: '', isDense: true, contentPadding: const EdgeInsets.all(0)),
              cursorColor: cPrimary,
              style: MyTextStyle.gilroyRegular(color: cWhite),
            ),
          ),
          GestureDetector(
            child: const SendBtn(),
            onTap: () {
              controller.addComment();
            },
          )
        ],
      ),
    );
  }
}

class SendBtn extends StatelessWidget {
  const SendBtn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: cPrimary,
      foregroundColor: cBlack,
      radius: 16,
      child: Container(
        padding: const EdgeInsets.only(left: 2),
        child: Image.asset(
          MyImages.send,
          height: 20,
          width: 20,
        ),
      ),
    );
  }
}
