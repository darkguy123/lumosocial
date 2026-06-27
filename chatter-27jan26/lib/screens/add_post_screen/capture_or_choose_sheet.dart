import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chatter/common/extensions/font_extension.dart';
import 'package:chatter/localization/languages.dart';
import 'package:chatter/screens/extra_views/back_button.dart';
import 'package:chatter/screens/extra_views/buttons.dart';
import 'package:chatter/utilities/const.dart';

class CaptureOrChooseSheet extends StatelessWidget {
  final Function() onCaptureTap;
  final Function() onChooseTap;

  const CaptureOrChooseSheet({super.key, required this.onCaptureTap, required this.onChooseTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          decoration: const ShapeDecoration(
            color: cBlackSheetBG,
            shape: SmoothRectangleBorder(borderRadius: SmoothBorderRadius.only(topLeft: SmoothRadius(cornerRadius: 30, cornerSmoothing: cornerSmoothing), topRight: SmoothRadius(cornerRadius: 30, cornerSmoothing: cornerSmoothing))),
          ),
          padding: const EdgeInsets.all(25),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Spacer(),
                    XMarkButton(),
                  ],
                ),
                Text(
                  LKeys.howDoYouWant.tr,
                  style: MyTextStyle.gilroyBold(size: 22, color: cWhite),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    btn(title: LKeys.capture, onTap: onCaptureTap),
                    const SizedBox(
                      width: 10,
                    ),
                    btn(
                      title: LKeys.choose,
                      onTap: onChooseTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget btn({required String title, required Function() onTap}) {
    return Expanded(
      child: CommonSheetButton(
        title: title.tr,
        onTap: onTap,
      ),
    );
  }
}
