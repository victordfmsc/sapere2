import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/local_book.dart';
import '../models/reader_settings.dart';

/// Persistencia en JSON dentro de `<documents>/local_reader/`:
/// un fichero por libro, `settings.json` y `pronunciation.json`.
class LocalLibraryService {
  final Directory root;

  LocalLibraryService._(this.root);

  static Future<LocalLibraryService> create() async {
    final docs = await getApplicationDocumentsDirectory();
    return createAt(Directory('${docs.path}${Platform.pathSeparator}local_reader'));
  }

  static Future<LocalLibraryService> createAt(Directory dir) async {
    if (!await dir.exists()) await dir.create(recursive: true);
    final booksDir = Directory('${dir.path}${Platform.pathSeparator}books');
    if (!await booksDir.exists()) await booksDir.create(recursive: true);
    return LocalLibraryService._(dir);
  }

  Directory get _booksDir =>
      Directory('${root.path}${Platform.pathSeparator}books');
  File get _settingsFile =>
      File('${root.path}${Platform.pathSeparator}settings.json');
  File get _rulesFile =>
      File('${root.path}${Platform.pathSeparator}pronunciation.json');

  File _bookFile(String id) {
    final safe = id.replaceAll(RegExp(r'[^\w\-]'), '_');
    return File('${_booksDir.path}${Platform.pathSeparator}$safe.json');
  }

  Future<List<LocalBook>> getBooks() async {
    final books = <LocalBook>[];
    try {
      if (!await _booksDir.exists()) return books;
      await for (final entity in _booksDir.list()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        final book = await _readBook(entity);
        if (book != null) books.add(book);
      }
    } catch (e) {
      debugPrint('[LocalLibraryService] getBooks failed: $e');
    }
    books.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return books;
  }

  Future<LocalBook?> getBook(String id) async {
    final file = _bookFile(id);
    if (!await file.exists()) return null;
    return _readBook(file);
  }

  Future<LocalBook?> _readBook(File file) async {
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return LocalBook.fromJson(json);
    } catch (e) {
      debugPrint('[LocalLibraryService] read ${file.path} failed: $e');
      return null;
    }
  }

  Future<void> saveBook(LocalBook b) async {
    try {
      b.updatedAt = DateTime.now();
      await _writeAtomic(_bookFile(b.id), jsonEncode(b.toJson()));
    } catch (e) {
      debugPrint('[LocalLibraryService] saveBook failed: $e');
    }
  }

  Future<void> deleteBook(String id) async {
    try {
      final file = _bookFile(id);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[LocalLibraryService] deleteBook failed: $e');
    }
  }

  Future<Map<String, String>> getPronunciationRules() async {
    try {
      if (!await _rulesFile.exists()) return {};
      final json = jsonDecode(await _rulesFile.readAsString());
      if (json is! Map) return {};
      return json.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (e) {
      debugPrint('[LocalLibraryService] getPronunciationRules failed: $e');
      return {};
    }
  }

  Future<void> savePronunciationRules(Map<String, String> rules) async {
    try {
      await _writeAtomic(_rulesFile, jsonEncode(rules));
    } catch (e) {
      debugPrint('[LocalLibraryService] savePronunciationRules failed: $e');
    }
  }

  Future<ReaderSettings> getSettings() async {
    try {
      if (!await _settingsFile.exists()) return ReaderSettings.defaults();
      final json = jsonDecode(await _settingsFile.readAsString()) as Map<String, dynamic>;
      return ReaderSettings.fromJson(json);
    } catch (e) {
      debugPrint('[LocalLibraryService] getSettings failed: $e');
      return ReaderSettings.defaults();
    }
  }

  Future<void> saveSettings(ReaderSettings s) async {
    try {
      await _writeAtomic(_settingsFile, jsonEncode(s.toJson()));
    } catch (e) {
      debugPrint('[LocalLibraryService] saveSettings failed: $e');
    }
  }

  Future<void> _writeAtomic(File file, String content) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content, flush: true);
    if (await file.exists()) await file.delete();
    await tmp.rename(file.path);
  }
}
