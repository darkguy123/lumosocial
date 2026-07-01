import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';

class InAppBrowserScreen extends StatefulWidget {
  final String url;
  const InAppBrowserScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<InAppBrowserScreen> createState() => _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends State<InAppBrowserScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  String _currentTitle = "Loading...";

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _currentTitle = Uri.parse(url).host;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _currentTitle = Uri.parse(url).host;
              _loadingProgress = 100;
            });
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121217),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: cPrimary, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _currentTitle,
                          style: MyTextStyle.gilroyBold(size: 14, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Secure Connection",
                    style: MyTextStyle.gilroyMedium(size: 10, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
            onPressed: () async {
              if (await _controller.canGoForward()) {
                await _controller.goForward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loadingProgress < 100)
            LinearProgressIndicator(
              value: _loadingProgress / 100.0,
              backgroundColor: Colors.transparent,
              color: cPrimary,
              minHeight: 2.5,
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
