import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/managers/my_refresh_indicator.dart';
import 'package:lumosocial/common/widgets/no_data_view.dart';
import 'package:lumosocial/enums/reel_page_type.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/models/musics_model.dart';
import 'package:lumosocial/models/reel_model.dart';
import 'package:lumosocial/models/registration.dart';
import 'package:lumosocial/screens/reels_screen/reel/reel_page.dart';
import 'package:lumosocial/screens/reels_screen/reels_screen_controller.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:lumosocial/main.dart';
import 'package:lumosocial/screens/reels_screen/widget/reels_text_field.dart';
import 'package:lumosocial/screens/reels_screen/widget/reels_top_bar.dart';



class ReelsScreen extends StatefulWidget {
  final ReelPageType pageType;
  final RxList<Reel> reels;
  final RxInt position;
  final User? user;
  final Music? music;
  final String? hashTag;
  final String? noReelDescription;
  final Widget? topView;
  final RxBool isLoading;
  final Future<void> Function()? onFetchMoreData;
  final Future<void> Function()? onRefresh;

  const ReelsScreen({
    super.key,
    required this.reels,
    required this.position,
    this.user,
    required this.pageType,
    this.hashTag,
    this.music,
    this.onFetchMoreData,
    this.topView,
    this.onRefresh,
    required this.isLoading,
    this.noReelDescription,
  });

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with AutomaticKeepAliveClientMixin, RouteAware, WidgetsBindingObserver {
  late ReelsScreenController controller;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    if (_isControllerInitialized) {
      controller.muteCurrentPlayer();
    }
    super.didPushNext();
  }

  @override
  void didPopNext() {
    if (_isControllerInitialized) {
      controller.unmuteCurrentPlayer();
    }
    super.didPopNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isControllerInitialized) return;
    if (state == AppLifecycleState.paused) {
      controller.muteCurrentPlayer();
    } else if (state == AppLifecycleState.resumed) {
      controller.unmuteCurrentPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isControllerInitialized) {
      controller = Get.put(
        ReelsScreenController(
          reels: widget.reels,
          position: widget.position,
          user: widget.user,
          hashtag: widget.hashTag,
          reelPageType: widget.pageType,
          onFetchMoreData: widget.onFetchMoreData,
          onRefresh: widget.onRefresh,
        ),
        tag: widget.pageType.withId(musicId: widget.music?.id, userId: widget.user?.id, hashTag: widget.hashTag),
      );
      _isControllerInitialized = true;
    }

    return Scaffold(
      backgroundColor: cBlack,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(
                child: MyRefreshIndicator(
                  onRefresh: () async {
                    if (widget.onRefresh != null) {
                      controller.onRefreshPage();
                    }
                  },
                  shouldRefresh: widget.onRefresh != null,
                  child: Obx(
                    () => Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        if (controller.reels.isEmpty)
                          if (widget.isLoading.value)
                            Center(child: CircularProgressIndicator(color: cPrimary))
                          else
                            NoDataView(
                              title: LKeys.noReels,
                              description: widget.noReelDescription,
                            )
                        else
                          VisibilityDetector(
                            key: Key('reels_list_${controller.reelPageType}'),
                            onVisibilityChanged: (info) {
                              if (info.visibleFraction == 1) {
                                if (controller.players.isEmpty) {
                                  controller.onPageChanged(controller.position.value);
                                }
                              } else {
                                controller.pauseAllPlayers();
                              }
                            },
                            child: Obx(
                              () => PageView.builder(
                                physics: CustomPageViewScrollPhysics(),
                                controller: controller.pageController,
                                itemCount: controller.reels.length,
                                onPageChanged: controller.onPageChanged,
                                scrollDirection: Axis.vertical,
                                itemBuilder: (context, index) {
                                  Reel reel = controller.reels[index];
                                  return Obx(() {
                                    return ReelPage(
                                      reelData: reel,
                                      videoPlayerController: controller.players[index]?.controller,
                                    );
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              ReelsTextField(controller: controller)
            ],
          ),
          ReelsTopBar(controller: controller, reelType: widget.pageType, widget: widget.topView)
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class CustomPageViewScrollPhysics extends ScrollPhysics {
  const CustomPageViewScrollPhysics({super.parent});

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 1,
        stiffness: 1000,
        damping: 60,
      );
}
