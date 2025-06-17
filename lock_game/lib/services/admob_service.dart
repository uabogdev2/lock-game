import 'dart:io' show Platform; // Used for platform-specific Ad Unit IDs
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // Ad Unit IDs - IMPORTANT: Replace with your actual Ad Unit IDs from AdMob console.
  // These should ideally be stored in environment variables and not hardcoded.
  // For testing, you can use Google's provided test Ad Unit IDs.
  // https://developers.google.com/admob/flutter/test-ads

  static String? _bannerAdUnitId;
  static String? _interstitialAdUnitId;
  static String? _rewardedAdUnitId;

  // Test Ad Unit IDs from Google
  static final String _testBannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';
  static final String _testInterstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';
  static final String _testRewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';


  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInitialized = false;
  static const int maxFailedLoadAttempts = 3;
  int _interstitialLoadAttempts = 0;
  int _rewardedLoadAttempts = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;
    final InitializationStatus status = await MobileAds.instance.initialize();
    _isInitialized = true;
    print('AdMob initialized: $status');
    // Set Ad Unit IDs (use test IDs if in debug mode or if actual IDs are not set)
    // In a real app, load these from environment variables (e.g., using flutter_dotenv)
    _bannerAdUnitId = kDebugMode ? _testBannerAdUnitId : null; // Replace null with env.bannerAdUnitId
    _interstitialAdUnitId = kDebugMode ? _testInterstitialAdUnitId : null; // Replace null with env.interstitialAdUnitId
    _rewardedAdUnitId = kDebugMode ? _testRewardedAdUnitId : null; // Replace null with env.rewardedAdUnitId

    // Pre-load ads after initialization if needed
    // loadBannerAd();
    // loadInterstitialAd();
    // loadRewardedAd();
  }

  void loadBannerAd() {
    if (_bannerAdUnitId == null) {
      print('Banner Ad Unit ID is not set. Skipping ad load.');
      return;
    }
    _bannerAd?.dispose(); // Dispose previous ad if any

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId!,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('BannerAd loaded.');
          // If you want to display the banner immediately after loading, you might need a way
          // to signal the UI, e.g., through a Provider or Stream.
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('BannerAd failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('BannerAd opened.'),
        onAdClosed: (Ad ad) => print('BannerAd closed.'),
        onAdImpression: (Ad ad) => print('BannerAd impression.'),
      ),
    )..load();
  }

  void loadInterstitialAd() {
    if (_interstitialAdUnitId == null) {
      print('Interstitial Ad Unit ID is not set. Skipping ad load.');
      return;
    }
    if (_interstitialLoadAttempts >= maxFailedLoadAttempts) {
        print('InterstitialAd: Max load attempts reached.');
        return;
    }

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('InterstitialAd loaded.');
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0; // Reset attempts on success
          _setInterstitialAdCallbacks();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
          _interstitialLoadAttempts++;
          _interstitialAd = null; // Ensure ad is null on failure
          // Retry loading (optional, with delay)
          // if (_interstitialLoadAttempts < maxFailedLoadAttempts) {
          //   Future.delayed(Duration(seconds: 30), () => loadInterstitialAd());
          // }
        },
      ),
    );
  }

  void _setInterstitialAdCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('InterstitialAd showed full screen content.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('InterstitialAd dismissed full screen content.');
        ad.dispose();
        _interstitialAd = null; // Clear the ad
        loadInterstitialAd(); // Pre-load the next one
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('InterstitialAd failed to show full screen content: $error');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // Pre-load the next one
      },
      onAdImpression: (InterstitialAd ad) => print('InterstitialAd impression.'),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd == null) {
      print('InterstitialAd not loaded yet. Trying to load...');
      loadInterstitialAd(); // Attempt to load if not available
      return;
    }
    _interstitialAd!.show();
  }


  void loadRewardedAd() {
    if (_rewardedAdUnitId == null) {
      print('Rewarded Ad Unit ID is not set. Skipping ad load.');
      return;
    }
     if (_rewardedLoadAttempts >= maxFailedLoadAttempts) {
        print('RewardedAd: Max load attempts reached.');
        return;
    }

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('RewardedAd loaded.');
          _rewardedAd = ad;
          _rewardedLoadAttempts = 0; // Reset attempts on success
          _setRewardedAdCallbacks();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAd failed to load: $error');
           _rewardedLoadAttempts++;
          _rewardedAd = null; // Ensure ad is null on failure
          // Retry loading (optional, with delay)
          // if (_rewardedLoadAttempts < maxFailedLoadAttempts) {
          //   Future.delayed(Duration(seconds: 30), () => loadRewardedAd());
          // }
        },
      ),
    );
  }

  void _setRewardedAdCallbacks() {
     _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('RewardedAd showed full screen content.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('RewardedAd dismissed full screen content.');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Pre-load the next one
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('RewardedAd failed to show full screen content: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Pre-load the next one
      },
      onAdImpression: (RewardedAd ad) => print('RewardedAd impression.'),
    );
  }

  void showRewardedAd(Function(RewardItem reward) onUserEarnedReward) {
    if (_rewardedAd == null) {
      print('RewardedAd not loaded yet. Trying to load...');
      loadRewardedAd(); // Attempt to load if not available
      return;
    }
    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print('User earned reward: ${reward.amount} ${reward.type}');
      onUserEarnedReward(reward);
    });
  }

  void disposeAds() {
    print('Disposing ads...');
    _bannerAd?.dispose();
    _bannerAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
