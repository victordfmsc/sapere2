import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyBYtzIqviLASVavhCdL4MGz40I7CJGfJSU';
  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict?key=$apiKey',
  );

  final body = {
    "instances": [
      {
        "prompt":
            "Un libro antiguo y mágico brillante con polvo de estrellas, iluminación cinematográfica, 4k",
      },
    ],
    "parameters": {"sampleCount": 1, "aspectRatio": "1:1"},
  };

  try {
    print('Calling Gemini API to generate image...');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      print('Success! Response keys: ${jsonResponse.keys}');
      if (jsonResponse['predictions'] != null &&
          jsonResponse['predictions'].isNotEmpty) {
        final prediction = jsonResponse['predictions'][0];
        print('Prediction contains keys: ${prediction.keys}');
        if (prediction['bytesBase64Encoded'] != null) {
          final base64String = prediction['bytesBase64Encoded'];
          print(
            'Successfully got base64 image. Length: ${base64String.length}',
          );
        }
      }
    } else {
      print('Failed with status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
