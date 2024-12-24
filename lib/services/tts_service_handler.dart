// lib/services/tts_service_handler.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
      debugPrint('$TAG Audio playback completed');
      _isPlaying = false;
      _callback?.onComplete();
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      debugPrint('$TAG Player state changed: $state');
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
      debugPrint('$TAG Starting TTS conversion for text: $text');
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
        debugPrint('$TAG TTS API response received successfully');
        await _playAudio(response.bodyBytes, text, callback);
      } else {
        debugPrint('$TAG Failed TTS response: ${response.statusCode}');
        throw Exception('Failed to get TTS response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('$TAG Error in TTS conversion: $e');
      rethrow;
    }
  }

  Future<void> _playAudio(
    Uint8List audioData,
    String text,
    TextToSpeechCallback callback,
  ) async {
    try {
      debugPrint('$TAG Starting audio playback');

      // Notify start of speech
      callback.onStart(text);

      // Save the audio data to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/tts_audio.mp3');
      await tempFile.writeAsBytes(audioData);

      // Play the audio file
      await _audioPlayer.stop(); // Stop any existing playback
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
      _isPlaying = true;

      // Split text and schedule word callbacks
      final words = text.split(' ');

      // Wait for duration to be available
      await Future.delayed(Duration(milliseconds: 100));
      final duration =
          await _audioPlayer.getDuration() ?? const Duration(seconds: 1);
      final wordDelay = duration.inMilliseconds ~/ words.length;

      debugPrint(
          '$TAG Audio duration: ${duration.inMilliseconds}ms, Word delay: $wordDelay ms');

      // Cancel any existing timers
      for (var timer in _pendingTimers) {
        timer.cancel();
      }
      _pendingTimers.clear();

      // Schedule word progress callbacks
      for (var i = 0; i < words.length; i++) {
        final timer = Timer(
          Duration(milliseconds: wordDelay * i),
          () {
            if (_isPlaying) {
              callback.onProgress(words[i]);
              debugPrint('$TAG Speaking word: ${words[i]}');
            }
          },
        );
        _pendingTimers.add(timer);
      }
    } catch (e) {
      debugPrint('$TAG Error playing audio: $e');
      await _audioPlayer.stop();
      _isPlaying = false;

      // Clean up timers
      for (var timer in _pendingTimers) {
        timer.cancel();
      }
      _pendingTimers.clear();

      rethrow;
    }
  }

  bool get isPlaying => _isPlaying;

  Future<void> pauseSpeech() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
    }
  }

  Future<void> resumeSpeech() async {
    if (!_isPlaying) {
      await _audioPlayer.resume();
      _isPlaying = true;
    }
  }

  Future<void> stopSpeech() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    for (var timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
  }

  Future<void> endConversation() async {
    await stopSpeech();
  }

  void dispose() {
    stopSpeech();
    _audioPlayer.dispose();
  }
}

// Custom Source class for byte array
class BytesSource extends Source {
  final Uint8List bytes;

  BytesSource(this.bytes);

  @override
  Future<void> setOnPlayer(AudioPlayer player) async {
    await player.setSourceBytes(bytes);
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
