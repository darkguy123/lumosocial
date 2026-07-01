import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GamePlayerScreen extends StatefulWidget {
  final String gameUrl;
  final String gameTitle;

  const GamePlayerScreen({
    Key? key,
    required this.gameUrl,
    required this.gameTitle,
  }) : super(key: key);

  @override
  State<GamePlayerScreen> createState() => _GamePlayerScreenState();
}

class _GamePlayerScreenState extends State<GamePlayerScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(widget.gameUrl));
  }

  void _showPauseOverlay() {
    setState(() {
      _isPaused = true;
    });
    // Tell webview to pause or execute JS to pause audio/loops
    _webViewController.runJavaScript('window.blur();');
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
    });
    _webViewController.runJavaScript('window.focus();');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen WebView player
          SafeArea(
            child: WebViewWidget(controller: _webViewController),
          ),
          
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: cPrimary),
            ),
            
          // Pause screen overlay
          if (_isPaused)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pause_circle_filled_rounded, color: cPrimary, size: 75),
                    const SizedBox(height: 15),
                    Text(
                      "GAME PAUSED",
                      style: MyTextStyle.gilroyBold(size: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cPrimary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text("Resume Game", style: MyTextStyle.gilroyBold(size: 15)),
                      onPressed: _resumeGame,
                    ),
                  ],
                ),
              ),
            ),

          // Floating controls action button at bottom center
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _isPaused ? 0.0 : 0.85,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pause action
                    GestureDetector(
                      onTap: _showPauseOverlay,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E24),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: const Icon(Icons.pause_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Quit / Exit action
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      ),
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
