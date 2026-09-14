import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/core/services/firebase_storage_service.dart';

/// storage.rules solo acepta image/*, audio/* y application/pdf: toda subida
/// tiene que salir con uno de esos tipos, nunca con octet-stream.
void main() {
  test('deduce el tipo por extensión', () {
    expect(
      FirebaseStorageService.contentTypeFor('/tmp/a.PDF', fallback: 'x'),
      'application/pdf',
    );
    expect(
      FirebaseStorageService.contentTypeFor('/tmp/a.mp3', fallback: 'x'),
      'audio/mpeg',
    );
    expect(
      FirebaseStorageService.contentTypeFor('/tmp/foto.jpeg', fallback: 'x'),
      'image/jpeg',
    );
    expect(
      FirebaseStorageService.contentTypeFor('/tmp/foto.png', fallback: 'x'),
      'image/png',
    );
  });

  test('sin extensión conocida usa el tipo por defecto de cada subida', () {
    expect(
      FirebaseStorageService.contentTypeFor(
        '/data/cache/image_picker123',
        fallback: 'image/jpeg',
      ),
      'image/jpeg',
    );
  });
}
