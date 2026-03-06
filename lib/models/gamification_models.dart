import 'package:cloud_firestore/cloud_firestore.dart';

class GamifiedSubject {
  final String category;
  final String name;
  final String icon;
  final List<GamifiedEpisode> episodes;

  GamifiedSubject({
    required this.category,
    required this.name,
    required this.icon,
    required this.episodes,
  });

  factory GamifiedSubject.fromJson(Map<String, dynamic> json) {
    var list = json['episodes'] as List? ?? [];
    List<GamifiedEpisode> episodesList =
        list.map((i) => GamifiedEpisode.fromJson(i)).toList();
    return GamifiedSubject(
      category: json['category'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      episodes: episodesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'name': name,
      'icon': icon,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }
}

class GamifiedEpisode {
  final int episodeNumber;
  final String level;
  final String title;
  final String description;
  final int xpBase;
  final String? badgeOnCompletion;

  GamifiedEpisode({
    required this.episodeNumber,
    required this.level,
    required this.title,
    required this.description,
    required this.xpBase,
    this.badgeOnCompletion,
  });

  factory GamifiedEpisode.fromJson(Map<String, dynamic> json) {
    return GamifiedEpisode(
      episodeNumber: json['episodeNumber'] ?? 0,
      level: json['level'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      xpBase: json['xpBase'] ?? 0,
      badgeOnCompletion: json['badgeOnCompletion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'episodeNumber': episodeNumber,
      'level': level,
      'title': title,
      'description': description,
      'xpBase': xpBase,
      'badgeOnCompletion': badgeOnCompletion,
    };
  }
}

class GamificationProfile {
  final String uid;
  final int totalXp;
  final String currentRank;
  final int currentStreak;
  final DateTime? lastActiveDate;
  final List<String> unlockedCategories;
  final List<String> unlockedSubjects;
  final List<String> acquiredBadges;
  final List<String> completedEpisodes;

  GamificationProfile({
    required this.uid,
    required this.totalXp,
    required this.currentRank,
    required this.currentStreak,
    this.lastActiveDate,
    required this.unlockedCategories,
    required this.unlockedSubjects,
    required this.acquiredBadges,
    required this.completedEpisodes,
  });

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      uid: json['uid'] ?? '',
      totalXp: json['totalXp'] ?? 0,
      currentRank: json['currentRank'] ?? 'Novato',
      currentStreak: json['currentStreak'] ?? 0,
      lastActiveDate:
          json['lastActiveDate'] is Timestamp
              ? (json['lastActiveDate'] as Timestamp).toDate()
              : null,
      unlockedCategories: List<String>.from(json['unlockedCategories'] ?? []),
      unlockedSubjects: List<String>.from(json['unlockedSubjects'] ?? []),
      acquiredBadges: List<String>.from(json['acquiredBadges'] ?? []),
      completedEpisodes: List<String>.from(json['completedEpisodes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'totalXp': totalXp,
      'currentRank': currentRank,
      'currentStreak': currentStreak,
      'lastActiveDate':
          lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'unlockedCategories': unlockedCategories,
      'unlockedSubjects': unlockedSubjects,
      'acquiredBadges': acquiredBadges,
      'completedEpisodes': completedEpisodes,
    };
  }
}
