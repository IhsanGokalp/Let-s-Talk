// lib/services/tts_service_handler.dart

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class TTSServiceHandler {
  static const String TAG = "TTSServiceHandler";
  static const String BASE_URL = "https://api.openai.com/v1/audio/speech";

  final String apiKey;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Timer> _pendingTimers = [];

  TextToSpeechCallback? _callback;
  bool _isPlaying = false;

  TTSServiceHandler({required this.apiKey}) {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _callback?.onComplete();
      debugPrint('$TAG on complete tts');
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  void setCallback(TextToSpeechCallback callback) {
    _callback = callback;
  }

  Future<void> convertTextToSpeech(
    String text,
    String voice,
    TextToSpeechCallback callback,
  ) async {
    try {
      _callback = callback;
      final String escapedText =
          text.replaceAll('\n', '\\n').replaceAll('"', '\\"');

      final response = await http.post(
        Uri.parse(BASE_URL),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'tts-1',
          'input': escapedText,
          'voice': voice,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('$TAG TTS Response: Received audio data');

        // Create URL from audio data for web
        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Notify start
        callback.onStart(text);

        // Play audio
        await _audioPlayer.play(UrlSource(url));
        _isPlaying = true;

        // Calculate word timing
        final words = text.split(' ');
        final wordDelay = 500; // Approximate 500ms per word

        // Schedule word progress callbacks
        for (var i = 0; i < words.length; i++) {
          final timer = Timer(
            Duration(milliseconds: wordDelay * i),
            () => callback.onProgress(words[i]),
          );
          _pendingTimers.add(timer);
        }

        // Clean up URL after playback
        _audioPlayer.onPlayerComplete.listen((_) {
          html.Url.revokeObjectUrl(url);
        });
      } else {
        debugPrint(
            '$TAG Failed to get TTS response. Response code: ${response.statusCode}');
        debugPrint('$TAG Response error body: ${response.body}');
        throw Exception('Failed to get TTS response');
      }
    } catch (e) {
      debugPrint('$TAG Error getting TTS response: $e');
      await _audioPlayer.stop();
      _isPlaying = false;
      rethrow;
    }
  }

  Future<void> endConversation() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    }
    _isPlaying = false;

    // Clear all pending timers
    for (var timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();

    debugPrint('$TAG endConversation');
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    endConversation();
    _audioPlayer.dispose();
  }
}

// Callback interface
abstract class TextToSpeechCallback {
  void onStart(String text);
  void onProgress(String word);
  void onComplete();
}

// Example usage:
class MyConversationScreen extends StatefulWidget {
  @override
  _MyConversationScreenState createState() => _MyConversationScreenState();
}

class _MyConversationScreenState extends State<MyConversationScreen>
    implements TextToSpeechCallback {
  late TTSServiceHandler _ttsHandler;
  String _currentWord = '';

  @override
  void initState() {
    super.initState();
    _ttsHandler = TTSServiceHandler(apiKey: 'your-api-key');
    _ttsHandler.setCallback(this);
  }

  Future<void> _speakText(String text) async {
    try {
      await _ttsHandler.convertTextToSpeech(
        text,
        'alloy',
        this,
      );
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void onStart(String text) {
    setState(() {
      // Handle speech start
    });
  }

  @override
  void onProgress(String word) {
    setState(() {
      _currentWord = word;
    });
  }

  @override
  void onComplete() {
    setState(() {
      _currentWord = '';
      // Handle speech completion
    });
  }

  @override
  void dispose() {
    _ttsHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Current word: $_currentWord'),
          ElevatedButton(
            onPressed: () => _speakText('Hello, how are you?'),
            child: Text('Speak'),
          ),
        ],
      ),
    );
  }
}
