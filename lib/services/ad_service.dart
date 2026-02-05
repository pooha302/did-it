import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();

  factory AdService() {
    return instance;
  }

  AdService._internal();

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;

  // Test IDs (Google provided)
  final String _iosTestUnitId = 'ca-app-pub-3940256099942544/1712485313';
  final String _androidTestUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // Production IDs (User provided)
  final String _iosRealUnitId = 'ca-app-pub-2756512315350932/6343692587';
  final String _androidRealUnitId = 'ca-app-pub-2756512315350932/3379112733';

  String get rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _androidTestUnitId : _iosTestUnitId;
    }
    return Platform.isAndroid ? _androidRealUnitId : _iosRealUnitId;
  }

  Future<void> init() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _numRewardedLoadAttempts++;
          if (_numRewardedLoadAttempts <= maxFailedLoadAttempts) {
            loadRewardedAd();
          }
        },
      ),
    );
  }

  void showRewardedAd({required Function onRewardEarned}) {
    if (_rewardedAd == null) {
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      onRewardEarned();
    });
    _rewardedAd = null;
  }
}
