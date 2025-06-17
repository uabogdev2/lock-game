import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
// Level model is imported for potential future use, as mentioned in requirements.
// For now, it's not directly used in user operations.
import '../models/level_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference<UserModel> _usersRef;

  FirestoreService() {
    _usersRef = _db.collection('users').withConverter<UserModel>(
          fromFirestore: (snapshot, _) => UserModel.fromSnapshot(snapshot),
          toFirestore: (user, _) => user.toJson(),
        );
  }

  // Create or update a user document
  Future<void> createUserDocument(UserModel user) async {
    try {
      await _usersRef.doc(user.uid).set(user, SetOptions(merge: true));
      print('User document created/updated for UID: ${user.uid}');
    } catch (e) {
      print('Error creating/updating user document for UID: ${user.uid}: $e');
      // Optionally rethrow or handle more gracefully
    }
  }

  // Get a user document
  Future<UserModel?> getUserDocument(String uid) async {
    try {
      final docSnapshot = await _usersRef.doc(uid).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      } else {
        print('User document not found for UID: $uid');
        return null;
      }
    } catch (e) {
      print('Error getting user document for UID: $uid: $e');
      return null;
    }
  }

  // Update user points
  Future<void> updateUserPoints(String uid, int points) async {
    try {
      await _usersRef.doc(uid).update({'points': points});
      print('User points updated for UID: $uid');
    } catch (e) {
      print('Error updating user points for UID: $uid: $e');
    }
  }

  // Unlock a level for a user
  Future<void> unlockLevel(String uid, int levelId) async {
    try {
      await _usersRef.doc(uid).update({
        'unlockedLevels': FieldValue.arrayUnion([levelId])
      });
      print('Level $levelId unlocked for UID: $uid');
    } catch (e) {
      print('Error unlocking level $levelId for UID: $uid: $e');
    }
  }

  // Update 'no ads' purchase status
  Future<void> updateNoAdsPurchase(String uid, bool status) async {
    try {
      await _usersRef.doc(uid).update({'noAdsPurchased': status});
      print('NoAds purchase status updated for UID: $uid');
    } catch (e) {
      print('Error updating NoAds purchase status for UID: $uid: $e');
    }
  }
}
