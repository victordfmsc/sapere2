import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/models/post.dart';

/// Estados de un documental generado SIN audio de servidor: la voz la pone el
/// lector bimodal del dispositivo, así que bukbukUrl viaja vacío para siempre.
void main() {
  Map<String, dynamic> doc({
    String? status,
    String bukbukUrl = '',
    List<String> description = const [],
    bool? readyToRead,
  }) {
    return <String, dynamic>{
      'postId': 'doc1',
      'bukbukUrl': bukbukUrl,
      'description': description,
      'status': status,
      'readyToRead': readyToRead,
    };
  }

  group('BukBukPost sin audio', () {
    test('completado sin audio no se queda en "procesando"', () {
      final post = BukBukPost.fromMap(
        doc(status: 'completed', description: const ['Capítulo uno.']),
      );

      expect(post.hasAudio, isFalse);
      expect(post.isCompleted, isTrue);
      expect(post.isFailed, isFalse);
      expect(post.isProcessing, isFalse);
    });

    test('pending sigue en "procesando"', () {
      final post = BukBukPost.fromMap(doc(status: 'pending'));

      expect(post.isCompleted, isFalse);
      expect(post.isFailed, isFalse);
      expect(post.isProcessing, isTrue);
    });

    test('generating_script con primer capítulo ya es legible', () {
      final post = BukBukPost.fromMap(
        doc(
          status: 'generating_script',
          description: const ['Capítulo uno.'],
          readyToRead: true,
        ),
      );

      expect(post.isProcessing, isTrue);
      expect(post.hasText, isTrue);
      expect(post.readyToRead, isTrue);
    });

    test('error sin audio es fallo, no proceso', () {
      final post = BukBukPost.fromMap(doc(status: 'error'));

      expect(post.isFailed, isTrue);
      expect(post.isProcessing, isFalse);
      expect(post.readyToRead, isFalse);
    });

    test('hasText ignora párrafos en blanco', () {
      final vacio = BukBukPost.fromMap(doc(description: const ['   ', '']));
      final lleno = BukBukPost.fromMap(doc(description: const ['', 'Hola.']));

      expect(vacio.hasText, isFalse);
      expect(vacio.readyToRead, isFalse);
      expect(lleno.hasText, isTrue);
      expect(lleno.readyToRead, isTrue);
    });

    test('readyToRead del documento manda aunque falte description', () {
      final post = BukBukPost.fromMap(doc(readyToRead: true));

      expect(post.hasText, isFalse);
      expect(post.readyToRead, isTrue);
    });

    test('readyToRead sobrevive al round-trip de toMap/fromMap', () {
      final original = BukBukPost.fromMap(
        doc(status: 'generating_script', readyToRead: true),
      );
      final copia = BukBukPost.fromMap(original.toMap());

      expect(copia.readyToReadFlag, isTrue);
      expect(copia.readyToRead, isTrue);
      expect(original.copyWith().readyToReadFlag, isTrue);
    });
  });

  group('BukBukPost heredado con audio', () {
    test('con bukbukUrl sigue completado aunque no haya status', () {
      final post = BukBukPost.fromMap(
        doc(bukbukUrl: 'https://cdn/audio.mp3', description: const ['Hola.']),
      );

      expect(post.hasAudio, isTrue);
      expect(post.isCompleted, isTrue);
      expect(post.isProcessing, isFalse);
    });
  });
}
