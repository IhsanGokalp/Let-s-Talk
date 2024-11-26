import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

import '../models/user_data.dart';
import '../services/chatgpt_service_handler.dart';
import '../services/tts_service_handler.dart';
import '../services/speech_handler.dart';
import '../config/env_config.dart';

class ConversationActivity extends StatefulWidget {
  final UserData userData;

  ConversationActivity({required this.userData});

  @override
  _ConversationActivityState createState() => _ConversationActivityState();
}

class _ConversationActivityState extends State<ConversationActivity>
    implements TextToSpeechCallback {
  late ChatGPTServiceHandler _chatGPTServiceHandler;
  late TTSServiceHandler _ttsServiceHandler;
  late SpeechHandler _speechHandler;

  bool _isProcessing = false;
  String _currentWord = '';
  List<Map<String, String>> _conversationHistory = [];
  final TextEditingController _conversationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeHandlers();
  }

  void _initializeHandlers() {
    _ttsServiceHandler = TTSServiceHandler(apiKey: EnvConfig.openAiApiKey);
    _ttsServiceHandler.setCallback(this);

    _chatGPTServiceHandler = ChatGPTServiceHandler(
      apiKey: EnvConfig.openAiApiKey,
      ttsServiceHandler: _ttsServiceHandler,
      onResponse: _onAIResponse,
      onError: _onAIError,
    );

    _speechHandler = SpeechHandler(
      context: context,
      conversationController: _conversationController,
    );

    // Connect speech handler to process results
    _speechHandler.setOnSpeechResult((String text) {
      _processSpeechResult(text);
    });

    // Listen to speech levels
    _speechHandler.soundLevelStream.listen((level) {
      // Handle sound level updates if needed
    });
  }

  void _onAIResponse(String response) {
    setState(() {
      _conversationHistory.add({"role": "assistant", "content": response});
      _conversationController.text += "Elif: $response\n\n";
      _isProcessing = false;
    });
  }

  void _onAIError(String error) {
    setState(() {
      _isProcessing = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    });
  }

  // Implement TextToSpeechCallback methods
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
    // Start listening again if needed
    if (!_speechHandler.isListening && mounted) {
      setState(() {
        _speechHandler.startListening();
      });
    }
  }

  // Modify the speech handler to process results
  void _processSpeechResult(String text) {
    setState(() {
      _isProcessing = true;
      _conversationController.text += "User: $text\n\n";
    });

    _chatGPTServiceHandler.generateTextAndConvertToSpeech(
      text,
      _conversationHistory,
    );
  }

  @override
  void dispose() {
    _ttsServiceHandler.dispose();
    _speechHandler.dispose();
    _conversationController.dispose();
    super.dispose();
  }

  Future<void> _pauseSpeech() async {
    await _ttsServiceHandler.pauseSpeech();
    setState(() {
      // Update UI if needed
    });
  }

  Future<void> _resumeSpeech() async {
    await _ttsServiceHandler.resumeSpeech();
    setState(() {
      // Update UI if needed
    });
  }

  Future<void> _stopSpeech() async {
    await _ttsServiceHandler.stopSpeech();
    setState(() {
      // Update UI if needed
    });
  }

  // Add speech control buttons to your UI
  Widget _buildSpeechControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_ttsServiceHandler.isPlaying)
          IconButton(
            icon: Icon(Icons.pause),
            onPressed: _pauseSpeech,
          ),
        if (!_ttsServiceHandler.isPlaying)
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: _resumeSpeech,
          ),
        IconButton(
          icon: Icon(Icons.stop),
          onPressed: _stopSpeech,
        ),
      ],
    );
  }
  // ... rest of your build method remains the same ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.userData.name} Let's Talk"),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Focus Areas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => print("Grammar Focus Selected"),
                  child: Text(
                    "Grammar",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                GestureDetector(
                  onTap: () => print("Pronunciation Focus Selected"),
                  child: Text(
                    "Pronunciation",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Conversation Display
            Expanded(
              child: TextField(
                controller: _conversationController,
                maxLines: null,
                readOnly: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            // Add current word display if TTS is active
            if (_currentWord.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Speaking: $_currentWord',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Add speech controls if TTS is active
            if (_ttsServiceHandler.isPlaying || _currentWord.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildSpeechControls(),
              ),

            // Sound Level Visualizer
            SoundLevelVisualizer(
              soundLevelStream: _speechHandler.soundLevelStream,
            ),

            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => print("Language Selection Clicked"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: Text("Turkish"),
                ),
                ElevatedButton(
                  onPressed: () => print("Language Selection Clicked"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: Text("Save Conversation"),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Progress Indicator
            if (_isProcessing) Center(child: CircularProgressIndicator()),

            // Start Listening Button
            Center(
              child: ElevatedButton(
                onPressed: (_isProcessing ||
                        _ttsServiceHandler.isPlaying) // Updated condition
                    ? null
                    : () {
                        setState(() {
                          _isProcessing = true;
                          _speechHandler.startListening();
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  _speechHandler.isListening
                      ? "Listening..."
                      : "Start Listening",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
