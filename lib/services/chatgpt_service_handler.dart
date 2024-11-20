import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../services/tts_service_handler.dart';

class ChatGPTServiceHandler {
  static const String TAG = "ChatGPTServiceHandler";
  static const String BASE_URL = "https://api.openai.com/v1/chat/completions";

  final String apiKey;
  final Function(String) onResponse;
  final Function(String) onError;
  final TTSServiceHandler ttsServiceHandler;

  ChatGPTServiceHandler({
    required this.apiKey,
    required this.onResponse,
    required this.onError,
    required this.ttsServiceHandler,
  });

  Future<void> generateTextAndConvertToSpeech(
    String prompt,
    List<Map<String, String>> conversationHistory,
  ) async {
    try {
      prompt = "$prompt keep answers short but not too short";

      conversationHistory.add({
        "role": "user",
        "content": prompt,
      });

      final response = await http.post(
        Uri.parse(BASE_URL),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': conversationHistory,
          "max_tokens": 100
        }),
      );

      print("=== Response from ChatGPT API ===");
      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final generatedText = jsonResponse['choices'][0]['message']['content'];

        conversationHistory.add({
          "role": "assistant",
          "content": generatedText,
        });

        onResponse(generatedText);

        // Implement TTS callback
        await ttsServiceHandler.convertTextToSpeech(
          generatedText,
          "alloy",
          _TTSCallback(),
        );
      } else {
        onError("Failed to generate text: ${response.statusCode}");
      }
    } catch (e) {
      onError("Error: $e");
    }
  }
}

// TTS Callback implementation
class _TTSCallback implements TextToSpeechCallback {
  @override
  void onStart(String text) {
    debugPrint('Started speaking: $text');
  }

  @override
  void onProgress(String word) {
    debugPrint('Speaking word: $word');
  }

  @override
  void onComplete() {
    debugPrint('Finished speaking');
  }
}
