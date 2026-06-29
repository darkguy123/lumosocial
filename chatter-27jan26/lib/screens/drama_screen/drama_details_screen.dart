import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/screens/drama_screen/drama_player_screen.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/utilities/web_service.dart';

class DramaDetailsScreen extends StatefulWidget {
  final int dramaId;
  const DramaDetailsScreen({super.key, required this.dramaId});

  @override
  State<DramaDetailsScreen> createState() => _DramaDetailsScreenState();
}

class _DramaDetailsScreenState extends State<DramaDetailsScreen> {
  Map<String, dynamic> _dramaData = {};
  List<dynamic> _episodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  void _fetchDetails() {
    final userId = SessionManager.shared.getUserID();
    
    ApiService.shared.call(
      url: WebService.dramaDetails,
      param: {
        'drama_id': widget.dramaId,
        'user_id': userId,
      },
      completion: (response) {
        if (response['status'] == true) {
          final data = response['data'] ?? {};
          setState(() {
            _dramaData = data;
            _episodes = data['episodes_list'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          Get.snackbar("Error", response['message'] ?? "Failed to fetch details.");
        }
      },
    );
  }

  void _logView(int id, String type) {
    ApiService.shared.call(
      url: WebService.dramaLogView,
      param: {'type': type, 'id': id},
      completion: (response) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))),
      );
    }

    final thumbnail = _dramaData['thumbnail'] ?? '';
    final title = _dramaData['title'] ?? '';
    final description = _dramaData['description'] ?? 'No description available.';
    final totalViews = _dramaData['views_count'] ?? 0;

    return Scaffold(
      backgroundColor: cBlack,
      body: CustomScrollView(
        slivers: [
          // Collapsible Poster Header
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: cBlack,
            leading: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () => Get.back(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    thumbnail,
                    fit: BoxFit.cover,
                  ),
                  // Dark shadow gradient on poster
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details synopsis
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gilroy-Bold',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF87).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${_episodes.length} Episodes",
                          style: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "$totalViews Views",
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Synopsis",
                    style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: 'Gilroy-Medium',
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Episode Selection",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),

          // Episodes List Grid/Builder
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final episode = _episodes[index];
                  final epTitle = episode['title'] ?? '';
                  final epNumber = episode['episode_number'] ?? 1;
                  final views = episode['views_count'] ?? 0;
                  final progressSec = int.tryParse(episode['progress_seconds']?.toString() ?? '0') ?? 0;

                  return GestureDetector(
                    onTap: () {
                      _logView(int.parse(episode['id'].toString()), 'episode');
                      Get.to(() => DramaPlayerScreen(
                            episodes: _episodes,
                            initialIndex: index,
                            dramaTitle: title,
                            dramaId: widget.dramaId,
                          ))?.then((_) {
                        // Refresh details on return to show updated playback progress bars
                        _fetchDetails();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          // Small Thumbnail Play Card
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(Icons.play_arrow_rounded, color: Color(0xFF00FF87), size: 28),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Episode $epNumber: $epTitle",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      "$views Views",
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                                    ),
                                    if (progressSec > 0) ...[
                                      const SizedBox(width: 10),
                                      Text(
                                        "• Resume watching",
                                        style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _episodes.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
