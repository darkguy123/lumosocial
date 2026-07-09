import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/extensions/image_extension.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/screens/extra_views/buttons.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateAppScreen extends StatelessWidget {
  const UpdateAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Padding(
            padding: EdgeInsetsGeometry.all(40),
            child: Image.asset(
              MyImages.update,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'Update the App',
                  style: MyTextStyle.gilroyBold(size: 24),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'This update is required to continue using the app. Please update now for security, stability, and performance improvements.',
                  textAlign: TextAlign.center,
                  style: MyTextStyle.gilroyRegular(size: 16, color: cLightText),
                ),
              ],
            ),
          ),
          Spacer(),
          CommonButton(
              text: LKeys.update,
              onTap: () {
                if (!kIsWeb && Platform.isAndroid) {
                  launchUrl(Uri.parse(SessionManager.shared.getSettings()?.playStoreDownloadLink ?? ''), mode: LaunchMode.externalApplication);
                } else {
                  launchUrl(Uri.parse(SessionManager.shared.getSettings()?.appStoreDownloadLink ?? ''), mode: LaunchMode.externalApplication);
                }
              })
        ],
      ),
    );
  }
}
