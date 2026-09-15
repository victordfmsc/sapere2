import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/core/constant/app_config.dart';
import 'package:sapere/core/services/story_functions_service.dart';
import 'package:sapere/models/learning_models.dart';
import 'package:sapere/models/sapere_category_type_model.dart';
import 'package:sapere/models/sapere_type_model.dart';

/// El resultado del SDK tiene constructor privado: se implementa a mano.
class _FakeResult<T> implements HttpsCallableResult<T> {
  _FakeResult(this.data);

  @override
  final T data;
}

class _FakeCallable implements HttpsCallable {
  _FakeCallable(this._respond);

  final Object? Function(Map<String, dynamic> payload) _respond;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async =>
      _FakeResult<T>(
        _respond(Map<String, dynamic>.from(parameters as Map)) as T,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// FirebaseFunctions sin Firebase: anota nombre, payload y timeout de cada
/// llamada y responde (o lanza) con [respond].
class _FakeFunctions implements FirebaseFunctions {
  _FakeFunctions(this.respond);

  final Object? Function(String name, Map<String, dynamic> payload) respond;
  final List<String> names = <String>[];
  final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];
  final List<Duration?> timeouts = <Duration?>[];

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    names.add(name);
    timeouts.add(options?.timeout);
    return _FakeCallable((payload) {
      payloads.add(payload);
      return respond(name, payload);
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

StoryFunctionsService _serviceThatThrows(Object error) =>
    StoryFunctionsService(
      functions: _FakeFunctions((name, payload) => throw error),
    );

Matcher _throwsStartStory(StartStoryError error, String code) => throwsA(
  isA<StartStoryException>()
      .having((e) => e.error, 'error', error)
      .having((e) => e.code, 'code', code),
);

void main() {
  group('AppConfig', () {
    test('las callables viven en europe-west1', () {
      expect(AppConfig.functionsRegion, 'europe-west1');
    });
  });

  group('CreditsBalance.fromMap', () {
    test('lee los tres campos del contrato', () {
      final balance = CreditsBalance.fromMap(const {
        'revenuecat': 7,
        'legacy': 3,
        'total': 10,
      });
      expect(balance.revenuecat, 7);
      expect(balance.legacy, 3);
      expect(balance.total, 10);
    });

    test('suma el total cuando el servidor no lo manda', () {
      final balance = CreditsBalance.fromMap(const {
        'revenuecat': 2,
        'legacy': 5,
      });
      expect(balance.total, 7);
    });

    test('tolera números como texto o nulos', () {
      final balance = CreditsBalance.fromMap(const {
        'revenuecat': '4',
        'legacy': null,
        'total': 4.0,
      });
      expect(balance.revenuecat, 4);
      expect(balance.legacy, 0);
      expect(balance.total, 4);
    });
  });

  group('StartStoryResult.fromMap', () {
    test('lee docId, status y créditos', () {
      final result = StartStoryResult.fromMap(const {
        'docId': 'abc123',
        'status': 'pending',
        'credits': {'revenuecat': 1, 'legacy': 0, 'total': 1},
      });
      expect(result.docId, 'abc123');
      expect(result.status, 'pending');
      expect(result.credits.total, 1);
    });

    test('usa valores seguros si falta el bloque de créditos', () {
      final result = StartStoryResult.fromMap(const {'docId': 'xyz'});
      expect(result.docId, 'xyz');
      expect(result.status, 'pending');
      expect(result.credits, CreditsBalance.empty);
    });
  });

  group('StartStoryException', () {
    test('cada motivo conserva el código original de Firebase', () {
      const e = StartStoryException(
        StartStoryError.insufficientCredits,
        code: 'resource-exhausted',
        message: 'insufficient_credits',
      );
      expect(e.error, StartStoryError.insufficientCredits);
      expect(e.code, 'resource-exhausted');
      expect(e.toString(), contains('insufficientCredits'));
    });
  });

  group('pendingRefundMessageKey', () {
    test('sin gasto o con el gasto ya reembolsado se puede reintentar', () {
      expect(pendingRefundMessageKey(const {}), isNull);
      expect(
        pendingRefundMessageKey(const {'spendId': 's1', 'refunded': true}),
        isNull,
      );
    });

    test('gasto sin devolver pide esperar al reembolso', () {
      expect(
        pendingRefundMessageKey(const {'spendId': 's1', 'refunded': false}),
        'refundInProgress',
      );
      expect(
        pendingRefundMessageKey(const {
          'spendId': 's1',
          'refundState': 'pending',
        }),
        'refundInProgress',
      );
    });

    test('reembolso en revision manual pide contactar con soporte', () {
      expect(
        pendingRefundMessageKey(const {
          'spendId': 's1',
          'refunded': false,
          'refundState': 'needs_review',
        }),
        'refundNeedsReview',
      );
    });
  });

  group('retryTitle', () {
    test('usa el titulo definitivo si el documento lo tiene', () {
      expect(
        retryTitle(const {
          'bukbukName': 'Constantinopla, 1453',
          'provisionalTitle': 'La caída de Constantinopla',
          'prompt': 'La caída de Constantinopla',
        }),
        'Constantinopla, 1453',
      );
    });

    test('con bukbukName vacio o en blanco usa el provisional', () {
      expect(
        retryTitle(const {
          'bukbukName': '',
          'provisionalTitle': 'La caída de Constantinopla',
        }),
        'La caída de Constantinopla',
      );
      expect(
        retryTitle(const {'bukbukName': '  ', 'provisionalTitle': 'Roma'}),
        'Roma',
      );
    });

    test('sin titulos usa el de la tarjeta y despues un extracto del prompt', () {
      expect(
        retryTitle(const {'bukbukName': '', 'prompt': 'Tema'}, fallback: 'Tarjeta'),
        'Tarjeta',
      );
      expect(
        retryTitle(const {
          'bukbukName': '',
          'prompt': 'La caída de Constantinopla',
        }, fallback: ' '),
        'La caída de Constantinopla',
      );
    });

    test('nunca devuelve un titulo vacio, que startStory descartaria', () {
      expect(retryTitle(const {'bukbukName': ''}), 'Audio Book');
      expect(retryTitle(const {'prompt': '  '}), 'Audio Book');
    });
  });

  group('titleFromPrompt', () {
    test('quita marcas, recorta a 40 caracteres y usa el respaldo', () {
      expect(titleFromPrompt('## **Roma**'), 'Roma');
      expect(titleFromPrompt('a' * 60), '${'a' * 37}...');
      expect(
        titleFromPrompt('  ', fallback: 'Audiolibro Sapere'),
        'Audiolibro Sapere',
      );
    });
  });

  group('whenStoryStarted', () {
    test('si startStory no devuelve documento no limpia ni sale', () async {
      var salidas = 0;

      final docId = await whenStoryStarted(() async => null, (_) {
        salidas++;
      });

      expect(docId, isNull);
      expect(salidas, 0);
    });

    test('con documento ejecuta la salida una vez con su docId', () async {
      final recibidos = <String>[];

      final docId = await whenStoryStarted(
        () async => 'doc1',
        recibidos.add,
      );

      expect(docId, 'doc1');
      expect(recibidos, ['doc1']);
    });
  });

  group('generateCommunityText', () {
    test('manda prompt, idioma e ids (sin systemPrompt) y limpia el texto', () async {
      final fake = _FakeFunctions(
        (name, payload) => {'text': '## La **Roma** antigua \n'},
      );

      final text = await StoryFunctionsService(
        functions: fake,
      ).generateCommunityText(
        prompt: 'Roma',
        languageCode: 'es_ES',
        bukbukCategoryId: 'cat1',
        bukbukId: 'tipo1',
      );

      expect(text, 'La Roma antigua');
      expect(fake.names, ['generateCommunityText']);
      expect(fake.payloads.single, {
        'prompt': 'Roma',
        'languageCode': 'es_ES',
        'bukbukCategoryId': 'cat1',
        'bukbukId': 'tipo1',
      });
    });

    test('omite los ids nulos o en blanco', () async {
      final fake = _FakeFunctions((name, payload) => {'text': 'Hola'});

      await StoryFunctionsService(functions: fake).generateCommunityText(
        prompt: 'Roma',
        languageCode: 'es_ES',
        bukbukCategoryId: ' ',
      );

      expect(fake.payloads.single, {'prompt': 'Roma', 'languageCode': 'es_ES'});
    });

    test('conserva letras como â (la ruta de Railway las cambiaba por —)', () async {
      final fake = _FakeFunctions(
        (name, payload) => {'text': 'Pão, âme et cân'},
      );

      final text = await StoryFunctionsService(
        functions: fake,
      ).generateCommunityText(prompt: 'x', languageCode: 'pt_PT');

      expect(text, 'Pão, âme et cân');
    });

    test('sin texto o con una respuesta que no es un mapa devuelve vacio', () async {
      for (final Object? response in <Object?>[
        <String, dynamic>{},
        <String, dynamic>{'text': null},
        null,
        'texto suelto',
      ]) {
        final text = await StoryFunctionsService(
          functions: _FakeFunctions((name, payload) => response),
        ).generateCommunityText(prompt: 'x', languageCode: 'es_ES');
        expect(text, '', reason: 'respuesta $response');
      }
    });

    test('las callables de IA esperan mas que los 60 s de startStory', () async {
      final fake = _FakeFunctions(
        (name, payload) => {'text': 'ok', 'docId': 'd1', 'created': 0},
      );
      final service = StoryFunctionsService(functions: fake);

      await service.generateCommunityText(prompt: 'x', languageCode: 'es_ES');
      await service.generateFlashcards(postId: 'p1');
      await service.startStory(prompt: 'x', languageCode: 'es_ES');

      expect(fake.names, [
        'generateCommunityText',
        'generateFlashcards',
        'startStory',
      ]);
      expect(fake.timeouts[0]!, greaterThan(const Duration(seconds: 60)));
      expect(fake.timeouts[1]!, greaterThan(const Duration(seconds: 60)));
      expect(fake.timeouts[2], const Duration(seconds: 60));
    });
  });

  group('generateFlashcards', () {
    test('manda solo el postId y lee created', () async {
      final fake = _FakeFunctions((name, payload) => {'created': 3});

      final result = await StoryFunctionsService(
        functions: fake,
      ).generateFlashcards(postId: 'post1');

      expect(fake.names, ['generateFlashcards']);
      expect(fake.payloads.single, {'postId': 'post1'});
      expect(result.created, 3);
      expect(result.skipped, isFalse);
    });
  });

  group('FlashcardsResult.fromMap', () {
    test('skipped admite booleano, motivo o numero', () {
      expect(
        FlashcardsResult.fromMap(const {'created': 0, 'skipped': true}).skipped,
        isTrue,
      );
      expect(
        FlashcardsResult.fromMap(const {
          'created': 0,
          'skipped': 'already_exists',
        }).skipped,
        isTrue,
      );
      expect(
        FlashcardsResult.fromMap(const {'created': 0, 'skipped': 3}).skipped,
        isTrue,
      );
      expect(
        FlashcardsResult.fromMap(const {
          'created': 2,
          'skipped': false,
        }).skipped,
        isFalse,
      );
    });

    test('created tolera texto, decimales o ausencia', () {
      expect(FlashcardsResult.fromMap(const {'created': '2'}).created, 2);
      expect(FlashcardsResult.fromMap(const {'created': 3.0}).created, 3);
      expect(FlashcardsResult.fromMap(const {}).created, 0);
    });
  });

  group('errores de las callables', () {
    const List<(String, String, StartStoryError)> casos = [
      ('resource-exhausted', 'rate_limited', StartStoryError.rateLimited),
      ('failed-precondition', 'ai_unavailable', StartStoryError.aiUnavailable),
      (
        'resource-exhausted',
        'insufficient_credits',
        StartStoryError.insufficientCredits,
      ),
      (
        'failed-precondition',
        'already_generating',
        StartStoryError.alreadyGenerating,
      ),
      ('failed-precondition', 'otra_cosa', StartStoryError.unknown),
      ('unavailable', 'space_down', StartStoryError.network),
      ('unauthenticated', 'unauthenticated', StartStoryError.unauthenticated),
      ('invalid-argument', 'prompt_required', StartStoryError.unknown),
      ('not-found', 'post_not_found', StartStoryError.unknown),
      ('internal', 'internal', StartStoryError.unknown),
      ('internal', 'rate_limited', StartStoryError.rateLimited),
      ('internal', 'ai_unavailable', StartStoryError.aiUnavailable),
    ];

    for (final (code, message, expected) in casos) {
      test('$code "$message" -> ${expected.name}', () async {
        final service = _serviceThatThrows(
          FirebaseFunctionsException(code: code, message: message),
        );

        await expectLater(
          service.generateCommunityText(prompt: 'x', languageCode: 'es_ES'),
          _throwsStartStory(expected, code),
        );
        await expectLater(
          service.generateFlashcards(postId: 'p1'),
          _throwsStartStory(expected, code),
        );
      });
    }

    test('timeout y sin red son network; cualquier otro fallo, unknown', () async {
      await expectLater(
        _serviceThatThrows(
          TimeoutException('lento'),
        ).generateFlashcards(postId: 'p1'),
        _throwsStartStory(StartStoryError.network, 'timeout'),
      );
      await expectLater(
        _serviceThatThrows(
          const SocketException('sin red'),
        ).generateCommunityText(prompt: 'x', languageCode: 'es_ES'),
        _throwsStartStory(StartStoryError.network, 'socket'),
      );
      await expectLater(
        _serviceThatThrows(
          StateError('raro'),
        ).generateCommunityText(prompt: 'x', languageCode: 'es_ES'),
        _throwsStartStory(StartStoryError.unknown, 'client'),
      );
    });
  });

  group('generationErrorMessageKey', () {
    test('ya en marcha, limite de uso e IA caida tienen aviso propio', () {
      expect(
        generationErrorMessageKey(StartStoryError.alreadyGenerating),
        'audioRequestAlready',
      );
      expect(
        generationErrorMessageKey(StartStoryError.rateLimited),
        'aiRateLimited',
      );
      expect(
        generationErrorMessageKey(StartStoryError.aiUnavailable),
        'aiUnavailable',
      );
    });

    test('el resto usa el aviso generico', () {
      for (final StartStoryError error in <StartStoryError>[
        StartStoryError.insufficientCredits,
        StartStoryError.unauthenticated,
        StartStoryError.network,
        StartStoryError.unknown,
      ]) {
        expect(generationErrorMessageKey(error), 'wentWrong');
      }
    });
  });

  group('requestCommunityText', () {
    final category = BukBukCategoryModel(
      names: const {'es_ES': 'Historia'},
      createdAt: DateTime(2026),
      docId: 'cat1',
    );
    final type = BukBukTypeModel(
      id: 'tipo1',
      order: 0,
      createdAt: Timestamp.fromDate(DateTime(2026)),
      names: const {},
      prompts: const {},
      descriptions: const {},
      photoUrl: '',
      isProOnly: false,
      userapp: false,
    );

    test('manda la categoria como bukbukCategoryId y el tipo como bukbukId', () async {
      final fake = _FakeFunctions((name, payload) => {'text': 'Roma'});
      final textos = <String>[];
      final errores = <Object>[];

      await requestCommunityText(
        StoryFunctionsService(functions: fake),
        prompt: 'Roma',
        languageCode: 'es_ES',
        category: category,
        type: type,
        onText: textos.add,
        onError: errores.add,
      );

      expect(fake.payloads.single, {
        'prompt': 'Roma',
        'languageCode': 'es_ES',
        'bukbukCategoryId': 'cat1',
        'bukbukId': 'tipo1',
      });
      expect(textos, ['Roma']);
      expect(errores, isEmpty);
    });

    const List<(String, String, StartStoryError)> fallos = [
      ('resource-exhausted', 'rate_limited', StartStoryError.rateLimited),
      ('failed-precondition', 'ai_unavailable', StartStoryError.aiUnavailable),
    ];

    for (final (code, message, expected) in fallos) {
      test('con $message avisa y relanza el error para la pagina', () async {
        final textos = <String>[];
        final errores = <Object>[];

        await expectLater(
          requestCommunityText(
            _serviceThatThrows(
              FirebaseFunctionsException(code: code, message: message),
            ),
            prompt: 'Roma',
            languageCode: 'es_ES',
            category: category,
            type: type,
            onText: textos.add,
            onError: errores.add,
          ),
          _throwsStartStory(expected, code),
        );
        expect(textos, isEmpty);
        expect(
          errores.single,
          isA<StartStoryException>().having((e) => e.error, 'error', expected),
        );
      });
    }
  });

  group('requestFlashcardsOnce', () {
    const FlashcardsResult tres = FlashcardsResult(created: 3, skipped: false);

    test('con una peticion del post en curso no llama otra vez', () async {
      final enCurso = <String>{};
      final pendiente = Completer<FlashcardsResult>();
      var llamadas = 0;

      final primera = requestFlashcardsOnce(
        enCurso,
        'p1',
        hasCards: () async => false,
        generate: () {
          llamadas++;
          return pendiente.future;
        },
      );
      await Future<void>.delayed(Duration.zero);
      final segunda = await requestFlashcardsOnce(
        enCurso,
        'p1',
        hasCards: () async => false,
        generate: () async {
          llamadas++;
          return tres;
        },
      );

      expect(segunda, isFalse);
      pendiente.complete(tres);
      expect(await primera, isTrue);
      expect(llamadas, 1);
      expect(enCurso, isEmpty);
    });

    test('otro post no espera al que esta en curso', () async {
      final enCurso = <String>{};
      final pendiente = Completer<FlashcardsResult>();
      final primera = requestFlashcardsOnce(
        enCurso,
        'p1',
        hasCards: () async => false,
        generate: () => pendiente.future,
      );

      final otra = await requestFlashcardsOnce(
        enCurso,
        'p2',
        hasCards: () async => false,
        generate: () async => tres,
      );

      expect(otra, isTrue);
      pendiente.complete(const FlashcardsResult(created: 0, skipped: true));
      expect(await primera, isFalse);
    });

    test('si el post ya tiene tarjetas no llama al servidor', () async {
      var llamadas = 0;

      final creadas = await requestFlashcardsOnce(
        <String>{},
        'p1',
        hasCards: () async => true,
        generate: () async {
          llamadas++;
          return tres;
        },
      );

      expect(creadas, isFalse);
      expect(llamadas, 0);
    });

    test('solo con tarjetas creadas toca sumar XP', () async {
      Future<bool> con(FlashcardsResult result) => requestFlashcardsOnce(
        <String>{},
        'p1',
        hasCards: () async => false,
        generate: () async => result,
      );

      expect(
        await con(const FlashcardsResult(created: 0, skipped: true)),
        isFalse,
      );
      expect(
        await con(const FlashcardsResult(created: 0, skipped: false)),
        isFalse,
      );
      expect(
        await con(const FlashcardsResult(created: 1, skipped: false)),
        isTrue,
      );
    });

    test('un fallo relanza y libera el post para la siguiente', () async {
      final enCurso = <String>{};

      await expectLater(
        requestFlashcardsOnce(
          enCurso,
          'p1',
          hasCards: () async => false,
          generate:
              () async =>
                  throw const StartStoryException(StartStoryError.rateLimited),
        ),
        throwsA(isA<StartStoryException>()),
      );

      expect(enCurso, isEmpty);
      expect(
        await requestFlashcardsOnce(
          enCurso,
          'p1',
          hasCards: () async => false,
          generate: () async => tres,
        ),
        isTrue,
      );
    });
  });

  group('shouldRequestFlashcards', () {
    const String url = 'https://storage/p1.mp3';

    test('al terminar el audio de este documental pide tarjetas', () {
      expect(
        shouldRequestFlashcards(
          wasCompleted: false,
          isCompleted: true,
          currentMediaId: url,
          postAudioUrl: url,
        ),
        isTrue,
      );
    });

    test('el completed repetido o el de otro audio no piden nada', () {
      expect(
        shouldRequestFlashcards(
          wasCompleted: true,
          isCompleted: true,
          currentMediaId: url,
          postAudioUrl: url,
        ),
        isFalse,
      );
      expect(
        shouldRequestFlashcards(
          wasCompleted: false,
          isCompleted: true,
          currentMediaId: 'https://storage/otro.mp3',
          postAudioUrl: url,
        ),
        isFalse,
      );
      expect(
        shouldRequestFlashcards(
          wasCompleted: false,
          isCompleted: false,
          currentMediaId: url,
          postAudioUrl: url,
        ),
        isFalse,
      );
    });

    test('sin audio del documental no pide nada', () {
      expect(
        shouldRequestFlashcards(
          wasCompleted: false,
          isCompleted: true,
          currentMediaId: null,
          postAudioUrl: null,
        ),
        isFalse,
      );
      expect(
        shouldRequestFlashcards(
          wasCompleted: false,
          isCompleted: true,
          currentMediaId: '',
          postAudioUrl: '',
        ),
        isFalse,
      );
    });
  });

  group('tarjetas que escribe generateFlashcards', () {
    // Documento de buildCard (functions/src/assist.js): los campos de
    // LearningCard.toMap, id del documento y fechas como texto ISO-8601.
    const Map<String, dynamic> servidor = {
      'id': 'doc1',
      'userId': 'u1',
      'noteId': null,
      'postId': 'p1',
      'question': '¿Quién fundó Roma según la leyenda?',
      'answer': 'Rómulo.',
      'box': 1,
      'nextReview': '2026-09-16T10:00:00.000Z',
      'correctCount': 0,
      'wrongCount': 0,
      'createdAt': '2026-09-15T10:00:00.000Z',
    };

    test('la app lee el documento del servidor', () {
      final card = LearningCard.fromMap(servidor);

      expect(card.id, 'doc1');
      expect(card.userId, 'u1');
      expect(card.postId, 'p1');
      expect(card.box, 1);
      expect(card.nextReview, DateTime.utc(2026, 9, 16, 10));
      expect(card.createdAt, DateTime.utc(2026, 9, 15, 10));
    });

    test('answerCard reescribe los mismos campos y nextReview como texto', () {
      expect(LearningCard.fromMap(servidor).toMap(), servidor);
    });
  });
}
