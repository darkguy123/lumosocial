import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/api_service/post_service.dart';
import 'package:lumosocial/models/posts_model.dart';
import 'package:lumosocial/models/room_model.dart';
import 'package:lumosocial/screens/chats_screen/chatting_screen/block_user_controller.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedScreenController extends BlockUserController {
  // List<Feed> posts = [];
  String scrollID = "${DateTime.now().millisecondsSinceEpoch}scrollID";
  RxList<Post> posts = <Post>[].obs;
  List<Room> suggestedRooms = [];
  List<dynamic> activeAds = [];
  bool? isFromFeedScreen;
  String profileFeedID = "profileFeedID";
  String feedViewID = "feedViewID";
  ScrollController? scrollController = ScrollController();
  int userId = 0;

  FeedScreenController({this.isFromFeedScreen, this.scrollController}) {
    if (this.scrollController == null) {
      this.scrollController = ScrollController();
    }
  }

  void fetchActiveAds() async {
    List<dynamic> userAds = [];
    try {
      final adsSnap = await FirebaseFirestore.instance.collection('ads').get();
      userAds = adsSnap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error fetching active Firestore ads: $e");
    }

    ApiService.shared.call(
      url: "${apiURL}ad/list",
      param: {},
      completion: (response) {
        List<dynamic> systemAds = [];
        if (response != null && response['status'] == true) {
          systemAds = response['data'] ?? [];
        }
        activeAds = [...systemAds, ...userAds];
        update();
      },
    );
  }

  @override
  void onReady() {
    super.onReady();
    update();
    if (isFromFeedScreen == true) {
      fetchActiveAds();
      fetchFeeds();
    }
    scrollController?.addListener(
      () {
        if (scrollController!.offset == scrollController!.position.maxScrollExtent) {
          if (!isLoading.value) {
            if ((isFromFeedScreen ?? false) == true) {
              fetchFeeds();
            } else {
              fetchUserPosts(userID: userId);
            }
          }
        }
      },
    );

    // if (isFromFeedScreen == true && posts.isEmpty) {
    //   fetchFeeds();
    // }
  }

  Future<void> fetchFeeds({bool isForRefresh = false}) async {
    isLoading.value = true;
    if (posts.isEmpty && !isForRefresh) {
      // startLoading();
    }
    await PostService.shared.fetchPosts(
        shouldSendSuggestedRoom: posts.isEmpty,
        start: isForRefresh ? 0 : posts.length,
        completion: (posts, suggestedRooms) {
          if (isForRefresh) {
            this.posts.value = [];
            update();
          }

          Future.delayed(Duration(milliseconds: 5), () {
            this.posts.addAll(posts);
            // stopLoading();
            isLoading.value = false;
            this.posts.refresh();
            update();
          });

          if (suggestedRooms.isNotEmpty) {
            this.suggestedRooms = suggestedRooms;
          }

          update();
        });
  }

  var isAllPostLoaded = false;

  Future<void> fetchUserPosts({int? userID = null, bool isForRefresh = false}) async {
    if (isForRefresh) {
      isAllPostLoaded = false;
      posts.clear();
      update();
    }
    if (isAllPostLoaded) return;
    if (userID != null) {
      userId = userID;
    }
    await PostService.shared.fetchUserPosts(userId, posts.length, (posts) {
      this.posts.addAll(posts);
      update();
      update([scrollID]);
      if (posts.length < Limits.pagination) {
        isAllPostLoaded = true;
      }
    });
  }
}
