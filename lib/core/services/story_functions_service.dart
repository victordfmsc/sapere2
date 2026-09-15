import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:sapere/core/constant/app_config.dart';
import 'package:sapere/models/sapere_category_type_model.dart';
import 'package:sapere/models/sapere_type_model.dart';

/// Motivos por los que falla una callable (`startStory`,
/// `generateCommunityText`, `generateFlashcards`). La interfaz decide con esto
/// qué aviso mostrar, sin mirar códigos de Firebase.
enum StartStoryError {
  insufficientCredits,
  alreadyGenerating,
  rateLimited,
  aiUnavailable,
  unauthenticated,
  network,
  unknown,
}

/// Error tipado de la capa de funciones. El servicio nunca deja escapar otra
/// excepción: todo fallo llega envuelto aquí.
class StartStoryException implements Exception {
  const StartStoryException(this.error, {this.code, this.message});

  final StartStoryError error;

  /// Código original de Firebase (`resource-exhausted`, `internal`...), para
  /// registro. Nunca se enseña al usuario.
  final String? code;

  /// Mensaje original saneado por el servidor (`insufficient_credits`...).
  final String? message;

  @override
  String toString() =>
      'StartStoryException(${error.name}, code: $code, message: $message)';
}

/// Clave del aviso que bloquea Reintentar mientras el gasto anterior siga sin
/// devolver (`generation` del documento), o null si se puede reintentar. Con
/// refundState 'needs_review' el barrido ya no lo devuelve: esperar no sirve.
String? pendingRefundMessageKey(Map<String, dynamic> generation) {
  final String spendId = (generation['spendId'] ?? '').toString();
  if (spendId.isEmpty || generation['refunded'] == true) return null;
  return generation['refundState'] == 'needs_review'
      ? 'refundNeedsReview'
      : 'refundInProgress';
}

/// Titulo provisional legible a partir del prompt (el definitivo lo escribe
/// el servidor).
String titleFromPrompt(String prompt, {String fallback = 'Audio Book'}) {
  final String clean = prompt.replaceAll(RegExp(r'[#*]'), '').trim();
  if (clean.isEmpty) return fallback;
  if (clean.length > 40) return "${clean.substring(0, 37)}...";
  return clean;
}

/// Titulo que viaja al reintentar el documento fallido [data]: el definitivo,
/// el provisional o [fallback], el primero que no este en blanco, y si no un
/// extracto del prompt. startStory descarta un titulo vacio.
String retryTitle(Map<String, dynamic> data, {String? fallback}) {
  for (final Object? candidate in <Object?>[
    data['bukbukName'],
    data['provisionalTitle'],
    fallback,
  ]) {
    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
  }
  final Object? prompt = data['prompt'];
  return titleFromPrompt(prompt is String ? prompt : '');
}

/// Arranca una creacion con [start] y solo si devuelve docId ejecuta
/// [onStarted] (limpiar el formulario, salir de la pagina). Con null el aviso
/// ya se mostro y quien llama debe quedarse como estaba.
Future<String?> whenStoryStarted(
  Future<String?> Function() start,
  FutureOr<void> Function(String docId) onStarted,
) async {
  final String? docId = await start();
  if (docId != null) await onStarted(docId);
  return docId;
}

/// Clave del aviso para [error]: generacion ya en marcha, limite de uso o IA
/// no disponible; el resto, el generico. Sin creditos se avisa con su dialogo.
String generationErrorMessageKey(StartStoryError error) {
  switch (error) {
    case StartStoryError.alreadyGenerating:
      return 'audioRequestAlready';
    case StartStoryError.rateLimited:
      return 'aiRateLimited';
    case StartStoryError.aiUnavailable:
      return 'aiUnavailable';
    case StartStoryError.insufficientCredits:
    case StartStoryError.unauthenticated:
    case StartStoryError.network:
    case StartStoryError.unknown:
      return 'wentWrong';
  }
}

/// Pide a [service] el texto de comunidad para la [category] y el [type]
/// elegidos y lo entrega a [onText]. Si falla llama a [onError] y relanza el
/// error para que la página elija el aviso.
Future<void> requestCommunityText(
  StoryFunctionsService service, {
  required String prompt,
  required String languageCode,
  required BukBukCategoryModel category,
  required BukBukTypeModel type,
  required void Function(String text) onText,
  required void Function(Object error) onError,
}) async {
  try {
    onText(
      await service.generateCommunityText(
        prompt: prompt,
        languageCode: languageCode,
        bukbukCategoryId: category.docId,
        bukbukId: type.id,
      ),
    );
  } catch (e) {
    onError(e);
    rethrow;
  }
}

/// Pide las flashcards de [postId] con [generate], salvo que ya haya otra
/// petición en curso para ese post ([inFlight]) o [hasCards] diga que ya tiene
/// tarjetas. True solo si el servidor creó alguna: entonces toca sumar XP y
/// recargar las pendientes.
Future<bool> requestFlashcardsOnce(
  Set<String> inFlight,
  String postId, {
  required Future<bool> Function() hasCards,
  required Future<FlashcardsResult> Function() generate,
}) async {
  if (!inFlight.add(postId)) return false;
  try {
    if (await hasCards()) return false;
    final FlashcardsResult result = await generate();
    return result.created > 0;
  } finally {
    inFlight.remove(postId);
  }
}

/// El reproductor pide flashcards solo cuando el audio que suena es el de este
/// documental ([currentMediaId] == [postAudioUrl]) y acaba de pasar a
/// completado. playbackState repite su último estado al suscribirse, que puede
/// ser el 'completed' de otro audio, y lo reemite con cada evento del
/// reproductor.
bool shouldRequestFlashcards({
  required bool wasCompleted,
  required bool isCompleted,
  required String? currentMediaId,
  required String? postAudioUrl,
}) =>
    isCompleted &&
    !wasCompleted &&
    postAudioUrl != null &&
    postAudioUrl.isNotEmpty &&
    currentMediaId == postAudioUrl;

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? 0;
}

/// Saldo de créditos tal y como lo devuelve el backend.
@immutable
class CreditsBalance {
  const CreditsBalance({
    required this.revenuecat,
    required this.legacy,
    required this.total,
  });

  factory CreditsBalance.fromMap(Map<String, dynamic> map) {
    final int revenuecat = _asInt(map['revenuecat']);
    final int legacy = _asInt(map['legacy']);
    final int total =
        map['total'] == null ? revenuecat + legacy : _asInt(map['total']);
    return CreditsBalance(
      revenuecat: revenuecat,
      legacy: legacy,
      total: total,
    );
  }

  static const CreditsBalance empty = CreditsBalance(
    revenuecat: 0,
    legacy: 0,
    total: 0,
  );

  final int revenuecat;
  final int legacy;
  final int total;

  @override
  String toString() =>
      'CreditsBalance(revenuecat: $revenuecat, legacy: $legacy, total: $total)';
}

/// Respuesta de la callable `startStory`.
@immutable
class StartStoryResult {
  const StartStoryResult({
    required this.docId,
    required this.status,
    required this.credits,
  });

  factory StartStoryResult.fromMap(Map<String, dynamic> map) {
    final dynamic rawCredits = map['credits'];
    return StartStoryResult(
      docId: (map['docId'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      credits:
          rawCredits is Map
              ? CreditsBalance.fromMap(Map<String, dynamic>.from(rawCredits))
              : CreditsBalance.empty,
    );
  }

  final String docId;
  final String status;
  final CreditsBalance credits;

  @override
  String toString() =>
      'StartStoryResult(docId: $docId, status: $status, credits: $credits)';
}

/// Respuesta de la callable `generateFlashcards`. Las tarjetas ya las escribio
/// el servidor en `learning_cards`.
@immutable
class FlashcardsResult {
  const FlashcardsResult({required this.created, required this.skipped});

  factory FlashcardsResult.fromMap(Map<String, dynamic> map) {
    final dynamic skipped = map['skipped'];
    return FlashcardsResult(
      created: _asInt(map['created']),
      skipped:
          skipped == true ||
          (skipped is String && skipped.isNotEmpty) ||
          (skipped is num && skipped > 0),
    );
  }

  final int created;

  /// El servidor no genero tarjetas (por ejemplo, porque ya existian).
  final bool skipped;

  @override
  String toString() => 'FlashcardsResult(created: $created, skipped: $skipped)';
}

/// Cliente de las Cloud Functions de generación (región `europe-west1`).
///
/// El servidor cobra el crédito, crea el documento de Firestore y encola la
/// tarea: la app ya no descuenta créditos ni escribe el documento.
class StoryFunctionsService {
  StoryFunctionsService({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  final FirebaseFunctions _functions;

  static const Duration _callTimeout = Duration(seconds: 60);

  /// Las callables de IA esperan al Space (hasta 420 s por seccion de guion):
  /// con los 60 s de startStory el cliente cortaria respuestas validas.
  static const Duration _aiCallTimeout = Duration(minutes: 10);

  /// Arranca la generación de un audiodocumental.
  ///
  /// Devuelve el `docId` creado por el servidor. Lanza [StartStoryException]
  /// (y solo eso) si no se pudo arrancar.
  Future<StartStoryResult> startStory({
    required String prompt,
    required String languageCode,
    String? systemPrompt,
    String? language,
    String? genre,
    String type = 'sapere',
    String? coverUrl,
    String? bukbukId,
    String? bukbukCategoryId,
    Map<String, dynamic>? bukbukTypeNames,
    Map<String, dynamic>? bukbukCategoryNames,
    String? gamificationSubject,
    int? gamificationEpisode,
    int? chapters,
    String? title,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'prompt': prompt,
      'languageCode': languageCode,
      'type': type,
    };
    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is Map && value.isEmpty) return;
      payload[key] = value;
    }

    put('systemPrompt', systemPrompt);
    put('language', language);
    put('genre', genre);
    put('coverUrl', coverUrl);
    put('bukbukId', bukbukId);
    put('bukbukCategoryId', bukbukCategoryId);
    put('bukbukTypeNames', bukbukTypeNames);
    put('bukbukCategoryNames', bukbukCategoryNames);
    put('gamificationSubject', gamificationSubject);
    put('gamificationEpisode', gamificationEpisode);
    put('chapters', chapters);
    put('title', title);

    final Map<String, dynamic> data = await _call('startStory', payload);
    return StartStoryResult.fromMap(data);
  }

  /// Saldo de créditos del usuario autenticado.
  Future<CreditsBalance> creditsBalance() async {
    final Map<String, dynamic> data = await _call(
      'creditsBalance',
      const <String, dynamic>{},
    );
    return CreditsBalance.fromMap(data);
  }

  /// Texto de comunidad para [prompt]. El marco lo resuelve el servidor con
  /// [bukbukCategoryId] y [bukbukId]. Lanza [StartStoryException] si falla.
  Future<String> generateCommunityText({
    required String prompt,
    required String languageCode,
    String? bukbukCategoryId,
    String? bukbukId,
  }) async {
    final Map<String, dynamic> data = await _call(
      'generateCommunityText',
      <String, dynamic>{
        'prompt': prompt,
        'languageCode': languageCode,
        if (bukbukCategoryId != null && bukbukCategoryId.trim().isNotEmpty)
          'bukbukCategoryId': bukbukCategoryId,
        if (bukbukId != null && bukbukId.trim().isNotEmpty)
          'bukbukId': bukbukId,
      },
      timeout: _aiCallTimeout,
    );
    final dynamic text = data['text'];
    return (text is String ? text : '').replaceAll(RegExp(r'[#*]'), '').trim();
  }

  /// Flashcards del documental [postId]: las escribe el servidor en
  /// `learning_cards` con la forma de `LearningCard.toMap` (`box` 1,
  /// `correctCount` y `wrongCount` 0) y `nextReview` como texto ISO-8601: las
  /// pendientes se filtran comparando ese texto y `answerCard` lo reescribe
  /// igual. Lanza [StartStoryException] si falla.
  Future<FlashcardsResult> generateFlashcards({required String postId}) async {
    final Map<String, dynamic> data = await _call(
      'generateFlashcards',
      <String, dynamic>{'postId': postId},
      timeout: _aiCallTimeout,
    );
    return FlashcardsResult.fromMap(data);
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload, {
    Duration timeout = _callTimeout,
  }) async {
    try {
      final HttpsCallableResult<dynamic> result = await _functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: timeout),
          )
          .call<dynamic>(payload);
      final dynamic raw = result.data;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      final StartStoryException mapped = _mapFunctionsException(e);
      debugPrint('❌ $name falló: $mapped');
      throw mapped;
    } on TimeoutException catch (e) {
      debugPrint('❌ $name agotó el tiempo de espera: $e');
      throw const StartStoryException(
        StartStoryError.network,
        code: 'timeout',
      );
    } on SocketException catch (e) {
      debugPrint('❌ $name sin red: ${e.message}');
      throw const StartStoryException(
        StartStoryError.network,
        code: 'socket',
      );
    } catch (e) {
      debugPrint('❌ $name error inesperado: $e');
      throw StartStoryException(
        StartStoryError.unknown,
        code: 'client',
        message: e.toString(),
      );
    }
  }

  static StartStoryException _mapFunctionsException(
    FirebaseFunctionsException e,
  ) {
    final String code = e.code.toLowerCase();
    final String message = (e.message ?? '').toLowerCase();

    StartStoryError error;
    switch (code) {
      case 'unauthenticated':
      case 'permission-denied':
        error = StartStoryError.unauthenticated;
        break;
      case 'resource-exhausted':
        error =
            message.contains('rate_limited')
                ? StartStoryError.rateLimited
                : StartStoryError.insufficientCredits;
        break;
      case 'failed-precondition':
        if (message.contains('already_generating')) {
          error = StartStoryError.alreadyGenerating;
        } else if (message.contains('ai_unavailable')) {
          error = StartStoryError.aiUnavailable;
        } else {
          error = StartStoryError.unknown;
        }
        break;
      case 'unavailable':
      case 'deadline-exceeded':
      case 'aborted':
        error = StartStoryError.network;
        break;
      default:
        error = StartStoryError.unknown;
    }

    // Red de seguridad: si el código no fue el esperado pero el mensaje sí lo
    // es, mandamos el mensaje.
    if (error == StartStoryError.unknown) {
      if (message.contains('insufficient_credits')) {
        error = StartStoryError.insufficientCredits;
      } else if (message.contains('already_generating')) {
        error = StartStoryError.alreadyGenerating;
      } else if (message.contains('rate_limited')) {
        error = StartStoryError.rateLimited;
      } else if (message.contains('ai_unavailable')) {
        error = StartStoryError.aiUnavailable;
      }
    }

    return StartStoryException(error, code: e.code, message: e.message);
  }
}
