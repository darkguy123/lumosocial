import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/login_screen/login_screen.dart';
import 'package:untitled/utilities/const.dart';

import '../extra_views/buttons.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  PageController pageController = PageController(viewportFraction: 1, keepPage: true);
  List<Widget> screens = [
    OnBoardingCard(assetName: MyImages.meeting, title: LKeys.chatRoom, desc: LKeys.chatRoomDesc),
    OnBoardingCard(assetName: MyImages.random, title: LKeys.randomRoom, desc: LKeys.randomRoomDesc),
    OnBoardingCard(assetName: MyImages.micFill, title: LKeys.audioSpace, desc: LKeys.audioSpaceDesc),
    OnBoardingCard(assetName: MyImages.quill, title: LKeys.createChatPost, desc: LKeys.createChatPostDesc),
  ];

  var currentPage = 0;

  @override
  void initState() {
    pageController.addListener(() {
      setState(() {
        currentPage = pageController.page?.toInt() ?? 0;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var isLastPage = (screens.length - 1) == currentPage;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LKeys.textChatDedicated.tr,
                    style: MyTextStyle.gilroyLight(size: 22),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    LKeys.socialMedia.tr,
                    style: MyTextStyle.gilroySemiBold(size: 23),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: pageController,
                children: screens,
              ),
            ),
            Container(
              height: 10,
              margin: EdgeInsets.only(bottom: 30),
              alignment: Alignment.center,
              child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(0),
                  scrollDirection: Axis.horizontal,
                  itemCount: screens.length,
                  itemBuilder: (context, index) {
                    return CircleAvatar(
                      radius: 10,
                      backgroundColor: currentPage == index ? cLightText.withValues(alpha: 0.5) : cLightBg,
                    );
                  }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: CommonButton(
                  text: isLastPage ? LKeys.letsStart : LKeys.next,
                  onTap: () {
                    if (!isLastPage) {
                      pageController.animateToPage(
                        currentPage + 1,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.linear,
                      );
                    } else {
                      Get.to(() => const LoginScreen());
                    }
                  }),
            ),
            Opacity(
              opacity: isLastPage ? 0 : 1,
              child: GestureDetector(
                onTap: () {
                  pageController.animateToPage(
                    screens.length - 1,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.linear,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      LKeys.skip.tr,
                      style: MyTextStyle.gilroyRegular(size: 16, color: cLightText),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class OnBoardingCard extends StatelessWidget {
  final String assetName;
  final String title;
  final String desc;

  const OnBoardingCard({required this.assetName, required this.title, required this.desc, super.key});

  @override
  Widget build(BuildContext context) {
    // return Padding(
    //   padding: const EdgeInsets.symmetric(vertical: 20),
    //   child: Row(
    //     children: [
    //       Container(
    //         decoration: BoxDecoration(
    //           shape: BoxShape.circle,
    //           boxShadow: [
    //             BoxShadow(
    //               color: cPrimary.withValues(alpha: 0.5),
    //               blurRadius: 10,
    //               offset: const Offset(0, 5), // Shadow position
    //             ),
    //           ],
    //         ),
    //         child: CircleAvatar(
    //           radius: 35,
    //           backgroundColor: cPrimary,
    //           child: Image.asset(
    //             assetName,
    //             height: 30,
    //             width: 30,
    //             color: cBlack,
    //           ),
    //         ),
    //       ),
    //       const SizedBox(
    //         width: 10,
    //       ),
    //       Expanded(
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Text(
    //               title.tr.toUpperCase(),
    //               style: MyTextStyle.gilroyExtraBold(),
    //             ),
    //             const SizedBox(
    //               height: 2,
    //             ),
    //             Text(
    //               desc.tr,
    //               style: MyTextStyle.gilroyLight(size: 16, color: cLightText),
    //             )
    //           ],
    //         ),
    //       )
    //     ],
    //   ),
    // );
    var imageSize = 100.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Image.asset(
                //   MyImages.introStroke,
                //   color: cRed,
                // ),
                Image.asset(
                  MyImages.introBG,
                  color: cPrimary,
                ),
                Container(
                  padding: const EdgeInsets.only(top: 20),
                  child: Image.asset(
                    assetName,
                    height: imageSize,
                    width: imageSize,
                    color: cPrimary,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title.tr,
                style: MyTextStyle.gilroyBold(size: 25),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  desc.tr,
                  style: MyTextStyle.gilroyRegular(size: 16, color: cLightText),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
