import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:sapere/core/constant/app_config.dart';

/// Motivos por los que `startStory` puede no arrancar. La interfaz decide con
/// esto qué diálogo mostrar, sin mirar códigos de Firebase.
enum StartStoryError {
  insufficientCredits,
  alreadyGenerating,
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

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    try {
      final HttpsCallableResult<dynamic> result = await _functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: _callTimeout),
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
        error = StartStoryError.insufficientCredits;
        break;
      case 'failed-precondition':
        error =
            message.contains('already_generating')
                ? StartStoryError.alreadyGenerating
                : StartStoryError.unknown;
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
      }
    }

    return StartStoryException(error, code: e.code, message: e.message);
  }
}
