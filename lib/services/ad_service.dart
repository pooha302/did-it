import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();

  factory AdService() {
    return instance;
  }

  AdService._internal();

  // Ad Unit Groups - Determined once at runtime
  static final _resetUnits = _AdUnit(
    ios: 'ca-app-pub-2756512315350932/6343692587',
    android: 'ca-app-pub-2756512315350932/3379112733',
  );

  static final _editHistoryUnits = _AdUnit(
    ios: 'ca-app-pub-2756512315350932/8173331309',
    android: 'ca-app-pub-2756512315350932/2441766122',
  );

  String get rewardedAdUnitId => _resetUnits.value;
  String get editHistoryAdUnitId => _editHistoryUnits.value;

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;

  RewardedAd? _editHistoryAd;
  int _numEditHistoryLoadAttempts = 0;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
    loadEditHistoryAd();
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

  void loadEditHistoryAd() {
    RewardedAd.load(
      adUnitId: editHistoryAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _editHistoryAd = ad;
          _numEditHistoryLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _editHistoryAd = null;
          _numEditHistoryLoadAttempts++;
          if (_numEditHistoryLoadAttempts <= maxFailedLoadAttempts) {
            loadEditHistoryAd();
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

  void showEditHistoryAd({required Function onRewardEarned}) {
    if (_editHistoryAd == null) {
      loadEditHistoryAd();
      debugPrint('Edit History Ad not ready yet.');
      return;
    }

    _editHistoryAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadEditHistoryAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadEditHistoryAd();
      },
    );

    _editHistoryAd!.show(onUserEarnedReward: (ad, reward) {
      onRewardEarned();
    });
    _editHistoryAd = null;
  }
}

/// Helper class to manage platform and environment specific Ad Unit IDs
class _AdUnit {
  final String value;

  _AdUnit({required String ios, required String android})
      : value = kDebugMode
            ? (Platform.isAndroid ? _testAndroidId : _testIosId)
            : (Platform.isAndroid ? android : ios);

  static const String _testIosId = 'ca-app-pub-3940256099942544/1712485313';
  static const String _testAndroidId = 'ca-app-pub-3940256099942544/5224354917';
}
