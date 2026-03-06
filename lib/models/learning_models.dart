// lib/models/learning_models.dart

enum NoteType { insight, keyData, question, connection }

class LearningNote {
  final String id;
  final String userId;
  final String postId;
  final String postTitle;
  final String content;
  final NoteType type;
  final int timestampMs;
  final DateTime createdAt;
  final List<String> tags;

  LearningNote({
    required this.id,
    required this.userId,
    required this.postId,
    required this.postTitle,
    required this.content,
    required this.type,
    required this.timestampMs,
    required this.createdAt,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'postTitle': postTitle,
      'content': content,
      'type': type.index,
      'timestampMs': timestampMs,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  factory LearningNote.fromMap(Map<String, dynamic> map) {
    return LearningNote(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      postId: map['postId'] ?? '',
      postTitle: map['postTitle'] ?? '',
      content: map['content'] ?? '',
      type: NoteType.values[map['type'] ?? 0],
      timestampMs: map['timestampMs'] ?? 0,
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}

class LearningCard {
  final String id;
  final String userId;
  final String? noteId; // Optional if auto-generated from text content
  final String postId;
  final String question;
  final String answer;
  final int box; // Leitner box (1-4)
  final DateTime nextReview;
  final int correctCount;
  final int wrongCount;
  final DateTime createdAt;

  LearningCard({
    required this.id,
    required this.userId,
    this.noteId,
    required this.postId,
    required this.question,
    required this.answer,
    this.box = 1,
    required this.nextReview,
    this.correctCount = 0,
    this.wrongCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'noteId': noteId,
      'postId': postId,
      'question': question,
      'answer': answer,
      'box': box,
      'nextReview': nextReview.toIso8601String(),
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LearningCard.fromMap(Map<String, dynamic> map) {
    return LearningCard(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      noteId: map['noteId'],
      postId: map['postId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      box: map['box'] ?? 1,
      nextReview: DateTime.parse(
        map['nextReview'] ?? DateTime.now().toIso8601String(),
      ),
      correctCount: map['correctCount'] ?? 0,
      wrongCount: map['wrongCount'] ?? 0,
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class LearningProfile {
  final String userId;
  final int wisdomXp;
  final int wisdomLevel;
  final int dailyStreak;
  final DateTime lastActivity;
  final List<String> badges;

  LearningProfile({
    required this.userId,
    this.wisdomXp = 0,
    this.wisdomLevel = 1,
    this.dailyStreak = 0,
    required this.lastActivity,
    this.badges = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'wisdomXp': wisdomXp,
      'wisdomLevel': wisdomLevel,
      'dailyStreak': dailyStreak,
      'lastActivity': lastActivity.toIso8601String(),
      'badges': badges,
    };
  }

  factory LearningProfile.fromMap(Map<String, dynamic> map) {
    return LearningProfile(
      userId: map['userId'] ?? '',
      wisdomXp: map['wisdomXp'] ?? 0,
      wisdomLevel: map['wisdomLevel'] ?? 1,
      dailyStreak: map['dailyStreak'] ?? 0,
      lastActivity: DateTime.parse(
        map['lastActivity'] ?? DateTime.now().toIso8601String(),
      ),
      badges: List<String>.from(map['badges'] ?? []),
    );
  }
}
