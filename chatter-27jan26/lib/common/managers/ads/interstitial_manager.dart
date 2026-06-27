import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';

class InterstitialManager {
  static var shared = InterstitialManager();

  InterstitialAd? interstitialAd;

  InterstitialManager() {
    if (SessionManager.shared.isAdMobOn()) {
      loadAd();
    }
  }

  void loadAd() {
    if (!SessionManager.shared.isAdMobOn()) return;

    InterstitialAd.load(
        adUnitId: SessionManager.shared.getInterstitialAdId(),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  loadAd();
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});

            Loggers.success('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            interstitialAd = ad;
            // _interstitialAd?.show();
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            Loggers.error('InterstitialAd failed to load: $error');
          },
        ));
  }

  void showAd() {
    Loggers.success("AD: ${interstitialAd}");
    if (SessionManager.shared.isAdMobOn()) {
      interstitialAd?.show();
    }
  }
}
