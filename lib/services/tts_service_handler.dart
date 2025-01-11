// lib/services/tts_service_handler.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TTSServiceHandler {
  static const String tag = "TTSServiceHandler";
  final FlutterTts _flutterTts = FlutterTts();
  TextToSpeechCallback? _callback;
  bool _isPlaying = false;
  String _currentText = '';

  TTSServiceHandler({required String apiKey}) {
    _initTTS();
  }

  void _initTTS() {
    _flutterTts.setStartHandler(() {
      debugPrint('$tag Started speaking');
      _isPlaying = true;
    });

    _flutterTts
        .setProgressHandler((String text, int start, int end, String word) {
      debugPrint('$tag Speaking word: $word');
      _callback?.onProgress(word);
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('$tag Completed speaking');
      _isPlaying = false;
      _callback?.onComplete();
    });
  }

  Future<void> convertTextToSpeech(
    String text,
    String voice,
    TextToSpeechCallback callback,
  ) async {
    try {
      _currentText = text;
      _callback?.onStart(text);
      _callback?.onStart(text);
      await _flutterTts.setVoice({"name": voice, "locale": "en-US"});
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('$tag Error in TTS conversion: $e');
      rethrow;
    }
  }

  bool get isPlaying => _isPlaying;

  Future<void> pauseSpeech() async {
    if (_isPlaying) {
      await _flutterTts.pause();
      _isPlaying = false;
    }
  }

  Future<void> resumeSpeech() async {
    if (!_isPlaying) {
      await _flutterTts.speak(_currentText);
      _isPlaying = true;
    }
  }

  Future<void> stopSpeech() async {
    await _flutterTts.stop();
    _isPlaying = false;
    debugPrint('$tag endConversation');
  }

  void dispose() {
    stopSpeech();
    _flutterTts.stop();
    debugPrint('$tag Disposed');
  }

  void setCallback(TextToSpeechCallback callback) {
    _callback = callback;
  }
}

// Callback interface
abstract class TextToSpeechCallback {
  void onStart(String text);
  void onProgress(String word);
  void onComplete();
}
