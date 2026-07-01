import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/screens/game_center/game_player_screen.dart';
import 'package:lumosocial/utilities/const.dart';

class GameCenterScreen extends StatefulWidget {
  const GameCenterScreen({Key? key}) : super(key: key);

  @override
  State<GameCenterScreen> createState() => _GameCenterScreenState();
}

class _GameCenterScreenState extends State<GameCenterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double _loadingProgress = 0.0;
  bool _isLoading = true;
  List<dynamic> _games = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startLoadingAnimation();
    _fetchGames();
  }

  void _startLoadingAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return false;
      setState(() {
        if (_loadingProgress < 1.0) {
          _loadingProgress += 0.02;
        }
      });
      return _loadingProgress < 1.0;
    }).then((_) {
      if (mounted && _games.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _fetchGames() {
    // Call custom API endpoint to get list of games
    ApiService.shared.call(
      url: "${apiURL}game/list",
      param: {},
      completion: (response) {
        if (mounted) {
          if (response['status'] == true) {
            setState(() {
              _games = response['data'] ?? [];
            });
            if (_loadingProgress >= 1.0) {
              setState(() {
                _isLoading = false;
              });
            }
          } else {
            Get.snackbar("Error", response['message'] ?? "Failed to fetch games list.");
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: _isLoading
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0F0F12),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              title: Text(
                "Game Hub",
                style: MyTextStyle.gilroyBold(size: 20, color: Colors.white),
              ),
              centerTitle: true,
            ),
      body: _isLoading ? _buildLoadingScreen() : _buildGameGrid(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0F0F12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gamepad Pulsing Animation
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: cPrimary.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                color: cPrimary,
                size: 75,
              ),
            ),
          ),
          const SizedBox(height: 35),
          // Loading text
          Text(
            "CONNECTING TO GAME HUB",
            style: MyTextStyle.gilroyBold(size: 14, color: Colors.white70).copyWith(letterSpacing: 2.0),
          ),
          const SizedBox(height: 20),
          // Line loading bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(cPrimary),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    return _games.isEmpty
        ? Center(
            child: Text(
              "No games available at the moment.",
              style: MyTextStyle.gilroyBold(size: 16, color: Colors.white60),
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            itemCount: _games.length,
            itemBuilder: (context, index) {
              final game = _games[index];
              final String thumbnail = game['thumbnail'] ?? '';
              
              return GestureDetector(
                onTap: () {
                  Get.to(() => GamePlayerScreen(gameUrl: game['url'], gameTitle: game['title']));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: thumbnail.isNotEmpty
                              ? MyCachedImage(
                                  imageUrl: thumbnail,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  color: Colors.white10,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.sports_esports_rounded, color: Colors.white24, size: 40),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game['title'] ?? '',
                                style: MyTextStyle.gilroyBold(size: 14, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                game['description'] ?? 'Tap to play!',
                                style: MyTextStyle.gilroyMedium(size: 11, color: Colors.white38),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
