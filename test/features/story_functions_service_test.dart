import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/core/constant/app_config.dart';
import 'package:sapere/core/services/story_functions_service.dart';

void main() {
  group('AppConfig', () {
    test('la generación por Firebase está activa y en europe-west1', () {
      expect(AppConfig.useFirebaseGeneration, isTrue);
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
}
