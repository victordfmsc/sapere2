import 'package:sapere/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import 'package:sapere/models/gamification_models.dart';
import '../../models/post.dart';
import '../constant/firestore_collection.dart';

class DataBaseHelper {
  final _fireStore = FirebaseFirestore.instance;
  CollectionReference<UserModel?> get userCollection => _fireStore
      .collection(firebaseUserCollection)
      .withConverter(
        fromFirestore: (snapshot, option) {
          return snapshot.exists ? UserModel.fromMap(snapshot.data()!) : null;
        },
        toFirestore: (user, opition) {
          return user!.toMap();
        },
      );
  //
  CollectionReference<BukBukPost?> get postCollection => _fireStore
      .collection(sapereCollection)
      .withConverter(
        fromFirestore: (snapshot, option) {
          return snapshot.exists ? BukBukPost.fromMap(snapshot.data()!) : null;
        },
        toFirestore: (post, option) {
          return post!.toMap();
        },
      );

  CollectionReference<GamificationProfile?> get gamificationCollection =>
      _fireStore
          .collection('gamification_profiles')
          .withConverter(
            fromFirestore: (snapshot, option) {
              return snapshot.exists
                  ? GamificationProfile.fromJson(snapshot.data()!)
                  : null;
            },
            toFirestore: (profile, option) {
              return profile!.toJson();
            },
          );

  Future<GamificationProfile?> getGamificationProfile(String uid) async {
    try {
      final doc = await gamificationCollection.doc(uid).get();
      if (doc.exists) {
        return doc.data();
      } else {
        // Return default profile if not exists
        return GamificationProfile(
          uid: uid,
          totalXp: 0,
          currentRank: 'Novato',
          currentStreak: 0,
          lastActiveDate: DateTime.now(),
          unlockedCategories: [],
          unlockedSubjects: [],
          acquiredBadges: [],
          completedEpisodes: [],
        );
      }
    } catch (e) {
      print('Error fetching gamification profile: $e');
      return null;
    }
  }

  Future<void> saveGamificationProfile(GamificationProfile profile) async {
    try {
      await gamificationCollection
          .doc(profile.uid)
          .set(profile, SetOptions(merge: true));
    } catch (e) {
      print('Error saving gamification profile: $e');
    }
  }

  Future<BukBukPost?> getGamificationEpisodePost(
    String subjectName,
    int episodeNumber, {
    String? languageCode,
  }) async {
    try {
      var query = postCollection
          .where('type', isEqualTo: 'gamification_episode')
          .where('gamificationSubject', isEqualTo: subjectName)
          .where('gamificationEpisode', isEqualTo: episodeNumber);

      if (languageCode != null) {
        query = query.where('languageCode', isEqualTo: languageCode);
      }

      final querySnapshot = await query.limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error fetching gamification episode post: $e');
      return null;
    }
  }

  Future<List<BukBukPost>> getGamificationPostsForSubject(
    String subjectName, {
    String? languageCode,
  }) async {
    try {
      var query = postCollection
          .where('type', isEqualTo: 'gamification_episode')
          .where('gamificationSubject', isEqualTo: subjectName);

      if (languageCode != null) {
        query = query.where('languageCode', isEqualTo: languageCode);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => doc.data()!).toList();
    } catch (e) {
      print('Error fetching gamification posts for subject: $e');
      return [];
    }
  }
}

class PostLimitChecker {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<bool> canUserNormalPost() async {
    try {
      final userDoc =
          await _firestore
              .collection(firebaseUserCollection)
              .doc(currentUserId)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final int credits = data?['credits'] ?? 0;
        print('User current credits is $credits');
        return credits > 0;
      } else {
        return false;
      }
    } catch (e) {
      print('❌ Error checking post limit: $e');
      return false;
    }
  }
}
