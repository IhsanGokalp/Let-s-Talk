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

  Future<String> _getAudioFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
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

      debugPrint('$TAG Converting text to speech: $escapedText');

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

      debugPrint('$TAG Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('$TAG TTS API response received successfully');
        await _playAudio(response.bodyBytes, text, callback);
      } else {
        debugPrint(
            '$TAG Failed to get TTS response. Response code: ${response.statusCode}');
        debugPrint('$TAG Response error body: ${response.body}');
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
    File? tempAudioFile;
    try {
      // Get file path
      final filePath = await _getAudioFilePath();
      tempAudioFile = File(filePath);
      await tempAudioFile.writeAsBytes(audioData);

      debugPrint('$TAG Audio file created at: ${tempAudioFile.path}');

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

      debugPrint('$TAG Word delay: $wordDelay ms');

      // Schedule word progress callbacks
      for (var i = 0; i < words.length; i++) {
        final timer = Timer(
          Duration(milliseconds: wordDelay * i),
          () {
            callback.onProgress(words[i]);
            debugPrint('$TAG Speaking word: ${words[i]}');
          },
        );
        _pendingTimers.add(timer);
      }

      // Clean up file after playback
      _audioPlayer.onPlayerComplete.listen((_) async {
        try {
          if (tempAudioFile != null && await tempAudioFile.exists()) {
            await tempAudioFile.delete();
            debugPrint('$TAG Temporary audio file deleted');
          }
        } catch (e) {
          debugPrint('$TAG Error deleting temporary file: $e');
        }
      });
    } catch (e) {
      debugPrint('$TAG Error playing audio: $e');
      await _audioPlayer.stop();
      _isPlaying = false;

      // Clean up file if there's an error
      if (tempAudioFile != null) {
        try {
          if (await tempAudioFile.exists()) {
            await tempAudioFile.delete();
            debugPrint('$TAG Temporary audio file deleted after error');
          }
        } catch (deleteError) {
          debugPrint('$TAG Error deleting temporary file: $deleteError');
        }
      }
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

    debugPrint('$TAG endConversation');
  }

  Future<void> pauseSpeech() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
      debugPrint('$TAG Speech paused');
    }
  }

  Future<void> resumeSpeech() async {
    if (!_isPlaying) {
      await _audioPlayer.resume();
      _isPlaying = true;
      debugPrint('$TAG Speech resumed');
    }
  }

  Future<void> stopSpeech() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    debugPrint('$TAG Speech stopped');
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    stopSpeech();
    _audioPlayer.dispose();
    debugPrint('$TAG Disposed');
  }
}

// Callback interface
abstract class TextToSpeechCallback {
  void onStart(String text);
  void onProgress(String word);
  void onComplete();
}
