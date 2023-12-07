import 'package:dio/dio.dart';
import 'secrets.dart' as Secrets;

class OpenAI {
  static const String apiKey = Secrets.openAiApiKey;
  final dio = Dio(BaseOptions(baseUrl: 'https://api.openai.com/v1', headers: {
    'Authorization': 'Bearer $apiKey',
    'OpenAI-Organization': Secrets.openAiOrgId
  }));

  Future<String> createTranscription(String path,
      {String? language, String? prompt}) async {
    // set up payload
    var body = {
      'file': await MultipartFile.fromFile(path),
      'model': 'whisper-1'
    };
    if (language != null) {
      body['language'] = language;
    }
    if (prompt != null) {
      body['prompt'] = prompt;
    }
    FormData formData = FormData.fromMap(body);

    // yeet
    Response response = await dio.post('/audio/transcriptions', data: formData);
    return response.data['text'];
  }

  Future<String> gpt4(String prompt) async {
    // use a fewshot prompt for translation
    var body = {
      'messages': [
        {
          'role': 'system',
          'content': 'You are a helpful interpreter between English and '
              'Japanese. When given a sentence in English, output its '
              'translation in Japanese, and vice versa.\n'
              'Translate idioms and figures of speech into the other '
              'language\'s equivalent. Use polite Japanese.\n'
              'The input is from a voice transcription and may contain minor '
              'typos.'
        },
        {'role': 'user', 'content': prompt},
      ],
      'model': 'gpt-4',
      'top_p': 0.9,
    };

    // yeet
    Response response = await dio.post('/chat/completions', data: body);
    return response.data['choices'][0]['message']['content'];
  }
}
