import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sapere/providers/sapere_provider.dart';
import 'package:sapere/views/dashboard/stream/add_sapere/add_sapere_page.dart';

/// BukBukProvider sin Firebase: solo guarda el modo comunidad.
class _FakeBukBukProvider implements BukBukProvider {
  @override
  bool isCommuinty = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // Get.to mira el navegador (necesita el binding) y, sin GetMaterialApp, solo
  // no falla en testMode: aqui no navega.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => Get.testMode = true);

  test('tras comprar, el primer documental no sale en modo comunidad', () {
    final provider = _FakeBukBukProvider();

    openFirstDocumentary(provider);

    expect(provider.isCommuinty, isFalse);
  });
}
