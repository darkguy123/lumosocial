import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/main.dart';
import 'package:lumosocial/screens/tabbar/tabbar_controller.dart';
import 'package:lumosocial/screens/dashboard_reels_screen/dashboard_reels_controller.dart';

class IPTVChannel {
  final String name;
  final String url;
  final String logo;
  final String category;
  final RxBool isLive;

  IPTVChannel({
    required this.name,
    required this.url,
    required this.logo,
    required this.category,
  }) : isLive = true.obs;
}

class LiveTvController extends GetxController {
  var allChannels = <IPTVChannel>[].obs;
  var paginatedChannels = <IPTVChannel>[].obs;
  var liveMatches = <dynamic>[].obs;
  var hasActiveMatches = false.obs;
  var isLoading = true.obs;
  var currentPage = 0.obs;
  final int itemsPerPage = 20;

  var selectedChannel = Rxn<IPTVChannel>();
  VideoPlayerController? videoPlayerController;
  var isVideoLoading = false.obs;
  var isVideoPlaying = false.obs;
  var hasVideoError = false.obs;

  // Category and Search variables
  var categories = <String>[].obs;
  var selectedCategory = 'All'.obs;
  var showSearch = false.obs;
  var searchSuggestions = <IPTVChannel>[].obs;

  // New volume/fullscreen management variables
  var isTransitioningToFullscreen = false.obs;
  var isMuted = false.obs;
  var volume = 1.0.obs;

  void toggleMute() {
    isMuted.value = !isMuted.value;
    if (videoPlayerController != null && videoPlayerController!.value.isInitialized) {
      if (isMuted.value) {
        videoPlayerController!.setVolume(0.0);
      } else {
        videoPlayerController!.setVolume(volume.value);
      }
    }
  }

  void setVolume(double val) {
    volume.value = val;
    if (val > 0) {
      isMuted.value = false;
    }
    if (videoPlayerController != null && videoPlayerController!.value.isInitialized) {
      videoPlayerController!.setVolume(isMuted.value ? 0.0 : val);
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchActiveMatches();
    fetchChannels();
  }

  void fetchActiveMatches() {
    ApiService.shared.call(
      url: "${apiURL}live-matches/active",
      param: {},
      completion: (response) {
        if (response['status'] == true) {
          liveMatches.value = response['data'] ?? [];
          hasActiveMatches.value = liveMatches.isNotEmpty;
        }
      },
    );
  }

  void playMatch(dynamic match) {
    final youtubeUrl = match['youtube_link'] ?? '';
    if (youtubeUrl.isEmpty) {
      Get.snackbar('No Stream', 'No YouTube link available for this match.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    // Convert watch URL to embed URL
    String embedUrl = youtubeUrl;
    final videoIdStr = yt.VideoId.parseVideoId(youtubeUrl);
    if (videoIdStr != null) {
      embedUrl = 'https://www.youtube.com/embed/$videoIdStr?autoplay=1&playsinline=1';
    }
    Get.to(() => LiveMatchYouTubePlayer(embedUrl: embedUrl, matchTitle: '${match["team1"] ?? ""} vs ${match["team2"] ?? ""}'));
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
        Set<String> uniqueCategories = {'All'};

        String currentName = '';
        String currentLogo = '';
        String currentCategory = 'General';

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('#EXTINF:')) {
            // Extract logo
            final logoMatch = RegExp(r'tvg-logo="([^"]+)"').firstMatch(line);
            currentLogo = logoMatch?.group(1) ?? '';

            // Extract category (group-title)
            final groupMatch = RegExp(r'group-title="([^"]+)"').firstMatch(line);
            currentCategory = groupMatch?.group(1) ?? 'General';
            if (currentCategory.isNotEmpty) {
              uniqueCategories.add(currentCategory);
            }

            // Extract name
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
                category: currentCategory,
              ));
            }
            currentName = '';
            currentLogo = '';
            currentCategory = 'General';
          }
        }

        allChannels.value = parsedChannels;
        categories.value = uniqueCategories.toList()..sort();
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

  List<IPTVChannel> get filteredChannels {
    if (selectedCategory.value == 'All') {
      return allChannels;
    }
    return allChannels.where((c) => c.category == selectedCategory.value).toList();
  }

  void updatePagination() {
    final list = filteredChannels;
    final start = currentPage.value * itemsPerPage;
    if (start < list.length) {
      final end = (start + itemsPerPage < list.length) ? start + itemsPerPage : list.length;
      paginatedChannels.value = list.sublist(start, end);
      checkChannelsLiveStatus();
    } else {
      paginatedChannels.clear();
    }
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    currentPage.value = 0;
    updatePagination();
  }

  void searchChannels(String query) {
    if (query.trim().isEmpty) {
      searchSuggestions.clear();
      return;
    }
    final results = allChannels
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .take(3)
        .toList();
    searchSuggestions.value = results;
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

  void playPrevious() {
    if (allChannels.isEmpty || selectedChannel.value == null) return;
    int index = allChannels.indexOf(selectedChannel.value!);
    if (index > 0) {
      int prevIndex = index - 1;
      int targetPage = prevIndex ~/ itemsPerPage;
      if (targetPage != currentPage.value) {
        currentPage.value = targetPage;
        updatePagination();
      }
      playChannel(allChannels[prevIndex]);
    }
  }

  void playNext() {
    if (allChannels.isEmpty || selectedChannel.value == null) return;
    int index = allChannels.indexOf(selectedChannel.value!);
    if (index < allChannels.length - 1) {
      int nextIndex = index + 1;
      int targetPage = nextIndex ~/ itemsPerPage;
      if (targetPage != currentPage.value) {
        currentPage.value = targetPage;
        updatePagination();
      }
      playChannel(allChannels[nextIndex]);
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
      await videoPlayerController!.setVolume(isMuted.value ? 0.0 : volume.value);
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
    for (var channel in paginatedChannels.toList()) {
      try {
        final response = await http.head(Uri.parse(channel.url)).timeout(const Duration(seconds: 2));
        channel.isLive.value = (response.statusCode >= 200 && response.statusCode < 400);
      } catch (_) {
        channel.isLive.value = false;
      }
    }
    // Keep all channels visible; isLive just updates the indicator dot
  }
}

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> with RouteAware, WidgetsBindingObserver {
  final LiveTvController controller = Get.put(LiveTvController());
  var _showInlineControls = false.obs;
  Timer? _inlineControlsTimer;

  void _triggerInlineControls() {
    _showInlineControls.value = true;
    _inlineControlsTimer?.cancel();
    _inlineControlsTimer = Timer(const Duration(seconds: 3), () {
      _showInlineControls.value = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      Get.find<TabBarController>().addListener(_checkMuteState);
      Get.find<DashboardReelsController>().addListener(_checkMuteState);
    } catch (e) {
      debugPrint('Error attaching muting listeners: $e');
    }
  }

  @override
  void dispose() {
    try {
      Get.find<TabBarController>().removeListener(_checkMuteState);
      Get.find<DashboardReelsController>().removeListener(_checkMuteState);
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _inlineControlsTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    if (!controller.isTransitioningToFullscreen.value) {
      _mutePlayer();
    }
    super.didPushNext();
  }

  @override
  void didPopNext() {
    controller.isTransitioningToFullscreen.value = false;
    _unmutePlayer();
    super.didPopNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _mutePlayer();
    } else if (state == AppLifecycleState.resumed) {
      _unmutePlayer();
    }
  }

  void _checkMuteState() {
    try {
      final tabController = Get.find<TabBarController>();
      final reelsController = Get.find<DashboardReelsController>();
      
      bool shouldMute = tabController.selectedTab != 2 || 
                        reelsController.selectedPageType.value != DashboardReelPageType.liveTv;
      
      if (shouldMute) {
        _mutePlayer();
      } else {
        _unmutePlayer();
      }
    } catch (e) {
      debugPrint('Error in checking mute state: $e');
    }
  }

  void _mutePlayer() {
    if (controller.videoPlayerController != null &&
        controller.videoPlayerController!.value.isInitialized) {
      controller.videoPlayerController!.setVolume(0.0);
    }
  }

  void _unmutePlayer() {
    if (controller.videoPlayerController != null &&
        controller.videoPlayerController!.value.isInitialized) {
      controller.videoPlayerController!.setVolume(controller.isMuted.value ? 0.0 : controller.volume.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBlack,
      body: Stack(
        children: [
          SafeArea(
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
                        onDoubleTap: () {
                          controller.isTransitioningToFullscreen.value = true;
                          Get.to(() => FullscreenLiveTvPlayer(controller: controller));
                        },
                        onTap: _triggerInlineControls,
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

                    // Floating Controls Overlay
                    Obx(() {
                      if (_showInlineControls.value &&
                          controller.videoPlayerController != null &&
                          controller.videoPlayerController!.value.isInitialized &&
                          !controller.hasVideoError.value) {
                        return Positioned.fill(
                          child: Container(
                            color: Colors.black45,
                            child: Stack(
                              children: [
                                // Play / Pause Indicator
                                Center(
                                  child: IconButton(
                                    icon: Icon(
                                      controller.isVideoPlaying.value
                                          ? Icons.pause_circle_outline_rounded
                                          : Icons.play_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 55,
                                    ),
                                    onPressed: () {
                                      _triggerInlineControls();
                                      if (controller.videoPlayerController!.value.isPlaying) {
                                        controller.videoPlayerController!.pause();
                                        controller.isVideoPlaying.value = false;
                                      } else {
                                        controller.videoPlayerController!.play();
                                        controller.isVideoPlaying.value = true;
                                      }
                                    },
                                  ),
                                ),
                                // Mute & Volume Control (bottom left)
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Obx(() => IconButton(
                                            icon: Icon(
                                              controller.isMuted.value
                                                  ? Icons.volume_off_rounded
                                                  : (controller.volume.value > 0.5
                                                      ? Icons.volume_up_rounded
                                                      : Icons.volume_down_rounded),
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            onPressed: () {
                                              _triggerInlineControls();
                                              controller.toggleMute();
                                            },
                                          )),
                                      Obx(() => SizedBox(
                                            width: 80,
                                            child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                activeTrackColor: cPrimary,
                                                inactiveTrackColor: Colors.white24,
                                                thumbColor: cPrimary,
                                                trackHeight: 2.0,
                                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                              ),
                                              child: Slider(
                                                value: controller.volume.value,
                                                min: 0.0,
                                                max: 1.0,
                                                onChanged: (val) {
                                                  _triggerInlineControls();
                                                  controller.setVolume(val);
                                                },
                                              ),
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                                // Fullscreen Toggle Button (bottom right)
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: IconButton(
                                    icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 28),
                                    onPressed: () {
                                      _showInlineControls.value = false;
                                      controller.isTransitioningToFullscreen.value = true;
                                      Get.to(() => FullscreenLiveTvPlayer(controller: controller));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    if (controller.isVideoLoading.value)
                      Center(child: CircularProgressIndicator(color: cPrimary)),
                  ],
                ),
              ),

              // Active channel indicator banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    IconButton(
                      icon: Icon(
                        controller.showSearch.value ? Icons.close_rounded : Icons.search_rounded,
                        color: const Color(0xFF00FF87),
                        size: 20,
                      ),
                      onPressed: () {
                        controller.showSearch.value = !controller.showSearch.value;
                        if (!controller.showSearch.value) {
                          controller.searchSuggestions.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Search input and suggestions
              Obx(() {
                if (!controller.showSearch.value) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.black,
                  child: Column(
                    children: [
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (text) => controller.searchChannels(text),
                        decoration: InputDecoration(
                          hintText: "Search channels...",
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00FF87)),
                          filled: true,
                          fillColor: Colors.grey[900],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (controller.searchSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.searchSuggestions.length,
                            itemBuilder: (context, index) {
                              final ch = controller.searchSuggestions[index];
                              return ListTile(
                                dense: true,
                                leading: ch.logo.isNotEmpty
                                    ? Image.network(ch.logo, width: 24, height: 24, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white))
                                    : const Icon(Icons.tv, color: Colors.white),
                                title: Text(ch.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text(ch.category, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                onTap: () {
                                  controller.playChannel(ch);
                                  controller.showSearch.value = false;
                                  controller.searchSuggestions.clear();
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              }),

              // Categories Filter Row
              Obx(() {
                if (controller.categories.isEmpty) return const SizedBox.shrink();
                return Container(
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.categories.length,
                    itemBuilder: (context, index) {
                      final cat = controller.categories[index];
                      final isSelected = controller.selectedCategory.value == cat;
                      return GestureDetector(
                        onTap: () => controller.selectCategory(cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00FF87) : Colors.grey[900],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                getCategoryIcon(cat),
                                size: 14,
                                color: isSelected ? Colors.black : const Color(0xFF00FF87),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat,
                                style: MyTextStyle.gilroyBold(
                                  color: isSelected ? Colors.black : Colors.white,
                                  size: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),

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
          Obx(() {
            if (controller.hasActiveMatches.value) {
              return Positioned(
                bottom: 80,
                right: 20,
                child: GestureDetector(
                  onTap: () => _showLiveMatchesPopup(context),
                  child: Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: cPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cPrimary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  void _showLiveMatchesPopup(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF121217),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Live Worldcup Matches",
              style: MyTextStyle.gilroyBold(color: Colors.white, size: 18),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.liveMatches.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "No matches scheduled at the moment.",
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                );
              }
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.liveMatches.length,
                  itemBuilder: (context, index) {
                    final match = controller.liveMatches[index];
                    final String liveStatus = match['live_status'] ?? 'UPCOMING';
                    
                    return Card(
                      color: const Color(0xFF1E1E24),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (match['team1_flag'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  match['team1_flag'],
                                  width: 32,
                                  height: 22,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, color: Colors.white24),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              match['team1'] ?? '',
                              style: MyTextStyle.gilroyBold(color: Colors.white, size: 14),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text("VS", style: TextStyle(color: cPrimary, fontWeight: FontWeight.bold)),
                            ),
                            Text(
                              match['team2'] ?? '',
                              style: MyTextStyle.gilroyBold(color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 8),
                            if (match['team2_flag'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  match['team2_flag'],
                                  width: 32,
                                  height: 22,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, color: Colors.white24),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          "${match['start_date']} @ ${match['start_time']}",
                          style: MyTextStyle.gilroyMedium(color: Colors.white60, size: 12),
                          textAlign: TextAlign.end,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: liveStatus == 'LIVE' ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: liveStatus == 'LIVE' ? Colors.green : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            liveStatus,
                            style: MyTextStyle.gilroyBold(
                              color: liveStatus == 'LIVE' ? Colors.green : Colors.grey,
                              size: 10,
                            ),
                          ),
                        ),
                        onTap: () {
                          Get.back(); // Close bottomsheet
                          controller.playMatch(match);
                        },
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

/// YouTube WebView player for Live Matches
class LiveMatchYouTubePlayer extends StatefulWidget {
  final String embedUrl;
  final String matchTitle;
  const LiveMatchYouTubePlayer({Key? key, required this.embedUrl, required this.matchTitle}) : super(key: key);

  @override
  State<LiveMatchYouTubePlayer> createState() => _LiveMatchYouTubePlayerState();
}

class _LiveMatchYouTubePlayerState extends State<LiveMatchYouTubePlayer> {
  late final WebViewController _webController;
  bool _isWebLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36")
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isWebLoading = false),
      ));

    // Try to extract YouTube video ID to load custom HTML iframe string (prevents mobile playback blocks)
    String? videoId;
    try {
      final uri = Uri.parse(widget.embedUrl);
      if (uri.pathSegments.contains('embed')) {
        final index = uri.pathSegments.indexOf('embed');
        if (index + 1 < uri.pathSegments.length) {
          videoId = uri.pathSegments[index + 1].split('?').first;
        }
      }
    } catch (e) {
      debugPrint("Error parsing YouTube video ID: $e");
    }

    if (videoId != null && videoId.isNotEmpty) {
      final html = '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
      html, body {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        background-color: #000000;
        overflow: hidden;
      }
      .video-container {
        position: relative;
        width: 100%;
        height: 100%;
      }
      .video-container iframe {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        border: 0;
      }
    </style>
  </head>
  <body>
    <div class="video-container">
      <iframe
        id="player"
        src="https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1&enablejsapi=1&fs=1&rel=0&showinfo=0&origin=https://www.youtube.com"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
        allowfullscreen>
      </iframe>
    </div>
  </body>
</html>
''';
      _webController.loadHtmlString(html, baseUrl: 'https://www.youtube.com');
    } else {
      _webController.loadRequest(
        Uri.parse(widget.embedUrl),
        headers: const {'Referer': 'https://www.youtube.com'},
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          WebViewWidget(controller: _webController),
          if (_isWebLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'LIVE • ${widget.matchTitle}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullscreenLiveTvPlayer extends StatefulWidget {
  final LiveTvController controller;
  const FullscreenLiveTvPlayer({Key? key, required this.controller}) : super(key: key);

  @override
  State<FullscreenLiveTvPlayer> createState() => _FullscreenLiveTvPlayerState();
}

class _FullscreenLiveTvPlayerState extends State<FullscreenLiveTvPlayer> {
  var _showControls = false.obs;
  Timer? _controlsTimer;

  void _triggerControls() {
    _showControls.value = true;
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      _showControls.value = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // Rotate to landscape and hide system status bars
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore orientations and system status bars
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Video Player View
          Center(
            child: widget.controller.videoPlayerController != null &&
                    widget.controller.videoPlayerController!.value.isInitialized &&
                    !widget.controller.hasVideoError.value
                ? GestureDetector(
                    onDoubleTap: () => Get.back(),
                    onTap: _triggerControls,
                    child: AspectRatio(
                      aspectRatio: widget.controller.videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(widget.controller.videoPlayerController!),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: cWhite),
                  ),
          ),

          // Interactive Overlay Controls
          Obx(() {
            if (_showControls.value) {
              return Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Next/Prev Channel arrows at left/right edges
                      Positioned(
                        left: 20,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 50),
                          onPressed: () {
                            _triggerControls();
                            widget.controller.playPrevious();
                          },
                        ),
                      ),
                      Positioned(
                        right: 20,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 50),
                          onPressed: () {
                            _triggerControls();
                            widget.controller.playNext();
                          },
                        ),
                      ),

                      // Exit Fullscreen (Close Button) top-right
                      Positioned(
                        top: 20,
                        right: 20,
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 36),
                          onPressed: () => Get.back(),
                        ),
                      ),

                      // Channel name in fullscreen at top-center
                      Positioned(
                        top: 25,
                        child: Text(
                          widget.controller.selectedChannel.value?.name ?? '',
                          style: MyTextStyle.gilroyBold(color: Colors.white, size: 16).copyWith(
                            shadows: [
                              const BoxShadow(color: Colors.black, blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

IconData getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'news':
      return Icons.newspaper_rounded;
    case 'sports':
      return Icons.sports_soccer_rounded;
    case 'music':
      return Icons.music_note_rounded;
    case 'movies':
    case 'entertainment':
      return Icons.movie_filter_rounded;
    case 'documentary':
      return Icons.travel_explore_rounded;
    case 'kids':
      return Icons.child_care_rounded;
    default:
      return Icons.tv_rounded;
  }
}
