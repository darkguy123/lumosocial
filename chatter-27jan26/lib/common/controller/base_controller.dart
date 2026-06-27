import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';

class BaseController extends GetxController {
  static var share = BaseController();
  RxBool isLoading = false.obs;

  void startLoading() {
    loader();
    isLoading.value = true;
    update();
  }

  void stopLoading([List<Object>? ids, bool condition = true]) {
    if (isLoading.value && (Get.isDialogOpen ?? false)) {
      Get.back();
      isLoading.value = false;
      update();
    }
  }

  loader({double? value}) {
    Get.dialog(
        Center(
          child: CircularProgressIndicator(
            color: cPrimary,
          ),
        ),
        barrierColor: Colors.transparent);
    // showDialog(
    //   context: Get.context!,
    //   // barrierDismissible: true,
    //   barrierDismissible: false,
    //   builder: (context) {
    //     return const Center(
    //       child: CircularProgressIndicator(
    //         color: cPrimary,
    //       ),
    //     );
    //   },
    // );
  }

  void materialSnackBar(String title, {SnackBarType type = SnackBarType.info, String? message, Function()? onCompletion}) {
    var color = type == SnackBarType.success ? cGreen : (type == SnackBarType.error ? cRed : cBlack);
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(
          title.tr.toString(),
          style: MyTextStyle.gilroySemiBold(size: 15, color: cWhite),
        ),
        backgroundColor: color,
        duration: const Duration(milliseconds: 2500),
        behavior: SnackBarBehavior.fixed,
        dismissDirection: DismissDirection.endToStart,
        elevation: 1,
      ),
    );
  }

  void showSnackBar(String title, {SnackBarType type = SnackBarType.info, String? message, Function()? onCompletion}) {
    materialSnackBar(title, type: type, message: message, onCompletion: onCompletion);

    // if (Get.isSnackbarOpen) {
    //   return;
    // }
    // var color = type == SnackBarType.success ? cGreen : (type == SnackBarType.error ? cRed : cBlack);
    // IconData icon = type == SnackBarType.success ? Icons.check_circle_rounded : (type == SnackBarType.error ? Icons.cancel_rounded : Icons.info_rounded);
    // Get.rawSnackbar(
    //   messageText: Text(
    //     title.tr,
    //     style: MyTextStyle.gilroyBold(color: color),
    //   ),
    //   snackPosition: SnackPosition.BOTTOM,
    //   borderRadius: 10,
    //   margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    //   icon: Icon(
    //     icon,
    //     color: color,
    //     size: 24,
    //   ),
    //   backgroundColor: cWhite,
    //   forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
    // );
  }

  void showConfirmationSheet({required desc, required buttonTitle, required onTap}) {
    Get.bottomSheet(ConfirmationSheet(
      desc: desc,
      buttonTitle: buttonTitle,
      onTap: onTap,
    ));
  }

  void handleURL({required String url}) async {
    var urlString = url;
    if (!urlString.startsWith('http')) {
      urlString = 'https:\\\\' + urlString;
    }
    final Uri uri = Uri.parse(urlString);

    if (!await launchUrl(uri)) {
      print('Could not launch $uri');
    }
  }

  Future<String> getPath() async {
    Directory? directory = await (Platform.isAndroid ? getExternalStorageDirectory() : getApplicationDocumentsDirectory());
    return directory?.path ?? '';
  }
}

enum SnackBarType { info, error, success }
