import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // aliased to avoid conflict
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb, defaultTargetPlatform, TargetPlatform

import '../models/user_model.dart';

class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream for user authentication state
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map((fb_auth.User? firebaseUser) {
      if (firebaseUser == null) {
        return null;
      }
      // In a real app, you'd fetch user data from Firestore here
      return UserModel(uid: firebaseUser.uid, unlockedLevels: [1], points: 0, noAdsPurchased: false);
    });
  }

  // Get current user UID
  String? get currentUserUid => _auth.currentUser?.uid;


  // Sign in Anonymously
  Future<UserModel?> signInAnonymously() async {
    try {
      final fb_auth.UserCredential userCredential = await _auth.signInAnonymously();
      final fb_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // Here, you might want to create a new document in Firestore for this anonymous user
        // For now, just returning a basic UserModel
        return UserModel(uid: firebaseUser.uid, unlockedLevels: [1], points: 0, noAdsPurchased: false);
      }
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      print('Failed to sign in anonymously: ${e.message}');
      return null;
    } catch (e) {
      print('An unexpected error occurred during anonymous sign in: $e');
      return null;
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final fb_auth.AuthCredential credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final fb_auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      final fb_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // If it's a new user, create a document in Firestore. Otherwise, update existing.
        // For now, just returning a UserModel. This will be expanded with FirestoreService.
        return UserModel(
          uid: firebaseUser.uid,
          // Potentially fetch other details like email if needed, though not in UserModel yet
        );
      }
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      print('Failed to sign in with Google (FirebaseAuthException): ${e.message}');
      return null;
    } catch (e) {
      print('An unexpected error occurred during Google sign in: $e');
      return null;
    }
  }

  // Sign in with Apple (Skeleton)
  Future<UserModel?> signInWithApple() async {
    // IMPORTANT: sign_in_with_apple is not available on Android, Windows, Linux, or web (partially).
    // Ensure you handle this, perhaps by not showing the Apple Sign In button on those platforms.
    // Use foundation.defaultTargetPlatform for the check
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.macOS)) {
         print('Apple Sign In is not available on this platform. Platform: $defaultTargetPlatform');
         // Potentially throw an error or return a specific result
         return null;
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // webAuthenticationOptions: WebAuthenticationOptions(  // For web, if you configure it
        //   clientId: 'your.bundle.id.here', // from Apple Developer portal
        //   redirectUri: Uri.parse('https://your-app.firebaseapp.com/__/auth/handler'),
        // ),
      );

      final fb_auth.OAuthProvider oAuthProvider = fb_auth.OAuthProvider('apple.com');
      final fb_auth.AuthCredential credentialApple = oAuthProvider.credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode, //This might be what you need for Apple
      );

      final fb_auth.UserCredential userCredential = await _auth.signInWithCredential(credentialApple);
      final fb_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Handle user creation/update in Firestore
        return UserModel(uid: firebaseUser.uid);
      }
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      print('Failed to sign in with Apple (FirebaseAuthException): ${e.code} ${e.message}');
      // Specific codes: 'cancelled', 'failed', 'invalid_response', 'operation-not-allowed'
      return null;
    } on SignInWithAppleException catch (e) {
       print('Failed to sign in with Apple (SignInWithAppleException): ${e.code} ${e.message}');
       return null;
    } catch (e) {
      print('An unexpected error occurred during Apple sign in: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Check if the current user signed in with Google
      // _auth.currentUser.providerData could be checked, but _googleSignIn.signOut() is safe to call even if not.
      // However, it's good practice to only call it if necessary.
      // For simplicity here, we call it. It will do nothing if not signed in with Google.
      await _googleSignIn.signOut();
      await _auth.signOut();
    } on fb_auth.FirebaseAuthException catch (e) {
      print('Error signing out (FirebaseAuthException): ${e.message}');
    } catch (e) {
      print('An unexpected error occurred during sign out: $e');
    }
  }
}

// Using foundation.defaultTargetPlatform directly from 'package:flutter/foundation.dart'
// No custom enum or helper needed for this specific check as foundation.defaultTargetPlatform provides the necessary info.
