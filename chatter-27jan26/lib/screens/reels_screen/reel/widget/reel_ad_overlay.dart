import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/screens/feed_screen/in_app_browser_screen.dart';
import 'package:lumosocial/utilities/const.dart';

class ReelAdOverlay extends StatefulWidget {
  final Map<String, dynamic> ad;
  const ReelAdOverlay({Key? key, required this.ad}) : super(key: key);

  @override
  State<ReelAdOverlay> createState() => _ReelAdOverlayState();
}

class _ReelAdOverlayState extends State<ReelAdOverlay> {
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

  void _onAdClicked() {
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
    final String campaignName = widget.ad['campaign_name'] ?? 'Sponsored';
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
      margin: const EdgeInsets.only(left: 12, right: 70, bottom: 90), // Offset slightly above description/side button bar
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        children: [
          if (mediaUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: MyCachedImage(
                imageUrl: mediaUrl,
                width: 48,
                height: 48,
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.campaign_rounded, color: cPrimary, size: 24),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      campaignName,
                      style: MyTextStyle.gilroyBold(size: 13, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: cPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: cPrimary, width: 0.5),
                      ),
                      child: Text(
                        "Ad",
                        style: MyTextStyle.gilroyBold(size: 8, color: cPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  targetLink.isNotEmpty ? Uri.parse(targetLink).host : "Sponsored",
                  style: MyTextStyle.gilroyMedium(size: 11, color: Colors.white60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cPrimary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _onAdClicked,
            child: Text(
              "Learn More",
              style: MyTextStyle.gilroyBold(size: 11),
            ),
          ),
        ],
      ),
    );
  }
}
