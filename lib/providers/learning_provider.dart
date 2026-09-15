import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/services/story_functions_service.dart';
import '../models/learning_models.dart';
import '../models/post.dart';

class LearningProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StoryFunctionsService _functions = StoryFunctionsService();
  final Set<String> _flashcardsInFlight = <String>{};

  List<LearningNote> _notes = [];
  List<LearningCard> _dueCards = [];
  LearningProfile? _profile;
  bool _isLoading = false;

  List<LearningNote> get notes => _notes;
  List<LearningCard> get dueCards => _dueCards;
  LearningProfile? get profile => _profile;
  bool get isLoading => _isLoading;

  String? get userId => _auth.currentUser?.uid;

  LearningProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadAll();
      } else {
        _profile = null;
        _notes = [];
        _dueCards = [];
        notifyListeners();
      }
    });
  }

  Future<void> loadAll() async {
    if (userId == null) return;
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([_loadProfile(), _loadNotes(), _loadDueCards()]);
    } catch (e) {
      print("Error loading Learning Space data: $e");
      // If it's a missing index error, the message will contain a link to create it.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    final doc =
        await _firestore.collection('learning_profiles').doc(userId).get();
    if (doc.exists) {
      _profile = LearningProfile.fromMap(doc.data()!);
    } else {
      _profile = LearningProfile(userId: userId!, lastActivity: DateTime.now());
      await _firestore
          .collection('learning_profiles')
          .doc(userId)
          .set(_profile!.toMap());
    }
  }

  Future<void> _loadNotes() async {
    final snapshot =
        await _firestore
            .collection('learning_notes')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
    _notes = snapshot.docs.map((d) => LearningNote.fromMap(d.data())).toList();
  }

  Future<void> _loadDueCards() async {
    final now = DateTime.now();
    final snapshot =
        await _firestore
            .collection('learning_cards')
            .where('userId', isEqualTo: userId)
            .where('nextReview', isLessThanOrEqualTo: now.toIso8601String())
            .get();
    _dueCards =
        snapshot.docs.map((d) => LearningCard.fromMap(d.data())).toList();
  }

  Future<void> addNote({
    required String postId,
    required String postTitle,
    required String content,
    required NoteType type,
    int timestampMs = 0,
  }) async {
    if (userId == null) return;

    final docRef = _firestore.collection('learning_notes').doc();
    final note = LearningNote(
      id: docRef.id,
      userId: userId!,
      postId: postId,
      postTitle: postTitle,
      content: content,
      type: type,
      timestampMs: timestampMs,
      createdAt: DateTime.now(),
    );

    await docRef.set(note.toMap());
    _notes.insert(0, note);

    // Add XP for capturing info
    await _addWisdomXp(5);
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    if (userId == null) return;
    try {
      await _firestore.collection('learning_notes').doc(noteId).delete();
      _notes.removeWhere((n) => n.id == noteId);
      notifyListeners();
    } catch (e) {
      print("Error deleting note: $e");
    }
  }

  Future<void> answerCard(LearningCard card, bool correct) async {
    if (userId == null) return;

    int newBox = correct ? card.box + 1 : 1;
    if (newBox > 4) newBox = 4;

    Duration nextInterval;
    switch (newBox) {
      case 1:
        nextInterval = const Duration(days: 1);
        break;
      case 2:
        nextInterval = const Duration(days: 3);
        break;
      case 3:
        nextInterval = const Duration(days: 7);
        break;
      case 4:
        nextInterval = const Duration(days: 30);
        break;
      default:
        nextInterval = const Duration(days: 1);
    }

    final updatedCard = LearningCard(
      id: card.id,
      userId: card.userId,
      postId: card.postId,
      noteId: card.noteId,
      question: card.question,
      answer: card.answer,
      box: newBox,
      nextReview: DateTime.now().add(nextInterval),
      correctCount: card.correctCount + (correct ? 1 : 0),
      wrongCount: card.wrongCount + (correct ? 0 : 1),
      createdAt: card.createdAt,
    );

    await _firestore
        .collection('learning_cards')
        .doc(card.id)
        .update(updatedCard.toMap());
    _dueCards.removeWhere((c) => c.id == card.id);

    if (correct) {
      await _addWisdomXp(10);
    }
    notifyListeners();
  }

  /// Pide al servidor (callable `generateFlashcards`) las tarjetas del
  /// documental; las escribe el propio servidor en `learning_cards`. Solo una
  /// petición a la vez por post. Un fallo solo se registra: el reproductor
  /// sigue igual.
  Future<void> generateCardsForPost(BukBukPost post) async {
    final String postId = post.postId ?? '';
    if (userId == null ||
        postId.isEmpty ||
        post.description == null ||
        post.description!.isEmpty) {
      return;
    }

    try {
      final bool created = await requestFlashcardsOnce(
        _flashcardsInFlight,
        postId,
        hasCards: () async {
          final existingSnapshot =
              await _firestore
                  .collection('learning_cards')
                  .where('userId', isEqualTo: userId)
                  .where('postId', isEqualTo: postId)
                  .limit(1)
                  .get();
          return existingSnapshot.docs.isNotEmpty;
        },
        generate: () => _functions.generateFlashcards(postId: postId),
      );
      if (created) {
        await _addWisdomXp(20); // XP for completing a lesson elaboration
        await _loadDueCards();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error generating flashcards: $e");
    }
  }

  Future<void> _addWisdomXp(int amount) async {
    if (_profile == null) return;

    int newXp = _profile!.wisdomXp + amount;
    int newLevel =
        1 + (newXp ~/ 100); // Simple level up logic: 100 XP per level

    final updatedProfile = LearningProfile(
      userId: _profile!.userId,
      wisdomXp: newXp,
      wisdomLevel: newLevel,
      dailyStreak: _profile!.dailyStreak, // Streak logic can be more complex
      lastActivity: DateTime.now(),
      badges: _profile!.badges,
    );

    await _firestore
        .collection('learning_profiles')
        .doc(userId)
        .set(updatedProfile.toMap());
    _profile = updatedProfile;
  }
}
