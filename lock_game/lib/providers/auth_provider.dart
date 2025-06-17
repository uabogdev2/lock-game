import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Stream<UserModel?> get userStream => _authService.user;

  // To track loading state for UI
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // To track errors for UI
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthProvider({required AuthService authService, required FirestoreService firestoreService})
      : _authService = authService,
        _firestoreService = firestoreService {
    // Listen to the auth state changes to automatically update currentUser
    // and fetch/create user data from Firestore.
    _authService.user.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(UserModel? authUser) async {
    _setLoading(true);
    _clearError();

    if (authUser == null) {
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
      return;
    }

    try {
      // Try to get user document from Firestore
      UserModel? firestoreUser = await _firestoreService.getUserDocument(authUser.uid);

      if (firestoreUser != null) {
        _currentUser = firestoreUser;
        print('AuthProvider: User data loaded from Firestore for ${authUser.uid}');
      } else {
        // If user document doesn't exist, create it
        print('AuthProvider: No Firestore document for ${authUser.uid}, creating one...');
        // Use the UID from authUser, but potentially merge with any other info if available
        // For a new user, points are 0, level 1 unlocked by default (as per UserModel constructor)
        UserModel newUser = UserModel(
          uid: authUser.uid,
          // email: authUser.email, // If email is part of your UserModel and available from authUser
          // displayName: authUser.displayName, // If displayName is part of your UserModel
        );
        await _firestoreService.createUserDocument(newUser);
        _currentUser = newUser; // Set current user to the newly created one
        print('AuthProvider: New user document created in Firestore for ${authUser.uid}');
      }
    } catch (e) {
      print('AuthProvider: Error in _onAuthStateChanged: $e');
      _setError('Failed to load user data: $e');
      // Decide if _currentUser should be null or retain authUser details without Firestore data
      _currentUser = authUser; // Fallback to auth details if Firestore fails for some reason
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    // No need to notifyListeners if only clearing, usually done before an action
  }

  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _clearError();
    try {
      final user = await _authService.signInAnonymously();
      // _onAuthStateChanged will handle setting _currentUser and Firestore interaction
      return user != null;
    } catch (e) {
      _setError('Anonymous sign-in failed: $e');
      _setLoading(false); // Ensure loading is stopped on error
      return false;
    }
    // Loading state will be managed by _onAuthStateChanged
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      final user = await _authService.signInWithGoogle();
      return user != null;
    } catch (e) {
      _setError('Google sign-in failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    _setLoading(true);
    _clearError();
    try {
      final user = await _authService.signInWithApple();
      return user != null;
    } catch (e) {
      _setError('Apple sign-in failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signOut();
      _currentUser = null; // Clear user immediately on explicit sign out
    } catch (e) {
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false); // _onAuthStateChanged will also set loading and notify
    }
  }

  // User data specific methods (integrated from the idea of UserProvider)
  Future<void> addPoints(int pointsToAdd) async {
    if (_currentUser == null) {
      _setError("Cannot add points: No user logged in.");
      return;
    }
    _setLoading(true);
    try {
      final newPoints = (_currentUser!.points) + pointsToAdd;
      await _firestoreService.updateUserPoints(_currentUser!.uid, newPoints);
      _currentUser = _currentUser!.copyWith(points: newPoints); // Assuming UserModel has copyWith
      print('Points added. New total: $newPoints');
    } catch (e) {
      _setError("Failed to add points: $e");
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> spendPoints(int pointsToSpend) async {
    if (_currentUser == null) {
      _setError("Cannot spend points: No user logged in.");
      return;
    }
    if (_currentUser!.points < pointsToSpend) {
      _setError("Not enough points to spend.");
      return;
    }
    _setLoading(true);
    try {
      final newPoints = (_currentUser!.points) - pointsToSpend;
      await _firestoreService.updateUserPoints(_currentUser!.uid, newPoints);
      _currentUser = _currentUser!.copyWith(points: newPoints);
      print('Points spent. New total: $newPoints');
    } catch (e) {
      _setError("Failed to spend points: $e");
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> unlockNewLevel(int levelId) async {
    if (_currentUser == null) {
      _setError("Cannot unlock level: No user logged in.");
      return;
    }
    if (_currentUser!.unlockedLevels.contains(levelId)) {
      print("Level $levelId already unlocked.");
      return; // Already unlocked
    }
    _setLoading(true);
    try {
      await _firestoreService.unlockLevel(_currentUser!.uid, levelId);
      // Add to local list and create new list to ensure change is detected
      final newUnlockedLevels = List<int>.from(_currentUser!.unlockedLevels)..add(levelId);
      _currentUser = _currentUser!.copyWith(unlockedLevels: newUnlockedLevels);
      print('Level $levelId unlocked.');
    } catch (e) {
      _setError("Failed to unlock level $levelId: $e");
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // This is needed if we update UserModel fields directly and want to use copyWith pattern
  // Make sure UserModel has a copyWith method.
  // If not, manual updates are needed:
  // _currentUser = UserModel(uid: _currentUser!.uid, points: newPoints, unlockedLevels: _currentUser!.unlockedLevels, noAdsPurchased: _currentUser!.noAdsPurchased);
}

// The UserModelCopyWith extension has been moved to user_model.dart
