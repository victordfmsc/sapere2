import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/services/local_storage_service.dart';
import '../models/history_item.dart';
import '../models/post.dart';

class HistoryProvider extends ChangeNotifier {
  static const String _storageKey = 'user_history';
  List<HistoryItem> _history = [];

  List<HistoryItem> get history => _history;
  List<HistoryItem> get audioHistory =>
      _history.where((i) => i.type == 'audio').toList();
  List<HistoryItem> get textHistory =>
      _history.where((i) => i.type == 'text').toList();

  HistoryProvider() {
    loadHistory();
  }

  Future<void> loadHistory() async {
    final data = await LocalStorage().getData(key: _storageKey);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        _history = decoded.map((item) => HistoryItem.fromMap(item)).toList();
        _history.sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
        notifyListeners();
      } catch (e) {
        print('Error decoding history: $e');
      }
    }
  }

  Future<void> saveAudioProgress(
    BukBukPost post,
    Duration position,
    Duration duration,
  ) async {
    final item = HistoryItem(
      id: post.postId ?? '',
      title: post.sapereName ?? '',
      coverUrl: post.newCover.toString(),
      type: 'audio',
      positionMs: position.inMilliseconds,
      totalDurationMs: duration.inMilliseconds,
      lastAccessed: DateTime.now(),
    );
    await _updateOrAddItem(item);
  }

  Future<void> saveTextProgress(BukBukPost post, double offset) async {
    final item = HistoryItem(
      id: post.postId ?? '',
      title: post.sapereName ?? '',
      coverUrl: post.newCover.toString(),
      type: 'text',
      scrollOffset: offset,
      lastAccessed: DateTime.now(),
    );
    await _updateOrAddItem(item);
  }

  Future<void> _updateOrAddItem(HistoryItem newItem) async {
    // Remove existing entry for same ID and Type
    _history.removeWhere((i) => i.id == newItem.id && i.type == newItem.type);

    // Add new item at the beginning
    _history.insert(0, newItem);

    // Limit to 20 items per type or 50 total
    if (_history.length > 50) {
      _history = _history.sublist(0, 50);
    }

    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_history.map((i) => i.toMap()).toList());
    await LocalStorage().setData(key: _storageKey, value: encoded);
  }

  HistoryItem? getProgress(String id, String type) {
    try {
      return _history.firstWhere((i) => i.id == id && i.type == type);
    } catch (_) {
      return null;
    }
  }
}
