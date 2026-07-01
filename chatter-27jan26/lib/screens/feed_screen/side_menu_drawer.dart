import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/screens/audio_space/audio_spaces_screen/audio_spaces_screen.dart';
import 'package:lumosocial/screens/drama_screen/drama_details_screen.dart';
import 'package:lumosocial/screens/game_center/game_center_screen.dart';
import 'package:lumosocial/screens/random_screen/random_screen.dart';
import 'package:lumosocial/screens/search_screen/search_screen.dart';
import 'package:lumosocial/screens/wallet_screen/wallet_screen.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/utilities/web_service.dart';

class SideMenuDrawer extends StatefulWidget {
  const SideMenuDrawer({Key? key}) : super(key: key);

  @override
  State<SideMenuDrawer> createState() => _SideMenuDrawerState();
}

class _SideMenuDrawerState extends State<SideMenuDrawer> {
  List<dynamic> _dramas = [];
  bool _isLoadingDramas = true;

  @override
  void initState() {
    super.initState();
    _fetchRandomDramas();
  }

  void _fetchRandomDramas() {
    ApiService.shared.call(
      url: WebService.dramaList,
      param: {'user_id': SessionManager.shared.getUserID()},
      completion: (response) {
        if (mounted) {
          setState(() {
            _isLoadingDramas = false;
          });
          if (response['status'] == true) {
            final allDramas = List<dynamic>.from(response['data'] ?? []);
            allDramas.shuffle(); // Randomize
            setState(() {
              _dramas = allDramas.take(5).toList();
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.shared.getUser();
    
    return Drawer(
      backgroundColor: cWhite,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  MyCachedProfileImage(
                    imageUrl: user?.profile,
                    fullName: user?.fullName,
                    width: 50,
                    height: 50,
                    cornerRadius: 25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Chatter User',
                          style: MyTextStyle.gilroyBold(size: 16, color: cBlack),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "@${user?.username ?? ''}",
                          style: MyTextStyle.gilroyMedium(size: 13, color: cLightText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Colors.black12),
            
            // Latest Dramas horizontal list
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0),
              child: Text(
                "Latest Dramas 🎬",
                style: MyTextStyle.gilroyBold(size: 14, color: cBlack),
              ),
            ),
            
            SizedBox(
              height: 110,
              child: _isLoadingDramas
                  ? const Center(child: CircularProgressIndicator(color: cPrimary))
                  : _dramas.isEmpty
                      ? Center(
                          child: Text(
                            "No dramas available",
                            style: MyTextStyle.gilroyMedium(size: 12, color: cLightText),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _dramas.length,
                          itemBuilder: (context, index) {
                            final drama = _dramas[index];
                            return GestureDetector(
                              onTap: () {
                                Get.back(); // Close Drawer
                                Get.to(() => DramaDetailsScreen(dramaId: (drama['id'] as num).toInt()));
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 70,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: MyCachedImage(
                                        imageUrl: drama['thumbnail'],
                                        width: 70,
                                        height: 75,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      drama['title'] ?? '',
                                      style: MyTextStyle.gilroyBold(size: 10, color: cBlack),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            const Divider(height: 1, color: Colors.black12),
            
            // Drawer items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.explore_outlined,
                    title: "Find Profiles",
                    onTap: () {
                      Get.back();
                      Get.to(() => RandomScreen());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.search_rounded,
                    title: "Search Profiles",
                    onTap: () {
                      Get.back();
                      Get.to(() => const SearchScreen());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.sports_esports_rounded,
                    title: "Game Center",
                    onTap: () {
                      Get.back();
                      Get.to(() => const GameCenterScreen());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Wallet Details",
                    onTap: () {
                      Get.back();
                      Get.to(() => const WalletScreen());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.podcasts_rounded,
                    title: "Audio Spaces",
                    onTap: () {
                      Get.back();
                      Get.to(() => const AudioSpacesScreen());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: cBlack, size: 24),
      title: Text(
        title,
        style: MyTextStyle.gilroyBold(size: 15, color: cBlack),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: cLightText, size: 20),
      onTap: onTap,
    );
  }
}
