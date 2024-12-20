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
  String _currentWord = '';
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

    if (_chatGPTServiceHandler == null) {
      debugPrint('Error: ChatGPT handler is null');
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
      _chatGPTServiceHandler!.generateTextAndConvertToSpeech(
        text,
        _conversationHistory,
      );
      debugPrint('Request sent to ChatGPT with conversation history');
    } catch (e, stackTrace) {
      debugPrint('Error calling ChatGPT: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _onAIResponse(String response) {
    debugPrint('Received AI response: $response');
    if (response.isEmpty) {
      debugPrint('Warning: Empty response received from AI');
      return;
    }

    // Stop listening while AI is responding
    _speechHandler?.stopListening();

    setState(() {
      _isProcessing = false;
      _conversationHistory.add({
        "role": "assistant",
        "content": response,
      });
      _conversationController.text += "Elif: $response\n\n";
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
    }
  }

  @override
  void onStart(String text) {
    debugPrint('Started speaking: $text');
  }

  @override
  void onProgress(String word) {
    setState(() {
      _currentWord = word;
    });
    debugPrint('Speaking word: $word');
  }

  @override
  void onComplete() {
    debugPrint('TTS Complete');
    if (_speechHandler != null && mounted && _isConversationActive) {
      // Add a delay to ensure TTS has fully finished
      Future.delayed(Duration(milliseconds: 300), () {
        if (_isConversationActive && mounted) {
          debugPrint('Restarting listening after TTS completion');
          _speechHandler?.startListening();
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
                isVisible: _speechHandler?.isListening ?? false,
                soundLevelStream: _speechHandler?.soundLevelStream,
              ),
            ),
            if (_currentWord.isNotEmpty)
              Center(
                child: Text(
                  _currentWord,
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
}
