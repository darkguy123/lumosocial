import 'package:flutter/material.dart';

const String appName = "Lumo Social";
const String baseURL = "https://social.equipmentmarket.ng/";
const String itemBaseURL = "https://social.equipmentmarket.ng/";
const String apiURL = "${baseURL}api/";
const String termsURL = "${baseURL}termsOfUse";
const String privacyURL = "${baseURL}privacyPolicy";
const String helpURL = "https://social.equipmentmarket.ng/help";
const String notificationTopic = "chatter"; // Do not change it

const String revenuecatAppleApiKey = '';
const String revenuecatAndroidApiKey = '';

const String agoraAppId = '0f431a7133e44d02bedc303cf2d05920';
const String agoraCustomerId = 'agora_customer_id';
const String agoraCustomerSecret = 'agora_customer_secret';

class Limits {
  static int username = 30;
  static int roomDescCount = 120;
  static int bioCount = 120;
  static int interestCount = 5;
  static int pagination = 20;
  static int storyDuration = 3;

  static int sightEngineCropSec = 5;

  static double imageSize = 1200;
  static int quality = 80;
}

const List<String> storyQuickReplyEmojis = ['😂', '😮', '😍', '😢', '👏', '🔥'];
const List<int> secondsForMakingReel = [15, 30];

extension O on String {
  String addBaseURL() {
    if (startsWith("http://") || startsWith("https://")) {
      return this;
    }
    return itemBaseURL + this;
  }
}

// Colors
const cPrimary = Color(0xFF40E378);
const cPulsing = Color(0xFFA1E5B3);
const cHashtagColor = Color(0xFF25CC5F);
const cWhite = Colors.white;
const cBlack = Color(0xFF0E0E0E);
const cBlackSheetBG = Color(0xFF1F1F1F);
const cMainText = Color(0xFF2d2d2d);
const cLightText = Color(0xFF979797);
const cLightIcon = Color(0xFFAEAEAE);
const cDarkText = Color(0xFF585858);
const cLightBg = Color(0xFFF1F1F1);
const cDarkBG = Color(0xFF212121);
const cBG = Color(0xFFF2F2F2);
const cGreen = Color(0xFF2CA757);
const cDarkGreen = Color(0xFF183321);
const cBlueTick = Color(0xFF1D9BF0);
const cRed = Color(0xFFFF3939);

const cAudioSpaceBG = Color(0xFF272727);
const cAudioSpaceDarkBG = Color(0xFF222222);
const cAudioSpaceLightBG = Color(0xFF3B3B3B);
const cAudioSpaceText = Color(0xFFD4D4D4);

const refreshIndicatorColor = cBlack;
const refreshIndicatorBgColor = cPrimary;

// Corner Radius-Smoothing
const cornerSmoothing = 1.0;
