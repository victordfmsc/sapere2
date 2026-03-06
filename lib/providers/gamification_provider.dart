import 'package:flutter/foundation.dart';
import 'package:sapere/models/gamification_models.dart';
import 'package:sapere/core/services/gamification_data_source.dart';
import 'package:sapere/core/services/database_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class GamificationProvider with ChangeNotifier {
  GamificationProfile? _profile;
  List<GamifiedSubject> _allSubjects = [];
  Map<String, List<GamifiedSubject>> _categorizedSubjects = {};
  bool _isLoading = true;
  String? _error;

  GamificationProfile? get profile => _profile;
  List<GamifiedSubject> get allSubjects => _allSubjects;
  Map<String, List<GamifiedSubject>> get categorizedSubjects =>
      _categorizedSubjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GamificationProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await loadStaticSubjects();
      await _loadProfileFromFirebase();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfileFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final db = DataBaseHelper();
      GamificationProfile? fetchedProfile = await db.getGamificationProfile(
        user.uid,
      );
      if (fetchedProfile != null) {
        _profile = fetchedProfile;
      }
    } else {
      _error = 'User not authenticated';
    }
  }

  Future<void> reloadSubjects() async {
    _isLoading = true;
    notifyListeners();
    try {
      await loadStaticSubjects();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStaticSubjects() async {
    _allSubjects = await GamificationDataSource.loadSubjectsFromCSV();
    _categorizedSubjects = GamificationDataSource.groupByCategory(_allSubjects);
  }

  void completeEpisode(String episodeId, int xpAmount) {
    if (_profile != null && !_profile!.completedEpisodes.contains(episodeId)) {
      final updatedEpisodes = List<String>.from(_profile!.completedEpisodes)
        ..add(episodeId);

      _profile = GamificationProfile(
        uid: _profile!.uid,
        totalXp: _profile!.totalXp + xpAmount,
        currentRank: _calculateRank(_profile!.totalXp + xpAmount),
        currentStreak: _profile!.currentStreak,
        lastActiveDate: _profile!.lastActiveDate,
        unlockedCategories: _profile!.unlockedCategories,
        unlockedSubjects: _profile!.unlockedSubjects,
        acquiredBadges: _profile!.acquiredBadges,
        completedEpisodes: updatedEpisodes,
      );

      notifyListeners();

      final db = DataBaseHelper();
      db.saveGamificationProfile(_profile!);
    }
  }

  void addXp(int amount) {
    if (_profile != null) {
      _profile = GamificationProfile(
        uid: _profile!.uid,
        totalXp: _profile!.totalXp + amount,
        currentRank: _calculateRank(_profile!.totalXp + amount),
        currentStreak: _profile!.currentStreak,
        lastActiveDate: _profile!.lastActiveDate,
        unlockedCategories: _profile!.unlockedCategories,
        unlockedSubjects: _profile!.unlockedSubjects,
        acquiredBadges: _profile!.acquiredBadges,
        completedEpisodes: _profile!.completedEpisodes,
      );
      notifyListeners();

      // Sync to Firebase
      final db = DataBaseHelper();
      db.saveGamificationProfile(_profile!);
    }
  }

  String _calculateRank(int xp) {
    if (xp >= 50000) return 'rankSage'.tr;
    if (xp >= 15000) return 'rankMaster'.tr;
    if (xp >= 5000) return 'rankScholar'.tr;
    if (xp >= 1000) return 'rankStudent'.tr;
    return 'rankNovice'.tr;
  }
}
