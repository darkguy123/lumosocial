import 'package:dismissible_page/dismissible_page.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/extensions/duration_extension.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/models/chat.dart';
import 'package:lumosocial/screens/post/post_card.dart';
import 'package:lumosocial/screens/post/post_controller.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/screens/post/video_ad_overlay.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/utilities/firebase_const.dart';
import 'package:video_player/video_player.dart';
import 'package:lumosocial/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class VideoPlayerSheet extends StatefulWidget {
  final PostController controller;

  VideoPlayerSheet({Key? key, required this.controller}) : super(key: key);

  @override
  State<VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<VideoPlayerSheet> with RouteAware, WidgetsBindingObserver {
  VideoPlayerController? playerController;
  bool isLoading = true;



  List<dynamic> _videoAds = [];
  bool _adTriggeredForThisVideo = false;
  bool _showAdOverlay = false;
  Map<String, dynamic>? _selectedAd;
  late int _adTriggerSecond;
  late bool _shouldShowAdForThisVideo;

  @override
  void initState() {
    _adTriggerSecond = 5 + Random().nextInt(15);
    _shouldShowAdForThisVideo = Random().nextBool();
    initPlayer();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    playerController?.removeListener(_playerListener);
    playerController?.pause();
    playerController = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    _mutePlayer();
    super.didPushNext();
  }

  @override
  void didPopNext() {
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

  void _mutePlayer() {
    if (playerController != null && playerController!.value.isInitialized) {
      playerController!.setVolume(0.0);
    }
  }

  void _unmutePlayer() {
    if (playerController != null && playerController!.value.isInitialized) {
      playerController!.setVolume(1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const ShapeDecoration(
        color: cBlackSheetBG,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.only(
            topLeft: SmoothRadius(cornerRadius: 20, cornerSmoothing: cornerSmoothing),
            topRight: SmoothRadius(cornerRadius: 20, cornerSmoothing: cornerSmoothing),
          ),
        ),
      ),
      margin: EdgeInsets.only(top: Get.statusBarHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 0, right: 20, left: 20),
            child: PostTopBar(
              controller: widget.controller,
              isForVideo: true,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PostDescriptionView(controller: widget.controller, isForVideo: true),
                    ),
                    if (playerController != null)
                      Container(
                        width: Get.width,
                        height: Get.width,
                        color: cWhite.withValues(alpha: 0.1),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            GestureDetector(
                              onTap: playPause,
                              child: Hero(
                                tag: 'player',
                                transitionOnUserGestures: true,
                                child: AspectRatio(
                                  aspectRatio: playerController!.value.aspectRatio,
                                  child: VideoPlayer(playerController!),
                                ),
                              ),
                            ),
                            if (_showAdOverlay && _selectedAd != null)
                              VideoAdOverlay(
                                ad: _selectedAd!,
                                onAdFinished: () {
                                  if (mounted) {
                                    setState(() {
                                      _showAdOverlay = false;
                                    });
                                  }
                                  playerController?.play();
                                },
                              ),
                            playerController != null && playerController!.value.isInitialized && !isLoading
                                ? ValueListenableBuilder(
                                    valueListenable: playerController!,
                                    builder: (context, VideoPlayerValue value, child) => Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () {
                                                context.pushTransparentRoute(
                                                  ContentFullScreenForPost(
                                                    message: ChatMessage(content: widget.controller.post.content?.first.content ?? '', msgType: 'VIDEO'),
                                                    playerController: playerController,
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                decoration: ShapeDecoration(
                                                  shape: const SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 5, cornerSmoothing: cornerSmoothing))),
                                                  color: cBlack.withValues(alpha: 0.4),
                                                ),
                                                margin: const EdgeInsets.all(10),
                                                padding: const EdgeInsets.all(4),
                                                child: const Icon(Icons.fullscreen_rounded, color: cWhite),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        value.isPlaying == true
                                            ? Container()
                                            : GestureDetector(
                                                onTap: playPause,
                                                child: CircleAvatar(
                                                  backgroundColor: cBlack.withValues(alpha: 0.4),
                                                  foregroundColor: cWhite,
                                                  child: const Icon(
                                                    Icons.play_arrow_rounded,
                                                    size: 30,
                                                  ),
                                                ),
                                              ),
                                        const Spacer(),
                                        VideoSlider(controller: playerController, onChange: onChange),
                                      ],
                                    ),
                                  )
                                : SizedBox(height: Get.width)
                          ],
                        ),
                      )
                    else
                      Container(
                        width: Get.width,
                        height: Get.width,
                        color: cWhite.withValues(alpha: 0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: cPrimary,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PostBottomBar(controller: widget.controller, isForVideo: true),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _fetchVideoAds() async {
    List<dynamic> userAds = [];
    try {
      final adsSnap = await FirebaseFirestore.instance.collection('ads').get();
      userAds = adsSnap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error fetching active Firestore ads: $e");
    }

    ApiService.shared.call(
      url: "${apiURL}ad/list",
      param: {},
      completion: (response) {
        List<dynamic> systemAds = [];
        if (response != null && response['status'] == true) {
          systemAds = (response['data'] ?? []).where((ad) => ad['ad_type'] == 'Skippable Video').toList();
        }
        if (mounted) {
          setState(() {
            _videoAds = [...systemAds, ...userAds];
          });
        }
      },
    );
  }

  void _playerListener() {
    if (playerController == null || !playerController!.value.isInitialized) return;
    
    final position = playerController!.value.position.inSeconds;
    if (position >= _adTriggerSecond && !_adTriggeredForThisVideo && _shouldShowAdForThisVideo && _videoAds.isNotEmpty) {
      _adTriggeredForThisVideo = true;
      
      playerController!.pause();
      if (mounted) {
        setState(() {
          _selectedAd = Map<String, dynamic>.from(_videoAds[Random().nextInt(_videoAds.length)]);
          _showAdOverlay = true;
        });
      }
    }
  }

  void initPlayer() {
    _fetchVideoAds();
    final url = widget.controller.post.content?.first.content?.addBaseURL() ?? '';
    final isHls = url.contains('.m3u8') || url.contains('m3u8');
    playerController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      formatHint: isHls ? VideoFormat.hls : null,
    )
      ..initialize().then((value) {
        if (Get.isBottomSheetOpen == true) {
          play();
        }
        isLoading = false;
        playerController?.addListener(_playerListener);
        if (mounted) {
          setState(() {});
        }
      });
    if (mounted) {
      setState(() {});
    }
  }

  void play() {
    playerController?.play();
  }

  void playPause() {
    if (playerController?.value.isPlaying == true) {
      playerController?.pause();
    } else {
      playerController?.play();
    }
  }

  void onChange(double value) {
    playerController?.seekTo(Duration(milliseconds: value.toInt()));
  }
}

class VideoSlider extends StatelessWidget {
  final VideoPlayerController? controller;
  final Function(double) onChange;

  const VideoSlider({Key? key, required this.controller, required this.onChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: const SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 5, cornerSmoothing: cornerSmoothing))),
        color: cBlack.withValues(alpha: 0.4),
      ),
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(7),
      child: Row(
        children: [
          Text(
            controller?.value.position.toStringTime() ?? "",
            style: MyTextStyle.gilroyRegular(color: cWhite, size: 14),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData().copyWith(trackHeight: 1, overlayShape: SliderComponentShape.noThumb),
              child: Slider(
                label: "",
                thumbColor: cPrimary,
                activeColor: cWhite,
                inactiveColor: cWhite.withValues(alpha: 0.4),
                value: controller?.value.position.inMilliseconds.toDouble() ?? 0,
                max: controller?.value.duration.inMilliseconds.toDouble() ?? 0,
                onChanged: (value) {
                  onChange(value);
                },
              ),
            ),
          ),
          Text(
            controller?.value.duration.toStringTime() ?? "",
            style: MyTextStyle.gilroyRegular(color: cWhite, size: 14),
          ),
        ],
      ),
    );
  }
}

class ContentFullScreenForPost extends StatefulWidget {
  final ChatMessage message;
  final VideoPlayerController? playerController;

  const ContentFullScreenForPost({super.key, required this.message, this.playerController});

  @override
  State<ContentFullScreenForPost> createState() => _ContentFullScreenForPost();
}

class _ContentFullScreenForPost extends State<ContentFullScreenForPost> {
  VideoPlayerController? controller;

  @override
  void initState() {
    var msgType = widget.message.msgType == 'TEXT' ? MessageType.text : (widget.message.msgType == 'IMAGE' ? MessageType.image : MessageType.video);
    if (msgType == MessageType.video) {
      if (widget.playerController == null) {
        controller = VideoPlayerController.networkUrl(Uri.parse(widget.message.content?.addBaseURL() ?? ''))
          ..initialize().then((value) {
            controller?.play();
            setState(() {});
          });
      } else {
        controller = widget.playerController;
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DismissiblePage(
      onDismissed: () {
        Navigator.of(context).pop();
      },
      isFullScreen: true,
      backgroundColor: Colors.transparent,
      // Note that scrollable widget inside DismissiblePage might limit the functionality
      // If scroll direction matches DismissiblePage direction
      direction: DismissiblePageDismissDirection.multi,
      child: Scaffold(
        body: Container(
          color: cBlack,
          child: SafeArea(
            top: true,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Center(
                    child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (controller!.value.isPlaying) {
                          controller?.pause();
                        } else {
                          controller?.play();
                        }
                      },
                      child: controller != null
                          ? Hero(
                              tag: 'player',
                              child: AspectRatio(
                                aspectRatio: controller!.value.aspectRatio,
                                child: VideoPlayer(controller!),
                              ),
                            )
                          : null,
                    ),
                    ValueListenableBuilder(
                      valueListenable: controller!,
                      builder: (context, VideoPlayerValue value, child) {
                        return Column(
                          children: [
                            const SizedBox(height: 50),
                            const Spacer(),
                            value.isPlaying == true
                                ? Container()
                                : GestureDetector(
                                    onTap: () {
                                      if (value.isPlaying) {
                                        controller?.pause();
                                      } else {
                                        controller?.play();
                                      }
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: cBlack.withValues(alpha: 0.4),
                                      foregroundColor: cWhite,
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                            const Spacer(),
                            VideoSlider(controller: controller, onChange: onChange),
                          ],
                        );
                      },
                    )
                  ],
                )),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        child: CircleAvatar(
                          backgroundColor: cLightBg.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.close_rounded,
                            color: cLightText,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onChange(double value) {
    controller?.seekTo(Duration(milliseconds: value.toInt()));
  }

  @override
  void dispose() {
    if (widget.playerController == null) {
      controller?.dispose();
    }
    super.dispose();
  }
}
