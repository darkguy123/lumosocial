import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';

class IPTVChannel {
  final String name;
  final String url;
  final String logo;
  final RxBool isLive;

  IPTVChannel({
    required this.name,
    required this.url,
    required this.logo,
  }) : isLive = true.obs;
}

class LiveTvController extends GetxController {
  var allChannels = <IPTVChannel>[].obs;
  var paginatedChannels = <IPTVChannel>[].obs;
  var isLoading = true.obs;
  var currentPage = 0.obs;
  final int itemsPerPage = 20;

  var selectedChannel = Rxn<IPTVChannel>();
  VideoPlayerController? videoPlayerController;
  var isVideoLoading = false.obs;
  var isVideoPlaying = false.obs;
  var hasVideoError = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChannels();
  }

  @override
  void onClose() {
    videoPlayerController?.dispose();
    super.onClose();
  }

  Future<void> fetchChannels() async {
    try {
      isLoading.value = true;
      final response = await http.get(Uri.parse('https://iptv-org.github.io/iptv/languages/eng.m3u'));
      if (response.statusCode == 200) {
        final lines = const LineSplitter().convert(response.body);
        List<IPTVChannel> parsedChannels = [];

        String currentName = '';
        String currentLogo = '';

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('#EXTINF:')) {
            // Extract logo
            final logoMatch = RegExp(r'tvg-logo="([^"]+)"').firstMatch(line);
            currentLogo = logoMatch?.group(1) ?? '';

            // Extract name (usually after tvg-name="..." or final comma)
            final nameMatch = RegExp(r'tvg-name="([^"]+)"').firstMatch(line);
            if (nameMatch != null) {
              currentName = nameMatch.group(1) ?? 'Unknown Channel';
            } else {
              final commaIndex = line.lastIndexOf(',');
              if (commaIndex != -1) {
                currentName = line.substring(commaIndex + 1).trim();
              } else {
                currentName = 'Unknown Channel';
              }
            }
          } else if (line.isNotEmpty && !line.startsWith('#')) {
            if (currentName.isNotEmpty) {
              parsedChannels.add(IPTVChannel(
                name: currentName,
                url: line,
                logo: currentLogo,
              ));
            }
            currentName = '';
            currentLogo = '';
          }
        }

        allChannels.value = parsedChannels;
        updatePagination();

        if (paginatedChannels.isNotEmpty) {
          playChannel(paginatedChannels.first);
        }
      }
    } catch (e) {
      debugPrint('Error fetching IPTV channels: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updatePagination() {
    final start = currentPage.value * itemsPerPage;
    if (start < allChannels.length) {
      final end = (start + itemsPerPage < allChannels.length) ? start + itemsPerPage : allChannels.length;
      paginatedChannels.value = allChannels.sublist(start, end);
      checkChannelsLiveStatus();
    } else {
      paginatedChannels.clear();
    }
  }

  void nextPage() {
    if ((currentPage.value + 1) * itemsPerPage < allChannels.length) {
      currentPage.value++;
      updatePagination();
    }
  }

  void prevPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
      updatePagination();
    }
  }

  Future<void> playChannel(IPTVChannel channel) async {
    selectedChannel.value = channel;
    isVideoLoading.value = true;
    hasVideoError.value = false;

    if (videoPlayerController != null) {
      await videoPlayerController!.dispose();
    }

    try {
      videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(channel.url));
      await videoPlayerController!.initialize();
      videoPlayerController!.setLooping(true);
      await videoPlayerController!.play();
      isVideoPlaying.value = true;
    } catch (e) {
      debugPrint('Video Player error: $e');
      hasVideoError.value = true;
      channel.isLive.value = false;
    } finally {
      isVideoLoading.value = false;
      update();
    }
  }

  Future<void> checkChannelsLiveStatus() async {
    // Check live status of current paginated list asynchronously
    for (var channel in paginatedChannels) {
      try {
        final response = await http.head(Uri.parse(channel.url)).timeout(const Duration(seconds: 2));
        channel.isLive.value = (response.statusCode >= 200 && response.statusCode < 400);
      } catch (_) {
        channel.isLive.value = false;
      }
    }
  }
}

class LiveTvScreen extends StatelessWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LiveTvController());

    return Scaffold(
      backgroundColor: cBlack,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: cPrimary));
          }

          if (controller.allChannels.isEmpty) {
            return const Center(
              child: Text(
                'No channels found.',
                style: TextStyle(color: cWhite, fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
              // Top Video Player Section
              Container(
                height: 230,
                width: double.infinity,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (controller.videoPlayerController != null &&
                        controller.videoPlayerController!.value.isInitialized &&
                        !controller.hasVideoError.value)
                      GestureDetector(
                        onTap: () {
                          if (controller.videoPlayerController!.value.isPlaying) {
                            controller.videoPlayerController!.pause();
                            controller.isVideoPlaying.value = false;
                          } else {
                            controller.videoPlayerController!.play();
                            controller.isVideoPlaying.value = true;
                          }
                        },
                        child: AspectRatio(
                          aspectRatio: controller.videoPlayerController!.value.aspectRatio,
                          child: VideoPlayer(controller.videoPlayerController!),
                        ),
                      )
                    else if (controller.hasVideoError.value)
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 50),
                          SizedBox(height: 10),
                          Text(
                            'Failed to load stream (Channel Offline)',
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ],
                      )
                    else
                      const Center(child: Text('Select a channel to play', style: TextStyle(color: cWhite))),

                    // Video Play/Pause Overlay indicator
                    if (controller.videoPlayerController != null &&
                        !controller.isVideoPlaying.value &&
                        !controller.isVideoLoading.value &&
                        !controller.hasVideoError.value)
                      const Icon(Icons.play_circle_outline, color: cWhite, size: 60),

                    if (controller.isVideoLoading.value)
                      Center(child: CircularProgressIndicator(color: cPrimary)),
                  ],
                ),
              ),

              // Active channel indicator banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[900],
                width: double.infinity,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: controller.selectedChannel.value?.isLive.value == true ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Now Playing: ${controller.selectedChannel.value?.name ?? "Select Channel"}',
                        style: MyTextStyle.gilroyBold(color: cWhite, size: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Channels List Section
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: controller.paginatedChannels.length,
                  itemBuilder: (context, index) {
                    final channel = controller.paginatedChannels[index];
                    final isSelected = controller.selectedChannel.value == channel;

                    return GestureDetector(
                      onTap: () => controller.playChannel(channel),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.grey[850] : Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? cPrimary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Channel Logo
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: channel.logo.isNotEmpty
                                  ? Image.network(
                                      channel.logo,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[800],
                                        width: 40,
                                        height: 40,
                                        child: const Icon(Icons.tv, color: cWhite, size: 20),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[800],
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.tv, color: cWhite, size: 20),
                                    ),
                            ),
                            const SizedBox(width: 8),

                            // Channel Name & Status Indicator
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    channel.name,
                                    style: MyTextStyle.gilroyBold(color: cWhite, size: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Obx(() => Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: channel.isLive.value ? Colors.green : Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          )),
                                      const SizedBox(width: 4),
                                      Obx(() => Text(
                                            channel.isLive.value ? 'Online' : 'Offline',
                                            style: MyTextStyle.gilroyRegular(
                                              color: channel.isLive.value ? Colors.green : Colors.red,
                                              size: 10,
                                            ),
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Pagination Control bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[950],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: cWhite, size: 20),
                      onPressed: controller.currentPage.value > 0 ? controller.prevPage : null,
                    ),
                    Text(
                      'Page ${controller.currentPage.value + 1} of ${((controller.allChannels.length) / controller.itemsPerPage).ceil()}',
                      style: MyTextStyle.gilroyBold(color: cWhite, size: 14),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: cWhite, size: 20),
                      onPressed: (controller.currentPage.value + 1) * controller.itemsPerPage <
                              controller.allChannels.length
                          ? controller.nextPage
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
