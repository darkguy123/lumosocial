import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/moderator_service.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/comments_model.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/screens/post/post_controller.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';

class CommentController extends BaseController {
  final Post post;
  final PostController postController;
  List<Comment> comments = [];
  TextEditingController textEditingController = TextEditingController();

  CommentController(this.post, this.postController);

  @override
  void onReady() {
    fetchComments();
    super.onReady();
  }

  Future<void> fetchComments() async {
    if (comments.isEmpty) {
      startLoading();
    }
    await PostService.shared.fetchComments(post.id ?? 0, comments.length, (comments) {
      stopLoading();
      this.comments.addAll(comments);
      update();
    });
  }

  void addComment() {
    if (textEditingController.text.isEmpty) {
      return;
    }
    startLoading();
    PostService.shared.addComment(textEditingController.text, post.id ?? 0, (comment) {
      stopLoading();
      comment.user = SessionManager.shared.getUser();
      comments.insert(0, comment);
      textEditingController.clear();
      postController.post.commentsCount += 1;
      postController.update(['comment']);
      postController.update();
      update();
    });
  }

  void deleteComment(Comment comment) {
    startLoading();
    PostService.shared.deleteComment(comment.id ?? 0, () {
      stopLoading();
      comments.removeWhere((element) => element.id == comment.id);
      postController.post.commentsCount -= 1;
      postController.update(['comment']);
      update();
    });
  }

  void deleteCommentByModerator(Comment comment) {
    Get.bottomSheet(ConfirmationSheet(
      desc: LKeys.deleteCommentDisc,
      buttonTitle: LKeys.delete,
      onTap: () {
        stopLoading();
        ModeratorService.shared.deleteComment(
            commentId: comment.id?.toInt() ?? 0,
            completion: () {
              stopLoading();
              comments.removeWhere((element) => element.id == comment.id);
              postController.post.commentsCount -= 1;
              postController.update(['comment']);
              update();
            });
      },
    ));
  }

  void likeDislikeComment(Comment comment) {
    // startLoading();
    var index = comments.indexWhere(
      (element) => element.id == comment.id,
    );
    print(comments.map(
      (e) => e.toJson(),
    ));
    print(comment.isLike);
    comments[index].isLike = comment.isLike == 1 ? 0 : 1;
    comments[index].commentLikeCount = comment.isLike == 1 ? (comments[index].commentLikeCount ?? 0) + 1 : (comments[index].commentLikeCount ?? 0) - 1;
    update();
    PostService.shared.likeDislike(comment.id ?? 0, (_) {
      // stopLoading();
    });
  }
}
