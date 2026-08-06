import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/common/widgets/loader_widget.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/common/widgets/no_data_view.dart';
import 'package:lumosocial/screens/extra_views/top_bar.dart';
import 'package:lumosocial/utilities/const.dart';

class RunningAdsScreen extends StatefulWidget {
  const RunningAdsScreen({Key? key}) : super(key: key);

  @override
  State<RunningAdsScreen> createState() => _RunningAdsScreenState();
}

class _RunningAdsScreenState extends State<RunningAdsScreen> {
  bool _isLoading = true;
  List<dynamic> _ads = [];

  @override
  void initState() {
    super.initState();
    _fetchUserRunningAds();
  }

  void _fetchUserRunningAds() async {
    setState(() {
      _isLoading = true;
    });

    final userId = SessionManager.shared.getUserID();
    ApiService.shared.call(
      url: "${apiURL}ad/userAds",
      param: {"user_id": userId},
      completion: (response) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (response['status'] == true && response['data'] != null) {
              _ads = response['data'];
            }
          });
        }
      },
    );
  }

  void _toggleAdStatus(int adId, int currentStatus) async {
    final int newStatus = (currentStatus == 1) ? 3 : 1; // 1 = Active, 3 = Paused
    final userId = SessionManager.shared.getUserID();

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: cPrimary)),
      barrierDismissible: false,
    );

    ApiService.shared.call(
      url: "${apiURL}ad/toggleStatus",
      param: {
        "user_id": userId,
        "ad_id": adId,
        "status": newStatus,
      },
      completion: (response) {
        Get.back(); // dismiss loader
        if (response['status'] == true) {
          Get.snackbar("Updated", "Campaign status updated successfully", backgroundColor: Colors.green, colorText: Colors.white);
          _fetchUserRunningAds();
        } else {
          Get.snackbar("Error", response['message'] ?? "Failed to update status", backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cWhite,
      body: Column(
        children: [
          const TopBarForInView(title: "Running Ad Campaigns"),
          Expanded(
            child: _isLoading
                ? LoaderWidget()
                : RefreshIndicator(
                    onRefresh: () async => _fetchUserRunningAds(),
                    color: cPrimary,
                    child: _ads.isEmpty
                        ? NoDataView(
                            showShow: true,
                            title: "No running campaigns found.",
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _ads.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final ad = _ads[index];
                              return _buildAdCard(ad);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final int status = ad['status'] ?? 0;
    final int adId = ad['id'] ?? 0;
    final String campaignName = ad['campaign_name'] ?? 'Campaign';
    final String adType = ad['ad_type'] ?? 'Feed Ad';
    final int budgetCoins = ad['budget_coins'] ?? 0;
    final int spentCoins = ad['spent_coins'] ?? 0;
    final int impressions = ad['impressions'] ?? 0;
    final int clicks = ad['clicks'] ?? 0;
    final String targetLink = ad['target_link'] ?? '';

    // Extract image/video media URL
    List<dynamic> mediaList = [];
    try {
      final rawMedia = ad['media_url'];
      if (rawMedia is String) {
        mediaList = jsonDecode(rawMedia);
      } else if (rawMedia is List) {
        mediaList = rawMedia;
      }
    } catch (_) {}
    final String mediaUrl = mediaList.isNotEmpty ? mediaList[0].toString() : '';

    String statusLabel = "Pending Review";
    Color statusColor = Colors.orange;
    if (status == 1) {
      statusLabel = "Running / Active";
      statusColor = Colors.green;
    } else if (status == 3) {
      statusLabel = "Paused";
      statusColor = Colors.amber;
    } else if (status == 2) {
      statusLabel = "Rejected";
      statusColor = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        color: cBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: mediaUrl.isNotEmpty
                    ? MyCachedImage(imageUrl: mediaUrl, width: 60, height: 60)
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.white10,
                        child: const Icon(Icons.campaign_rounded, color: cPrimary, size: 30),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaignName,
                      style: MyTextStyle.gilroyBold(size: 16, color: cWhite),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adType,
                      style: MyTextStyle.gilroyMedium(size: 12, color: cLightText),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        statusLabel,
                        style: MyTextStyle.gilroyBold(size: 11, color: statusColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Budget & Performance Metrics Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn("Budget", "$budgetCoins Lc"),
                _buildMetricColumn("Spent", "$spentCoins Lc"),
                _buildMetricColumn("Views", "$impressions"),
                _buildMetricColumn("Clicks", "$clicks"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Pause / Resume
          if (status == 1 || status == 3)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == 1 ? Colors.orange : cPrimary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: Icon(status == 1 ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
                label: Text(
                  status == 1 ? "Pause Campaign" : "Resume Campaign",
                  style: MyTextStyle.gilroyBold(size: 14),
                ),
                onPressed: () => _toggleAdStatus(adId, status),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: MyTextStyle.gilroyBold(size: 15, color: cPrimary)),
        const SizedBox(height: 2),
        Text(label, style: MyTextStyle.gilroyMedium(size: 11, color: Colors.white60)),
      ],
    );
  }
}
