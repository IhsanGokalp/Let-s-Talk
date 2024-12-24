import 'package:flutter/material.dart';
import 'package:lets_tallk/models/user_data.dart';
import 'package:lets_tallk/services/chatgpt_service_handler.dart';
import 'package:lets_tallk/services/speech_handler.dart';
import 'package:lets_tallk/services/tts_service_handler.dart';
import 'package:lets_tallk/widgets/dot_waveform_animator.dart';
import 'package:lets_tallk/config/env_config.dart';

class ConversationActivity extends StatefulWidget {
  final UserData userData;

  const ConversationActivity({Key? key, required this.userData})
      : super(key: key);

  @override
  _ConversationActivityState createState() => _ConversationActivityState();
}

class _ConversationActivityState extends State<ConversationActivity>
    implements TextToSpeechCallback {
  SpeechHandler? _speechHandler;
  TTSServiceHandler? _ttsServiceHandler;
  ChatGPTServiceHandler? _chatGPTServiceHandler;
  final TextEditingController _conversationController = TextEditingController();
  bool _isProcessing = false;
  bool _isConversationActive = false;
  bool _isSpeaking = false;
  final List<Map<String, String>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeHandlers();
  }

  void _initializeHandlers() {
    _speechHandler = SpeechHandler(
      context: context,
      conversationController: _conversationController,
    );

    _ttsServiceHandler = TTSServiceHandler(
      apiKey: EnvConfig.openAiApiKey,
    );
    _ttsServiceHandler?.setCallback(this);

    _chatGPTServiceHandler = ChatGPTServiceHandler(
      apiKey: EnvConfig.openAiApiKey,
      onResponse: _onAIResponse,
      onError: _onAIError,
      ttsServiceHandler: _ttsServiceHandler!,
    );

    _speechHandler?.setOnSpeechResult(_processSpeechResult);
  }

  void _processSpeechResult(String text) {
    debugPrint('Processing speech result: $text');

    if (_chatGPTServiceHandler == null || !_isConversationActive) {
      debugPrint(
          'Error: ChatGPT handler is null or conversation is not active');
      return;
    }

    setState(() {
      _isProcessing = true;
      _conversationHistory.add({
        "role": "user",
        "content": text,
      });
      _conversationController.text += "User: $text\n\n";
    });

    try {
      // Stop listening while processing the response
      _speechHandler?.stopListening();

      _chatGPTServiceHandler!.generateTextAndConvertToSpeech(
        text,
        _conversationHistory,
      );
      debugPrint('Request sent to ChatGPT successfully');
    } catch (e, stackTrace) {
      debugPrint('Error calling ChatGPT: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isProcessing = false;
        // Only restart listening if there was an error
        if (_isConversationActive) {
          _speechHandler?.startListening();
        }
      });
    }
  }

  void _onAIResponse(String response) {
    debugPrint('Received AI response: $response');
    if (response.isEmpty) {
      debugPrint('Warning: Empty response received from AI');
      return;
    }

    setState(() {
      _isProcessing = false;
      _conversationHistory.add({
        "role": "assistant",
        "content": response,
      });
      _conversationController.text += "Elif: $response\n\n";
      // Keep _isProcessing true until TTS completes
      // It will be set to false in onComplete
    });
  }

  void _onAIError(String error) {
    debugPrint('AI Error: $error');
    setState(() {
      _isProcessing = false;
      _conversationController.text += "Error: $error\n\n";
    });
  }

  void _startConversation() {
    if (_speechHandler != null && !_isConversationActive) {
      setState(() {
        _isConversationActive = true;
        _isProcessing = false;
      });
      _speechHandler?.startListening();
      debugPrint('Conversation started');
    }
  }

  void _stopConversation() {
    if (_speechHandler != null) {
      setState(() {
        _isConversationActive = false;
        _isProcessing = false;
      });
      _speechHandler?.stopListening();
      _ttsServiceHandler?.endConversation();
      debugPrint('Conversation ended');
    }
  }

  @override
  void onStart(String text) {
    debugPrint('Started speaking: $text');
    setState(() {
      _isSpeaking = true;
    });
  }

  @override
  void onProgress(String word) {
    debugPrint('Speaking word: $word');
  }

  @override
  void onComplete() {
    debugPrint('TTS Complete');
    setState(() {
      _isSpeaking = false;
    });

    // Restart listening after TTS completes
    if (_speechHandler != null && mounted && _isConversationActive) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (_isConversationActive && mounted) {
          debugPrint('Restarting listening after TTS completion');
          _speechHandler?.startListening(); // Start the microphone again
        }
      });
    }
  }

  @override
  void dispose() {
    _speechHandler?.dispose();
    _conversationController.dispose();
    _ttsServiceHandler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'Building UI - isProcessing: $_isProcessing, isConversationActive: $_isConversationActive, isListening: ${_speechHandler?.isListening}');

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.userData.name} Let's Talk"),
        backgroundColor: Colors.white,
        actions: [
          // Add conversation state indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                if (_isProcessing)
                  Icon(Icons.sync, color: Colors.orange)
                else if (_speechHandler?.isListening ?? false)
                  Icon(Icons.mic, color: Colors.green)
                else if (_ttsServiceHandler?.isPlaying ?? false)
                  Icon(Icons.volume_up, color: Colors.blue)
                else
                  Icon(Icons.mic_off, color: Colors.red),
                SizedBox(width: 8),
                Text(_getStatusText()),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _conversationController,
                maxLines: null,
                readOnly: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Conversation will appear here...',
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: DotWaveformAnimator(
                isVisible: (_speechHandler?.isListening ?? false) &&
                    _isConversationActive,
                soundLevelStream: _speechHandler?.soundLevelStream,
              ),
            ),
            if (_isSpeaking)
              Center(
                child: Text(
                  'Speaking...',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isConversationActive ? null : _startConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isConversationActive ? Colors.grey : Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    _isConversationActive
                        ? "Conversation Active"
                        : "Start Conversation",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isConversationActive ? _stopConversation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isConversationActive ? Colors.red : Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    "End Conversation",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            if (_isProcessing) Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_isProcessing) return 'Processing...';
    if (_speechHandler?.isListening ?? false) return 'Listening';
    if (_ttsServiceHandler?.isPlaying ?? false) return 'Speaking';
    if (_isConversationActive) return 'Ready';
    return 'Inactive';
  }
}
