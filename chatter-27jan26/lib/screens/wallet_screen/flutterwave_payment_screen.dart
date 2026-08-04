import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';

class FlutterwavePaymentResult {
  final bool success;
  final String txRef;
  final String? transactionId;

  FlutterwavePaymentResult({
    required this.success,
    required this.txRef,
    this.transactionId,
  });
}

class FlutterwavePaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String txRef;

  const FlutterwavePaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.txRef,
  });

  @override
  State<FlutterwavePaymentScreen> createState() => _FlutterwavePaymentScreenState();
}

class _FlutterwavePaymentScreenState extends State<FlutterwavePaymentScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF151515))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            _checkPaymentCompletion(url);
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _loadingProgress = 100;
              });
            }
            _checkPaymentCompletion(url);
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentCompletion(String url) {
    if (_isFinished) return;

    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('status=successful') ||
        lowerUrl.contains('status=completed') ||
        lowerUrl.contains('callback') ||
        lowerUrl.contains('flutterwave/callback') ||
        lowerUrl.contains('tx_ref=')) {
      _isFinished = true;

      // Extract transaction ID if present
      String? txId;
      final uri = Uri.parse(url);
      if (uri.queryParameters.containsKey('transaction_id')) {
        txId = uri.queryParameters['transaction_id'];
      }

      Get.back(
        result: FlutterwavePaymentResult(
          success: true,
          txRef: widget.txRef,
          transactionId: txId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF151515),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () {
            swalConfirmation(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Flutterwave Checkout",
              style: MyTextStyle.gilroyBold(size: 16, color: Colors.white),
            ),
            Row(
              children: [
                const Icon(Icons.lock_rounded, color: Color(0xFF00FF87), size: 12),
                const SizedBox(width: 4),
                Text(
                  "Secure Payment",
                  style: MyTextStyle.gilroyMedium(size: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
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
              color: const Color(0xFF00FF87),
              minHeight: 3,
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF151515),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Complete payment in popup",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF87),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Get.back(
                      result: FlutterwavePaymentResult(
                        success: true,
                        txRef: widget.txRef,
                      ),
                    );
                  },
                  child: const Text(
                    "I Have Paid",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void swalConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Cancel Payment?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to exit the payment process?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Continue Paying", style: TextStyle(color: Color(0xFF00FF87))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Get.back(
                result: FlutterwavePaymentResult(
                  success: false,
                  txRef: widget.txRef,
                ),
              );
            },
            child: const Text("Exit", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
