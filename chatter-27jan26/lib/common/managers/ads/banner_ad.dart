import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:untitled/common/managers/session_manager.dart';

class BannerAdView extends StatefulWidget {
  final bool top;
  final bool bottom;

  BannerAdView({super.key, this.top = false, this.bottom = false});

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadAd();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          bottom: widget.bottom,
          top: widget.top,
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      );
    } else {
      return Container(height: 0);
    }
  }

  void loadAd() {
    if (SessionManager.shared.isAdMobOn()) {
      _bannerAd = BannerAd(
        adUnitId: SessionManager.shared.getBannerAdId(),
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('$ad loaded.');
            setState(() {});
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('BannerAd failed to load: $err');
            ad.dispose();
            _bannerAd = null;
            setState(() {});
          },
        ),
      )..load();
    }
  }
}
