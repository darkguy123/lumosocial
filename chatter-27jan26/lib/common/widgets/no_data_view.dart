import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chatter/common/extensions/font_extension.dart';
import 'package:chatter/localization/languages.dart';
import 'package:chatter/utilities/const.dart';

class NoDataView extends StatelessWidget {
  const NoDataView({
    super.key,
    this.title = LKeys.noDataFound,
    this.description,
    this.child,
    this.showShow = true,
  });

  final String title;
  final String? description;
  final Widget? child;
  final bool showShow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showShow)
          SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(minHeight: Get.height / 2),
              margin: EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title.tr,
                    style: MyTextStyle.gilroySemiBold(
                      color: cDarkText,
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  if (description != null)
                    Text(
                      description!.tr,
                      style: MyTextStyle.gilroyRegular(
                        size: 16,
                        color: cLightText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  Container(width: double.infinity)
                ],
              ),
            ),
          ),
        child ?? Container()
      ],
    );
  }
}
