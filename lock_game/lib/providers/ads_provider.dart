import 'package:flutter/material.dart';
import '../services/iap_service.dart';
import '../services/admob_service.dart';

class AdsProvider extends ChangeNotifier {
  final IAPService _iapService;
  final AdMobService _adMobService;

  bool _showAds = true; // Default to showing ads
  bool get showAds => _showAds;

  bool _isBannerAdLoaded = false;
  bool get isBannerAdLoaded => _isBannerAdLoaded; // UI can use this to allocate space

  AdsProvider({required IAPService iapService, required AdMobService adMobService})
      : _iapService = iapService,
        _adMobService = adMobService {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize AdMob
    await _adMobService.initialize();

    // Listen to IAPService for changes in 'noAdsPurchased' status
    _iapService.addListener(_updateAdStatus);
    // Set initial ad status
    _updateAdStatus();

    // If ads are to be shown, load them
    if (_showAds) {
      loadBannerAd(); // Example: auto-load banner
      // Pre-load other ads as needed
      // _adMobService.loadInterstitialAd();
      // _adMobService.loadRewardedAd();
    }
  }

  void _updateAdStatus() {
    final newShowAdsStatus = !_iapService.noAdsPurchased;
    if (_showAds != newShowAdsStatus) {
      _showAds = newShowAdsStatus;
      print('AdsProvider: Show ads status updated to $_showAds');
      if (!_showAds) {
        // If ads are turned off, dispose any existing ads
        _adMobService.disposeAds();
        _isBannerAdLoaded = false;
      } else {
        // Ads are now to be shown, (re)load them
        loadBannerAd();
        // Potentially load other ad types too
      }
      notifyListeners();
    }
  }

  // --- Banner Ad Methods ---
  void loadBannerAd() {
    if (!_showAds || _adMobService.bannerAdUnitId == null) {
        _isBannerAdLoaded = false;
        // notifyListeners(); // Only notify if state actually changes from loaded to not
        return;
    }
    _adMobService.bannerAd?.dispose(); // Dispose previous one
    _adMobService.bannerAd = BannerAd(
      adUnitId: _adMobService.bannerAdUnitId!, // Use the one from AdMobService (test or real)
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('AdsProvider: BannerAd loaded.');
          _isBannerAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('AdsProvider: BannerAd failed to load: $error');
          ad.dispose();
          _isBannerAdLoaded = false;
          notifyListeners();
        },
        onAdOpened: (Ad ad) => print('AdsProvider: BannerAd opened.'),
        onAdClosed: (Ad ad) => print('AdsProvider: BannerAd closed.'),
      ),
    )..load();
  }

  BannerAd? get currentBannerAd => _showAds ? _adMobService.bannerAd : null;

  // --- Interstitial Ad Methods ---
  void loadInterstitialAd() {
    if (!_showAds) return;
    _adMobService.loadInterstitialAd(); // Delegates to AdMobService
  }

  void showInterstitialAd() {
    if (!_showAds) {
      print("AdsProvider: Ads are disabled, not showing interstitial.");
      return;
    }
    _adMobService.showInterstitialAd(); // Delegates to AdMobService
  }

  // --- Rewarded Ad Methods ---
  void loadRewardedAd() {
    if (!_showAds) return;
    _adMobService.loadRewardedAd(); // Delegates to AdMobService
  }

  void showRewardedAd({required VoidCallback onAdShown, required VoidCallback onAdDismissed, required Function(RewardItem reward) onUserEarnedReward, required VoidCallback onAdFailedToShow}) {
    if (!_showAds) {
      print("AdsProvider: Ads are disabled, not showing rewarded ad.");
      onAdFailedToShow(); // Indicate failure if ads are off
      return;
    }
    // Enhance AdMobService's showRewardedAd or handle callbacks here
    // For simplicity, directly using AdMobService's show, but might need more complex callback handling
    _adMobService.showRewardedAd((RewardItem reward) {
        print("AdsProvider: User earned reward: ${reward.amount} ${reward.type}");
        onUserEarnedReward(reward);
        // Potentially, also call _authProvider.addPoints or similar based on reward
    });
    // Note: AdMobService's showRewardedAd doesn't directly expose onAdShown, onAdDismissed, onAdFailedToShow
    // This would require modifying AdMobService or using its FullScreenContentCallback more directly here.
    // For this skeleton, we'll assume the basic showRewardedAd is sufficient and callbacks passed to it are primary.
    // The passed `onAdShown` etc. are more for the UI layer to react.
    // The `AdMobService` itself logs these events from its FullScreenContentCallback.
  }


  @override
  void dispose() {
    print('Disposing AdsProvider');
    _iapService.removeListener(_updateAdStatus);
    // AdMobService's ads are disposed by its own disposeAds method,
    // which could be called here or when _showAds becomes false.
    // _adMobService.disposeAds(); // Ensure ads are disposed if provider is disposed.
    super.dispose();
  }
}
