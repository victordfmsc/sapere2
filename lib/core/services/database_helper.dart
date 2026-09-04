import 'package:sapere/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

      final querySnapshot = await query.limit(5).get();
      for (final doc in querySnapshot.docs) {
        final post = doc.data();
        if (post != null && (post.isCompleted || post.isMine)) return post;
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
      return querySnapshot.docs
          .map((doc) => doc.data()!)
          .where((post) => post.isCompleted || post.isMine)
          .toList();
    } catch (e) {
      print('Error fetching gamification posts for subject: $e');
      return [];
    }
  }
}
