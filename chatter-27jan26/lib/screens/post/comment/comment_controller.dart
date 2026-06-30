import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/moderator_service.dart';
import 'package:lumosocial/common/api_service/post_service.dart';
import 'package:lumosocial/common/controller/base_controller.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/models/comments_model.dart';
import 'package:lumosocial/models/posts_model.dart';
import 'package:lumosocial/screens/post/post_controller.dart';
import 'package:lumosocial/screens/sheets/confirmation_sheet.dart';

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
    final commentText = textEditingController.text.trim();
    if (commentText.isEmpty) {
      return;
    }
    textEditingController.clear();
    
    // Create an optimistic temporary comment object
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempComment = Comment(
      id: tempId,
      userId: SessionManager.shared.getUser()?.id,
      postId: post.id,
      desc: commentText,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      user: SessionManager.shared.getUser(),
      isLike: 0,
      commentLikeCount: 0,
    );
    
    comments.insert(0, tempComment);
    postController.post.commentsCount = (postController.post.commentsCount ?? 0) + 1;
    postController.update(['comment']);
    postController.update();
    update();

    PostService.shared.addComment(commentText, post.id ?? 0, (comment) {
      final index = comments.indexWhere((element) => element.id == tempId);
      if (index != -1) {
        comment.user = SessionManager.shared.getUser();
        comments[index] = comment;
        update();
      }
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
