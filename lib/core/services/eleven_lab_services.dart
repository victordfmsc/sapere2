import 'dart:convert';
import 'dart:io';
import 'package:sapere/core/constant/const.dart';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../constant/strings.dart';

class ElevenLabsService {
  final String apiKey = 'sk_ca072229dd3b2e9d7809e3d84805988266b6360d44f38d67';
  Future<File> generateAudioFromText(
    String text, {
    String format = 'mp3',
    String? voiceId,
  }) async {
    final savedLocale = await LocalStorage().getData(
      key: AppLocalKeys.localeKey,
    );
    final effectiveVoiceId =
        voiceId ?? getVoiceIdFromLocale(savedLocale ?? 'en_US');

    final url = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$effectiveVoiceId',
    );

    final headers = {'Content-Type': 'application/json', 'xi-api-key': apiKey};

    final body = jsonEncode({
      'text': text,
      'model_id': 'eleven_flash_v2_5',
      'voice_settings': {'stability': 0.5, 'similarity_boost': 0.5},
      'output_format': 'mp3_44100_128',
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final fileName = 'audio_output.$format';
      final fullPath = '${dir.path}/$fileName';

      final file = File(fullPath);
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } else {
      print('❌ Failed to generate audio: ${response.body}');
      throw Exception('Audio generation failed');
    }
  }
}
