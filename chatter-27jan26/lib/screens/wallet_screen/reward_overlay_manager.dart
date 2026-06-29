import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/screens/wallet_screen/wallet_screen.dart';

class RewardOverlayManager {
  static final List<OverlayEntry> _activeToasts = [];
  static final List<Map<String, dynamic>> _toastQueue = [];
  static bool _isShowingLimitPopup = false;

  static void handleReward(Map<String, dynamic> rewardData) {
    if (rewardData['success'] == true) {
      double earned = double.tryParse(rewardData['earned'].toString()) ?? 0.0;
      double totalToday = double.tryParse(rewardData['total_today'].toString()) ?? 0.0;
      String message = rewardData['message'] ?? '';

      // Extract action name from message (e.g., "like", "comment", etc.)
      String action = "activity";
      if (message.toLowerCase().contains("like")) {
        action = "like";
      } else if (message.toLowerCase().contains("comment")) {
        action = "comment";
      } else if (message.toLowerCase().contains("post")) {
        action = "first post";
      } else if (message.toLowerCase().contains("follow")) {
        action = "following user";
      } else if (message.toLowerCase().contains("registration")) {
        action = "registration";
      }

      if (earned > 0) {
        showEarningToast(earned, action);
      }

      // Check if daily limit of 10 Lc is reached
      if (totalToday >= 10.0 && !_isShowingLimitPopup) {
        // Show center limit popup
        showLimitReachedPopup(totalToday);
      }
    }
  }

  static void showEarningToast(double amount, String action) {
    final context = Get.overlayContext;
    if (context == null) return;

    late OverlayEntry overlayEntry;
    
    // Position offset based on active toasts to layer them
    double topOffset = 60.0 + (_activeToasts.length * 75.0);

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: topOffset,
          left: 20,
          right: 20,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              overlayEntry.remove();
              _activeToasts.remove(overlayEntry);
              _repositionToasts();
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00FF87), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF87).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FF87),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.monetization_on,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Coin Reward Earned!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Gilroy-Bold',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "You earned +$amount Lc for $action.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Gilroy-Regular',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                      onPressed: () {
                        overlayEntry.remove();
                        _activeToasts.remove(overlayEntry);
                        _repositionToasts();
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
    _activeToasts.add(overlayEntry);

    // Auto dismiss after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (_activeToasts.contains(overlayEntry)) {
        overlayEntry.remove();
        _activeToasts.remove(overlayEntry);
        _repositionToasts();
      }
    });
  }

  static void _repositionToasts() {
    // Force a rebuild of active overlays if needed to update positioning offset
    final context = Get.overlayContext;
    if (context == null) return;
    for (var toast in _activeToasts) {
      toast.markNeedsBuild();
    }
  }

  static void showLimitReachedPopup(double totalToday) {
    _isShowingLimitPopup = true;
    final context = Get.overlayContext;
    if (context == null) return;

    int countdown = 5;
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Start countdown once dialog mounts
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (countdown > 1) {
                setState(() {
                  countdown--;
                });
              } else {
                timer.cancel();
                Navigator.of(dialogContext).pop();
                _isShowingLimitPopup = false;
                Get.to(() => const WalletScreen());
              }
            });

            return Dialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFF00FF87), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF87).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF00FF87),
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Daily Earning Capped!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gilroy-Bold',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Congratulations! You reached today's cap by earning $totalToday Lc today.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Gilroy-Regular',
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Moving to wallet countdown animation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF87)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Moving to wallet in $countdown...",
                          style: const TextStyle(
                            color: Color(0xFF00FF87),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Action button / slider alternative
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF87),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      onPressed: () {
                        countdownTimer?.cancel();
                        Navigator.of(dialogContext).pop();
                        _isShowingLimitPopup = false;
                        Get.to(() => const WalletScreen());
                      },
                      child: const Text(
                        "Go to Wallet Now",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      countdownTimer?.cancel();
      _isShowingLimitPopup = false;
    });
  }
}
