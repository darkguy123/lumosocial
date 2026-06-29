import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/models/registration.dart';
import 'package:lumosocial/screens/chats_screen/chatting_screen/chatting_controller.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/utilities/web_service.dart';
import 'package:lumosocial/utilities/firebase_const.dart';

class DramaPlayerScreen extends StatefulWidget {
  final List<dynamic> episodes;
  final int initialIndex;
  final String dramaTitle;
  final int dramaId;

  const DramaPlayerScreen({
    super.key,
    required this.episodes,
    required this.initialIndex,
    required this.dramaTitle,
    required this.dramaId,
  });

  @override
  State<DramaPlayerScreen> createState() => _DramaPlayerScreenState();
}

class _DramaPlayerScreenState extends State<DramaPlayerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  VideoPlayerController? _videoPlayerController;
  bool _isPlaying = false;
  bool _isPlayerInitialized = false;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializePlayer(_currentIndex);
  }

  void _initializePlayer(int index) async {
    _progressTimer?.cancel();
    if (_videoPlayerController != null) {
      await _saveProgress();
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }

    setState(() {
      _isPlayerInitialized = false;
      _isPlaying = false;
    });

    final episode = widget.episodes[index];
    final url = episode['video_url'] ?? '';
    final resumeSeconds = int.tryParse(episode['progress_seconds']?.toString() ?? '0') ?? 0;

    if (url.isEmpty) {
      Get.snackbar("Error", "Episode video content is missing.", backgroundColor: Colors.red);
      return;
    }

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await _videoPlayerController!.initialize();
      if (resumeSeconds > 0 && resumeSeconds < _videoPlayerController!.value.duration.inSeconds) {
        await _videoPlayerController!.seekTo(Duration(seconds: resumeSeconds));
      }
      setState(() {
        _isPlayerInitialized = true;
        _isPlaying = true;
      });
      _videoPlayerController!.play();
      _videoPlayerController!.setLooping(true);

      // Periodically sync watch progress every 10 seconds
      _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _saveProgress();
      });
    } catch (e) {
      debugPrint("Video Player Error: $e");
      Get.snackbar("Playback Error", "Failed to load episode video content.", backgroundColor: Colors.red);
    }
  }

  Future<void> _saveProgress() async {
    if (_videoPlayerController == null || !_isPlayerInitialized) return;
    
    final userId = SessionManager.shared.getUserID();
    final episode = widget.episodes[_currentIndex];
    final episodeId = int.parse(episode['id'].toString());
    final currentSeconds = _videoPlayerController!.value.position.inSeconds;

    ApiService.shared.call(
      url: WebService.dramaSaveProgress,
      param: {
        'user_id': userId,
        'drama_episode_id': episodeId,
        'seconds': currentSeconds,
      },
      completion: (response) {},
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _initializePlayer(index);
  }

  void _togglePlayPause() {
    if (_videoPlayerController == null) return;
    setState(() {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        _isPlaying = false;
        _saveProgress();
      } else {
        _videoPlayerController!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _saveProgress();
    _videoPlayerController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Watch Party Share Modal
  void _openWatchPartyShareModal() {
    List<User> users = [];
    bool isSearching = false;
    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          void searchUsers(String query) {
            if (query.trim().length < 3) {
              setModalState(() {
                users.clear();
              });
              return;
            }
            setModalState(() {
              isSearching = true;
            });
            ApiService.shared.call(
              url: WebService.walletSearchUsers,
              param: {'query': query},
              completion: (response) {
                setModalState(() {
                  isSearching = false;
                });
                if (response['status'] == true) {
                  final list = response['data'] as List? ?? [];
                  setModalState(() {
                    users = list.map((e) => User.fromJson(e)).toList();
                  });
                }
              },
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 25,
              bottom: MediaQuery.of(context).viewInsets.bottom + 25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Invite to Watch Party 🍿",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: searchController,
                  onChanged: searchUsers,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Enter username to invite",
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF87))),
                  ),
                ),
                const SizedBox(height: 15),
                if (isSearching)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
                else if (users.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, idx) {
                        final u = users[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: u.profile != null ? NetworkImage(u.profile!) : null,
                            child: u.profile == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(u.fullName ?? '', style: const TextStyle(color: Colors.white)),
                          subtitle: Text("@${u.username ?? ''}", style: const TextStyle(color: Colors.white54)),
                          trailing: const Icon(Icons.send_rounded, color: Color(0xFF00FF87)),
                          onTap: () {
                            Get.back(); // close modal
                            _sendWatchPartyInvite(u);
                          },
                        );
                      },
                    ),
                  )
                else if (searchController.text.length >= 3)
                  const Center(child: Text("No users found", style: TextStyle(color: Colors.white30))),
              ],
            ),
          );
        });
      },
    );
  }

  void _sendWatchPartyInvite(User targetUser) {
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))),
      barrierDismissible: false,
    );

    final ChattingController chattingController = ChattingController(user: targetUser);
    
    // Allow Firestore setup and references to load
    Future.delayed(const Duration(milliseconds: 800), () {
      Get.back(); // close loading dialog
      
      final episode = widget.episodes[_currentIndex];
      final epNum = episode['episode_number'] ?? 1;

      chattingController.messageTextController.text = "come and join my watch party 🍿";
      chattingController.commonSend(
        type: MessageType.watchParty,
        dramaId: widget.dramaId,
        episodeId: int.parse(episode['id'].toString()),
        dramaTitle: "${widget.dramaTitle} (Episode $epNum)",
        episodeNumber: epNum,
      );

      Get.snackbar(
        "Invite Sent",
        "Watch party invite successfully sent to @${targetUser.username}.",
        backgroundColor: const Color(0xFF00FF87),
        colorText: Colors.black,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: widget.episodes.length,
        itemBuilder: (context, index) {
          final episode = widget.episodes[index];
          final epTitle = episode['title'] ?? '';
          final epNum = episode['episode_number'] ?? 1;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Vertical Video Player Container
              GestureDetector(
                onTap: _togglePlayPause,
                child: _isPlayerInitialized && _videoPlayerController != null
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _videoPlayerController!.value.aspectRatio,
                          child: VideoPlayer(_videoPlayerController!),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))),
              ),

              // Play/Pause Overlay indicator
              if (!_isPlaying && _isPlayerInitialized)
                const Center(
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white54, size: 80),
                ),

              // Left Sidebar Top Navigation back
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),

              // Right Sidebar Watch Party Action
              Positioned(
                right: 16,
                bottom: 120,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.share_rounded, color: Color(0xFF00FF87), size: 24),
                        onPressed: _openWatchPartyShareModal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Invite",
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Bottom Info HUD
              Positioned(
                left: 16,
                right: 16,
                bottom: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dramaTitle,
                      style: const TextStyle(
                        color: Color(0xFF00FF87),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Episode $epNum: $epTitle",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Progress Bar
                    if (_isPlayerInitialized && _videoPlayerController != null)
                      VideoProgressIndicator(
                        _videoPlayerController!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF00FF87),
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
