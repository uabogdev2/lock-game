import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final int points;
  final List<int> unlockedLevels;
  final bool noAdsPurchased;

  UserModel({
    required this.uid,
    this.points = 0,
    this.unlockedLevels = const [1], // By default, level 1 is unlocked
    this.noAdsPurchased = false,
  });

  // Factory constructor to create a UserModel from a Firestore snapshot
  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("User data not found in snapshot!");
    }
    return UserModel(
      uid: snapshot.id,
      points: data['points'] as int? ?? 0,
      unlockedLevels: List<int>.from(data['unlockedLevels'] as List<dynamic>? ?? [1]),
      noAdsPurchased: data['noAdsPurchased'] as bool? ?? false,
    );
  }

  // Method to convert UserModel to a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid, // Though typically uid is the document ID, including it here for completeness
      'points': points,
      'unlockedLevels': unlockedLevels,
      'noAdsPurchased': noAdsPurchased,
    };
  }

  // Method to create a copy of UserModel instance with updated fields
  UserModel copyWith({
    String? uid,
    int? points,
    List<int>? unlockedLevels,
    bool? noAdsPurchased,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      points: points ?? this.points,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      noAdsPurchased: noAdsPurchased ?? this.noAdsPurchased,
    );
  }
}
