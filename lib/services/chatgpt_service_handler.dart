import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatGPTServiceHandler {
  final String apiKey;
  final Function(String) onResponse;
  final Function(String) onError;

  ChatGPTServiceHandler({
    required this.apiKey,
    required this.onResponse,
    required this.onError,
  });

  Future<void> sendRequest(
      String prompt, List<Map<String, String>> history) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final messages = [
      ...history.map((entry) => {"role": "user", "content": entry["User"]}),
      {"role": "user", "content": prompt},
    ];

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"model": "gpt-3.5-turbo", "messages": messages}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data["choices"][0]["message"]["content"];
      onResponse(content);
    } else {
      onError("Error: ${response.statusCode}");
    }
  }
}
