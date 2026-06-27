import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:chatter/common/widgets/no_data_view.dart';
import 'package:chatter/localization/languages.dart';
import 'package:chatter/screens/extra_views/top_bar.dart';
import 'package:chatter/screens/feed_screen/feed_screen.dart';
import 'package:chatter/screens/single_post_screen/single_post_controller.dart';

class SinglePostScreen extends StatelessWidget {
  final int postId;

  const SinglePostScreen({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = SinglePostController(postId);
    return Scaffold(
      body: Column(
        children: [
          const TopBarForInView(title: LKeys.post),
          GetBuilder(
            init: controller,
            tag: '$postId',
            builder: (controller) {
              return Expanded(
                child: NoDataView(
                  showShow: controller.posts.isEmpty,
                  child: FeedsView(controller: controller, id: 'feed_$postId'),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
