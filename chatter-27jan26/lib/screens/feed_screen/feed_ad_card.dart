import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/screens/feed_screen/in_app_browser_screen.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedAdCard extends StatefulWidget {
  final Map<String, dynamic> ad;
  const FeedAdCard({Key? key, required this.ad}) : super(key: key);

  @override
  State<FeedAdCard> createState() => _FeedAdCardState();
}

class _FeedAdCardState extends State<FeedAdCard> {
  bool _impressionLogged = false;

  @override
  void initState() {
    super.initState();
    _logImpression();
  }

  void _logImpression() {
    if (_impressionLogged) return;
    _impressionLogged = true;
    ApiService.shared.call(
      url: "${apiURL}ad/logImpression",
      param: {"ad_id": widget.ad['id']},
      completion: (response) {},
    );
  }

  void _onAdClicked() async {
    ApiService.shared.call(
      url: "${apiURL}ad/logClick",
      param: {"ad_id": widget.ad['id']},
      completion: (response) {},
    );

    final link = widget.ad['target_link'] ?? '';
    if (link.isNotEmpty) {
      Get.to(() => InAppBrowserScreen(url: link));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String campaignName = widget.ad['campaign_name'] ?? 'Sponsored Ad';
    final String targetLink = widget.ad['target_link'] ?? '';
    
    // Parse media
    List<dynamic> mediaList = [];
    try {
      final rawMedia = widget.ad['media_url'];
      if (rawMedia is String) {
        mediaList = jsonDecode(rawMedia);
      } else if (rawMedia is List) {
        mediaList = rawMedia;
      }
    } catch (e) {
      // Ignore format errors
    }

    final String mediaUrl = mediaList.isNotEmpty ? mediaList[0] : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: cBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Ad Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: cPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.campaign_rounded, color: Colors.black, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaignName,
                        style: MyTextStyle.gilroyBold(size: 15, color: cWhite),
                      ),
                      Text(
                        "Sponsored",
                        style: MyTextStyle.gilroyMedium(size: 11, color: cPrimary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: cLightText),
              ],
            ),
          ),
          
          // Image / Video Card
          if (mediaUrl.isNotEmpty)
            GestureDetector(
              onTap: _onAdClicked,
              child: AspectRatio(
                aspectRatio: 1.0, // 1:1 Aspect Ratio
                child: MyCachedImage(
                  imageUrl: mediaUrl,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),

          // Call to Action Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1E1E24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetLink.isNotEmpty ? Uri.parse(targetLink).host : "Learn More",
                        style: MyTextStyle.gilroyMedium(size: 12, color: Colors.white60),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Click to visit our sponsored link",
                        style: MyTextStyle.gilroyBold(size: 14, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cPrimary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: _onAdClicked,
                  child: Text(
                    "Open Link",
                    style: MyTextStyle.gilroyBold(size: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
