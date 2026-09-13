import '../models/local_book.dart';
import 'text_tokenizer_service.dart';

class PlainTextDocumentParser {
  final TextTokenizerService tokenizer;

  PlainTextDocumentParser({TextTokenizerService? tokenizer})
      : tokenizer = tokenizer ?? TextTokenizerService();

  static final RegExp _blankLines = RegExp(r'\n\s*\n');
  static final RegExp _spaces = RegExp(r'[ \t ]+');

  Future<LocalBook> parseString({
    required String content,
    required String title,
    required String bookId,
    required String languageCode,
    String? coverPath,
  }) async {
    final paragraphs = splitParagraphs(content);
    final sentences = tokenizer.splitParagraphs(paragraphs);
    return LocalBook(
      id: bookId,
      title: title,
      languageCode: languageCode,
      coverPath: coverPath,
      paragraphs: paragraphs,
      sentences: sentences,
    );
  }

  /// Párrafos separados por líneas en blanco; si no hay ninguna, por `\n`.
  List<String> splitParagraphs(String content) {
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final chunks = _blankLines.hasMatch(normalized)
        ? normalized.split(_blankLines)
        : normalized.split('\n');
    return chunks
        .map((c) => c.replaceAll('\n', ' ').replaceAll(_spaces, ' ').trim())
        .where((c) => c.isNotEmpty)
        .toList();
  }
}
