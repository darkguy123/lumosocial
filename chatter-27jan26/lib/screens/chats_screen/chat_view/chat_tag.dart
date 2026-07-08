import 'dart:io';
import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:lumosocial/common/api_service/story_service.dart';
import 'package:lumosocial/common/controller/base_controller.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/models/chat.dart';
import 'package:lumosocial/models/registration.dart';
import 'package:lumosocial/screens/chats_screen/chatting_screen/chatting_controller.dart';
import 'package:lumosocial/screens/chats_screen/chatting_screen/content_full_screen.dart';
import 'package:lumosocial/screens/extra_views/back_button.dart';
import 'package:lumosocial/screens/profile_screen/profile_screen.dart';
import 'package:lumosocial/screens/story_screen/story_screen.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/utilities/firebase_const.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/utilities/web_service.dart';
import 'package:lumosocial/screens/drama_screen/drama_player_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lumosocial/utilities/translate_util.dart';

class ChatTag extends StatelessWidget {
  final ChattingController controller;
  final int index;
  final ChatMessage message;
  final bool isFromRoom;

  const ChatTag({Key? key, required this.index, required this.message, this.isFromRoom = false, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    return Row(
      mainAxisAlignment: isMyMsg ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        isMyMsg ? const Spacer() : Container(),
        Column(
          crossAxisAlignment: isMyMsg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            commonChooseView(),
            Text(
              message.getChatTime(),
              style: MyTextStyle.gilroyRegular(size: 12, color: cLightText),
            ),
            const SizedBox(
              height: 10,
            )
          ],
        ),
        !isMyMsg ? const Spacer() : Container(),
      ],
    );
  }

  Widget storyView() {
    bool isEmojiText = isSingleEmoji(message.msg ?? '');
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    var isStoryDeleted = message.thumbnail == null || message.thumbnail == "";
    bool shouldShowReaction = isEmojiText || isStoryDeleted;
    double emojiSize = shouldShowReaction ? 50 : 0;
    return Column(
      crossAxisAlignment: isMyMsg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMyMsg) storyDivider(isStoryDeleted, isMyMsg),
            isStoryDeleted
                ? Text(
                    LKeys.storyHasBeenDeleted.tr,
                    style: MyTextStyle.gilroyRegular(color: cLightText),
                  )
                : Container(
                    width: (Get.width * 0.5) / 1.65 + (emojiSize / 2),
                    height: (Get.width * 0.5) + (emojiSize / 2),
                    child: Stack(
                      alignment: isMyMsg ? Alignment.topRight : Alignment.topLeft,
                      children: [
                        Container(
                          constraints: BoxConstraints(maxWidth: Get.width * 0.6),
                          padding: EdgeInsets.all(1.5),
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: ShapeDecoration(
                            color: cBlack,
                            shape: const SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius.all(
                              SmoothRadius(cornerRadius: 6.5, cornerSmoothing: cornerSmoothing),
                            )),
                          ),
                          child: ClipSmoothRect(
                            radius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 5, cornerSmoothing: cornerSmoothing)),
                            child: GestureDetector(
                              onTap: () {
                                BaseController.share.startLoading();
                                StoryService.shared.fetchStoryById(
                                  storyId: (message.storyId ?? 0).toInt(),
                                  completion: (story) {
                                    BaseController.share.stopLoading();
                                    if (story != null) {
                                      var user = story.user ?? User();
                                      user.stories = [story];
                                      Get.bottomSheet(StoryScreen(users: [user], index: 0), ignoreSafeArea: false, isScrollControlled: true);
                                    } else {
                                      controller.removeStoryFromMessage(message: message);
                                    }
                                  },
                                );
                              },
                              child: MyCachedImage(
                                imageUrl: message.thumbnail,
                                height: Get.width * 0.5,
                                width: (Get.width * 0.5) / 1.65,
                              ),
                            ),
                          ),
                        ),
                        if (shouldShowReaction)
                          Positioned(
                            bottom: 0,
                            left: isMyMsg ? 0 : null,
                            right: !isMyMsg ? 0 : null,
                            child: Container(
                              child: Text(
                                message.msg ?? '',
                                style: TextStyle(
                                  fontSize: emojiSize,
                                  color: cBlack,
                                  shadows: <Shadow>[
                                    Shadow(
                                      blurRadius: 10,
                                      color: cBlack.withValues(alpha: 0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
            if (isMyMsg) storyDivider(isStoryDeleted, isMyMsg)
          ],
        ),
        ((message.msg ?? '').isNotEmpty && !shouldShowReaction)
            ? Container(
                padding: EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: ShapeDecoration(
                  color: isMyMsg ? cBlack : cLightText.withValues(alpha: 0.15),
                  shape: const SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 8, cornerSmoothing: cornerSmoothing))),
                ),
                child: Text(
                  message.msg ?? '',
                  style: MyTextStyle.gilroyRegular(size: 16, color: isMyMsg ? cWhite : cBlack),
                ),
              )
            : Container()
      ],
    );
  }

  Widget storyDivider(bool isStoryDeleted, bool isMyMsg) {
    return Container(
      constraints: BoxConstraints(maxWidth: Get.width * 0.6),
      height: isStoryDeleted ? 20 : Get.width * 0.5,
      width: 3,
      margin: EdgeInsets.only(right: isMyMsg ? 0 : 5, left: isMyMsg ? 5 : 0, top: 4.5),
      decoration: ShapeDecoration(
        color: cLightText.withValues(alpha: 0.3),
        shape: const SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 8, cornerSmoothing: cornerSmoothing))),
      ),
    );
  }

  bool isSingleEmoji(String input) {
    // Check if the string has exactly one character
    if (input.runes.length != 1) {
      return false;
    }

    // Regular expression to match emojis
    final emojiRegex = RegExp(
        r'[\u{1F600}-\u{1F64F}' // Emoticons
        r'\u{1F300}-\u{1F5FF}' // Symbols & Pictographs
        r'\u{1F680}-\u{1F6FF}' // Transport & Map Symbols
        r'\u{1F700}-\u{1F77F}' // Alchemical Symbols
        r'\u{1F780}-\u{1F7FF}' // Geometric Shapes Extended
        r'\u{1F800}-\u{1F8FF}' // Supplemental Arrows-C
        r'\u{1F900}-\u{1F9FF}' // Supplemental Symbols and Pictographs
        r'\u{1FA00}-\u{1FA6F}' // Chess Symbols
        r'\u{1FA70}-\u{1FAFF}' // Symbols and Pictographs Extended-A
        r'\u{2600}-\u{26FF}' // Miscellaneous Symbols
        r'\u{2700}-\u{27BF}' // Dingbats
        r'\u{1F1E6}-\u{1F1FF}' // Regional Indicator Symbols
        r'\u{1F900}-\u{1F9FF}]', // Supplemental Symbols and Pictographs
        unicode: true);

    // Test the single character against the emoji regex
    return emojiRegex.hasMatch(input);
  }

  Widget imageAndVideoView() {
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    return Container(
      constraints: BoxConstraints(maxWidth: Get.width * 0.6),
      padding: EdgeInsets.all(5),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: ShapeDecoration(
        color: isMyMsg ? cBlack : cLightText.withValues(alpha: 0.15),
        shape: const SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 10, cornerSmoothing: cornerSmoothing))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          remoteUserNameView(verticalPadding: 3, horizontalPadding: 5),
          ClipSmoothRect(
            radius: const SmoothBorderRadius.all(SmoothRadius(cornerRadius: 5, cornerSmoothing: cornerSmoothing)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.bottomSheet(ContentFullScreen(message: message), ignoreSafeArea: false, isScrollControlled: true);
                  },
                  child: MyCachedImage(
                    imageUrl: message.msgType == MessageType.video ? message.thumbnail : message.content,
                    width: Get.width * 0.6,
                    height: Get.width * 0.6,
                  ),
                ),
                message.msgType == MessageType.video
                    ? const CircleAvatar(
                        radius: 13,
                        backgroundColor: cPrimary,
                        foregroundColor: cBlack,
                        child: Icon(Icons.play_arrow_rounded, size: 20),
                      )
                    : Container(width: 0),
              ],
            ),
          ),
          (message.msg ?? '') != '' ? textView(padding: 3, showBgColor: false) : Container(width: 0),
        ],
      ),
    );
  }

  Widget remoteUserNameView({double? verticalPadding, double? horizontalPadding}) {
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    var user = controller.room?.roomUsers?.firstWhere(
      (element) => element.id == message.senderId,
      orElse: () => User(fullName: 'Unknown'),
    );
    if (!isMyMsg && isFromRoom) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding ?? 0, horizontal: horizontalPadding ?? 0),
        child: Column(
          children: [
            FittedBox(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (user?.id != null && user?.id != 0) {
                        Get.to(() => ProfileScreen(userId: user?.id ?? 0));
                      }
                    },
                    child: Text(
                      user?.fullName ?? '',
                      style: MyTextStyle.gilroyBold(color: cBlack),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const VerifyIcon()
                ],
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      );
    } else {
      return const Column();
    }
  }

  Widget textView({double? padding, bool showBgColor = true}) {
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    return Container(
      constraints: BoxConstraints(maxWidth: Get.width * 0.6),
      padding: EdgeInsets.all(padding ?? 10),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: ShapeDecoration(
        color: showBgColor
            ? isMyMsg
                ? cBlack
                : cLightText.withValues(alpha: 0.15)
            : Colors.transparent,
        shape: const SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 10, cornerSmoothing: cornerSmoothing))),
      ),
      // child: Text(
      //   message.msg ?? '',
      //   style: MyTextStyle.gilroyRegular(size: 16, color: isMyMsg ? cWhite : cBlack),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          padding == null ? remoteUserNameView() : Container(),
          TranslatableChatText(
            text: message.msg ?? '',
            isMyMsg: isMyMsg,
            controller: controller,
          ),
        ],
      ),
    );
  }

  Widget commonChooseView() {
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    switch (message.msgType) {
      case MessageType.text:
        return textView();
      case MessageType.image:
        return imageAndVideoView();
      case MessageType.video:
        return imageAndVideoView();
      case MessageType.storyReply:
        return storyView();
      case MessageType.watchParty:
        return watchPartyView();
      case MessageType.audio:
        return AudioBubblePlayer(audioUrl: (message.content ?? "").addBaseURL(), isMyMsg: isMyMsg);
      case MessageType.call:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMyMsg ? cBlack : cLightText.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_end_rounded, color: isMyMsg ? Colors.white : Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(
                message.msg ?? "Voice Call ended",
                style: MyTextStyle.gilroyMedium(color: isMyMsg ? Colors.white : Colors.black, size: 14),
              ),
            ],
          ),
        );
      case MessageType.coinTransfer:
        return CoinTransferBubble(message: message, isMyMsg: isMyMsg);
    }
  }

  Widget watchPartyView() {
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    return Container(
      width: Get.width * 0.6,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isMyMsg ? const Color(0xFF1E1E1E) : const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00FF87).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_filter_rounded, color: Color(0xFF00FF87), size: 24),
              const SizedBox(width: 8),
              Text(
                "Watch Party Invite 🍿",
                style: MyTextStyle.gilroyBold(size: 14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message.msg ?? "come and join my watch party",
            style: MyTextStyle.gilroyMedium(size: 13, color: Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            message.dramaTitle ?? "",
            style: MyTextStyle.gilroyBold(size: 15, color: const Color(0xFF00FF87)),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF87),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                BaseController.share.startLoading();
                ApiService.shared.call(
                  url: WebService.dramaDetails,
                  param: {
                    'drama_id': message.dramaId?.toInt() ?? 0,
                    'user_id': SessionManager.shared.getUserID(),
                  },
                  completion: (response) {
                    BaseController.share.stopLoading();
                    if (response['status'] == true) {
                      final episodes = response['data']['episodes_list'] as List? ?? [];
                      int index = 0;
                      if (message.episodeNumber != null) {
                        index = episodes.indexWhere((e) => e['episode_number'] == message.episodeNumber?.toInt());
                        if (index == -1) index = 0;
                      }
                      Get.to(() => DramaPlayerScreen(
                            episodes: episodes,
                            initialIndex: index,
                            dramaTitle: message.dramaTitle ?? "",
                            dramaId: message.dramaId?.toInt() ?? 0,
                          ));
                    } else {
                      Get.snackbar("Error", "Failed to load watch party drama details.");
                    }
                  },
                );
              },
              child: const Text("Join", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

}

/// Coin transfer receipt bubble
class CoinTransferBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMyMsg;

  const CoinTransferBubble({Key? key, required this.message, required this.isMyMsg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // msg format: "COIN_TRANSFER:amount" stored in content field
    final rawContent = message.content ?? '';
    final parts = rawContent.split(':');
    final amount = parts.length > 1 ? parts[1] : (message.msg ?? '0');

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMyMsg
              ? [const Color(0xFF1A1A1A), const Color(0xFF0E0E0E)]
              : [const Color(0xFF1E2A1E), const Color(0xFF0F1A0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00FF87).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF87).withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on_rounded, color: Color(0xFF00FF87), size: 18),
              const SizedBox(width: 6),
              Text(
                isMyMsg ? 'Sent' : 'Received',
                style: const TextStyle(color: Color(0xFF00FF87), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$amount Lc',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'gilroy_bold',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMyMsg ? 'Coins Sent' : 'Coins Received',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Get.snackbar(
                'Lumo Wallet',
                'Open your wallet to check your current balance.',
                backgroundColor: const Color(0xFF00FF87),
                colorText: Colors.black,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF87).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00FF87).withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Check Balance',
                style: TextStyle(
                  color: Color(0xFF00FF87),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class ChatButton extends StatelessWidget {
  final String title;
  final Color color;
  final Function()? onTap;

  const ChatButton({Key? key, required this.title, required this.color, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 30),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
        child: Text(
          title.tr,
          style: MyTextStyle.gilroySemiBold(color: color),
        ),
      ),
    );
  }
}

class AudioBubblePlayer extends StatefulWidget {
  final String audioUrl;
  final bool isMyMsg;

  const AudioBubblePlayer({Key? key, required this.audioUrl, required this.isMyMsg}) : super(key: key);

  @override
  State<AudioBubblePlayer> createState() => _AudioBubblePlayerState();
}

class _AudioBubblePlayerState extends State<AudioBubblePlayer> {
  late PlayerController playerController;
  bool isPlaying = false;
  bool isInitialized = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    playerController = PlayerController();
    _downloadAndPrepare();
  }

  Future<void> _downloadAndPrepare() async {
    try {
      // audio_waveforms needs a local file path — download the remote URL first
      final dir = await getTemporaryDirectory();
      final fileName = widget.audioUrl.split('/').last.split('?').first;
      final localPath = '${dir.path}/$fileName';
      final file = File(localPath);

      if (!file.existsSync()) {
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(widget.audioUrl));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes);
        httpClient.close();
      }

      await playerController.preparePlayer(
        path: localPath,
        shouldExtractWaveform: true,
        noOfSamples: 30,
      );

      if (mounted) {
        setState(() => isInitialized = true);
      }

      playerController.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() => isPlaying = state == PlayerState.playing);
        }
      });
    } catch (e) {
      debugPrint("AudioBubblePlayer error: $e");
      if (mounted) {
        setState(() => hasError = true);
      }
    }
  }

  @override
  void dispose() {
    playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isMyMsg ? cBlack : cLightText.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (!isInitialized) return;
              if (isPlaying) {
                await playerController.pausePlayer();
              } else {
                await playerController.startPlayer();
              }
            },
            child: Icon(
              hasError
                  ? Icons.error_outline_rounded
                  : (isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
              color: hasError ? Colors.red : (widget.isMyMsg ? cPrimary : cBlack),
              size: 32,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: hasError
                ? Text('Audio unavailable', style: TextStyle(color: widget.isMyMsg ? Colors.white54 : Colors.black45, fontSize: 12))
                : (isInitialized
                    ? AudioFileWaveforms(
                        size: const Size(140, 30),
                        playerController: playerController,
                        enableSeekGesture: true,
                        waveformType: WaveformType.fitWidth,
                        playerWaveStyle: PlayerWaveStyle(
                          fixedWaveColor: widget.isMyMsg ? Colors.white38 : Colors.black26,
                          liveWaveColor: widget.isMyMsg ? const Color(0xFF00FF87) : cPrimary,
                          spacing: 4,
                          waveThickness: 2.5,
                        ),
                      )
                    : const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: cPrimary),
                        ),
                      )),
          ),
        ],
      ),
    );
  }
}

class TranslatableChatText extends StatefulWidget {
  final String text;
  final bool isMyMsg;
  final ChattingController controller;

  const TranslatableChatText({
    Key? key,
    required this.text,
    required this.isMyMsg,
    required this.controller,
  }) : super(key: key);

  @override
  State<TranslatableChatText> createState() => _TranslatableChatTextState();
}

class _TranslatableChatTextState extends State<TranslatableChatText> {
  bool _isTranslated = false;
  bool _isTranslating = false;
  late String _displayText;

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
  }

  @override
  void didUpdateWidget(covariant TranslatableChatText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _displayText = widget.text;
      _isTranslated = false;
    }
  }

  void _toggleTranslation() async {
    if (_isTranslated) {
      setState(() {
        _displayText = widget.text;
        _isTranslated = false;
      });
    } else {
      setState(() {
        _isTranslating = true;
      });
      try {
        final translated = await translateText(widget.text, targetLang: 'en');
        setState(() {
          _displayText = translated;
          _isTranslated = true;
        });
      } catch (e) {
        debugPrint("Translation error: $e");
      } finally {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetectableText(
          maxLines: null,
          detectionRegExp: detectionRegExp(atSign: false, url: true)!,
          onTap: (p0) async {
            widget.controller.handleURL(url: p0);
          },
          lessStyle: MyTextStyle.gilroyMedium(color: cPrimary),
          moreStyle: MyTextStyle.gilroyMedium(color: cPrimary),
          trimCollapsedText: LKeys.showMore.tr,
          trimExpandedText: '  ${LKeys.showLess.tr}',
          text: _displayText,
          basicStyle: MyTextStyle.gilroyRegular(size: 16, color: widget.isMyMsg ? cWhite : cBlack),
          detectedStyle: MyTextStyle.gilroySemiBold(size: 16, color: cPrimary),
        ),
        if (widget.text.isNotEmpty) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _isTranslating ? null : _toggleTranslation,
            child: Text(
              _isTranslating
                  ? "Translating..."
                  : _isTranslated
                      ? "Show original"
                      : "Translate",
              style: MyTextStyle.gilroySemiBold(
                size: 11,
                color: widget.isMyMsg ? const Color(0xFF00FF87) : cPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
