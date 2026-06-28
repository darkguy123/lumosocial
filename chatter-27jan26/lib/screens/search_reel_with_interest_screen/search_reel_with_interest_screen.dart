import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/enums/reel_page_type.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/models/setting_model.dart';
import 'package:lumosocial/screens/extra_views/search_bar.dart';
import 'package:lumosocial/screens/extra_views/top_bar.dart';
import 'package:lumosocial/screens/reels_screen/reels_grid.dart';
import 'package:lumosocial/screens/rooms_screen/rooms_by_interest/room_explore_by_interests.dart';
import 'package:lumosocial/screens/search_reel_with_interest_screen/search_reel_with_interest_screen_controller.dart';

class SearchReelWithInterestScreen extends StatelessWidget {
  final Interest interest;

  const SearchReelWithInterestScreen({super.key, required this.interest});

  @override
  Widget build(BuildContext context) {
    SearchReelWithInterestScreenController controller = Get.put(SearchReelWithInterestScreenController(interest));
    return Scaffold(
      body: Column(
        children: [
          TopBarForInView(
            title: LKeys.reels,
            child: RoomInterestTag(title: interest.title ?? '', onTap: () {}),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: MySearchBar(
              controller: controller.textEditingController,
              onChange: (text) {
                controller.onSearchTextChanged();
              },
            ),
          ),
          Expanded(
            child: ReelsGrid(
              reels: controller.reels,
              reelType: ReelPageType.search,
              isLoading: controller.isLoading,
              onFetchMoreData: controller.searchReels,
            ),
          )
        ],
      ),
    );
  }
}
