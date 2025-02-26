import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class SpeechHandler {
  static const String TAG = "SpeechHandler";

  final BuildContext context;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  final StreamController<double> _soundLevelController =
      StreamController<double>.broadcast();

  // Add this callback
  void Function(String)? onSpeechResult;

  // Constants
  static const int SPEECH_START_TIMEOUT = 5000;
  static const int USER_STOP_SPEAKING_TIMEOUT = 3000;
  static const double RMS_THRESHOLD = 0.1;

  // Timer for timeouts
  Timer? _speechStartTimer;
  Timer? _userStopSpeakingTimer;

  // Text controller for conversation
  final TextEditingController conversationController;
  final List<Map<String, String>> conversationHistory = [];

  SpeechHandler({
    required this.context,
    required this.conversationController,
  }) {
    initializeAndCheck();
  }

  // Add this method to set the callback
  void setOnSpeechResult(void Function(String) callback) {
    onSpeechResult = callback;
  }

  Stream<double> get soundLevelStream => _soundLevelController.stream;
  bool get isListening => _isListening;

  Future<bool> _checkPermission() async {
    bool hasPermission = await _speechToText.hasPermission;
    if (!hasPermission) {
      hasPermission = await _speechToText.initialize();
    }
    return hasPermission;
  }

  void _handleError(String error) {
    print('Speech recognition error: $error');
    _showToast(error);
    if (_isListening) {
      _speechToText.stop();
      _isListening = false;
    }
  }

  Future<bool> initializeAndCheck() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) => _handleError(error.errorMsg),
        onStatus: _handleStatus,
      );
      debugPrint('Speech recognition available: $available');
      return available;
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      return false;
    }
  }

  void _handleStatus(String status) {
    print('Speech recognition status: $status');
    switch (status) {
      case 'listening':
        _isListening = true;
        break;
      case 'notListening':
        _isListening = false;
        break;
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _startSpeechTimeout() {
    _speechStartTimer?.cancel();
    _speechStartTimer = Timer(Duration(milliseconds: SPEECH_START_TIMEOUT), () {
      if (!_isListening) {
        endConversation();
      }
    });
  }

  void _processSpeech(String voiceInput) {
    conversationHistory.add({
      'role': 'user',
      'content': voiceInput,
    });

    conversationController.text += '\nUser: $voiceInput\n\n';
    // Add callback for speech results
    onSpeechResult?.call(voiceInput);
  }

  void stopListening() {
    if (_isListening) {
      _speechToText.stop();
      _isListening = false;
      _speechStartTimer?.cancel();
      _userStopSpeakingTimer?.cancel();
    }
  }

  void clearConversationHistory() {
    conversationHistory.clear();
    conversationController.clear();
  }

  void endConversation() {
    stopListening();
    // Additional cleanup if needed
  }

  void startListening(Function(String) onResult) async {
    if (!_isListening) {
      bool hasPermission = await _checkPermission();
      if (!hasPermission) {
        _showToast('Microphone permission is required');
        return;
      }

      bool available = await _speechToText.initialize();
      if (available) {
        _isListening = true;
        _speechToText.listen(
          onResult: (result) {
            onResult(result.recognizedWords);
            if (result.finalResult) {
              _processSpeech(result.recognizedWords);
            }
          },
          listenFor: Duration(seconds: 30),
          localeId: 'en_US',
          cancelOnError: true,
          partialResults: true,
        );
      } else {
        _showToast('Speech recognition failed to initialize');
      }
    }
  }

  void dispose() {
    _speechStartTimer?.cancel();
    _userStopSpeakingTimer?.cancel();
    _soundLevelController.close();
    _speechToText.cancel();
  }
}

// Widget for visualizing sound levels (similar to DotWaveformAnimator)
class SoundLevelVisualizer extends StatelessWidget {
  final Stream<double> soundLevelStream;

  const SoundLevelVisualizer({
    Key? key,
    required this.soundLevelStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: soundLevelStream,
      builder: (context, snapshot) {
        double level = snapshot.data ?? 0.0;
        return Container(
          width: 20 + (level * 10), // Adjust size based on sound level
          height: 20 + (level * 10),
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// Example usage in a StatefulWidget:
class ConversationScreen extends StatefulWidget {
  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late SpeechHandler _speechHandler;
  final TextEditingController _conversationController = TextEditingController();

  void _initializeHandlers() {
    _speechHandler = SpeechHandler(
      context: context,
      conversationController: _conversationController,
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeHandlers();
    _checkAndInitializeSpeech();
  }

  Future<void> _checkAndInitializeSpeech() async {
    bool available = await _speechHandler?.initializeAndCheck() ?? false;
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Speech recognition is not available or permission denied'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voice Conversation')),
      body: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _conversationController,
              maxLines: null,
              readOnly: true,
            ),
          ),
          SoundLevelVisualizer(
            soundLevelStream: _speechHandler.soundLevelStream,
          ),
          ElevatedButton(
            onPressed: () {
              _speechHandler.startListening((String recognizedText) {
                // Handle the recognized text here
                print(recognizedText); // Print recognized text
              });
            },
            child: Text('Start Listening'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speechHandler.dispose();
    _conversationController.dispose();
    super.dispose();
  }
}
