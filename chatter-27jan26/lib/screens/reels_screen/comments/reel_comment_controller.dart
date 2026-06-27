import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/moderator_service.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/reel_comments_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';

class ReelCommentController extends BaseController {
  final ReelController reelController;
  RxList<ReelComment> comments = RxList();
  TextEditingController textEditingController = TextEditingController();

  ReelCommentController(this.reelController);

  Reel? get reel => reelController.reel.value;

  @override
  void onReady() {
    fetchComments();
    super.onReady();
  }

  Future<void> fetchComments() async {
    if (comments.isEmpty) {
      startLoading();
    }

    this.comments.addAll(
          await ReelService.shared.fetchComments(reelId: reel?.id ?? 0, start: comments.length),
        );
    stopLoading();
  }

  void addComment() async {
    if (textEditingController.text.isEmpty) {
      return;
    }
    startLoading();

    ReelComment? comment = await ReelService.shared.addComment(comment: textEditingController.text, reelId: reel?.id ?? 0);
    stopLoading();
    if (comment != null) {
      comment.user = SessionManager.shared.getUser();
      comments.insert(0, comment);
    }
    textEditingController.clear();
    reelController.reel.update((val) {
      val?.commentsCount = (reelController.reel.value?.commentsCount ?? 0) + 1;
    });
  }

  void deleteComment(ReelComment comment) async {
    startLoading();
    await ReelService.shared.deleteComment(comment.id ?? 0);
    stopLoading();
    comments.removeWhere((element) => element.id == comment.id);
    reelController.reel.update((val) {
      val?.commentsCount = (reelController.reel.value?.commentsCount ?? 0) - 1;
    });
  }

  void deleteCommentByModerator(ReelComment comment) {
    Get.bottomSheet(ConfirmationSheet(
      desc: LKeys.deleteCommentDisc,
      buttonTitle: LKeys.delete,
      onTap: () {
        stopLoading();
        ModeratorService.shared.deleteReelComment(commentId: comment.id?.toInt() ?? 0);
        comments.removeWhere((element) => element.id == comment.id);
        reelController.reel.value?.commentsCount = (reelController.reel.value?.commentsCount ?? 0) - 1;
        reelController.update(['comment']);
        update();
      },
    ));
  }
}
