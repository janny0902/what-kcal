import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

bool get adsSupported =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// 출시 앱 ID는 ca-app-pub-3648414759201370~3120558671.
/// 디버그 실행은 구글 샘플 광고, 출시 빌드는 아래 실제 단위를 쓴다.
class AdUnits {
  static const testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const releaseBanner = 'ca-app-pub-3648414759201370/8645357250';
  static const testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const releaseInterstitial = 'ca-app-pub-3648414759201370/4926348952';

  static String get banner => kDebugMode ? testBanner : releaseBanner;
  static String get interstitial => kDebugMode ? testInterstitial : releaseInterstitial;
}

Future<bool> showInterstitial() async {
  if (!adsSupported) return false;
  final completer = Completer<bool>();
  await InterstitialAd.load(
    adUnitId: AdUnits.interstitial,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            if (!completer.isCompleted) completer.complete(false);
          },
        );
        ad.show();
      },
      onAdFailedToLoad: (error) {
        if (!completer.isCompleted) completer.complete(false);
      },
    ),
  );
  return completer.future.timeout(const Duration(seconds: 30), onTimeout: () => false);
}

class AdmobBanner extends StatefulWidget {
  const AdmobBanner({super.key});

  @override
  State<AdmobBanner> createState() => _AdmobBannerState();
}

class _AdmobBannerState extends State<AdmobBanner> {
  BannerAd? _ad;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (!adsSupported) return;
    final ad = BannerAd(
      adUnitId: AdUnits.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _ready = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_ready || ad == null) return const SizedBox.shrink();
    return ColoredBox(
      color: Colors.white,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
