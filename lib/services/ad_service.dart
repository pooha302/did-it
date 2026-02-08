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
  
  // Edit History Ad IDs
  final String _iosEditHistoryUnitId = 'ca-app-pub-2756512315350932/8173331309';
  final String _androidEditHistoryUnitId = 'ca-app-pub-2756512315350932/2441766122';

  String get rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _androidTestUnitId : _iosTestUnitId;
    }
    return Platform.isAndroid ? _androidRealUnitId : _iosRealUnitId;
  }

  String get editHistoryAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _androidTestUnitId : _iosTestUnitId;
    }
    return Platform.isAndroid ? _androidEditHistoryUnitId : _iosEditHistoryUnitId;
  }

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
      // If ad is not ready, maybe just let them edit? 
      // Or show a message? For now, we'll try to load and return logic is up to caller logic if needed, 
      // but usually we can't show immediately if not loaded. 
      // Ideally we should tell the user to try again.
      // For this implementation, if it fails to show (null), we might just allow it or fail silently. 
      // Let's assume onRewardEarned should only be called if ad is shown.
      // But if ad fails to load, user is stuck. 
      // Often better fallback is to allow it if ad fails in production, but let's stick to strict logic for now unless requested.
      // Wait, if _editHistoryAd is null, we can't show it. 
      // Should we trigger onRewardEarned anyway for better UX? 
      // I'll stick to NOT calling it, but I'll add a print.
      debugPrint("Edit History Ad not ready yet.");
      // Just in case, let's try to load it.
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
