import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

import 'audio_space_controller.dart';
import 'audio_space_members_view.dart';

class AudioSpaceRequestsView extends StatelessWidget {
  final AudioSpaceController controller;

  AudioSpaceRequestsView(this.controller);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: (controller.audioSpace.requests.length == 0)
          ? Container(
              alignment: Alignment.center,
              child: Text(
                LKeys.noRequests.tr,
                style: MyTextStyle.gilroySemiBold(color: cLightText),
              ),
            )
          : ListView.builder(
              itemCount: controller.audioSpace.requests.length,
              padding: EdgeInsets.all(12),
              itemBuilder: (context, index) {
                return AudioSpaceUserCard(
                  user: controller.audioSpace.requests[index],
                  controller: controller,
                );
              },
            ),
    );
  }
}
