import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/logo_tag.dart';
import 'package:untitled/utilities/const.dart';

class AudioSpaceEndedForUserScreen extends StatelessWidget {
  const AudioSpaceEndedForUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cAudioSpaceDarkBG,
      child: Column(
        children: [
          SizedBox(
            height: 50,
          ),
          SizedBox(
            height: AppBar().preferredSize.height,
          ),
          LogoTag(
            isWhite: true,
            width: 130,
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                LKeys.audio.tr,
                style: MyTextStyle.gilroyLight(
                  size: 25,
                  color: cPrimary,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                LKeys.space.tr,
                style: MyTextStyle.gilroyBold(
                  size: 25,
                  color: cPrimary,
                ),
              )
            ],
          ),
          Spacer(),
          SizedBox(
            height: 10,
          ),
          Text(
            LKeys.ended.tr,
            style: MyTextStyle.gilroySemiBold(
              size: 25,
              color: cRed,
            ).copyWith(letterSpacing: 1),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              Get.back();
              Get.back();
            },
            child: SafeArea(
              child: ClipRRect(
                borderRadius: SmoothBorderRadius(cornerRadius: 100, cornerSmoothing: cornerSmoothing),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 60),
                  color: cWhite.withValues(alpha: 0.1),
                  child: Text(
                    LKeys.close.tr,
                    style: MyTextStyle.gilroySemiBold(size: 16, color: cWhite.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
          ),
        ],
      ),
    );
  }
}
