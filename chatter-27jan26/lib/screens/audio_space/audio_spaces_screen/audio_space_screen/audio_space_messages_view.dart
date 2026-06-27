import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

import 'audio_space_controller.dart';

class AudioSpaceMessagesView extends StatelessWidget {
  final AudioSpaceController controller;

  AudioSpaceMessagesView(this.controller);

  @override
  Widget build(BuildContext context) {
    if ((controller.messages.length == 0)) {
      return Expanded(
        child: Container(
          alignment: Alignment.center,
          child: Text(
            LKeys.noMessages.tr,
            style: MyTextStyle.gilroySemiBold(color: cLightText),
          ),
        ),
      );
    } else {
      return Expanded(
        child: ListView.builder(
          reverse: true,
          controller: controller.messageScrollController,
          itemCount: controller.messages.length,
          padding: EdgeInsets.all(12),
          itemBuilder: (context, index) {
            var message = controller.messages.reversed.toList()[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: MyCachedProfileImage(
                      imageUrl: message.user?.image,
                      fullName: message.user?.fullName,
                      width: 40,
                      height: 40,
                      cornerRadius: 100,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: cAudioSpaceLightBG,
                        borderRadius: SmoothBorderRadius(cornerRadius: 12, cornerSmoothing: cornerSmoothing),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message.user?.fullName ?? '',
                                  style: MyTextStyle.gilroySemiBold(color: cAudioSpaceText),
                                ),
                              ),
                              Text(
                                message.getChatTime(),
                                style: MyTextStyle.gilroyRegular(color: cLightText.withValues(alpha: 0.7), size: 12),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            message.content ?? '',
                            style: MyTextStyle.gilroyMedium(color: cLightText.withValues(alpha: 0.7)),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      );
    }
  }
}
