import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/moderator_service.dart';
import 'package:lumosocial/common/api_service/reel_service.dart';
import 'package:lumosocial/common/controller/base_controller.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/models/reel_comments_model.dart';
import 'package:lumosocial/models/reel_model.dart';
import 'package:lumosocial/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:lumosocial/screens/sheets/confirmation_sheet.dart';

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
    final commentText = textEditingController.text.trim();
    if (commentText.isEmpty) {
      return;
    }
    textEditingController.clear();

    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempComment = ReelComment(
      id: tempId,
      userId: SessionManager.shared.getUser()?.id,
      reelId: reel?.id,
      description: commentText,
      createdAt: DateTime.now(),
      user: SessionManager.shared.getUser(),
    );

    comments.insert(0, tempComment);
    reelController.reel.update((val) {
      val?.commentsCount = (reelController.reel.value?.commentsCount ?? 0) + 1;
    });

    ReelService.shared.addComment(comment: commentText, reelId: reel?.id ?? 0).then((comment) {
      if (comment != null) {
        final index = comments.indexWhere((element) => element.id == tempId);
        if (index != -1) {
          comment.user = SessionManager.shared.getUser();
          comments[index] = comment;
        }
      } else {
        comments.removeWhere((element) => element.id == tempId);
        reelController.reel.update((val) {
          val?.commentsCount = (reelController.reel.value?.commentsCount ?? 1) - 1;
        });
      }
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
